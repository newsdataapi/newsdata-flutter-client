// Two flavours of pagination: scrollAll (merged) and paginate (Stream).

import 'dart:io';

import 'package:newsdataapi/newsdataapi.dart';

Future<void> main() async {
  final client = NewsDataApiClient(
    apiKey: Platform.environment['NEWSDATA_API_KEY'] ?? '',
  );

  try {
    // 1. scrollAll: follow nextPage and return one merged response.
    final merged = await client.scrollAll(
      endpoint: Endpoint.latest,
      params: {'q': 'news'},
      maxResults: 200,
    );
    print('merged total: ${merged.articles.length}');

    // 2. paginate: idiomatic Stream<NewsdataResponse>, one page at a time.
    var page = 0;
    await for (final r in client.paginate(
      endpoint: Endpoint.latest,
      params: {'q': 'news'},
      maxPages: 5,
    )) {
      page += 1;
      print('page $page: ${r.articles.length} articles');
    }
  } finally {
    client.close();
  }
}
