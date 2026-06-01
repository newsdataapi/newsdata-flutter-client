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
    'symbol',
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
    'symbol',
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
};
