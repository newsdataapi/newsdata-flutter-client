// Real-time WebSocket support for NewsData.io.
//
// Uses `web_socket_channel`, which works on native and web targets alike
// (`dart:io`'s WebSocket is native-only).

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'client.dart';
import 'constants.dart';
import 'errors.dart';
import 'response.dart';

/// NewsData.io real-time WebSocket service.
///
/// Registers, lists, and deletes the account's real-time queries and streams
/// the responses for a registered query. The management calls delegate to the
/// wrapped [NewsDataApiClient]:
///
/// ```dart
/// final client = NewsDataApiClient(apiKey: 'YOUR_API_KEY');
/// final ws = NewsDataApiWebSocket(client);
///
/// final registered = await ws.websocketRegister(q: 'bitcoin');
/// final id = registered.aggregate!['registration_id'] as String;
///
/// await for (final response in ws.stream(id)) {
///   for (final article in response.articles) {
///     print(article.title);
///   }
/// }
/// ```
///
/// Transient drops (network errors, server restarts, abnormal closes) are
/// reconnected automatically with a capped exponential backoff; pass
/// `reconnect: false` to stop on the first disconnect. A permanent rejection
/// always throws [NewsdataWebSocketAuthException] and is never retried.
///
/// Break out of the `await for` loop, cancel the subscription, or call
/// [close] to stop; the connection is closed either way.
class NewsDataApiWebSocket {
  NewsDataApiWebSocket(
    this._client, {
    String baseUrl = wsBaseUrl,
    bool reconnect = true,
    Duration reconnectDelay = wsReconnectDelay,
    Duration reconnectDelayMax = wsReconnectDelayMax,
    Duration handshakeTimeout = wsHandshakeTimeout,
    WebSocketChannel Function(Uri uri)? connect,
  })  : _baseUrl = baseUrl,
        _reconnect = reconnect,
        _reconnectDelay = reconnectDelay,
        _reconnectDelayMax = reconnectDelayMax,
        _handshakeTimeout = handshakeTimeout,
        _connect = connect ?? WebSocketChannel.connect;

  final NewsDataApiClient _client;
  final String _baseUrl;
  final bool _reconnect;
  final Duration _reconnectDelay;
  final Duration _reconnectDelayMax;
  final Duration _handshakeTimeout;

  /// Injection point for tests; defaults to [WebSocketChannel.connect].
  final WebSocketChannel Function(Uri uri) _connect;

  WebSocketChannel? _channel;
  bool _closed = false;

  // ---- query management -------------------------------------------------

  /// Register a real-time query. See [NewsDataApiClient.websocketRegister].
  Future<NewsdataResponse> websocketRegister({
    String? q,
    String? qInTitle,
    String? qInMeta,
    List<String>? country,
    List<String>? excludeCountry,
    List<String>? category,
    List<String>? excludeCategory,
    List<String>? language,
    List<String>? excludeLanguage,
    List<String>? domain,
    List<String>? domainUrl,
    List<String>? excludeDomain,
    String? priorityDomain,
    String? timezone,
    bool? fullContent,
    bool? image,
    bool? video,
    bool? removeDuplicate,
    List<String>? tag,
    String? sentiment,
    double? sentimentScore,
    List<String>? region,
    List<String>? organization,
    List<String>? creator,
    List<String>? dataType,
    List<String>? excludeField,
    String? rawQuery,
  }) {
    return _client.websocketRegister(
      q: q,
      qInTitle: qInTitle,
      qInMeta: qInMeta,
      country: country,
      excludeCountry: excludeCountry,
      category: category,
      excludeCategory: excludeCategory,
      language: language,
      excludeLanguage: excludeLanguage,
      domain: domain,
      domainUrl: domainUrl,
      excludeDomain: excludeDomain,
      priorityDomain: priorityDomain,
      timezone: timezone,
      fullContent: fullContent,
      image: image,
      video: video,
      removeDuplicate: removeDuplicate,
      tag: tag,
      sentiment: sentiment,
      sentimentScore: sentimentScore,
      region: region,
      organization: organization,
      creator: creator,
      dataType: dataType,
      excludeField: excludeField,
      rawQuery: rawQuery,
    );
  }

  /// List registered queries. See [NewsDataApiClient.websocketFetch].
  Future<NewsdataResponse> websocketFetch() => _client.websocketFetch();

