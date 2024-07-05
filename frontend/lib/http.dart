import "dart:convert";

import "package:frontend/const.dart";
import "package:http/http.dart" as http;

const maxTries = 4;

Future<http.Response> get(String url) async {
  log.info("Getting $url");

  final start = DateTime.now();

  http.Response res;
  Object? error;
  for (int i = 0; i < maxTries; i++) {
    try {
      res = await http.get(Uri.parse(url));
    } catch (err) {
      error = err;
      log.shout("Unable to connect to $url: $err");
      await Future.delayed(const Duration(milliseconds: 500));
      continue;
    }

    final replyMs = DateTime.now().difference(start).inMilliseconds;
    log.info("Got reply in ${replyMs}ms");

    if ([200, 404].contains(res.statusCode)) return res;

    error = "Error ${res.statusCode}: $url";
    if (res.statusCode < 500) throw error;
  }

  throw error!;
}

Future<T> getJson<T>(String url) async {
  final res = await get(url);
  if (res.statusCode != 200) {
    throw "Error ${res.statusCode}: ${res.reasonPhrase}";
  }
  return jsonDecode(utf8.decode(res.bodyBytes));
}

Future<T> postJson<T>(String url, Object body) async {
  log.info("Posting to $url");

  final start = DateTime.now();

  http.Response res;
  Object? error;
  final encodedBody = json.encode(body);
  for (int i = 0; i < maxTries; i++) {
    try {
      res = await http.post(Uri.parse(url),
          headers: {"Content-Type": "application/json"}, body: encodedBody);
    } catch (err) {
      error = err;
      log.shout("Unable to connect to $url: $err");
      await Future.delayed(const Duration(milliseconds: 500));
      continue;
    }

    final replyMs = DateTime.now().difference(start).inMilliseconds;
    log.info("Got reply in ${replyMs}ms");

    if (res.statusCode != 200) throw "Error ${res.statusCode}";

    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  throw error!;
}
