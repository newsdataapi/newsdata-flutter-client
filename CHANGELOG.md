# Changelog

## 0.3.0

- Added `ArticleV2` and `response.articlesV2` for v2's article layout, which
  renames and regroups the v1 fields: `id` for `article_id`, `url` for `link`,
  `publishedAt` for `pubDate`, `metaDescription` for `description`, `keyword`
  for `keywords`, `ticker` for `symbol`, and the `source`, `media` and `ai`
  groups for the flat `source_*`, `image_url` / `video_url` and
  `sentiment` / `ai_tag` / `ai_region` / `ai_org` fields. New in v2:
  `ai.summary`, `fetchedAt`, `duplicate`, `coin` and `marketId`. The v2
  endpoints and the real-time stream carry this layout; `Article` and
  `response.articles` continue to model v1. A field your plan does not include
  arrives as the API's notice string in place of the data — decoding tolerates
  it, and the new `isPlanNotice(value)` tells it apart from real data.
- Added the v2 endpoints: `newsV2`, `marketV2`, `cryptoV2`, `sourcesV2`,
  `countNewsV2`, `countMarketV2`, `countCryptoV2`, each with typed named
  parameters for v2's filter vocabulary (`sourceUrl` / `excludeSourceUrl`
  replace the four domain filters, `sourcePriority` replaces `priorityDomain`,
  `content` replaces `fullContent`). `Endpoint.newsV2` and friends work with
  `scrollAll` / `paginate`. There is no `/2/archive` — `newsV2` covers
  historical news through `fromDate` / `toDate`.
- `NewsdataResponse` now reads the v2 envelope's `total_results` / `next_page`
  as well as v1's `totalResults` / `nextPage`, so `totalResults` and
  `nextPage` are populated whichever version answered.
- Added the `excludeDomainUrl` filter to the v1 endpoints that accept it
  (everything but `sources`); it joins the `domain` mutually-exclusive group.
- A 429 whose body says the API credits are exhausted now throws
  `NewsdataApiLimitExceededException` (the account's whole pool) or
  `NewsdataApiKeyLimitExceededException` (this one key's cap). Both extend
  `NewsdataRateLimitException`, so existing catches keep working. The new
  `RegistrationLimitExceeded` code — every real-time registration the plan
  allows is in use — is likewise never retried, but keeps the plain
  `NewsdataRateLimitException`, since it is about slots rather than credits.
- **Breaking:** the real-time service moved to API v2. The management endpoints
  are now `/2/websocket/{register,fetch,delete}`, `news_type` is `news` rather
  than `latest`, and `websocketRegister` takes the v2 filter vocabulary:
  `sourceUrl` / `excludeSourceUrl` replace `domain`, `domainUrl`,
  `excludeDomain` and `excludeDomainUrl`, `sourcePriority` replaces
  `priorityDomain`, and `content` replaces `fullContent`. Streamed responses
  and `websocketFetch` now carry `total_results`, and `websocketFetch` answers
  with a flat `results` list (one entry per query, each with a new `last_used`
  timestamp) rather than nesting it under `results['queries']`. Streamed
  articles use the v2 layout, so `Article` and `response.articles` — which
  model v1 — no longer fit them; decode them with `response.articlesV2`.
- **Breaking:** `baseUrl` is now the API root without a version segment
  (`https://newsdata.io/api/`); the endpoint paths carry `1/` or `2/`. Drop the
  trailing `1/` if you override it.

## 0.0.2

- First release via automated tokenless OIDC publishing from GitHub Actions
  (Trusted Publisher configured on pub.dev). No source changes.

## 0.0.1

Initial release.

- `NewsDataApiClient` with typed named-parameter methods for all 8 endpoints
  (`latest`, `archive`, `crypto`, `sources`, `market`, `count`,
  `cryptoCount`, `marketCount`).
- Client-side parameter validation (mutually-exclusive groups,
  `sentiment_score` requires `sentiment`, `size` 1–50,
  `from_date`/`to_date` required on count endpoints, `rawQuery` parsing).
- Typed exception hierarchy: `NewsdataException` →
  `NewsdataValidationException`, `NewsdataApiException` (→ `NewsdataAuthException`,
  `NewsdataRateLimitException`, `NewsdataServerException`),
  `NewsdataNetworkException`.
- Retries with exponential backoff and `Retry-After` parsing
  (integer seconds + HTTP-date).
- Two pagination helpers: `scrollAll` (merged) and `paginate`
  (`Stream<NewsdataResponse>`).
- Configurable `http.Client` injection, request timeout, and optional
  logger callback (API key is redacted in logged URLs).
- Typed `Article` deserialization with all server fields including AI
  enrichments (`aiTag`, `aiRegion`, `aiOrg`, `sentiment`, `sentimentStats`).
- 34 unit tests using `package:http/testing` mocks — no network needed.
- Compatible with Dart 3.0+ and Flutter 3.0+; works on iOS, Android, Web,
  and Desktop in pure Dart with no platform channels.
