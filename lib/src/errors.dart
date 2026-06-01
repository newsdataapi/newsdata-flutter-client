// Exception hierarchy for the Newsdata.io Dart client.
//
// All exceptions thrown by the SDK derive from `NewsdataException`, so callers
// can use a single
//
//   } on NewsdataException catch (e) { ... }
//
// as a catch-all. More specific subclasses are provided for cases where
// callers want to react differently (validation, auth, rate limiting, etc.).

/// Base class for every exception raised by the Newsdata.io SDK.
class NewsdataException implements Exception {
  NewsdataException(this.message);

  final String message;

  @override
  String toString() => 'NewsdataException: $message';
}

/// A user-provided parameter failed client-side validation. No request was
/// sent.
class NewsdataValidationException extends NewsdataException {
  NewsdataValidationException(super.message, {this.param});

  /// The offending parameter name, when known.
  final String? param;

  @override
  String toString() => param != null
      ? 'NewsdataValidationException: $message (param: $param)'
      : 'NewsdataValidationException: $message';
}

/// The API returned a structured error response.
class NewsdataApiException extends NewsdataException {
  NewsdataApiException(
    super.message, {
    this.statusCode,
    this.responseBody,
  });

  /// HTTP status returned by the API.
  final int? statusCode;

  /// Parsed JSON body of the error response, when available.
  final Map<String, dynamic>? responseBody;

  @override
  String toString() => 'NewsdataApiException: $message (status: $statusCode)';
}

/// Raised on 401 / 403 responses (missing, invalid, or unauthorized API key).
class NewsdataAuthException extends NewsdataApiException {
  NewsdataAuthException(
    super.message, {
    super.statusCode,
    super.responseBody,
  });
}

/// Raised on 429 responses once retries are exhausted. `retryAfter` is the
/// number of seconds the `Retry-After` header asked for, or `null` when the
/// header was missing or unparseable.
class NewsdataRateLimitException extends NewsdataApiException {
  NewsdataRateLimitException(
    super.message, {
    super.statusCode = 429,
    super.responseBody,
    this.retryAfter,
  });

  final int? retryAfter;

  @override
  String toString() => retryAfter != null
      ? 'NewsdataRateLimitException: $message (retry after ${retryAfter}s)'
      : 'NewsdataRateLimitException: $message';
}

/// Raised on 5xx responses once retries are exhausted.
class NewsdataServerException extends NewsdataApiException {
  NewsdataServerException(
    super.message, {
    super.statusCode,
    super.responseBody,
  });
}

/// A network-level failure (DNS, TLS, timeout, socket error) prevented the
/// request from completing.
class NewsdataNetworkException extends NewsdataException {
  NewsdataNetworkException(super.message, {this.cause});

  /// The underlying error, when available.
  final Object? cause;

  @override
  String toString() => cause != null
      ? 'NewsdataNetworkException: $message (cause: $cause)'
      : 'NewsdataNetworkException: $message';
}
