/// Official Dart/Flutter client for the Newsdata.io News API.
///
/// See https://github.com/newsdataapi/newsdata-flutter-client for usage docs.
library newsdataapi;

export 'src/client.dart' show NewsDataApiClient, NewsdataLogger, redactApiKey;
export 'src/websocket.dart' show NewsDataApiWebSocket;
export 'src/constants.dart' show Endpoint;
export 'src/errors.dart'
    show
        NewsdataException,
        NewsdataValidationException,
        NewsdataApiException,
        NewsdataAuthException,
        NewsdataRateLimitException,
        NewsdataApiLimitExceededException,
        NewsdataApiKeyLimitExceededException,
        NewsdataServerException,
        NewsdataNetworkException,
        NewsdataWebSocketException,
        NewsdataWebSocketAuthException;
export 'src/article_v2.dart'
    show
        ArticleV2,
        ArticleV2Source,
        ArticleV2Media,
        ArticleV2Ai,
        ArticleV2Sentiment,
        isPlanNotice;
export 'src/response.dart' show NewsdataResponse, Article;
export 'src/validator.dart' show validateAndEncode;
