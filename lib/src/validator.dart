// Client-side parameter validation and normalization, mirroring the official
// Python/PHP/Node/Go clients:
//
//   - keys are lowercased (the API is case-insensitive);
//   - null values are dropped;
//   - arrays are comma-joined; booleans become '1' / '0';
//   - `size` must be an integer within bounds;
//   - `sentiment_score` must be numeric and requires `sentiment`;
//   - mutually-exclusive groups are rejected;
//   - unknown parameters for the endpoint are rejected;
//   - `rawQuery`, when present, must be the only parameter and is parsed and
//     checked against the endpoint's allowed keys.

import 'constants.dart';
import 'errors.dart';

/// Validate and normalize endpoint parameters. Returns a map from API
/// parameter name to its string representation, ready to be URL-encoded.
///
/// [rawQuery] is handled separately because it's mutually exclusive with
/// every other parameter — pass either [params] *or* a non-null [rawQuery],
/// not both.
Map<String, String> validateAndEncode(
  String endpoint,
  Map<String, Object?> params, {
  String? rawQuery,
}) {
  final allowed = filters[endpoint];
  if (allowed == null) {
    throw NewsdataValidationException('unknown endpoint: $endpoint');
  }

  // Lowercase keys and drop nulls.
  final lowered = <String, Object>{};
  for (final entry in params.entries) {
    final value = entry.value;
    if (value == null) continue;
    lowered[entry.key.toLowerCase()] = value;
  }

  // rawQuery is mutually exclusive with every other parameter.
  if (rawQuery != null) {
    if (lowered.isNotEmpty) {
      final keys = lowered.keys.toList()..sort();
      throw NewsdataValidationException(
        'rawQuery cannot be combined with other parameters; got rawQuery and $keys',
        param: 'rawQuery',
      );
    }
    return _parseRawQuery(rawQuery, allowed);
  }

  // Count endpoints require an explicit date range.
  if (requiresDateRange.contains(endpoint)) {
    for (final required in const ['from_date', 'to_date']) {
      final v = lowered[required];
      if (v == null || (v is String && v.isEmpty)) {
        throw NewsdataValidationException(
          '$required is required for the $endpoint endpoint',
          param: required,
        );
      }
    }
  }

  // Mutually-exclusive groups.
  for (final group in mutexGroups) {
    final set = group.where(lowered.containsKey).toList();
    if (set.length > 1) {
      throw NewsdataValidationException(
        'these parameters are mutually exclusive: $set',
        param: set.first,
      );
    }
  }

  // sentiment_score requires sentiment.
  if (lowered.containsKey('sentiment_score') &&
      !lowered.containsKey('sentiment')) {
    throw NewsdataValidationException(
      'sentiment_score requires sentiment to be set',
      param: 'sentiment_score',
    );
  }

  // Per-param validation + coercion.
  final out = <String, String>{};
  for (final entry in lowered.entries) {
    final name = entry.key;
    if (!allowed.contains(name)) {
      throw NewsdataValidationException(
        'unsupported parameter for the $endpoint endpoint: $name',
        param: name,
      );
    }
    out[name] = _coerce(name, entry.value);
  }
  return out;
}

String _coerce(String name, Object value) {
  if (boolParams.contains(name)) return _coerceBool(name, value);
  if (intParams.contains(name)) return _coerceInt(name, value);
  if (floatParams.contains(name)) return _coerceFloat(name, value);
  return _coerceString(name, value);
}

String _coerceBool(String name, Object value) {
  if (value is bool) return value ? '1' : '0';
  if (value is int) {
    if (value == 0) return '0';
    if (value == 1) return '1';
  }
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == '1' || v == 'true' || v == 'yes') return '1';
    if (v == '0' || v == 'false' || v == 'no') return '0';
  }
  throw NewsdataValidationException('$name must be a boolean', param: name);
}

String _coerceInt(String name, Object value) {
  int? n;
  if (value is int) {
    n = value;
  } else if (value is String) {
    n = int.tryParse(value);
  }
  if (n == null) {
    throw NewsdataValidationException('$name must be an integer', param: name);
  }
  if (name == 'size' && (n < sizeMin || n > sizeMax)) {
    throw NewsdataValidationException(
      'size must be between $sizeMin and $sizeMax (got $n)',
      param: 'size',
    );
  }
  return n.toString();
}

String _coerceFloat(String name, Object value) {
  if (value is int) return value.toString();
  if (value is double) return value.toString();
  if (value is num) return value.toString();
  if (value is String && double.tryParse(value) != null) return value;
  throw NewsdataValidationException('$name must be a number', param: name);
}

String _coerceString(String name, Object value) {
  if (value is String) return value;
  if (value is num) return value.toString();
  if (value is List) {
    final parts = <String>[];
    for (final item in value) {
      if (item is String) {
        parts.add(item);
      } else if (item is num) {
        parts.add(item.toString());
      } else {
        throw NewsdataValidationException(
          'all items in $name must be strings',
          param: name,
        );
      }
    }
    return parts.join(',');
  }
  throw NewsdataValidationException(
    '$name must be a String or List<String>',
    param: name,
  );
}

/// Parse a rawQuery string (query fragment or full URL) into validated values.
Map<String, String> _parseRawQuery(String rawQuery, Set<String> allowed) {
  if (rawQuery.isEmpty) {
    throw NewsdataValidationException(
      'rawQuery must be a non-empty string',
      param: 'rawQuery',
    );
  }

  String queryString = rawQuery;
  try {
    final parsed = Uri.parse(rawQuery);
    if (parsed.hasScheme && parsed.hasAuthority) {
      queryString = parsed.query;
    }
  } catch (_) {
    // Not a parseable URI; treat the whole string as the query.
  }
  if (queryString.startsWith('?')) {
    queryString = queryString.substring(1);
  }

  final values = Uri.splitQueryString(queryString);

  final out = <String, String>{};
  for (final entry in values.entries) {
    final name = entry.key.trim().toLowerCase();
    if (name.isEmpty) continue;
    if (name == 'apikey') continue; // supplied by the client
    if (!allowed.contains(name)) {
      throw NewsdataValidationException(
        'unknown parameter in rawQuery: ${entry.key}',
        param: entry.key,
      );
    }
    if (entry.value.isEmpty) {
      throw NewsdataValidationException(
        'parameter ${entry.key} in rawQuery must have a value',
        param: entry.key,
      );
    }
    out[name] = entry.value;
  }
  return out;
}
