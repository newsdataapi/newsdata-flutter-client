/// Official Dart/Flutter client for the Newsdata.io News API.
///
/// See https://github.com/newsdataapi/newsdata-flutter-client for usage docs.
library newsdataapi;

export 'src/client.dart' show NewsDataApiClient, NewsdataLogger, redactApiKey;
export 'src/constants.dart' show Endpoint;
export 'src/errors.dart'
    show
        NewsdataException,
        NewsdataValidationException,
        NewsdataApiException,
        NewsdataAuthException,
        NewsdataRateLimitException,
        NewsdataServerException,
        NewsdataNetworkException;
export 'src/response.dart' show NewsdataResponse, Article;
export 'src/validator.dart' show validateAndEncode;
