# Changelog

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
