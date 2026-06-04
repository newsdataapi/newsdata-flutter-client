<div align="center">

![Newsdata.io logo](https://raw.githubusercontent.com/newsdataapi/newsdata-flutter-client/main/newsdata-logo.png)

# Newsdata.io Dart / Flutter Client

[![pub.dev](https://img.shields.io/pub/v/newsdataapi.svg?logo=dart&color=0175c2)](https://pub.dev/packages/newsdataapi)
[![pub.dev points](https://img.shields.io/pub/points/newsdataapi?logo=dart)](https://pub.dev/packages/newsdataapi/score)
[![CI](https://img.shields.io/github/actions/workflow/status/newsdataapi/newsdata-flutter-client/ci.yml?branch=main&logo=github&label=CI)](https://github.com/newsdataapi/newsdata-flutter-client/actions/workflows/ci.yml)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.0-0175c2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)

</div>

Official Dart/Flutter client for the [Newsdata.io](https://newsdata.io) News
API. Pure Dart — works in Flutter (iOS, Android, Web, Desktop) **and** standalone
Dart (CLI, server, AngularDart). Typed named-parameter methods for all eight
endpoints with client-side validation, retries with exponential backoff,
`Stream`-based pagination, and a typed exception hierarchy.

Zero Flutter dependencies; only runtime deps are `package:http` and
`package:meta`.

## Installation

```bash
flutter pub add newsdataapi
# or for pure Dart projects:
dart pub add newsdataapi
```

## Quickstart

```dart
import 'package:newsdataapi/newsdataapi.dart';

Future<void> main() async {
  final client = NewsDataApiClient(apiKey: 'YOUR_API_KEY');

  try {
    final resp = await client.latest(
      q: 'bitcoin',
      country: ['us', 'gb'],
      language: ['en'],
    );
    for (final article in resp.articles) {
      print('${article.title} — ${article.link}');
    }
  } on NewsdataRateLimitException catch (e) {
    print('rate limited, retry after ${e.retryAfter} seconds');
  } on NewsdataException catch (e) {
    print('failed: $e');
  } finally {
    client.close();
  }
}
```

## Endpoints

| Method | Endpoint | Notes |
|--------|----------|-------|
| `client.latest(...)` | `/1/latest` | Real-time news |
| `client.archive(...)` | `/1/archive` | Historical news |
| `client.sources(...)` | `/1/sources` | Available sources (single page) |
| `client.crypto(...)` | `/1/crypto` | Cryptocurrency news |
| `client.market(...)` | `/1/market` | Market / financial news |
| `client.count({required fromDate, required toDate, ...})` | `/1/count` | Aggregate counts |
| `client.cryptoCount({required fromDate, required toDate, ...})` | `/1/crypto/count` | Aggregate crypto counts |
| `client.marketCount({required fromDate, required toDate, ...})` | `/1/market/count` | Aggregate market counts |

Every endpoint method has **typed named parameters** for every accepted field —
the Dart compiler enforces that only valid parameters for that endpoint
compile. The count endpoints' `fromDate` / `toDate` are `required`, so
forgetting them is a compile error, not a runtime one.

Multi-value params accept `List<String>` (sent comma-joined). Booleans become
`1`/`0`. Names like `qInTitle`/`fromDate` are camelCase Dart-side — the SDK
maps them to the API's lowercase form (`qintitle`, `from_date`).

## Pagination

Two helpers — both work for every endpoint except `sources`:

```dart
// 1) scrollAll: follow nextPage and return one merged response.
final all = await client.scrollAll(
  endpoint: Endpoint.latest,
  params: {'q': 'news'},
  maxResults: 200,
);
print(all.articles.length); // up to 200 articles

// 2) paginate: idiomatic Stream<NewsdataResponse>.
await for (final page in client.paginate(
  endpoint: Endpoint.latest,
  params: {'q': 'news'},
  maxPages: 5,
)) {
  process(page.articles);
}
```

`paginate` returns a `Stream`, so you can use everything Dart streams give
you — `take`, `where`, `transform`, cancellation via `await for` break.

## Raw query

```dart
await client.latest(rawQuery: 'q=bitcoin&country=us&language=en');
```

`rawQuery` is mutually exclusive with every other parameter and is parsed and
validated against the endpoint's allowed keys before the request leaves.

## Client-side validation

A `NewsdataValidationException` is thrown — before any HTTP request — when:

- a parameter is not accepted by that endpoint;
- mutually-exclusive parameters are set together — `q`/`qInTitle`/`qInMeta`,
  `country`/`excludeCountry`, `category`/`excludeCategory`,
  `language`/`excludeLanguage`, `domain`/`domainUrl`/`excludeDomain`;
- `size` is outside 1–50;
- `sentimentScore` is set without `sentiment`.

Plus the count endpoints' `fromDate`/`toDate` are `required` at the type
level — no runtime check needed.

## Error handling

```dart
try {
  final resp = await client.latest(q: 'news');
} on NewsdataValidationException catch (e) {
  // bad parameter — e.param, e.message
} on NewsdataAuthException catch (e) {
  // 401 / 403
} on NewsdataRateLimitException catch (e) {
  // 429 — e.retryAfter (seconds)
} on NewsdataServerException catch (e) {
  // 5xx
} on NewsdataApiException catch (e) {
  // other API errors — e.statusCode, e.responseBody
} on NewsdataNetworkException catch (e) {
  // socket / TLS / timeout — e.cause
}
```

Hierarchy:

```
NewsdataException                       (catch-all base)
├── NewsdataValidationException         (.param, .message)
├── NewsdataApiException                (.statusCode, .responseBody)
│   ├── NewsdataAuthException           (401 / 403)
│   ├── NewsdataRateLimitException      (429; .retryAfter)
│   └── NewsdataServerException         (5xx)
└── NewsdataNetworkException            (.cause)
```

## Configuration

```dart
final client = NewsDataApiClient(
  apiKey: apiKey,
  timeout: const Duration(seconds: 30),
  maxRetries: 5,
  retryBackoff: const Duration(seconds: 2),     // base, exponential
  retryBackoffMax: const Duration(seconds: 60), // cap on a single sleep
  paginationDelay: const Duration(seconds: 1),
  includeHeaders: true,                          // attach response headers
  httpClient: myCustomClient,                    // proxies, mTLS, etc.
  logger: (level, msg) => print('[$level] $msg'),// API key is redacted in URLs
);
```

`httpClient` is the standard `http.Client` — inject `http_test_handler`,
`http_logger`, `dio_http_client`, or any package that provides one, and the
SDK uses it transparently. The SDK does not close the injected client (the
caller owns it); it does close a client it created itself when `client.close()`
is called.

Retries cover network errors, HTTP 429, and 5xx responses. 429 honors the
`Retry-After` header (integer seconds or HTTP-date); otherwise backoff is
exponential. Auth and other 4xx errors are never retried.

## Where it works

| Platform | Supported |
|---|:-:|
| Flutter — iOS | ✅ |
| Flutter — Android | ✅ |
| Flutter — Web | ✅ (CORS rules on the API apply) |
| Flutter — macOS / Windows / Linux | ✅ |
| Pure Dart — CLI / server | ✅ |

This is a pure Dart package, not a plugin — no platform channels, no Swift
or Kotlin to compile.

## Development

```bash
dart pub get
dart analyze --fatal-infos
dart format --output=none --set-exit-if-changed lib test example
dart test                                       # 34 tests; no network needed
```

The test suite uses `package:http/testing`'s `MockClient` to mock the API
end-to-end. No API key required.

## Related libraries

Official Newsdata.io clients across languages and runtimes:

- **Python** — [newsdataapi/python-client](https://github.com/newsdataapi/python-client) ([PyPI](https://pypi.org/project/newsdataapi/))
- **Node.js** — [newsdataapi/newsdata-nodejs-client](https://github.com/newsdataapi/newsdata-nodejs-client) (npm)
- **React (hooks)** — [newsdataapi/newsdata-reactjs-client](https://github.com/newsdataapi/newsdata-reactjs-client) (npm)
- **PHP** — [newsdataapi/php-client](https://github.com/newsdataapi/php-client) ([Packagist](https://packagist.org/packages/newsdataio/newsdataapi))
- **Java** — [newsdataapi/newsdata-java-sdk](https://github.com/newsdataapi/newsdata-java-sdk) (Maven Central)
- **.NET** — [newsdataapi/newsdata-dotnet-sdk](https://github.com/newsdataapi/newsdata-dotnet-sdk) ([NuGet](https://www.nuget.org/packages/Newsdata.Api/))
- **Go** — [newsdataapi/newsdata-go-client](https://github.com/newsdataapi/newsdata-go-client) (Go modules)
- **MCP Server (AI assistants)** — [newsdataapi/newsdata.io-mcp](https://github.com/newsdataapi/newsdata.io-mcp) ([PyPI](https://pypi.org/project/newsdata-mcp/))

Also see [free news datasets](https://github.com/newsdataapi/newsdata.io-free-datasets) for ML / NLP work.

## License

[MIT](./LICENSE)
