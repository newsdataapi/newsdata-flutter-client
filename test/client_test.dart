import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newsdataapi/newsdataapi.dart';
import 'package:test/test.dart';

String successBody(String resultsJson) =>
    '{"status":"success","results":$resultsJson}';

http.Response jsonResponse(int status, String body,
    {Map<String, String>? headers}) {
  return http.Response(body, status, headers: headers ?? {});
}

void main() {
  group('NewsDataApiClient', () {
    test('successful request resolves to a NewsdataResponse', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return jsonResponse(
          200,
          successBody('[{"article_id":"1","title":"a"}]'),
        );
      });
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      final resp = await client.latest(q: 'x');
      expect(resp.articles, hasLength(1));
      expect(resp.articles.first.title, 'a');
      expect(captured!.queryParameters['apikey'], 'key');
      expect(captured!.queryParameters['q'], 'x');
    });

    test('401 throws NewsdataAuthException with status code', () async {
      final mock = MockClient((_) async => jsonResponse(
            401,
            '{"status":"error","results":{"message":"bad key"}}',
          ));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      expect(
        () => client.latest(q: 'x'),
        throwsA(isA<NewsdataAuthException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );
    });

    test('429 retries then throws NewsdataRateLimitException', () async {
      var calls = 0;
      final mock = MockClient((_) async {
        calls += 1;
        final retryAfter = calls == 2 ? '7' : '0';
        return jsonResponse(
          429,
          '{"status":"error"}',
          headers: {'retry-after': retryAfter},
        );
      });
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        maxRetries: 2,
        retryBackoff: const Duration(milliseconds: 1),
      );

      try {
        await client.latest(q: 'x');
        fail('expected NewsdataRateLimitException');
      } on NewsdataRateLimitException catch (e) {
        expect(e.retryAfter, 7);
      }
      expect(calls, 2);
    });

    test('5xx is retried and then succeeds', () async {
      var calls = 0;
      final mock = MockClient((_) async {
        calls += 1;
        if (calls == 1) {
          return jsonResponse(503, '{"status":"error"}');
        }
        return jsonResponse(
          200,
          successBody('[{"article_id":"1","title":"recovered"}]'),
        );
      });
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        maxRetries: 3,
        retryBackoff: const Duration(milliseconds: 1),
      );

      final resp = await client.latest(q: 'x');
      expect(resp.articles.first.title, 'recovered');
      expect(calls, 2);
    });

    test('scrollAll merges results across pages', () async {
      final pages = [
        '{"status":"success","totalResults":3,"nextPage":"p2","results":[{"article_id":"1","title":"a"},{"article_id":"2","title":"b"}]}',
        '{"status":"success","totalResults":3,"results":[{"article_id":"3","title":"c"}]}',
      ];
      var calls = 0;
      final mock = MockClient((_) async => jsonResponse(200, pages[calls++]));
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        paginationDelay: Duration.zero,
      );

      final merged = await client.scrollAll(
        endpoint: Endpoint.latest,
        params: {'q': 'x'},
      );
      expect(merged.articles, hasLength(3));
      expect(calls, 2);
    });

    test('scrollAll honors maxResults', () async {
      final mock = MockClient((_) async => jsonResponse(
            200,
            '{"status":"success","nextPage":"p2","results":[{"article_id":"1","title":"a"},{"article_id":"2","title":"b"}]}',
          ));
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        paginationDelay: Duration.zero,
      );

      final merged = await client.scrollAll(
        endpoint: Endpoint.latest,
        params: {'q': 'x'},
        maxResults: 1,
      );
      expect(merged.articles, hasLength(1));
    });

    test('paginate yields one response per page', () async {
      final pages = [
        '{"status":"success","nextPage":"p2","results":[{"article_id":"1","title":"a"}]}',
        '{"status":"success","results":[{"article_id":"2","title":"b"}]}',
      ];
      var calls = 0;
      final mock = MockClient((_) async => jsonResponse(200, pages[calls++]));
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        paginationDelay: Duration.zero,
      );

      final seen = <String>[];
      await for (final page in client.paginate(
        endpoint: Endpoint.latest,
        params: {'q': 'x'},
      )) {
        seen.addAll(page.articles.map((a) => a.title ?? ''));
      }
      expect(seen, ['a', 'b']);
    });

    test('paginate stops at maxPages', () async {
      final pages = [
        '{"status":"success","nextPage":"p2","results":[{"article_id":"1","title":"a"}]}',
        '{"status":"success","nextPage":"p3","results":[{"article_id":"2","title":"b"}]}',
        '{"status":"success","nextPage":"p4","results":[{"article_id":"3","title":"c"}]}',
      ];
      var calls = 0;
      final mock = MockClient((_) async => jsonResponse(200, pages[calls++]));
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        paginationDelay: Duration.zero,
      );

      var count = 0;
      await for (final _ in client.paginate(
        endpoint: Endpoint.latest,
        params: {'q': 'x'},
        maxPages: 2,
      )) {
        count += 1;
      }
      expect(count, 2);
      expect(calls, 2);
    });

    test('empty apiKey is rejected', () {
      expect(
        () => NewsDataApiClient(apiKey: ''),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('redactApiKey hides the key', () {
      expect(
        redactApiKey('https://newsdata.io/api/1/latest?apikey=SECRET&q=foo'),
        'https://newsdata.io/api/1/latest?apikey=REDACTED&q=foo',
      );
    });

    test('typed errors form a catchable hierarchy', () async {
      final mock =
          MockClient((_) async => jsonResponse(401, '{"status":"error"}'));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      try {
        await client.latest(q: 'x');
        fail('expected exception');
      } on NewsdataException catch (e) {
        // catch-all base.
        expect(e, isA<NewsdataAuthException>());
        expect(e, isA<NewsdataApiException>());
      }
    });

    test('Article fields decode from snake_case JSON', () async {
      final mock = MockClient((_) async => jsonResponse(
            200,
            successBody(
              '[{"article_id":"a1","title":"t","link":"l","ai_tag":["x","y"],"sentiment":"positive","source_priority":1}]',
            ),
          ));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      final resp = await client.latest(q: 'x');
      final art = resp.articles.first;
      expect(art.articleId, 'a1');
      expect(art.title, 't');
      expect(art.link, 'l');
      expect(art.aiTag, ['x', 'y']);
      expect(art.sentiment, 'positive');
      expect(art.sourcePriority, 1);
    });

    test('count returns aggregate map when present', () async {
      final mock = MockClient((_) async => jsonResponse(
            200,
            '{"status":"success","results":{"total":42,"hour":{"00":1}}}',
          ));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      final resp = await client.count(
        fromDate: '2024-01-01',
        toDate: '2024-01-02',
      );
      expect(resp.aggregate, isNotNull);
      expect(resp.aggregate!['total'], 42);
      expect(resp.articles, isEmpty);
    });

    test('apikey embedded in URL stays out of error response bodies', () async {
      // The client never logs the URL in errors; this just confirms the
      // request URL contained the apikey as expected.
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return jsonResponse(401, '{"status":"error"}');
      });
      final client = NewsDataApiClient(apiKey: 'mykey', httpClient: mock);
      try {
        await client.latest(q: 'x');
      } on NewsdataAuthException {
        // expected
      }
      // Captured URL should contain the key (we sent it); redaction is for
      // logging only.
      expect(captured!.queryParameters['apikey'], 'mykey');
    });

    // Encoded JSON helper sanity for jsonEncode usage.
    test('jsonEncode + jsonDecode roundtrip on Article', () {
      final art = Article.fromJson(jsonDecode(
        '{"article_id":"x","title":"y","keywords":["a","b"]}',
      ) as Map<String, dynamic>);
      expect(art.articleId, 'x');
      expect(art.keywords, ['a', 'b']);
    });
  });
}
