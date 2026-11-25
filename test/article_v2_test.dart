// The v2 article layout: field names, groups, and the plan-notice wrinkle.

import 'dart:convert';

import 'package:newsdataapi/newsdataapi.dart';
import 'package:test/test.dart';

/// One article exactly as API v2 sends it, every group populated. The
/// real-time stream sends this same layout.
const String v2ArticleJson = '''
{
  "id": "9f8e7d6c5b4a39281706f5e4d3c2b1a0",
  "title": "Central bank holds rates steady as inflation cools",
  "meta_description": "The central bank kept its key rate unchanged on Wednesday.",
  "content": "Full article text...",
  "url": "https://www.example.com/business/central-bank-holds-rates",
  "published_at": "2026-10-22T06:15:00Z",
  "fetched_at": "2026-10-22T06:18:42Z",
  "datatype": "news",
  "language": "english",
  "country": ["india"],
  "category": ["business"],
  "keyword": ["interest rates", "inflation"],
  "creator": ["Jane Doe"],
  "duplicate": false,
  "media": {"image_url": "https://www.example.com/images/rates.jpg", "video_url": null},
  "source": {
    "name": "Example News",
    "url": "https://www.example.com",
    "icon_url": "https://www.example.com/icon.png",
    "priority": 1520
  },
  "ai": {
    "summary": "The central bank left its policy rate unchanged.",
    "sentiment": {"label": "neutral", "score": {"negative": 4.12, "neutral": 90.33, "positive": 5.55}},
    "tag": ["banking and finance", "economy"],
    "region": ["mumbai,maharashtra,india", "delhi,india"],
    "organization": ["reserve bank of india"]
  }
}
''';

ArticleV2 parse(String json) =>
    ArticleV2.fromJson(jsonDecode(json) as Map<String, dynamic>);

