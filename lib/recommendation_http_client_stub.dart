import 'package:http/http.dart' as http;

http.Client createRecommendationHttpClient() {
  return http.Client();
}

bool get canSetCookieHeader => true;

bool storeHostingCookie(Uri endpoint, String value) {
  return false;
}
