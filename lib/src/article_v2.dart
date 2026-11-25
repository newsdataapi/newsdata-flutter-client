// The v2 article layout.
//
// v2 renamed and regrouped the v1 fields: `article_id` became `id`, `link`
// became `url`, `pubDate` became `published_at`, `description` became
// `meta_description`, and the source, media and AI fields moved into the
// `source`, `media` and `ai` groups. Use [ArticleV2] for the v2 endpoints and
// the real-time stream; use `Article` for the v1 endpoints.

/// Prefix of the string the API sends in place of a field your plan does not
/// include (`"ONLY AVAILABLE IN PAID PLANS"`, `"ONLY AVAILABLE IN
/// PROFESSIONAL AND CORPORATE PLANS"`, `"ONLY AVAILABLE IN CORPORATE PLANS"`).
const String planNoticePrefix = 'ONLY AVAILABLE IN';

/// Whether [value] is the API's "not in your plan" notice rather than real
/// data.
///
/// The notice arrives in the field itself, so a withheld list field holds the
/// single notice string and a withheld sentiment carries it in
/// [ArticleV2Sentiment.label]:
///
/// ```dart
/// if (a.country.length == 1 && isPlanNotice(a.country.first)) {
///   // the plan does not include country tagging
/// }
/// ```
bool isPlanNotice(String? value) {
  if (value == null) return false;
  return value.trim().toUpperCase().startsWith(planNoticePrefix);
}

/// One news article from API v2.
///
/// JSON keys are the API's own field paths — the same names `exclude_field`
/// accepts and the same names the NewsData documentation uses, so one
/// vocabulary covers parameters, results and docs. Field names here are the
/// camelCase spelling of those paths.
///
/// A field your plan does not include holds the API's notice string instead of
/// data; see [isPlanNotice].
class ArticleV2 {
  ArticleV2({
    required this.id,
    this.title,
    this.url,
    this.metaDescription,
    this.content,
    this.publishedAt,
    this.fetchedAt,
    this.language,
    this.dataType,
    this.duplicate,
    this.country = const [],
    this.category = const [],
    this.keyword = const [],
    this.creator = const [],
    this.coin = const [],
    this.ticker = const [],
    this.marketId = const [],
    ArticleV2Source? source,
    ArticleV2Media? media,
    ArticleV2Ai? ai,
  })  : source = source ?? const ArticleV2Source(),
        media = media ?? const ArticleV2Media(),
        ai = ai ?? ArticleV2Ai();

  /// Decode a raw article map (as parsed by `jsonDecode`).
  factory ArticleV2.fromJson(Map<String, dynamic> json) => ArticleV2(
        id: (json['id'] as String?) ?? '',
        title: json['title'] as String?,
        url: json['url'] as String?,
        metaDescription: json['meta_description'] as String?,
        content: json['content'] as String?,
        publishedAt: json['published_at'] as String?,
        fetchedAt: json['fetched_at'] as String?,
        language: json['language'] as String?,
        dataType: json['datatype'] as String?,
        duplicate: json['duplicate'] as bool?,
        country: stringListOf(json['country']),
        category: stringListOf(json['category']),
        keyword: stringListOf(json['keyword']),
        creator: stringListOf(json['creator']),
        coin: stringListOf(json['coin']),
        ticker: stringListOf(json['ticker']),
        marketId: stringListOf(json['market_id']),
        source: ArticleV2Source.fromJson(_mapOf(json['source'])),
        media: ArticleV2Media.fromJson(_mapOf(json['media'])),
        ai: ArticleV2Ai.fromJson(_mapOf(json['ai'])),
      );

  /// The article's stable identifier (v1: `article_id`).
  final String id;

  /// Headline.
  final String? title;

  /// Address of the article (v1: `link`).
  final String? url;

  /// The publisher's summary (v1: `description`).
  final String? metaDescription;

  /// Full text, when the plan and the request include it.
  final String? content;

  /// Publication time, UTC ISO-8601 (v1: `pubDate`).
  final String? publishedAt;

  /// When the platform fetched the article, UTC ISO-8601.
  final String? fetchedAt;

  /// Language name, e.g. `"english"`.
  final String? language;

  /// Feed the article came from, e.g. `"news"`.
  final String? dataType;

  /// Whether the platform considers the article a duplicate.
  final bool? duplicate;

  /// Countries the article relates to.
  final List<String> country;

  /// Categories the article was classified into.
  final List<String> category;

  /// Publisher keywords (v1: `keywords`).
  final List<String> keyword;

  /// Bylines.
  final List<String> creator;

  /// Cryptocurrencies mentioned (crypto endpoints).
  final List<String> coin;

  /// Stock tickers mentioned (v1: `symbol`).
  final List<String> ticker;

  /// Market identifiers (market endpoints).
  final List<String> marketId;

  /// The publisher the article came from. Never null; its fields are null when
  /// the API sent no `source` group.
  final ArticleV2Source source;

  /// Image and video addresses. Never null; its fields are null when the API
  /// sent no `media` group.
  final ArticleV2Media media;

  /// The platform's AI enrichment. Never null; its fields are null or empty
  /// when the API sent no `ai` group.
  final ArticleV2Ai ai;

  @override
  String toString() => 'ArticleV2(id: $id, title: $title)';
}

