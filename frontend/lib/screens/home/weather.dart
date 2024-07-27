import "dart:async";
import "dart:convert";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:frontend/net.dart";
import "package:frontend/ui.dart";
import "package:frontend/http.dart";

class Weather extends StatefulWidget {
  const Weather({super.key});

  static String? coords;

  @override
  State<Weather> createState() => _WeatherState();
}

class _WeatherState extends State<Weather> {
  final client = HttpClient();

  bool loaded = false;
  String? city;
  String? temp;
  String? icon;
  String? forecast;

  @override
  void initState() {
    super.initState();
    updateWeather();
  }

  Future<void> updateWeather() async {
    final coords = await getCoords();
    if (!mounted || coords == null) return;
    final Map<String, dynamic>? meta, json;
    try {
      meta = await client.getJson("https://api.weather.gov/points/$coords");
      if (meta == null) return;
      json = await client.getJson(meta["properties"]["forecast"]);
      if (json == null || !mounted) return;
    } catch (err) {
      Timer(const Duration(seconds: 1), updateWeather);
      throw "Failed to get forecast: $err";
    }

    final weather = json["properties"]["periods"][0];
    setState(() {
      loaded = true;
      city = meta!["properties"]["relativeLocation"]["properties"]["city"];
      temp = "${weather["temperature"]} °${weather["temperatureUnit"]}";
      icon = weather["icon"];
      forecast = weather["shortForecast"]
          .replaceFirst(RegExp(" then.*"), "")
          .replaceAll(RegExp(r"\band\b", caseSensitive: false), "&")
          .replaceFirst("Slight ", "");
    });
  }

  Future<String?> getCoords() async {
    if (Weather.coords != null) return Weather.coords!;
    await waitUntilOnline();
    // wget is used because dart seems to always use IPv4, which in my tests are
    // less accurate.
    final wget = await Process.run("wget", [
      "-O-",
      "https://reallyfreegeoip.org/json/",
    ]);
    final json = jsonDecode(wget.stdout);
    return Weather.coords = "${json["latitude"]},${json["longitude"]}";
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          color: Colors.white,
          height: 1,
          margin: const EdgeInsets.all(16),
        ),
        Text(
          city!,
          style: const TextStyle(fontSize: 32),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: const BoxDecoration(shape: BoxShape.circle),
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 16,
              ),
              child: CachedNetworkImage(imageUrl: icon!),
            ),
            Text(
              temp!,
              style: const TextStyle(fontSize: 64),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            forecast!,
            style: const TextStyle(fontSize: 38),
          ),
        )
      ],
    );
  }
}
