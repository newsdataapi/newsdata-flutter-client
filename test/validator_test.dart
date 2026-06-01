import 'package:newsdataapi/src/constants.dart';
import 'package:newsdataapi/src/errors.dart';
import 'package:newsdataapi/src/validator.dart';
import 'package:test/test.dart';

void main() {
  group('validateAndEncode', () {
    test('arrays are comma-joined', () {
      final out = validateAndEncode('latest', {
        'country': ['us', 'gb']
      });
      expect(out['country'], 'us,gb');
    });

    test('booleans are coerced to 1/0', () {
      final out = validateAndEncode(
        'latest',
        {'full_content': true, 'image': false},
      );
      expect(out['full_content'], '1');
      expect(out['image'], '0');
    });

    test('keys are lowercased', () {
      final out = validateAndEncode('latest', {'qInTitle': 'hi'});
      expect(out['qintitle'], 'hi');
    });

    test('null values are dropped', () {
      final out = validateAndEncode('latest', {'q': 'x', 'country': null});
      expect(out['q'], 'x');
      expect(out.containsKey('country'), isFalse);
    });

    test('size upper bound is rejected', () {
      expect(
        () => validateAndEncode('latest', {'size': sizeMax + 1}),
        throwsA(isA<NewsdataValidationException>()
            .having((e) => e.param, 'param', 'size')),
      );
    });

    test('size within bounds is accepted', () {
      final out = validateAndEncode('latest', {'size': 50});
      expect(out['size'], '50');
    });

    test('mutually exclusive params are rejected', () {
      expect(
        () => validateAndEncode('latest', {'q': 'a', 'qInTitle': 'b'}),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('unknown parameter is rejected', () {
      expect(
        () => validateAndEncode('latest', {'nope': 'x'}),
        throwsA(isA<NewsdataValidationException>()
            .having((e) => e.param, 'param', 'nope')),
      );
    });

    test('crypto rejects country', () {
      expect(
        () => validateAndEncode('crypto', {'country': 'us'}),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('sentiment_score requires sentiment', () {
      expect(
        () => validateAndEncode('latest', {'sentiment_score': 0.5}),
        throwsA(isA<NewsdataValidationException>()
            .having((e) => e.param, 'param', 'sentiment_score')),
      );
    });

    test('sentiment_score with sentiment is accepted', () {
      final out = validateAndEncode(
        'latest',
        {'sentiment': 'positive', 'sentiment_score': 0.5},
      );
      expect(out['sentiment'], 'positive');
      expect(out['sentiment_score'], '0.5');
    });

    test('count requires date range', () {
      expect(
        () => validateAndEncode('count', {'q': 'x'}),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('count with dates is accepted', () {
      final out = validateAndEncode(
        'count',
        {'from_date': '2024-01-01', 'to_date': '2024-01-02'},
      );
      expect(out['from_date'], '2024-01-01');
      expect(out['to_date'], '2024-01-02');
    });

    test('rawQuery is parsed and validated', () {
      final out = validateAndEncode(
        'latest',
        const <String, Object?>{},
        rawQuery: 'q=foo&country=us',
      );
      expect(out['q'], 'foo');
      expect(out['country'], 'us');
    });

    test('rawQuery rejects other params', () {
      expect(
        () => validateAndEncode(
          'latest',
          {'country': 'us'},
          rawQuery: 'q=foo',
        ),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('rawQuery rejects unknown keys', () {
      expect(
        () => validateAndEncode(
          'latest',
          const <String, Object?>{},
          rawQuery: 'bogus=1',
        ),
        throwsA(isA<NewsdataValidationException>()),
      );
    });

    test('rawQuery ignores embedded apikey', () {
      final out = validateAndEncode(
        'latest',
        const <String, Object?>{},
        rawQuery: 'apikey=secret&q=foo',
      );
      expect(out['q'], 'foo');
      expect(out.containsKey('apikey'), isFalse);
    });

    test('rawQuery accepts a full URL', () {
      final out = validateAndEncode(
        'latest',
        const <String, Object?>{},
        rawQuery: 'https://newsdata.io/api/1/latest?q=foo&language=en',
      );
      expect(out['q'], 'foo');
      expect(out['language'], 'en');
    });

    test('validation error exposes the param name', () {
      try {
        validateAndEncode('latest', {'size': 999});
        fail('expected NewsdataValidationException');
      } on NewsdataValidationException catch (e) {
        expect(e.param, 'size');
      }
    });
  });
}
