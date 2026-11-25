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

  // v2
  static const String newsV2 = 'news_v2';
  static const String marketV2 = 'market_v2';
  static const String cryptoV2 = 'crypto_v2';
  static const String sourcesV2 = 'sources_v2';
  static const String countNewsV2 = 'count_news_v2';
  static const String countMarketV2 = 'count_market_v2';
  static const String countCryptoV2 = 'count_crypto_v2';

  // The real-time service is v2 only.
  static const String websocketRegister = 'websocket_register';
  static const String websocketFetch = 'websocket_fetch';
  static const String websocketDelete = 'websocket_delete';
}

/// API root. The paths in [endpointPaths] carry the API version, so the v1 and
/// v2 endpoints share one base.
const String baseUrl = 'https://newsdata.io/api/';

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

/// The feed a registered query matches against; only news so far.
const String wsNewsType = 'news';

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
  // v1
  'latest': '1/latest',
  'crypto': '1/crypto',
  'archive': '1/archive',
  'sources': '1/sources',
  'market': '1/market',
  'count': '1/count',
  'crypto_count': '1/crypto/count',
  'market_count': '1/market/count',
  // v2
  'news_v2': '2/news',
  'market_v2': '2/market',
  'crypto_v2': '2/crypto',
  'sources_v2': '2/sources',
  'count_news_v2': '2/count/news',
  'count_market_v2': '2/count/market',
  'count_crypto_v2': '2/count/crypto',
  // The real-time service is v2 only.
  'websocket_register': '2/websocket/register',
  'websocket_fetch': '2/websocket/fetch',
  'websocket_delete': '2/websocket/delete',
};

/// Error codes on a 429 that waiting cannot fix, so they are never retried.
/// `ApiLimitExceeded` and `ApiKeyLimitExceeded` mean the API credits are
/// exhausted rather than a transient rate limit — backoff cannot conjure more
/// credits. `RegistrationLimitExceeded` means every real-time registration the
/// plan allows is in use; only deleting one frees a slot.
///
/// `ApiLimitExceeded` is the documented code (see the ErrorCode enum in
/// https://newsdata.io/openapi.json); `ApiKeyLimitExceeded` is accepted too
/// because the API has been observed to send it and the spec is not exhaustive.
const Set<String> quotaExhaustedCodes = {
  'ApiLimitExceeded',
  'ApiKeyLimitExceeded',
  'RegistrationLimitExceeded',
};

/// Endpoints that require both `from_date` and `to_date`.
const Set<String> requiresDateRange = {'count', 'crypto_count', 'market_count'};

/// Parameters sent as boolean flags (coerced to `1`/`0`).
const Set<String> boolParams = {
  'full_content',
  'image',
  'video',
  'removeduplicate',
  // v2 spellings
  'content',
  'remove_duplicate',
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
  ['domain', 'domainurl', 'excludedomain', 'excludedomainurl'],
  // v2 names
  ['q', 'q_in_title', 'q_in_meta'],
  ['country', 'exclude_country'],
  ['category', 'exclude_category'],
  ['language', 'exclude_language'],
  ['source_url', 'exclude_source_url'],
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
    'excludedomainurl',
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
    'excludedomainurl',
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
    'excludedomainurl',
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
    'excludedomainurl',
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
    'excludedomainurl',
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
    'excludedomainurl',
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
    'excludedomainurl',
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

  // ---- v2 ------------------------------------------------------------
  // v2 renames the filter vocabulary to snake_case and folds
  // domain/domainurl/excludedomain/excludedomainurl into
  // source_url/exclude_source_url.
  'news_v2': {
    'q',
    'q_in_title',
    'q_in_meta',
    'country',
    'exclude_country',
    'category',
    'exclude_category',
    'language',
    'exclude_language',
    'source_url',
    'exclude_source_url',
    'source_priority',
    'from_date',
    'to_date',
    'timeframe',
    'timezone',
    'size',
    'content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'sentiment_score',
    'region',
    'organization',
    'creator',
    'datatype',
    'exclude_field',
    'remove_duplicate',
    'id',
    'url',
    'sort',
  },
  'market_v2': {
    'q',
    'q_in_title',
    'q_in_meta',
    'country',
    'exclude_country',
    'language',
    'exclude_language',
    'source_url',
    'exclude_source_url',
    'source_priority',
    'from_date',
    'to_date',
    'timeframe',
    'timezone',
    'size',
    'content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'sentiment_score',
    'organization',
    'market_id',
    'creator',
    'datatype',
    'exclude_field',
    'remove_duplicate',
    'id',
    'url',
    'sort',
  },
  'crypto_v2': {
    'q',
    'q_in_title',
    'q_in_meta',
    'coin',
    'language',
    'exclude_language',
    'source_url',
    'exclude_source_url',
    'source_priority',
    'from_date',
    'to_date',
    'timeframe',
    'timezone',
    'size',
    'content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'exclude_field',
    'remove_duplicate',
    'id',
    'url',
    'sort',
  },
  'sources_v2': {
    'country',
    'category',
    'language',
    'source_priority',
    'source_url',
  },
  'count_news_v2': {
    'q',
    'q_in_title',
    'q_in_meta',
    'country',
    'exclude_country',
    'category',
    'exclude_category',
    'language',
    'exclude_language',
    'source_url',
    'exclude_source_url',
    'source_priority',
    'from_date',
    'to_date',
    'timeframe',
    'interval',
    'size',
    'content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'sentiment_score',
    'region',
    'organization',
    'creator',
    'datatype',
    'remove_duplicate',
    'sort',
  },
  'count_market_v2': {
    'q',
    'q_in_title',
    'q_in_meta',
    'country',
    'exclude_country',
    'language',
    'exclude_language',
    'source_url',
    'exclude_source_url',
    'source_priority',
    'from_date',
    'to_date',
    'timeframe',
    'interval',
    'size',
    'content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'sentiment_score',
    'organization',
    'market_id',
    'creator',
    'datatype',
    'remove_duplicate',
    'sort',
  },
  'count_crypto_v2': {
    'q',
    'q_in_title',
    'q_in_meta',
    'coin',
    'language',
    'exclude_language',
    'source_url',
    'exclude_source_url',
    'source_priority',
    'from_date',
    'to_date',
    'timeframe',
    'interval',
    'size',
    'content',
    'image',
    'video',
    'page',
    'tag',
    'sentiment',
    'remove_duplicate',
    'sort',
  },

  // Real-time query registration. The real-time service is v2 only, so these
  // are the v2 filter names. No date or paging filters apply — a registered
  // query matches news as it is published. `news_type` is set by
  // websocketRegister, not by the caller.
  'websocket_register': {
    'q',
    'q_in_title',
    'q_in_meta',
    'country',
    'exclude_country',
    'category',
    'exclude_category',
    'language',
    'exclude_language',
    'source_url',
    'exclude_source_url',
    'source_priority',
    'timezone',
    'content',
    'image',
    'video',
    'remove_duplicate',
    'tag',
    'sentiment',
    'sentiment_score',
    'region',
    'organization',
    'creator',
    'datatype',
    'exclude_field',
    'news_type',
  },
  'websocket_fetch': <String>{},
  'websocket_delete': {'registration_id'},
};
