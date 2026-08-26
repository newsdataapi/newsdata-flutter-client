import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newsdataapi/newsdataapi.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

http.Response jsonResponse(int status, String body) =>
    http.Response(body, status, headers: const {});

String articleFrame(String id, String title) =>
    '{"status":"success","totalResults":1,'
    '"results":[{"article_id":"$id","title":"$title"}]}';

/// A scriptable stand-in for a live [WebSocketChannel]. [script] runs with the
/// fake once the stream is subscribed, and drives what the client sees.
class FakeChannel implements WebSocketChannel {
  FakeChannel(this.script, this.connectionNumber);

  final void Function(FakeChannel channel) script;
  final int connectionNumber;

  final _controller = StreamController<Object?>();
  final _readyCompleter = Completer<void>();

  @override
  int? closeCode;
  @override
  String? closeReason;

  /// Drive the script as soon as the fake exists — the client awaits `ready`
  /// before it subscribes, so waiting for `.stream` would deadlock. Events
  /// sent before the subscription are buffered by the controller.
  void start() => scheduleMicrotask(() => script(this));

  @override
  Stream<Object?> get stream => _controller.stream;

  @override
  Future<void> get ready => _readyCompleter.future;

  /// Complete the handshake successfully.
  void open() {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  /// Fail the handshake with [error].
  void rejectHandshake(Object error) {
    if (!_readyCompleter.isCompleted) _readyCompleter.completeError(error);
    _controller.close();
  }

  /// Deliver one frame.
  void send(String payload) => _controller.add(payload);

  /// Drop the connection with a close code.
  void drop(int code, [String reason = '']) {
    closeCode = code;
    closeReason = reason;
    _controller.close();
  }

  @override
  WebSocketSink get sink => _FakeSink(this);

  @override
  String? get protocol => null;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  _FakeSink(this.channel);
  final FakeChannel channel;

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!channel._controller.isClosed) await channel._controller.close();
  }

  @override
  void add(Object? data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<Object?> stream) async {}
  @override
  Future<void> get done => channel._controller.done;
}

/// Builds a connect function that hands out scripted fakes, recording each.
({
  WebSocketChannel Function(Uri) connect,
  List<FakeChannel> channels,
  List<Uri> uris,
}) fakeConnector(void Function(FakeChannel channel) script) {
  final channels = <FakeChannel>[];
  final uris = <Uri>[];
  WebSocketChannel connect(Uri uri) {
    uris.add(uri);
    final channel = FakeChannel(script, channels.length + 1);
    channels.add(channel);
    channel.start();
    return channel;
  }

  return (connect: connect, channels: channels, uris: uris);
}

NewsDataApiClient clientWith([http.Client? httpClient]) => NewsDataApiClient(
      apiKey: 'key',
      httpClient: httpClient ??
          MockClient((_) async => jsonResponse(200, '{"status":"success"}')),
    );

