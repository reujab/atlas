import "dart:convert";
import "dart:io";

import "package:frontend/main.dart";
import "package:frontend/net.dart";
import "package:http/http.dart" as http;

final server = Platform.environment["SERVER"]!;

class HttpClient {
  static const maxTries = 3;

  final client = http.Client();

  bool closed = false;

  Future<http.Response?> get(String url) async {
    await waitUntilOnline();
    if (closed) return null;

    log.info("Getting $url");

    http.Response res;
    Object? error;
    for (int i = 0; i < maxTries; i++) {
      final start = DateTime.now();

      try {
        res = await http.get(Uri.parse(url));
      } catch (err) {
        error = err;
        log.shout("Unable to connect to $url: $err");
        await Future.delayed(const Duration(milliseconds: 500));
        if (closed) return null;
        continue;
      }
      if (closed) return null;

      final replyMs = DateTime.now().difference(start).inMilliseconds;
      log.info("Got reply in ${replyMs}ms");

      if ([200, 404].contains(res.statusCode)) return res;

      throw "Error ${res.statusCode}";
    }

    throw error!;
  }

  Future<T?> getJson<T>(String url) async {
    final res = await get(url);
    if (res == null) return null;
    if (res.statusCode != 200) {
      throw "Error ${res.statusCode}: ${res.reasonPhrase}";
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Future<T?> postJson<T>(String url, Object body) async {
    await waitUntilOnline();
    if (closed) return null;

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

  void close() {
    closed = true;
    // This does not abort requests.
    // https://github.com/dart-lang/http/issues/424
    client.close();
  }
}
