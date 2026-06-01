// HTTP client for the Newsdata.io REST API.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'constants.dart';
import 'errors.dart';
import 'response.dart';
import 'validator.dart';

/// Function signature for the optional logger. The client calls this once per
/// request attempt and on retries; the URL is already API-key-redacted.
typedef NewsdataLogger = void Function(String level, String message);

/// HTTP client for the Newsdata.io API. Construct with [NewsDataApiClient.new]
/// and call the per-endpoint methods ([latest], [archive], …). All methods
/// return `Future<NewsdataResponse>` and throw [NewsdataException] subclasses
/// on failure.
///
/// Safe for concurrent use.
class NewsDataApiClient {
  NewsDataApiClient({
    required String apiKey,
    String baseUrl = baseUrl_,
    Duration timeout = defaultRequestTimeout,
    int maxRetries = defaultMaxRetries,
    Duration retryBackoff = defaultRetryBackoff,
    Duration retryBackoffMax = defaultRetryBackoffMax,
    Duration paginationDelay = defaultPaginationDelay,
    bool includeHeaders = false,
    http.Client? httpClient,
    NewsdataLogger? logger,
  })  : _apiKey = _requireApiKey(apiKey),
        _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
        _timeout = timeout,
        _maxRetries = math.max(1, maxRetries),
        _retryBackoff = retryBackoff,
        _retryBackoffMax = retryBackoffMax,
        _paginationDelay = paginationDelay,
        _includeHeaders = includeHeaders,
        _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _logger = logger;

  final String _apiKey;
  final String _baseUrl;
  final Duration _timeout;
  final int _maxRetries;
  final Duration _retryBackoff;
  final Duration _retryBackoffMax;
  final Duration _paginationDelay;
  final bool _includeHeaders;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final NewsdataLogger? _logger;

