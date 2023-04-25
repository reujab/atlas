import "dart:convert";

import "package:frontend/const.dart";
import "package:http/http.dart" as http;

const maxTries = 5;

Future<http.Response> get(String url) async {
  log.info("Getting $url");

  final then = DateTime.now();

  http.Response res;
  for (int i = 1; i <= maxTries; i++) {
    try {
      res = await http.get(Uri.parse(url));
    } catch (err) {
      log.shout("Unable to connect to $url: $err");
      if (i == maxTries) rethrow;
      await Future.delayed(const Duration(milliseconds: 250));
      continue;
    }

    if (res.statusCode != 200) {
      final err = "$url responded with ${res.statusCode}";
      log.severe(err);
      if (i == maxTries || res.statusCode < 500 && res.statusCode != 404) {
        throw err;
      }
      continue;
    }

    log.info(
        "Got response in ${DateTime.now().difference(then).inMilliseconds}ms");

    return res;
  }

  throw UnimplementedError();
}

Future<T> getJson<T>(String url) async {
  return jsonDecode(utf8.decode((await get(url)).bodyBytes));
}
