import 'package:http/http.dart' as http;

import 'recommendation_http_client_stub.dart'
    if (dart.library.js_interop) 'recommendation_http_client_web.dart' as impl;

http.Client createRecommendationHttpClient() {
  return impl.createRecommendationHttpClient();
}

bool get canSetCookieHeader => impl.canSetCookieHeader;

bool storeHostingCookie(Uri endpoint, String value) {
  return impl.storeHostingCookie(endpoint, value);
}
