<div align="center">

![Newsdata.io logo](https://raw.githubusercontent.com/newsdataapi/newsdata-flutter-client/main/newsdata-logo.png)

# Newsdata.io Dart / Flutter Client

[![pub.dev](https://img.shields.io/pub/v/newsdataapi.svg?logo=dart&color=0175c2)](https://pub.dev/packages/newsdataapi)
[![pub.dev points](https://img.shields.io/pub/points/newsdataapi?logo=dart)](https://pub.dev/packages/newsdataapi/score)
[![CI](https://img.shields.io/github/actions/workflow/status/newsdataapi/newsdata-flutter-client/ci.yml?branch=main&logo=github&label=CI)](https://github.com/newsdataapi/newsdata-flutter-client/actions/workflows/ci.yml)
[![Dart SDK](https://img.shields.io/badge/dart-%3E%3D3.0-0175c2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.1-85EA2D)](https://newsdata.io/openapi.json)

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

The API has two versions. v2 is the current one; the v1 methods keep working
unchanged.

### v2

| Method | Endpoint | Notes |
|--------|----------|-------|
| `client.newsV2(...)` | `/2/news` | Latest news, or historical with `fromDate` / `toDate` |
| `client.marketV2(...)` | `/2/market` | Market / financial news |
| `client.cryptoV2(...)` | `/2/crypto` | Cryptocurrency news |
| `client.sourcesV2(...)` | `/2/sources` | Available sources (single page) |
| `client.countNewsV2(...)` | `/2/count/news` | Aggregate news counts |
| `client.countMarketV2(...)` | `/2/count/market` | Aggregate market counts |
| `client.countCryptoV2(...)` | `/2/count/crypto` | Aggregate crypto counts |
| `client.websocketRegister(...)` | `/2/websocket/register` | Register a real-time query |
| `client.websocketFetch()` | `/2/websocket/fetch` | List registered queries |
| `client.websocketDelete(id)` | `/2/websocket/delete` | Delete a registered query |

v2 renames the filter vocabulary and folds the four domain filters into two.
Dart-side the names stay camelCase; the SDK maps them to v2's snake_case form:

| v1 (Dart) | v2 (Dart) | v2 (wire) |
|-----------|-----------|-----------|
| `qInTitle`, `qInMeta` | `qInTitle`, `qInMeta` | `q_in_title`, `q_in_meta` |
| `excludeCountry`, `excludeCategory`, `excludeLanguage` | same | `exclude_country`, `exclude_category`, `exclude_language` |
| `domain`, `domainUrl`, `excludeDomain`, `excludeDomainUrl` | `sourceUrl`, `excludeSourceUrl` | `source_url`, `exclude_source_url` |
| `priorityDomain` | `sourcePriority` | `source_priority` |
| `fullContent` | `content` | `content` |
| `removeDuplicate`, `excludeField` | same | `remove_duplicate`, `exclude_field` |

`coin` and `marketId` keep their names. Unlike the v1 count endpoints, the v2
ones do not require `fromDate` / `toDate`.

```dart
final resp = await client.newsV2(
  qInTitle: 'tesla',
  sourceUrl: ['bbc.com'],
  content: true,
);
print('${resp.totalResults} results, next page ${resp.nextPage}');
```

The v2 envelope spells its total and cursor `total_results` / `next_page`
where v1 spells them `totalResults` / `nextPage`. `NewsdataResponse` reads
either, so `totalResults`, `nextPage`, `scrollAll` and `paginate` behave the
same whichever version answered. Pass `Endpoint.newsV2` and friends to the
pagination helpers.

There is no `/2/archive` — `newsV2` covers historical news through
`fromDate` / `toDate`.

#### v2 articles

v2 renamed and regrouped the article fields, so the v2 endpoints and the
real-time stream decode with `articlesV2` and `ArticleV2`, while the v1
endpoints keep `articles` and `Article`:

```dart
final resp = await client.newsV2(q: 'bitcoin');

for (final a in resp.articlesV2) {
  print('${a.title} ${a.url} ${a.publishedAt}');
  print('${a.source.name} ${a.source.priority}');
  print(a.media.imageUrl);
  print('${a.ai.summary} ${a.ai.sentiment.label} ${a.ai.tag}');
}
```

| v1 (`Article`) | v2 (`ArticleV2`) |
|----------------|------------------|
| `articleId` | `id` |
| `link` | `url` |
| `pubDate` | `publishedAt` |
| `description` | `metaDescription` |
| `keywords` | `keyword` |
| `symbol` | `ticker` |
| `sourceName`, `sourceUrl`, `sourcePriority`, `sourceIcon` | `source.name`, `source.url`, `source.priority`, `source.iconUrl` |
| `imageUrl`, `videoUrl` | `media.imageUrl`, `media.videoUrl` |
| `sentiment`, `sentimentStats` | `ai.sentiment.label`, `ai.sentiment.score` |
| `aiTag`, `aiRegion`, `aiOrg` | `ai.tag`, `ai.region`, `ai.organization` |
| — | `ai.summary`, `fetchedAt`, `duplicate`, `coin`, `marketId` |

The `source`, `media` and `ai` groups are never null — a group the API did not
send has null fields and empty lists — so `a.source.name` needs no null check
on the group itself. `ai.region` entries are comma-separated paths from the
narrowest place to the widest (`"mumbai,maharashtra,india"`), so do not split
them on commas.

A field your plan does not include arrives as the API's notice string in place
of the data (`"ONLY AVAILABLE IN PAID PLANS"`). Decoding tolerates it — a list
field holds the single notice, and a withheld sentiment carries it in
`ai.sentiment.label` — and `isPlanNotice(value)` tells it apart from real
data.

### v1

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

The real-time service is v2 only — there are no v1 WebSocket methods.

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

## Real-time news (WebSocket)

The real-time service is part of API v2. Register a query first — the returned
`registration_id` identifies it from then on:

```dart
final registered = await client.websocketRegister(q: 'bitcoin', language: ['en']);
final registrationId = registered.aggregate!['registration_id'] as String;
```

`websocketRegister` takes the same filter parameters as `newsV2` (`q`,
`qInTitle`, `country`, `excludeCountry`, `sourceUrl`, `content`,
`excludeField`, `timezone`, …) — the date, paging and sorting filters, `id` and
`url` don't apply to a standing query. Registering an identical query twice
throws `NewsdataApiException` with `statusCode` 409; the existing id is in the
response body.

`websocketFetch()` lists every registered query: `rawResults` is a list with
one entry per query, carrying its `registration_id`, the filters it was
registered with (`query`), how many devices are streaming it now
(`active_clients`) and when one last connected (`last_used`, UTC).
`websocketDelete(id)` removes one. Once every registration the plan allows is
in use, registering another throws a 429 `NewsdataRateLimitException` carrying
the code `RegistrationLimitExceeded`; it is not retried, since only deleting a
registration frees a slot.

Then stream. Each response carries `status`, `totalResults` and its results,
and its articles use the v2 layout, so decode them with `articlesV2`:

```dart
final ws = NewsDataApiWebSocket(client);

await for (final response in ws.stream(registrationId)) {
  for (final a in response.articlesV2) {
    print('${a.title} - ${a.url} (${a.source.name})');
  }
}
```

Break out of the loop, cancel the subscription, or call `ws.close()` to stop;
the connection is closed either way.

Transient drops (network errors, server restarts, abnormal closes) are
reconnected automatically with a capped exponential backoff. Pass
`reconnect: false` to stop on the first disconnect instead. A permanent
rejection — bad API key or unknown
`registration_id`, exhausted API credits, or too many simultaneous devices — throws
`NewsdataWebSocketAuthException` and is **not** retried.

The server always accepts the handshake and then closes with code **1008** when
the connection is refused, carrying one of three reasons: `invalid credentials
or registration not found`, `api limit reached`, or `device limit reached` (more
than 5 devices on one `registration_id`). Every other close code — including
`1013` (`send timeout`, meaning the client read too slowly) — is transient and
reconnects.

**Each delivered article consumes 1 API credit per connected device.**

Catch it like any other client error:

```dart
try {
  await for (final response in ws.stream(registrationId)) {
    // ...
  }
} on NewsdataWebSocketAuthException catch (e) {
  print('rejected: ${e.message}');
} on NewsdataWebSocketException catch (e) {
  print('stream error: ${e.message}');
}
```

All connection options are optional:

```dart
final ws = NewsDataApiWebSocket(
  client,
  baseUrl: 'wss://ws.newsdata.io/ws/event',           // staging / self-hosted
  reconnect: true,                                     // default true
  reconnectDelay: const Duration(seconds: 1),          // first delay; doubles each retry
  reconnectDelayMax: const Duration(seconds: 30),      // cap on the delay
  handshakeTimeout: const Duration(seconds: 10),       // opening handshake bound
);
```

Streaming uses [`web_socket_channel`](https://pub.dev/packages/web_socket_channel),
so it works on native **and** web targets.

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
│   │   ├── NewsdataApiLimitExceededException     (account credits gone)
│   │   └── NewsdataApiKeyLimitExceededException  (this key's cap gone)
│   │   (RegistrationLimitExceeded stays on NewsdataRateLimitException —
│   │    real-time registration slots, not credits)
│   └── NewsdataServerException         (5xx)
├── NewsdataNetworkException            (.cause)
└── NewsdataWebSocketException          (.cause — real-time stream)
    └── NewsdataWebSocketAuthException  (policy-violation close 1008)
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

A 429 that waiting cannot fix is never retried.
`NewsdataApiLimitExceededException` means the account's whole credit pool is
exhausted, `NewsdataApiKeyLimitExceededException` means this one key hit its
own cap while the account may still have credits; both extend
`NewsdataRateLimitException`, so an existing `on NewsdataRateLimitException`
catch keeps working. `RegistrationLimitExceeded` is also never retried, but
keeps the plain `NewsdataRateLimitException` — it is about real-time
registration slots, not credits, and is fixed by deleting a registration.

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
- **Node.js** — [newsdataapi/newsdata-nodejs-client](https://github.com/newsdataapi/newsdata-nodejs-client) ([npm](https://www.npmjs.com/package/newsdata-nodejs-client))
- **React (hooks)** — [newsdataapi/newsdata-reactjs-client](https://github.com/newsdataapi/newsdata-reactjs-client) ([npm](https://www.npmjs.com/package/newsdataapi))
- **PHP** — [newsdataapi/php-client](https://github.com/newsdataapi/php-client) ([Packagist](https://packagist.org/packages/newsdataio/newsdataapi))
- **Java** — [newsdataapi/newsdata-java-sdk](https://github.com/newsdataapi/newsdata-java-sdk) ([Maven Central](https://central.sonatype.com/artifact/io.newsdata/newsdataapi))
- **.NET** — [newsdataapi/newsdata-dotnet-sdk](https://github.com/newsdataapi/newsdata-dotnet-sdk) ([NuGet](https://www.nuget.org/packages/Newsdata.Api/))
- **Go** — [newsdataapi/newsdata-go-client](https://github.com/newsdataapi/newsdata-go-client) ([pkg.go.dev](https://pkg.go.dev/github.com/newsdataapi/newsdata-go-client))
- **MCP Server (AI assistants)** — [newsdataapi/newsdata.io-mcp](https://github.com/newsdataapi/newsdata.io-mcp) ([PyPI](https://pypi.org/project/newsdata-mcp/))

Also see [free news datasets](https://github.com/newsdataapi/newsdata.io-free-datasets) for ML / NLP work.

## License

[MIT](./LICENSE)
