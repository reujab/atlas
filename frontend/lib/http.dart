import "dart:convert";

import "package:frontend/const.dart";
import "package:http/http.dart" as http;

Future<http.Response> get(String url) async {
  const maxTries = 5;

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

    log.info(
        "Got reply in ${DateTime.now().difference(then).inMilliseconds}ms");

    if (res.statusCode != 200) {
      final err = "$url responded with ${res.statusCode}";
      log.severe(err);
      if (res.statusCode == 404) return res;
      if (i == maxTries || res.statusCode < 500) throw err;
      continue;
    }

    return res;
  }

  throw UnimplementedError();
}

Future<T> getJson<T>(String url) async {
  return jsonDecode(utf8.decode((await get(url)).bodyBytes));
}
