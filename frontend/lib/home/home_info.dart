import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
import "package:frontend/http.dart";
import "package:intl/intl.dart";

class Weather {
  const Weather({
    required this.city,
    required this.temp,
    required this.icon,
    required this.forecast,
  });

  final String city;
  final String temp;
  final String icon;
  final String forecast;
}

class HomeInfo extends StatefulWidget {
  const HomeInfo({super.key});

  static String? coords;

  @override
  State<HomeInfo> createState() => _HomeInfoState();
}

class _HomeInfoState extends State<HomeInfo> {
  DateTime date = DateTime.now();

  Weather? weather;

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (date.second != now.second) {
        setState(() {
          date = now;
        });
      }
    });

    updateWeather();
  }

  Future<String> getCoords() async {
    if (HomeInfo.coords != null) return HomeInfo.coords!;

    final loc = (await getJson(
            "https://location.services.mozilla.com/v1/geolocate?key=geoclue"))[
        "location"];
    HomeInfo.coords = "${loc["lat"]},${loc["lng"]}";
    return HomeInfo.coords!;
  }

  Future<void> updateWeather() async {
    if (!mounted) return;

    final coords = await getCoords();
    final Map<String, dynamic> meta, json;
    try {
      meta = await getJson("https://api.weather.gov/points/$coords");
      json = await getJson(meta["properties"]["forecast"]);
    } catch (err) {
      Timer(const Duration(seconds: 1), updateWeather);
      throw "Failed to get forecast: $err";
    }
    if (!mounted) return;
    final forecast = json["properties"]["periods"][0];
    setState(() {
      weather = Weather(
        city: meta["properties"]["relativeLocation"]["properties"]["city"],
        temp: "${forecast["temperature"]} °${forecast["temperatureUnit"]}",
        icon: forecast["icon"],
        forecast: forecast["shortForecast"]
            .replaceFirst(RegExp(" then.*"), "")
            .replaceAll("and", "&"),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jms("en_US").format(date);

    return UnconstrainedBox(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(right: 64),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Color(0xB34B5563),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat("EEEE").format(date),
                style: const TextStyle(fontSize: 32),
              ),
              Text(
                DateFormat.yMMMd("en_US").format(date),
                style: const TextStyle(fontSize: 48),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: time.characters
                    .map(
                      (char) => Container(
                        width: int.tryParse(char) == null ? null : 38,
                        alignment: Alignment.center,
                        child: Text(char, style: const TextStyle(fontSize: 64)),
                      ),
                    )
                    .toList(),
              ),
              ...(weather == null
                  ? []
                  : [
                      Container(
                        color: Colors.white,
                        height: 1,
                        margin: const EdgeInsets.all(16),
                      ),
                      Text(
                        weather!.city,
                        style: const TextStyle(fontSize: 32),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            decoration:
                                const BoxDecoration(shape: BoxShape.circle),
                            clipBehavior: Clip.antiAlias,
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: CachedNetworkImage(imageUrl: weather!.icon),
                          ),
                          Text(
                            weather!.temp,
                            style: const TextStyle(fontSize: 64),
                          ),
                        ],
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(
                          weather!.forecast,
                          style: const TextStyle(fontSize: 38),
                        ),
                      )
                    ]),
            ],
          ),
        ),
      ),
    );
  }
}
