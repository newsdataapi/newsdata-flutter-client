// Static configuration for the Newsdata.io client: base URL, endpoint paths,
// HTTP defaults, and the per-endpoint accepted-parameter sets.
//
// Parameter names are lowercase here; user-supplied keys are lowercased before
// validation (the API is case-insensitive, so `qInTitle` and `qintitle` are
// equivalent). The sets mirror the server-side filter mapping and the official
// Python/PHP/Node/Go clients.

/// Endpoint identifiers — pass these as the `endpoint:` argument to
/// `scrollAll` and `paginate`.
abstract class Endpoint {
  static const String latest = 'latest';
  static const String archive = 'archive';
  static const String crypto = 'crypto';
  static const String sources = 'sources';
  static const String market = 'market';
  static const String count = 'count';
  static const String cryptoCount = 'crypto_count';
  static const String marketCount = 'market_count';
  static const String websocketRegister = 'websocket_register';
  static const String websocketFetch = 'websocket_fetch';
  static const String websocketDelete = 'websocket_delete';
}

/// API base URL.
const String baseUrl = 'https://newsdata.io/api/1/';

/// HTTP defaults.
const Duration defaultRequestTimeout = Duration(seconds: 30);
const int defaultMaxRetries = 5;
const Duration defaultRetryBackoff = Duration(seconds: 2);
const Duration defaultRetryBackoffMax = Duration(seconds: 60);
const Duration defaultPaginationDelay = Duration(seconds: 1);

/// Response-size bounds. The API caps a single response at 50.
const int sizeMin = 1;
const int sizeMax = 50;

/// HTTP method per endpoint; anything absent is a GET.
const Map<String, String> endpointMethods = {
  'websocket_register': 'POST',
  'websocket_delete': 'DELETE',
};

/// Endpoints whose success envelope may carry no `results` field, so they are
/// exempt from the results-present check applied to the news endpoints.
const Set<String> resultsOptional = {
  'websocket_register',
  'websocket_fetch',
  'websocket_delete',
};

/// Real-time WebSocket endpoint.
const String wsBaseUrl = 'wss://ws.newsdata.io/ws/event';

/// The feed a registered query matches against.
const String wsNewsType = 'latest';

/// Close code the server uses for a permanent connection rejection.
const int wsPolicyViolation = 1008;

/// Wait before the first reconnect; doubles after each consecutive failure.
const Duration wsReconnectDelay = Duration(seconds: 1);

/// Upper bound on the reconnect delay.
const Duration wsReconnectDelayMax = Duration(seconds: 30);

/// Bound on the opening handshake.
const Duration wsHandshakeTimeout = Duration(seconds: 10);

/// Endpoint key → path appended to [baseUrl].
const Map<String, String> endpointPaths = {
  'latest': 'latest',
  'crypto': 'crypto',
  'archive': 'archive',
  'sources': 'sources',
  'market': 'market',
  'count': 'count',
  'crypto_count': 'crypto/count',
  'market_count': 'market/count',
  'websocket_register': 'websocket/register',
  'websocket_fetch': 'websocket/fetch',
  'websocket_delete': 'websocket/delete',
};

/// Error codes on a 429 meaning the account's API credits are exhausted rather
/// than a transient rate limit. These are never retried — waiting out the
/// backoff cannot conjure more credits.
///
/// `ApiLimitExceeded` is the documented code (see the ErrorCode enum in
/// https://newsdata.io/openapi.json); `ApiKeyLimitExceeded` is accepted too
/// because the API has been observed to send it and the spec is not exhaustive.
const Set<String> quotaExhaustedCodes = {
  'ApiLimitExceeded',
  'ApiKeyLimitExceeded',
};

/// Endpoints that require both `from_date` and `to_date`.
const Set<String> requiresDateRange = {'count', 'crypto_count', 'market_count'};

/// Parameters sent as boolean flags (coerced to `1`/`0`).
const Set<String> boolParams = {
  'full_content',
  'image',
  'video',
  'removeduplicate',
};

/// Parameters that must be integers.
const Set<String> intParams = {'size'};

/// Parameters that must be numeric (int or float).
const Set<String> floatParams = {'sentiment_score'};

/// Mutually-exclusive parameter groups. Setting more than one member of a
/// group is rejected before the request is sent.
const List<List<String>> mutexGroups = [
  ['q', 'qintitle', 'qinmeta'],
  ['country', 'excludecountry'],
  ['category', 'excludecategory'],
  ['language', 'excludelanguage'],
  ['domain', 'domainurl', 'excludedomain'],
];

