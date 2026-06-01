// A minimal CLI example. Set NEWSDATA_API_KEY in your env and run:
//
//   dart run example/newsdataapi_example.dart
//
// Works in any Dart context (CLI, server, Flutter mobile / web / desktop).

import 'dart:io';

import 'package:newsdataapi/newsdataapi.dart';

Future<void> main() async {
  final apiKey = Platform.environment['NEWSDATA_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('set NEWSDATA_API_KEY in your env');
    exit(1);
  }

  final client = NewsDataApiClient(apiKey: apiKey);

  try {
    // 1. Single request with typed named parameters.
    final resp = await client.latest(
      q: 'bitcoin',
      country: ['us', 'gb'],
      language: ['en'],
    );
    for (final article in resp.articles) {
      print('- ${article.title}');
      print('  ${article.link}');
    }
  } on NewsdataValidationException catch (e) {
    print('Invalid param ${e.param}: ${e.message}');
  } on NewsdataAuthException catch (e) {
    print('Auth failed: HTTP ${e.statusCode}');
  } on NewsdataRateLimitException catch (e) {
    print('Rate limited; retry after ${e.retryAfter} seconds');
  } on NewsdataException catch (e) {
    print('Request failed: $e');
  } finally {
    client.close();
  }
}
