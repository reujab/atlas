import "dart:async";
import "dart:io";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
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

  Future<String?> getCoords() async {
    if (Weather.coords != null) return Weather.coords!;

    final json = await client.postJson(
        "https://www.googleapis.com/geolocation/v1/geolocate?key=${Platform.environment["GOOGLE_LOCATION_KEY"]}",
        {"considerIp": true});
    if (json == null) return null;
    final loc = json["location"];
    Weather.coords = "${loc["lat"]},${loc["lng"]}";
    return Weather.coords!;
  }

  Future<void> updateWeather() async {
    if (!mounted) return;

    final coords = await getCoords();
    if (coords == null) return;
    final Map<String, dynamic>? meta, json;
    try {
      meta = await client.getJson("https://api.weather.gov/points/$coords");
      if (meta == null) return;
      json = await client.getJson(meta["properties"]["forecast"]);
      if (json == null) return;
    } catch (err) {
      Timer(const Duration(seconds: 1), updateWeather);
      throw "Failed to get forecast: $err";
    }
    if (!mounted) return;

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

  @override
  void initState() {
    super.initState();
    updateWeather();
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