void main() {
  group('ArticleV2.fromJson', () {
    test('v2 spells the top-level fields id/url/published_at', () {
      final a = parse(v2ArticleJson);

      expect(a.id, '9f8e7d6c5b4a39281706f5e4d3c2b1a0');
      expect(a.title, 'Central bank holds rates steady as inflation cools');
      expect(
          a.url, 'https://www.example.com/business/central-bank-holds-rates');
      expect(a.publishedAt, '2026-10-22T06:15:00Z');
      expect(a.fetchedAt, '2026-10-22T06:18:42Z');
      expect(a.metaDescription,
          'The central bank kept its key rate unchanged on Wednesday.');
      expect(a.content, 'Full article text...');
      expect(a.language, 'english');
      expect(a.dataType, 'news');
      expect(a.duplicate, isFalse);
      expect(a.country, ['india']);
      expect(a.category, ['business']);
      expect(a.keyword, ['interest rates', 'inflation']);
      expect(a.creator, ['Jane Doe']);
    });

    test('source, media and ai arrive as groups', () {
      final a = parse(v2ArticleJson);

      expect(a.source.name, 'Example News');
      expect(a.source.url, 'https://www.example.com');
      expect(a.source.iconUrl, 'https://www.example.com/icon.png');
      expect(a.source.priority, 1520);

      expect(a.media.imageUrl, 'https://www.example.com/images/rates.jpg');
      expect(a.media.videoUrl, isNull);

      expect(a.ai.summary, 'The central bank left its policy rate unchanged.');
      expect(a.ai.sentiment.label, 'neutral');
      expect(a.ai.sentiment.score['neutral'], 90.33);
      expect(a.ai.sentiment.score['negative'], 4.12);
      expect(a.ai.tag, ['banking and finance', 'economy']);
      expect(a.ai.organization, ['reserve bank of india']);
    });

    test('ai.region entries contain commas and are not split', () {
      expect(parse(v2ArticleJson).ai.region,
          ['mumbai,maharashtra,india', 'delhi,india']);
    });

    test('an absent group reads as empty rather than null', () {
      final a = parse('{"id":"x","title":"hi"}');

      expect(a.id, 'x');
      expect(a.source.name, isNull);
      expect(a.media.imageUrl, isNull);
      expect(a.ai.summary, isNull);
      expect(a.ai.sentiment.label, isNull);
      expect(a.ai.sentiment.score, isEmpty);
      expect(a.duplicate, isNull);
      expect(a.country, isEmpty);
      expect(a.keyword, isEmpty);
    });

    test('an unknown field is ignored', () {
      expect(parse('{"id":"x","something_new":42}').id, 'x');
    });

    test('a missing id reads as an empty string', () {
      expect(parse('{"title":"hi"}').id, '');
    });
  });

  group('plan notices', () {
    test('a notice where a list is documented does not fail decoding', () {
      final a = parse(
          '{"id":"x","ai":{"tag":"ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS"}}');

      expect(a.ai.tag, hasLength(1));
      expect(isPlanNotice(a.ai.tag.first), isTrue);
    });

    test('a notice replacing the sentiment object lands in its label', () {
      final a =
          parse('{"id":"x","ai":{"sentiment":"ONLY AVAILABLE IN PAID PLANS"}}');

      expect(isPlanNotice(a.ai.sentiment.label), isTrue);
      expect(a.ai.sentiment.score, isEmpty);
    });

    test('a notice inside the sentiment label is recognised too', () {
      final a = parse(
          '{"id":"x","ai":{"sentiment":{"label":"ONLY AVAILABLE IN PAID PLANS"}}}');
      expect(isPlanNotice(a.ai.sentiment.label), isTrue);
    });

    test('notices are recognised whatever their case or padding', () {
      for (final value in [
        'ONLY AVAILABLE IN PAID PLANS',
        'ONLY AVAILABLE IN PROFESSIONAL AND CORPORATE PLANS',
        '  only available in corporate plans  ',
      ]) {
        expect(isPlanNotice(value), isTrue, reason: value);
      }
    });

    test('real values and null are not notices', () {
      for (final value in ['', 'india', 'neutral', 'available in paid plans']) {
        expect(isPlanNotice(value), isFalse, reason: value);
      }
      expect(isPlanNotice(null), isFalse);
    });
  });

  group('lenient numbers', () {
    test('source.priority accepts a number, a quoted number, or neither', () {
      expect(parse('{"source":{"priority":1520}}').source.priority, 1520);
      expect(parse('{"source":{"priority":"1520"}}').source.priority, 1520);
      expect(parse('{"source":{"priority":null}}').source.priority, isNull);
      expect(
        parse('{"source":{"priority":"ONLY AVAILABLE IN PAID PLANS"}}')
            .source
            .priority,
        isNull,
        reason: 'a non-numeric priority must not fail the article',
      );
    });
  });

  group('the sentiment score map', () {
    test('a class the platform adds later is still decoded', () {
      final a = parse(
          '{"ai":{"sentiment":{"label":"mixed","score":{"mixed":51.0}}}}');
      expect(a.ai.sentiment.score['mixed'], 51.0);
    });

    test('an int score is read as a double', () {
      final a = parse(
          '{"ai":{"sentiment":{"label":"neutral","score":{"neutral":90}}}}');
      expect(a.ai.sentiment.score['neutral'], 90.0);
    });

    test('a sentiment without a score still has an empty one', () {
      final a = parse('{"ai":{"sentiment":{"label":"neutral"}}}');
      expect(a.ai.sentiment.label, 'neutral');
      expect(a.ai.sentiment.score, isEmpty);
    });
  });

  group('NewsdataResponse.articlesV2', () {
    test('decodes the v2 envelope results', () {
      final response = NewsdataResponse.fromJson(jsonDecode(
        '{"status":"success","total_results":2841,'
        '"next_page":"1792649700000000000","results":[$v2ArticleJson]}',
      ) as Map<String, dynamic>);

      expect(response.totalResults, 2841);
      expect(response.nextPage, '1792649700000000000');

      final articles = response.articlesV2;
      expect(articles, hasLength(1));
      expect(articles.first.source.name, 'Example News');
      expect(articles.first.url,
          'https://www.example.com/business/central-bank-holds-rates');
    });

    test('is empty on a count endpoint aggregate page', () {
      final response = NewsdataResponse.fromJson(
          jsonDecode('{"status":"success","results":{"2026-10-22":5}}')
              as Map<String, dynamic>);
      expect(response.articlesV2, isEmpty);
    });

    test('is empty when there are no results at all', () {
      final response = NewsdataResponse.fromJson(
          jsonDecode('{"status":"success"}') as Map<String, dynamic>);
      expect(response.articlesV2, isEmpty);
    });
  });
}