void main() {
  group('NewsDataApiWebSocket.stream', () {
    test('yields each response as it arrives', () async {
      final f = fakeConnector((c) {
        c.open();
        c.send(articleFrame('a1', 'one'));
        c.send(articleFrame('a2', 'two'));
      });
      final ws = NewsDataApiWebSocket(clientWith(),
          connect: f.connect, reconnect: false);

      final titles = <String>[];
      await for (final response in ws.stream('reg-1')) {
        titles.add(response.articles.first.title!);
        if (titles.length == 2) break;
      }

      expect(titles, ['one', 'two']);
    });

    test('sends apikey and registration_id in the query', () async {
      final f = fakeConnector((c) {
        c.open();
        c.send(articleFrame('a1', 'one'));
      });
      final ws = NewsDataApiWebSocket(clientWith(),
          connect: f.connect, reconnect: false);

      await for (final _ in ws.stream('reg-42')) {
        break;
      }

      expect(f.uris.first.queryParameters['apikey'], 'key');
      expect(f.uris.first.queryParameters['registration_id'], 'reg-42');
    });

    test('skips malformed frames', () async {
      final f = fakeConnector((c) {
        c.open();
        c.send('not json at all');
        c.send(articleFrame('a1', 'one'));
      });
      final ws = NewsDataApiWebSocket(clientWith(),
          connect: f.connect, reconnect: false);

      final seen = <String>[];
      await for (final response in ws.stream('reg-1')) {
        seen.add(response.articles.first.title!);
        break;
      }

      expect(seen, ['one'], reason: 'malformed frame should be skipped');
    });

    test('close code 1008 is a permanent rejection and is not retried',
        () async {
      final f = fakeConnector((c) {
        c.open();
        c.drop(1008, 'quota exhausted');
      });
      // reconnect stays ON to prove a permanent rejection is not retried.
      final ws = NewsDataApiWebSocket(
        clientWith(),
        connect: f.connect,
        reconnectDelay: const Duration(milliseconds: 1),
      );

      await expectLater(
        ws.stream('reg-1').toList(),
        throwsA(
          isA<NewsdataWebSocketAuthException>().having(
            (e) => e.message,
            'message',
            contains('quota exhausted'),
          ),
        ),
      );
      expect(f.channels, hasLength(1),
          reason: 'a permanent rejection must not retry');
    });

    test('a handshake rejected with 401 is permanent', () async {
      final f = fakeConnector((c) {
        c.rejectHandshake(
          WebSocketChannelException('WebSocketException: status 401'),
        );
      });
      final ws = NewsDataApiWebSocket(
        clientWith(),
        connect: f.connect,
        reconnectDelay: const Duration(milliseconds: 1),
      );

      await expectLater(
        ws.stream('reg-1').toList(),
        throwsA(isA<NewsdataWebSocketAuthException>()),
      );
      expect(f.channels, hasLength(1));
    });

    test('a transient failure stops with a websocket error when reconnect '
        'is disabled', () async {
      final f = fakeConnector((c) {
        c.rejectHandshake(WebSocketChannelException('connection refused'));
      });
      final ws = NewsDataApiWebSocket(clientWith(),
          connect: f.connect, reconnect: false);

      await expectLater(
        ws.stream('reg-1').toList(),
        throwsA(
          allOf(
            isA<NewsdataWebSocketException>(),
            isNot(isA<NewsdataWebSocketAuthException>()),
          ),
        ),
      );
    });

    test('reconnects after a transient drop', () async {
      final f = fakeConnector((c) {
        if (c.connectionNumber == 1) {
          c.open();
          c.drop(1011, 'server restart'); // transient
          return;
        }
        c.open();
        c.send(articleFrame('a1', 'after-reconnect'));
      });
      final ws = NewsDataApiWebSocket(
        clientWith(),
        connect: f.connect,
        reconnectDelay: const Duration(milliseconds: 1),
        reconnectDelayMax: const Duration(milliseconds: 5),
      );

      final titles = <String>[];
      await for (final response in ws.stream('reg-1')) {
        titles.add(response.articles.first.title!);
        break;
      }

      expect(titles, ['after-reconnect']);
      expect(f.channels.length, greaterThanOrEqualTo(2));
    });

    test('rejects an empty registration id', () async {
      final ws = NewsDataApiWebSocket(clientWith());
      await expectLater(
        ws.stream('').toList(),
        throwsA(isA<NewsdataValidationException>()),
      );
    });
  });

  group('query management', () {
    test('websocketRegister POSTs and injects news_type=latest', () async {
      http.Request? captured;
      final mock = MockClient((req) async {
        captured = req;
        return jsonResponse(
          200,
          '{"status":"success","results":{"registration_id":"reg-9"}}',
        );
      });
      final client = clientWith(mock);

      final resp = await client.websocketRegister(q: 'bitcoin');

      expect(captured!.method, 'POST');
      expect(captured!.url.queryParameters['news_type'], 'latest');
      expect(captured!.url.queryParameters['q'], 'bitcoin');
      expect(captured!.url.path, contains('websocket/register'));
      expect(resp.aggregate!['registration_id'], 'reg-9');
    });

    test('websocketFetch uses GET', () async {
      http.Request? captured;
      final mock = MockClient((req) async {
        captured = req;
        return jsonResponse(
          200,
          '{"status":"success","results":{"queries":[]}}',
        );
      });

      await clientWith(mock).websocketFetch();

      expect(captured!.method, 'GET');
      expect(captured!.url.path, contains('websocket/fetch'));
    });

    test('websocketDelete uses DELETE and carries registration_id', () async {
      http.Request? captured;
      final mock = MockClient((req) async {
        captured = req;
        return jsonResponse(
          200,
          '{"status":"success","results":{"deleted":true}}',
        );
      });

      await clientWith(mock).websocketDelete('reg-9');

      expect(captured!.method, 'DELETE');
      expect(captured!.url.queryParameters['registration_id'], 'reg-9');
    });

    test('websocketDelete rejects an empty id', () {
      expect(
        () => clientWith().websocketDelete(''),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('a resultless success envelope still succeeds', () async {
      final mock =
          MockClient((_) async => jsonResponse(200, '{"status":"success"}'));

      final resp = await clientWith(mock).websocketDelete('reg-9');
      expect(resp.status, 'success');
    });
  });
}
