// Typed shapes for API responses.

import 'dart:convert';

/// Top-level envelope returned by every endpoint.
///
/// `rawResults` holds the JSON for `results` because its shape varies by
/// endpoint:
///   - news endpoints (latest, archive, crypto, market) return a `List`;
///   - the count endpoints return a `Map` on the final page.
///
/// Use [articles] / [aggregate] to decode it into a typed shape.
class NewsdataResponse {
  NewsdataResponse({
    this.status,
    this.totalResults = 0,
    this.rawResults,
    this.nextPage,
    this.headers,
  });

  /// Decode a raw JSON map (as parsed by `jsonDecode`) into a response.
  factory NewsdataResponse.fromJson(Map<String, dynamic> json) {
    return NewsdataResponse(
      status: json['status'] as String?,
      totalResults: (json['totalResults'] as int?) ?? 0,
      rawResults: json['results'],
      nextPage: json['nextPage'] as String?,
    );
  }

  final String? status;
  final int totalResults;
  final dynamic rawResults;
  final String? nextPage;

  /// Set when the client was configured with `includeHeaders: true`.
  final Map<String, String>? headers;

  /// `rawResults` decoded as a list of articles. Returns an empty list when
  /// `rawResults` is null, empty, or not a list (e.g. on a count endpoint's
  /// aggregate page).
  List<Article> get articles {
    final raw = rawResults;
    if (raw is! List) return const <Article>[];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(Article.fromJson)
        .toList(growable: false);
  }

  /// `rawResults` decoded as a map (the shape count endpoints return on the
  /// final page). Returns null when `rawResults` is not a map.
  Map<String, dynamic>? get aggregate {
    final raw = rawResults;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.cast<String, dynamic>();
    }
    return null;
  }

  /// Re-serialize a custom-built response. Internal helper for pagination.
  Map<String, dynamic> toJson() => {
        if (status != null) 'status': status,
        'totalResults': totalResults,
        if (rawResults != null) 'results': rawResults,
        if (nextPage != null) 'nextPage': nextPage,
      };

  @override
  String toString() {
    final r = jsonEncode(toJson());
    return r.length > 120 ? '${r.substring(0, 120)}…' : r;
  }
}

/// One news article. Field names use camelCase; JSON tags use the API's
/// snake_case.
class Article {
  Article({
    required this.articleId,
    this.title,
    this.link,
    this.description,
    this.content,
    this.keywords = const [],
    this.creator = const [],
    this.videoUrl,
    this.imageUrl,
    this.pubDate,
    this.pubDateTZ,
    this.sourceId,
    this.sourcePriority,
    this.sourceUrl,
    this.sourceIcon,
    this.sourceName,
    this.language,
    this.country = const [],
    this.category = const [],
    this.aiTag = const [],
    this.aiRegion = const [],
    this.aiOrg = const [],
    this.sentiment,
    this.sentimentStats,
    this.dataType,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        articleId: (json['article_id'] as String?) ?? '',
        title: json['title'] as String?,
        link: json['link'] as String?,
        description: json['description'] as String?,
        content: json['content'] as String?,
        keywords: _stringList(json['keywords']),
        creator: _stringList(json['creator']),
        videoUrl: json['video_url'] as String?,
        imageUrl: json['image_url'] as String?,
        pubDate: json['pubDate'] as String?,
        pubDateTZ: json['pubDateTZ'] as String?,
        sourceId: json['source_id'] as String?,
        sourcePriority: _toInt(json['source_priority']),
        sourceUrl: json['source_url'] as String?,
        sourceIcon: json['source_icon'] as String?,
        sourceName: json['source_name'] as String?,
        language: json['language'] as String?,
        country: _stringList(json['country']),
        category: _stringList(json['category']),
        aiTag: _stringList(json['ai_tag']),
        aiRegion: _stringList(json['ai_region']),
        aiOrg: _stringList(json['ai_org']),
        sentiment: json['sentiment'] as String?,
        sentimentStats: json['sentiment_stats'] is Map
            ? Map<String, dynamic>.from(json['sentiment_stats'] as Map)
            : null,
        dataType: json['datatype'] as String?,
      );

  final String articleId;
  final String? title;
  final String? link;
  final String? description;
  final String? content;
  final List<String> keywords;
  final List<String> creator;
  final String? videoUrl;
  final String? imageUrl;
  final String? pubDate;
  final String? pubDateTZ;
  final String? sourceId;
  final int? sourcePriority;
  final String? sourceUrl;
  final String? sourceIcon;
  final String? sourceName;
  final String? language;
  final List<String> country;
  final List<String> category;
  final List<String> aiTag;
  final List<String> aiRegion;
  final List<String> aiOrg;
  final String? sentiment;
  final Map<String, dynamic>? sentimentStats;
  final String? dataType;

  @override
  String toString() => 'Article(id: $articleId, title: $title)';
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((e) => e is String ? e : e?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String && value.isNotEmpty) return [value];
  return const [];
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  if (value is num) return value.toInt();
  return null;
}