  static String _requireApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      throw NewsdataValidationException(
        'apiKey must be a non-empty string',
        param: 'apiKey',
      );
    }
    return apiKey;
  }

  /// Release the underlying [http.Client] if this client created it. Safe to
  /// call multiple times. If you passed your own client via [httpClient], it
  /// is not closed (the caller owns it).
  void close() {
    if (_ownsHttpClient) _httpClient.close();
  }

  // ---- endpoint methods ------------------------------------------------

  /// Fetch real-time news. GET /1/latest.
  Future<NewsdataResponse> latest({
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
    Object? timeframe,
    String? timezone,
    int? size,
    bool? fullContent,
    bool? image,
    bool? video,
    String? page,
    List<String>? tag,
    String? sentiment,
    List<String>? region,
    List<String>? excludeField,
    bool? removeDuplicate,
    Object? id,
    List<String>? organization,
    String? url,
    String? sort,
    List<String>? creator,
    List<String>? dataType,
    double? sentimentScore,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.latest,
      {
        'q': q,
        'qintitle': qInTitle,
        'qinmeta': qInMeta,
        'country': country,
        'excludecountry': excludeCountry,
        'category': category,
        'excludecategory': excludeCategory,
        'language': language,
        'excludelanguage': excludeLanguage,
        'domain': domain,
        'domainurl': domainUrl,
        'excludedomain': excludeDomain,
        'prioritydomain': priorityDomain,
        'timeframe': timeframe?.toString(),
        'timezone': timezone,
        'size': size,
        'full_content': fullContent,
        'image': image,
        'video': video,
        'page': page,
        'tag': tag,
        'sentiment': sentiment,
        'region': region,
        'excludefield': excludeField,
        'removeduplicate': removeDuplicate,
        'id': id,
        'organization': organization,
        'url': url,
        'sort': sort,
        'creator': creator,
        'datatype': dataType,
        'sentiment_score': sentimentScore,
      },
      rawQuery: rawQuery,
    );
  }

  /// Fetch historical news. GET /1/archive.
  Future<NewsdataResponse> archive({
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
    int? size,
    bool? fullContent,
    bool? image,
    bool? video,
    String? page,
    String? fromDate,
    String? toDate,
    List<String>? excludeField,
    Object? id,
    String? url,
    String? sort,
    List<String>? tag,
    String? sentiment,
    double? sentimentScore,
    List<String>? region,
    List<String>? organization,
    List<String>? creator,
    List<String>? dataType,
    bool? removeDuplicate,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.archive,
      {
        'q': q,
        'qintitle': qInTitle,
        'qinmeta': qInMeta,
        'country': country,
        'excludecountry': excludeCountry,
        'category': category,
        'excludecategory': excludeCategory,
        'language': language,
        'excludelanguage': excludeLanguage,
        'domain': domain,
        'domainurl': domainUrl,
        'excludedomain': excludeDomain,
        'prioritydomain': priorityDomain,
        'timezone': timezone,
        'size': size,
        'full_content': fullContent,
        'image': image,
        'video': video,
        'page': page,
        'from_date': fromDate,
        'to_date': toDate,
        'excludefield': excludeField,
        'id': id,
        'url': url,
        'sort': sort,
        'tag': tag,
        'sentiment': sentiment,
        'sentiment_score': sentimentScore,
        'region': region,
        'organization': organization,
        'creator': creator,
        'datatype': dataType,
        'removeduplicate': removeDuplicate,
      },
      rawQuery: rawQuery,
    );
  }

  /// Fetch cryptocurrency news. GET /1/crypto.
  Future<NewsdataResponse> crypto({
    String? q,
    String? qInTitle,
    String? qInMeta,
    List<String>? language,
    List<String>? excludeLanguage,
    List<String>? domain,
    List<String>? domainUrl,
    List<String>? excludeDomain,
    String? priorityDomain,
    Object? timeframe,
    String? timezone,
    int? size,
    bool? fullContent,
    bool? image,
    bool? video,
    String? page,
    List<String>? tag,
    String? sentiment,
    List<String>? coin,
    List<String>? excludeField,
    String? fromDate,
    String? toDate,
    bool? removeDuplicate,
    Object? id,
    String? url,
    String? sort,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.crypto,
      {
        'q': q,
        'qintitle': qInTitle,
        'qinmeta': qInMeta,
        'language': language,
        'excludelanguage': excludeLanguage,
        'domain': domain,
        'domainurl': domainUrl,
        'excludedomain': excludeDomain,
        'prioritydomain': priorityDomain,
        'timeframe': timeframe?.toString(),
        'timezone': timezone,
        'size': size,
        'full_content': fullContent,
        'image': image,
        'video': video,
        'page': page,
        'tag': tag,
        'sentiment': sentiment,
        'coin': coin,
        'excludefield': excludeField,
        'from_date': fromDate,
        'to_date': toDate,
        'removeduplicate': removeDuplicate,
        'id': id,
        'url': url,
        'sort': sort,
      },
      rawQuery: rawQuery,
    );
  }

  /// List available news sources. GET /1/sources. Single-page endpoint;
  /// [scrollAll] and [paginate] are not supported for sources.
  Future<NewsdataResponse> sources({
    List<String>? country,
    List<String>? category,
    List<String>? language,
    String? priorityDomain,
    List<String>? domainUrl,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.sources,
      {
        'country': country,
        'category': category,
        'language': language,
        'prioritydomain': priorityDomain,
        'domainurl': domainUrl,
      },
      rawQuery: rawQuery,
    );
  }

  /// Fetch market / financial news. GET /1/market.
  Future<NewsdataResponse> market({
    String? q,
    String? qInTitle,
    String? qInMeta,
    String? fromDate,
    String? toDate,
    List<String>? country,
    List<String>? excludeCountry,
    List<String>? domain,
    List<String>? domainUrl,
    List<String>? excludeDomain,
    List<String>? language,
    List<String>? excludeLanguage,
    String? priorityDomain,
    String? timezone,
    Object? timeframe,
    int? size,
    bool? fullContent,
    bool? image,
    bool? video,
    String? page,
    List<String>? tag,
    String? sentiment,
    List<String>? excludeField,
    bool? removeDuplicate,
    List<String>? organization,
    List<String>? symbol,
    Object? id,
    String? url,
    String? sort,
    List<String>? creator,
    List<String>? dataType,
    double? sentimentScore,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.market,
      {
        'q': q,
        'qintitle': qInTitle,
        'qinmeta': qInMeta,
        'from_date': fromDate,
        'to_date': toDate,
        'country': country,
        'excludecountry': excludeCountry,
        'domain': domain,
        'domainurl': domainUrl,
        'excludedomain': excludeDomain,
        'language': language,
        'excludelanguage': excludeLanguage,
        'prioritydomain': priorityDomain,
        'timezone': timezone,
        'timeframe': timeframe?.toString(),
        'size': size,
        'full_content': fullContent,
        'image': image,
        'video': video,
        'page': page,
        'tag': tag,
        'sentiment': sentiment,
        'excludefield': excludeField,
        'removeduplicate': removeDuplicate,
        'organization': organization,
        'symbol': symbol,
        'id': id,
        'url': url,
        'sort': sort,
        'creator': creator,
        'datatype': dataType,
        'sentiment_score': sentimentScore,
      },
      rawQuery: rawQuery,
    );
  }

  /// Fetch aggregate news counts for a date range. GET /1/count. Requires
  /// [fromDate] and [toDate].
  Future<NewsdataResponse> count({
    required String fromDate,
    required String toDate,
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
    bool? fullContent,
    bool? image,
    bool? video,
    String? priorityDomain,
    String? page,
    int? size,
    String? sort,
    String? interval,
    List<String>? tag,
    String? sentiment,
    double? sentimentScore,
    List<String>? region,
    List<String>? organization,
    List<String>? creator,
    List<String>? dataType,
    bool? removeDuplicate,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.count,
      {
        'from_date': fromDate,
        'to_date': toDate,
        'q': q,
        'qintitle': qInTitle,
        'qinmeta': qInMeta,
        'country': country,
        'excludecountry': excludeCountry,
        'category': category,
        'excludecategory': excludeCategory,
        'language': language,
        'excludelanguage': excludeLanguage,
        'domain': domain,
        'domainurl': domainUrl,
        'excludedomain': excludeDomain,
        'full_content': fullContent,
        'image': image,
        'video': video,
        'prioritydomain': priorityDomain,
        'page': page,
        'size': size,
        'sort': sort,
        'interval': interval,
        'tag': tag,
        'sentiment': sentiment,
        'sentiment_score': sentimentScore,
        'region': region,
        'organization': organization,
        'creator': creator,
        'datatype': dataType,
        'removeduplicate': removeDuplicate,
      },
      rawQuery: rawQuery,
    );
  }

  /// Fetch aggregate crypto counts. GET /1/crypto/count. Requires [fromDate]
  /// and [toDate].
  Future<NewsdataResponse> cryptoCount({
    required String fromDate,
    required String toDate,
    String? q,
    String? qInTitle,
    String? qInMeta,
    List<String>? language,
    List<String>? excludeLanguage,
    List<String>? coin,
    List<String>? domain,
    List<String>? domainUrl,
    List<String>? excludeDomain,
    bool? fullContent,
    bool? image,
    bool? video,
    String? priorityDomain,
    String? page,
    String? sentiment,
    int? size,
    String? sort,
    List<String>? tag,
    String? interval,
    bool? removeDuplicate,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.cryptoCount,
      {
        'from_date': fromDate,
        'to_date': toDate,
        'q': q,
        'qintitle': qInTitle,
        'qinmeta': qInMeta,
        'language': language,
        'excludelanguage': excludeLanguage,
        'coin': coin,
        'domain': domain,
        'domainurl': domainUrl,
        'excludedomain': excludeDomain,
        'full_content': fullContent,
        'image': image,
        'video': video,
        'prioritydomain': priorityDomain,
        'page': page,
        'sentiment': sentiment,
        'size': size,
        'sort': sort,
        'tag': tag,
        'interval': interval,
        'removeduplicate': removeDuplicate,
      },
      rawQuery: rawQuery,
    );
  }

  /// Fetch aggregate market counts. GET /1/market/count. Requires [fromDate]
  /// and [toDate].
  Future<NewsdataResponse> marketCount({
    required String fromDate,
    required String toDate,
    String? q,
    String? qInTitle,
    String? qInMeta,
    List<String>? country,
    List<String>? excludeCountry,
    List<String>? domain,
    List<String>? domainUrl,
    List<String>? excludeDomain,
    List<String>? language,
    List<String>? excludeLanguage,
    bool? fullContent,
    bool? image,
    bool? video,
    List<String>? organization,
    List<String>? symbol,
    String? priorityDomain,
    String? page,
    String? sentiment,
    bool? removeDuplicate,
    int? size,
    String? sort,
    List<String>? tag,
    String? interval,
    List<String>? creator,
    List<String>? dataType,
    double? sentimentScore,
    String? rawQuery,
  }) {
    return _dispatch(
      Endpoint.marketCount,
      {
        'from_date': fromDate,
        'to_date': toDate,
        'q': q,
        'qintitle': qInTitle,
        'qinmeta': qInMeta,
        'country': country,
        'excludecountry': excludeCountry,
        'domain': domain,
        'domainurl': domainUrl,
        'excludedomain': excludeDomain,
        'language': language,
        'excludelanguage': excludeLanguage,
        'full_content': fullContent,
        'image': image,
        'video': video,
        'organization': organization,
        'symbol': symbol,
        'prioritydomain': priorityDomain,
        'page': page,
        'sentiment': sentiment,
        'removeduplicate': removeDuplicate,
        'size': size,
        'sort': sort,
        'tag': tag,
        'interval': interval,
        'creator': creator,
        'datatype': dataType,
        'sentiment_score': sentimentScore,
      },
      rawQuery: rawQuery,
    );
  }

  // ---- pagination ------------------------------------------------------

  /// Follow `nextPage` cursors and return one merged [NewsdataResponse],
  /// capped at [maxResults] articles when set.
  ///
  /// For news endpoints (latest, archive, crypto, market) the merged response
  /// holds the concatenation of every page's articles. For count endpoints,
  /// `rawResults` is the final aggregate object.
  Future<NewsdataResponse> scrollAll({
    required String endpoint,
    Map<String, Object?> params = const {},
    int? maxResults,
  }) async {
    if (endpoint == Endpoint.sources) {
      throw NewsdataValidationException(
        'scrollAll is not supported for the sources endpoint',
      );
    }
    final request = <String, Object?>{...params};
    final accumulated = <Map<String, dynamic>>[];
    NewsdataResponse? last;
    int total = 0;
    String? nextPage;

    while (true) {
      final resp = await _dispatch(endpoint, request);
      last = resp;
      total = resp.totalResults;
      final raw = resp.rawResults;
      if (raw is List) {
        for (final item in raw) {
          if (item is Map) {
            accumulated.add(Map<String, dynamic>.from(item));
          }
        }
      }
      nextPage = resp.nextPage;

      if (maxResults != null && accumulated.length >= maxResults) {
        accumulated.removeRange(maxResults, accumulated.length);
        nextPage = null;
      }
      if (nextPage == null || nextPage.isEmpty) break;
      request['page'] = nextPage;
      await Future<void>.delayed(_paginationDelay);
    }

    return NewsdataResponse(
      status: 'success',
      totalResults: total,
      rawResults: accumulated.isNotEmpty ? accumulated : last.rawResults,
      headers: _includeHeaders ? last.headers : null,
    );
  }

  /// Yield one [NewsdataResponse] per page. Stop iterating (break out of the
  /// `await for`) to cancel early. [maxPages] caps the number of pages.
  Stream<NewsdataResponse> paginate({
    required String endpoint,
    Map<String, Object?> params = const {},
    int? maxPages,
  }) async* {
    if (endpoint == Endpoint.sources) {
      throw NewsdataValidationException(
        'paginate is not supported for the sources endpoint',
      );
    }
    final request = <String, Object?>{...params};
    int pages = 0;
    while (true) {
      final resp = await _dispatch(endpoint, request);
      yield resp;
      pages += 1;

      // Count endpoints return a map on the final page.
      if (resp.rawResults is Map) return;
      if (maxPages != null && pages >= maxPages) return;
      final nextPage = resp.nextPage;
      if (nextPage == null || nextPage.isEmpty) return;
      request['page'] = nextPage;
      await Future<void>.delayed(_paginationDelay);
    }
  }

  // ---- internals -------------------------------------------------------

  @visibleForTesting
  Future<NewsdataResponse> dispatchForTesting(
    String endpoint,
    Map<String, Object?> params, {
    String? rawQuery,
  }) =>
      _dispatch(endpoint, params, rawQuery: rawQuery);

  Future<NewsdataResponse> _dispatch(
    String endpoint,
    Map<String, Object?> params, {
    String? rawQuery,
  }) async {
    final encoded = validateAndEncode(endpoint, params, rawQuery: rawQuery);
    return _request(endpoint, encoded);
  }

  Future<NewsdataResponse> _request(
    String endpoint,
    Map<String, String> values,
  ) async {
    final path = endpointPaths[endpoint]!;
    final query = <String, String>{...values, 'apikey': _apiKey};
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final logUrl = redactApiKey(uri.toString());

    Object? lastError;
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      _log('info', 'GET $logUrl (attempt $attempt/$_maxRetries)');

      http.Response response;
      try {
        final request = http.Request('GET', uri);
        request.headers['Accept'] = 'application/json';
        final streamed = await _httpClient.send(request).timeout(_timeout);
        response = await http.Response.fromStream(streamed);
      } on TimeoutException catch (e) {
        if (attempt >= _maxRetries) {
          throw NewsdataNetworkException('request timed out', cause: e);
        }
        lastError = e;
        _log('warn', 'timeout');
        await Future<void>.delayed(_backoff(attempt));
        continue;
      } catch (e) {
        if (attempt >= _maxRetries) {
          throw NewsdataNetworkException('network error: $e', cause: e);
        }
        lastError = e;
        _log('warn', 'network error: $e');
        await Future<void>.delayed(_backoff(attempt));
        continue;
      }

      final status = response.statusCode;
      Map<String, dynamic>? body;
      dynamic decoded;
      try {
        decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) body = decoded;
      } catch (_) {
        if (status >= 500 && attempt < _maxRetries) {
          _log('warn', 'non-JSON response (status $status)');
          await Future<void>.delayed(_backoff(attempt));
          continue;
        }
        throw NewsdataApiException(
          'non-JSON response from API (status $status)',
          statusCode: status,
        );
      }

      if (status == 200 &&
          body != null &&
          body['status'] == 'success' &&
          body['results'] != null) {
        final parsed = NewsdataResponse.fromJson(body);
        if (_includeHeaders) {
          return NewsdataResponse(
            status: parsed.status,
            totalResults: parsed.totalResults,
            rawResults: parsed.rawResults,
            nextPage: parsed.nextPage,
            headers: response.headers,
          );
        }
        return parsed;
      }

      final message = _errorMessage(body, status);

      if (status == 429) {
        final retryAfter = _parseRetryAfter(response.headers['retry-after']);
        if (attempt >= _maxRetries) {
          throw NewsdataRateLimitException(
            message,
            statusCode: 429,
            responseBody: body,
            retryAfter: retryAfter,
          );
        }
        final wait = retryAfter != null
            ? Duration(seconds: retryAfter)
            : _backoff(attempt);
        _log('warn', '429 rate limit; sleeping ${wait.inMilliseconds}ms');
        await Future<void>.delayed(wait);
        continue;
      }

      if (status >= 500) {
        if (attempt >= _maxRetries) {
          throw NewsdataServerException(
            message,
            statusCode: status,
            responseBody: body,
          );
        }
        _log('warn', '$status server error');
        await Future<void>.delayed(_backoff(attempt));
        continue;
      }

      if (status == 401 || status == 403) {
        throw NewsdataAuthException(
          message,
          statusCode: status,
          responseBody: body,
        );
      }

      throw NewsdataApiException(
        message,
        statusCode: status,
        responseBody: body,
      );
    }

    // Defensive — the loop should always return or throw above.
    throw NewsdataException(
      'request to $endpoint did not complete (maxRetries=$_maxRetries, lastError=$lastError)',
    );
  }

  Duration _backoff(int attempt) {
    final ms = _retryBackoff.inMilliseconds * math.pow(2, attempt - 1);
    final cappedMs = ms > _retryBackoffMax.inMilliseconds
        ? _retryBackoffMax.inMilliseconds
        : ms.toInt();
    return Duration(milliseconds: cappedMs);
  }

  void _log(String level, String message) {
    _logger?.call(level, '[newsdataapi] $message');
  }

  String _errorMessage(Map<String, dynamic>? body, int status) {
    if (body != null) {
      final results = body['results'];
      if (results is Map &&
          results['message'] is String &&
          (results['message'] as String).isNotEmpty) {
        return results['message'] as String;
      }
      final m = body['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return 'API request failed with HTTP $status';
  }
}

const String baseUrl_ = baseUrl;

int? _parseRetryAfter(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final asInt = int.tryParse(trimmed);
  if (asInt != null) return asInt < 0 ? 0 : asInt;
  try {
    final date = HttpDate.parse(trimmed);
    final diff = date.difference(DateTime.now()).inSeconds;
    return diff < 0 ? 0 : diff;
  } catch (_) {
    return null;
  }
}

/// Replace the `apikey` query parameter's value with `REDACTED` so the URL is
/// safe to log.
String redactApiKey(String url) => url.replaceAllMapped(
      RegExp('(apikey=)[^&]*', caseSensitive: false),
      (m) => '${m[1]}REDACTED',
    );

/// Minimal HTTP-date parser exposed for testing.
@visibleForTesting
class HttpDate {
  static DateTime parse(String date) {
    // Use Dart's built-in RFC 1123 / RFC 850 / asctime parsing via
    // HttpHeaders, falling back to ISO.
    try {
      return DateTime.parse(date);
    } catch (_) {
      // Roughly parse RFC 1123 dates (used by Retry-After) via a regex.
      // For full conformance, dart:io's HttpDate would be used but that
      // pulls in the dart:io dependency. This minimal parser covers the
      // common case `Wed, 21 Oct 2015 07:28:00 GMT`.
      final match = RegExp(
        r'^[A-Za-z]{3}, (\d{2}) ([A-Za-z]{3}) (\d{4}) (\d{2}):(\d{2}):(\d{2}) GMT$',
      ).firstMatch(date);
      if (match == null) {
        throw FormatException('unparseable HTTP-date', date);
      }
      const months = {
        'Jan': 1,
        'Feb': 2,
        'Mar': 3,
        'Apr': 4,
        'May': 5,
        'Jun': 6,
        'Jul': 7,
        'Aug': 8,
        'Sep': 9,
        'Oct': 10,
        'Nov': 11,
        'Dec': 12,
      };
      final day = int.parse(match[1]!);
      final month = months[match[2]] ?? 1;
      final year = int.parse(match[3]!);
      final hour = int.parse(match[4]!);
      final minute = int.parse(match[5]!);
      final second = int.parse(match[6]!);
      return DateTime.utc(year, month, day, hour, minute, second);
    }
  }
}