  /// Delete a registered query. See [NewsDataApiClient.websocketDelete].
  Future<NewsdataResponse> websocketDelete(String registrationId) =>
      _client.websocketDelete(registrationId);

  // ---- streaming --------------------------------------------------------

  Uri _uri(String registrationId) => Uri.parse(_baseUrl).replace(
        queryParameters: <String, String>{
          'apikey': _client.apiKeyForWebSocket,
          'registration_id': registrationId,
        },
      );

  Duration _nextDelay(Duration delay) {
    final doubled = delay * 2;
    return doubled > _reconnectDelayMax ? _reconnectDelayMax : doubled;
  }

  /// Connect and yield each response for [registrationId] as it arrives.
  /// Responses have the familiar `status` / `totalResults` / `results` shape.
  Stream<NewsdataResponse> stream(String registrationId) async* {
    if (registrationId.isEmpty) {
      throw NewsdataValidationException(
        'registrationId must be a non-empty string',
        param: 'registration_id',
      );
    }

    final uri = _uri(registrationId);
    final logUrl = redactApiKey(uri.toString());
    var delay = _reconnectDelay;
    _closed = false;

    try {
      while (!_closed) {
        final channel = _connect(uri);
        _channel = channel;

        var opened = false;
        Object? failure;

        try {
          // `ready` completes when the handshake succeeds, and throws on a
          // rejected or failed one.
          await channel.ready.timeout(_handshakeTimeout);
          opened = true;
          _client.logFromWebSocket('info', 'connected to $logUrl');
          delay = _reconnectDelay; // reset after a successful connect

          await for (final message in channel.stream) {
            if (_closed) return;
            final response = _parse(message);
            if (response != null) yield response;
          }
        } catch (e) {
          failure = e;
        }

        if (_closed) return;

        final closeCode = channel.closeCode;
        final closeReason = channel.closeReason;

        // Close code 1008 is a permanent rejection, whether it arrived as a
        // clean close or as an error.
        if (closeCode == wsPolicyViolation) {
          throw NewsdataWebSocketAuthException(
            (closeReason == null || closeReason.isEmpty)
                ? 'connection rejected'
                : closeReason,
            cause: failure,
          );
        }

        if (failure != null) {
          final auth = _permanentAuthError(failure, opened);
          if (auth != null) throw auth;
          if (!_reconnect) throw _transientError(failure);
          _client.logFromWebSocket(
            'warn',
            'connection to $logUrl failed ($failure); reconnecting in $delay',
          );
        } else {
          // Clean close.
          if (!_reconnect) return;
        }

        if (!_reconnect) return;
        await Future<void>.delayed(delay);
        delay = _nextDelay(delay);
      }
    } finally {
      close();
    }
  }

  /// Parse one frame, returning null when it isn't a JSON object.
  NewsdataResponse? _parse(Object? message) {
    if (message is! String) return null;
    try {
      final decoded = jsonDecode(message);
      if (decoded is! Map<String, dynamic>) return null;
      return NewsdataResponse.fromJson(decoded);
    } catch (_) {
      return null; // skip malformed frames
    }
  }

  /// The auth error to throw if the failure is permanent, else null.
  ///
  /// Close code 1008 is the documented permanent signal and is handled by the
  /// caller; this covers the defensive case of a proxy rejecting the handshake
  /// itself. The underlying platform error carries the status only on native
  /// targets, so the message is matched for 401 / 403.
  NewsdataWebSocketAuthException? _permanentAuthError(
    Object failure,
    bool opened,
  ) {
    if (opened) return null; // the handshake succeeded; this drop is transient
    final text = failure.toString();
    if (text.contains('401') || text.contains('403')) {
      return NewsdataWebSocketAuthException(
        'connection rejected',
        cause: failure,
      );
    }
    return null;
  }

  /// Wrap a transient failure; used only when reconnect is disabled.
  NewsdataWebSocketException _transientError(Object failure) =>
      NewsdataWebSocketException('connection error: $failure', cause: failure);

  /// Close the active connection, ending any in-flight [stream].
  void close() {
    _closed = true;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(
        channel.sink.close(ws_status.normalClosure).catchError((Object _) {}),
      );
    }
  }
}
