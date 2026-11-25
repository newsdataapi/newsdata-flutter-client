// The v2 endpoints: versioned paths, the snake_case filter vocabulary, the
// snake_case envelope keys, and the quota-exhausted exception split.

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:newsdataapi/newsdataapi.dart';
import 'package:test/test.dart';

String successBody(String resultsJson) =>
    '{"status":"success","results":$resultsJson}';

http.Response jsonResponse(
  int status,
  String body, {
  Map<String, String>? headers,
}) {
  return http.Response(body, status, headers: headers ?? {});
}

String quotaBody(String code) =>
    '{"status":"error","results":{"message":"limit","code":"$code"}}';

void main() {
  group('v2 endpoint paths', () {
    test('each v2 method hits its versioned path', () async {
      final expected = <String, String>{
        '/api/2/news': 'newsV2',
        '/api/2/market': 'marketV2',
        '/api/2/crypto': 'cryptoV2',
        '/api/2/sources': 'sourcesV2',
        '/api/2/count/news': 'countNewsV2',
        '/api/2/count/market': 'countMarketV2',
        '/api/2/count/crypto': 'countCryptoV2',
      };

      for (final entry in expected.entries) {
        Uri? captured;
        final mock = MockClient((req) async {
          captured = req.url;
          return jsonResponse(200, successBody('[]'));
        });
        final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

        // sources takes no `q`, so send a filter every v2 endpoint accepts.
        switch (entry.value) {
          case 'newsV2':
            await client.newsV2(language: ['en']);
          case 'marketV2':
            await client.marketV2(language: ['en']);
          case 'cryptoV2':
            await client.cryptoV2(language: ['en']);
          case 'sourcesV2':
            await client.sourcesV2(language: ['en']);
          case 'countNewsV2':
            await client.countNewsV2(language: ['en']);
          case 'countMarketV2':
            await client.countMarketV2(language: ['en']);
          case 'countCryptoV2':
            await client.countCryptoV2(language: ['en']);
        }
        expect(captured!.path, entry.key, reason: entry.value);
      }
    });

    test('v1 methods keep their versioned path', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return jsonResponse(200, successBody('[]'));
      });
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      await client.latest(q: 'x');
      expect(captured!.path, '/api/1/latest');
    });
  });

  group('v2 filter vocabulary', () {
    test('sends the snake_case names', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return jsonResponse(200, successBody('[]'));
      });
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      await client.newsV2(
        qInTitle: 'tesla',
        excludeCountry: ['cn'],
        sourceUrl: ['bbc.com'],
        sourcePriority: 'top',
        content: true,
        removeDuplicate: true,
        excludeField: ['description'],
      );

      final q = captured!.queryParameters;
      expect(q['q_in_title'], 'tesla');
      expect(q['exclude_country'], 'cn');
      expect(q['source_url'], 'bbc.com');
      expect(q['source_priority'], 'top');
      expect(q['content'], '1');
      expect(q['remove_duplicate'], '1');
      expect(q['exclude_field'], 'description');
    });

    test('rawQuery on a v2 method is checked against the v2 keyset', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return jsonResponse(200, successBody('[]'));
      });
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      await client.newsV2(rawQuery: 'q_in_title=tesla&source_url=bbc.com');
      expect(captured!.queryParameters['q_in_title'], 'tesla');

      expect(
        () => client.newsV2(rawQuery: 'qInTitle=tesla'),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('source_url and exclude_source_url are mutually exclusive', () {
      final mock =
          MockClient((_) async => jsonResponse(200, successBody('[]')));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      expect(
        () => client.newsV2(
          sourceUrl: ['a.com'],
          excludeSourceUrl: ['b.com'],
        ),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('q / qInTitle / qInMeta are mutually exclusive', () {
      final mock =
          MockClient((_) async => jsonResponse(200, successBody('[]')));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      expect(
        () => client.newsV2(q: 'a', qInTitle: 'b'),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('country / excludeCountry are mutually exclusive', () {
      final mock =
          MockClient((_) async => jsonResponse(200, successBody('[]')));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      expect(
        () => client.newsV2(country: ['us'], excludeCountry: ['cn']),
        throwsA(isA<NewsdataValidationException>()),
      );
    });
  });

  group('v2 envelope', () {
    test('reads total_results and next_page', () async {
      final mock = MockClient((_) async => jsonResponse(
            200,
            '{"status":"success","total_results":42,"results":[],'
            '"next_page":"abc"}',
          ));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      final resp = await client.newsV2(q: 'x');
      expect(resp.totalResults, 42);
      expect(resp.nextPage, 'abc');
    });

    test('still reads the v1 totalResults and nextPage', () async {
      final mock = MockClient((_) async => jsonResponse(
            200,
            '{"status":"success","totalResults":42,"results":[],'
            '"nextPage":"abc"}',
          ));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      final resp = await client.latest(q: 'x');
      expect(resp.totalResults, 42);
      expect(resp.nextPage, 'abc');
    });

    test('scrollAll follows the v2 cursor', () async {
      var calls = 0;
      final mock = MockClient((req) async {
        calls++;
        if (calls == 1) {
          return jsonResponse(
            200,
            '{"status":"success","total_results":2,'
            '"results":[{"article_id":"1"}],"next_page":"p2"}',
          );
        }
        return jsonResponse(
          200,
          '{"status":"success","total_results":2,'
          '"results":[{"article_id":"2"}]}',
        );
      });
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        paginationDelay: Duration.zero,
      );

      final merged = await client.scrollAll(
        endpoint: Endpoint.newsV2,
        params: {'q': 'x'},
      );
      expect(merged.articles, hasLength(2));
      expect(calls, 2);
    });

    test('scrollAll rejects the v2 sources endpoint', () {
      final mock =
          MockClient((_) async => jsonResponse(200, successBody('[]')));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      expect(
        () => client.scrollAll(endpoint: Endpoint.sourcesV2),
        throwsA(isA<NewsdataValidationException>()),
      );
    });
  });

  group('the quota split', () {
    test('ApiLimitExceeded raises the account-pool exception', () async {
      var calls = 0;
      final mock = MockClient((_) async {
        calls++;
        return jsonResponse(429, quotaBody('ApiLimitExceeded'));
      });
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        maxRetries: 5,
        retryBackoff: Duration.zero,
      );

      await expectLater(
        client.newsV2(q: 'x'),
        throwsA(isA<NewsdataApiLimitExceededException>()),
      );
      expect(calls, 1, reason: 'an exhausted quota must not retry');
    });

    test('ApiKeyLimitExceeded raises the per-key exception', () async {
      final mock = MockClient((_) async => jsonResponse(
            429,
            quotaBody('ApiKeyLimitExceeded'),
            headers: {'x-apikey-limit-remaining': '0'},
          ));
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        maxRetries: 5,
        retryBackoff: Duration.zero,
      );

      await expectLater(
        client.newsV2(q: 'x'),
        throwsA(isA<NewsdataApiKeyLimitExceededException>()),
      );
    });

    test('both still match NewsdataRateLimitException', () async {
      final mock = MockClient(
        (_) async => jsonResponse(429, quotaBody('ApiLimitExceeded')),
      );
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        maxRetries: 1,
        retryBackoff: Duration.zero,
      );

      await expectLater(
        client.newsV2(q: 'x'),
        throwsA(isA<NewsdataRateLimitException>()),
      );
    });

    test('a transient 429 still retries and stays the base exception',
        () async {
      var calls = 0;
      final mock = MockClient((_) async {
        calls++;
        return jsonResponse(429, quotaBody('RateLimitExceeded'));
      });
      final client = NewsDataApiClient(
        apiKey: 'key',
        httpClient: mock,
        maxRetries: 2,
        retryBackoff: Duration.zero,
      );

      await expectLater(
        client.newsV2(q: 'x'),
        throwsA(
          allOf(
            isA<NewsdataRateLimitException>(),
            isNot(isA<NewsdataApiLimitExceededException>()),
            isNot(isA<NewsdataApiKeyLimitExceededException>()),
          ),
        ),
      );
      expect(calls, 2);
    });
  });

  group('excludedomainurl (v1)', () {
    test('is accepted on the v1 endpoints that take it', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return jsonResponse(200, successBody('[]'));
      });
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      await client.latest(excludeDomainUrl: ['bbc.com']);
      expect(captured!.queryParameters['excludedomainurl'], 'bbc.com');
    });

    test('joins the v1 domain mutex group', () {
      final mock =
          MockClient((_) async => jsonResponse(200, successBody('[]')));
      final client = NewsDataApiClient(apiKey: 'key', httpClient: mock);

      expect(
        () => client.latest(domain: ['a.com'], excludeDomainUrl: ['b.com']),
        throwsA(isA<NewsdataValidationException>()),
      );
    });
  });
}