/// Per-endpoint accepted parameters (lowercase API names).
const Map<String, Set<String>> filters = {
  'latest': {
    'q',
    'qintitle',
    'qinmeta',
    'country',
    'excludecountry',
    'category',
    'excludecategory',
    'language',
    'excludelanguage',
    'domain',
    'domainurl',
    'excludedomain',
    'prioritydomain',
    'timeframe',
    'timezone',
    'size',
    'full_content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'region',
    'excludefield',
    'removeduplicate',
    'id',
    'organization',
    'url',
    'sort',
    'creator',
    'datatype',
    'sentiment_score',
  },
  'archive': {
    'q',
    'qintitle',
    'qinmeta',
    'country',
    'excludecountry',
    'category',
    'excludecategory',
    'language',
    'excludelanguage',
    'domain',
    'domainurl',
    'excludedomain',
    'prioritydomain',
    'timezone',
    'size',
    'full_content',
    'image',
    'video',
    'page',
    'from_date',
    'to_date',
    'excludefield',
    'id',
    'url',
    'sort',
    'tag',
    'sentiment',
    'sentiment_score',
    'region',
    'organization',
    'creator',
    'datatype',
    'removeduplicate',
  },
  'crypto': {
    'q',
    'qintitle',
    'qinmeta',
    'language',
    'excludelanguage',
    'domain',
    'domainurl',
    'excludedomain',
    'prioritydomain',
    'timeframe',
    'timezone',
    'size',
    'full_content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'coin',
    'excludefield',
    'from_date',
    'to_date',
    'removeduplicate',
    'id',
    'url',
    'sort',
  },
  'sources': {'country', 'category', 'language', 'prioritydomain', 'domainurl'},
  'market': {
    'q',
    'qintitle',
    'qinmeta',
    'from_date',
    'to_date',
    'country',
    'excludecountry',
    'domain',
    'domainurl',
    'excludedomain',
    'language',
    'excludelanguage',
    'prioritydomain',
    'timezone',
    'timeframe',
    'size',
    'full_content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'excludefield',
    'removeduplicate',
    'organization',
    'market_id',
    'id',
    'url',
    'sort',
    'creator',
    'datatype',
    'sentiment_score',
  },
  'count': {
    'from_date',
    'to_date',
    'q',
    'qintitle',
    'qinmeta',
    'country',
    'excludecountry',
    'category',
    'excludecategory',
    'language',
    'excludelanguage',
    'domain',
    'domainurl',
    'excludedomain',
    'full_content',
    'image',
    'video',
    'prioritydomain',
    'page',
    'size',
    'sort',
    'interval',
    'tag',
    'sentiment',
    'sentiment_score',
    'region',
    'organization',
    'creator',
    'datatype',
    'removeduplicate',
  },
  'crypto_count': {
    'from_date',
    'to_date',
    'q',
    'qintitle',
    'qinmeta',
    'language',
    'excludelanguage',
    'coin',
    'domain',
    'domainurl',
    'excludedomain',
    'full_content',
    'image',
    'video',
    'prioritydomain',
    'page',
    'sentiment',
    'size',
    'sort',
    'tag',
    'interval',
    'removeduplicate',
  },
  'market_count': {
    'from_date',
    'to_date',
    'q',
    'qintitle',
    'qinmeta',
    'country',
    'excludecountry',
    'domain',
    'domainurl',
    'excludedomain',
    'language',
    'excludelanguage',
    'full_content',
    'image',
    'video',
    'organization',
    'market_id',
    'prioritydomain',
    'page',
    'sentiment',
    'removeduplicate',
    'size',
    'sort',
    'tag',
    'interval',
    'creator',
    'datatype',
    'sentiment_score',
  },
  // Real-time query registration. No date/paging filters — a registered query
  // matches news as it is published. `news_type` is set by websocketRegister,
  // not by the caller.
  'websocket_register': {
    'q',
    'qintitle',
    'qinmeta',
    'country',
    'excludecountry',
    'category',
    'excludecategory',
    'language',
    'excludelanguage',
    'domain',
    'domainurl',
    'excludedomain',
    'prioritydomain',
    'timezone',
    'full_content',
    'image',
    'video',
    'removeduplicate',
    'tag',
    'sentiment',
    'sentiment_score',
    'region',
    'organization',
    'creator',
    'datatype',
    'excludefield',
    'news_type',
  },
  'websocket_fetch': <String>{},
  'websocket_delete': {'registration_id'},
};