/// The publisher an article came from — the v2 `source` group.
///
/// It replaces v1's `source_id`, `source_name`, `source_url`, `source_icon`
/// and `source_priority` fields.
class ArticleV2Source {
  const ArticleV2Source({
    this.name,
    this.url,
    this.iconUrl,
    this.priority,
  });

  /// Decode a raw `source` map.
  factory ArticleV2Source.fromJson(Map<String, dynamic> json) =>
      ArticleV2Source(
        name: json['name'] as String?,
        url: json['url'] as String?,
        iconUrl: json['icon_url'] as String?,
        priority: lenientInt(json['priority']),
      );

  /// Publisher name, e.g. `"Example News"`.
  final String? name;

  /// The publisher's home page.
  final String? url;

  /// The publisher's icon.
  final String? iconUrl;

  /// The platform's source-priority rank (lower ranks first), or null when the
  /// API did not send a usable number.
  final int? priority;

  @override
  String toString() => 'ArticleV2Source(name: $name, priority: $priority)';
}

/// An article's media addresses — the v2 `media` group. It replaces v1's
/// `image_url` and `video_url` fields. Either field is null on an article
/// without that medium.
class ArticleV2Media {
  const ArticleV2Media({this.imageUrl, this.videoUrl});

  /// Decode a raw `media` map.
  factory ArticleV2Media.fromJson(Map<String, dynamic> json) => ArticleV2Media(
        imageUrl: json['image_url'] as String?,
        videoUrl: json['video_url'] as String?,
      );

  /// Lead image.
  final String? imageUrl;

  /// Lead video.
  final String? videoUrl;

  @override
  String toString() => 'ArticleV2Media(imageUrl: $imageUrl)';
}

/// The platform's AI enrichment of an article — the v2 `ai` group.
///
/// It replaces v1's `sentiment`, `sentiment_stats`, `ai_tag`, `ai_region` and
/// `ai_org` fields, and adds [summary].
///
/// Fields are null or empty on articles the platform did not enrich. When your
/// plan does not include a field, it holds the API's notice string instead of
/// data — see [isPlanNotice].
class ArticleV2Ai {
  ArticleV2Ai({
    this.summary,
    ArticleV2Sentiment? sentiment,
    this.tag = const [],
    this.region = const [],
    this.organization = const [],
  }) : sentiment = sentiment ?? const ArticleV2Sentiment();

  /// Decode a raw `ai` map.
  factory ArticleV2Ai.fromJson(Map<String, dynamic> json) => ArticleV2Ai(
        summary: json['summary'] as String?,
        sentiment: ArticleV2Sentiment.fromJson(json['sentiment']),
        tag: stringListOf(json['tag']),
        region: stringListOf(json['region']),
        organization: stringListOf(json['organization']),
      );

  /// A one-or-two-sentence summary of the article.
  final String? summary;

  /// Sentiment label and per-class confidence. Never null; its fields are
  /// empty when the API sent no sentiment.
  final ArticleV2Sentiment sentiment;

  /// Topic tags, e.g. `["banking and finance"]`.
  final List<String> tag;

  /// Places the article relates to, each a comma-separated path from the
  /// narrowest to the widest (`"mumbai,maharashtra,india"`). Entries contain
  /// commas themselves, so do not split them.
  final List<String> region;

  /// Organisations mentioned.
  final List<String> organization;

  @override
  String toString() => 'ArticleV2Ai(sentiment: ${sentiment.label})';
}

/// An article's sentiment classification: a [label] (`"positive"`,
/// `"neutral"`, `"negative"`) and the per-class confidence [score].
///
/// [score] is a map rather than three fields so a class the platform adds
/// later is still decoded; the keys today are `"negative"`, `"neutral"` and
/// `"positive"`.
///
/// When your plan does not include sentiment, the API sends its notice string
/// in place of the object. It is decoded into [label] with an empty score,
/// where [isPlanNotice] recognises it.
class ArticleV2Sentiment {
  const ArticleV2Sentiment({this.label, this.score = const {}});

  /// Decode the raw `ai.sentiment` value: the sentiment object, or the bare
  /// notice string the API sends when the plan does not include sentiment.
  factory ArticleV2Sentiment.fromJson(dynamic value) {
    if (value is String) {
      return ArticleV2Sentiment(label: value);
    }
    if (value is! Map) return const ArticleV2Sentiment();

    final score = <String, double>{};
    final raw = value['score'];
    if (raw is Map) {
      raw.forEach((key, val) {
        if (val is num) score['$key'] = val.toDouble();
      });
    }
    return ArticleV2Sentiment(
      label: value['label'] as String?,
      score: Map.unmodifiable(score),
    );
  }

  /// The winning class, or a plan notice.
  final String? label;

  /// Confidence per class, as percentages. Never null.
  final Map<String, double> score;

  @override
  String toString() => 'ArticleV2Sentiment(label: $label, score: $score)';
}

/// Reads a value the API documents as an array of strings but may send as a
/// single string.
///
/// The v2 list fields (`country`, `keyword`, `ai.tag`, ...) are JSON arrays,
/// but the API replaces the whole field with one "not in your plan" notice
/// string when the plan does not include it. This yields a one-element list in
/// that case, which [isPlanNotice] recognises.
List<String> stringListOf(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e is String ? e : e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.isNotEmpty) return [value];
  return const [];
}

/// Reads an int the API may send as a number or as a quoted number. Anything
/// else (a plan notice, say) reads as null rather than failing the article.
int? lenientInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

Map<String, dynamic> _mapOf(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return const <String, dynamic>{};
}
