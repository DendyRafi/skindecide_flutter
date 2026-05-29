import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

http.Client createRecommendationHttpClient() {
  return BrowserClient()..withCredentials = true;
}

bool get canSetCookieHeader => false;

bool storeHostingCookie(Uri endpoint, String value) {
  if (web.window.location.hostname != endpoint.host) {
    return false;
  }

  web.document.cookie = '__test=$value; max-age=21600; path=/';
  return true;
}
