import "dart:io";
import "dart:math";

import "package:flutter/widgets.dart";
import "package:frontend/router.dart";
import "package:frontend/screens/home/tile.dart";
import "package:frontend/screens/home/info.dart";
import "package:frontend/screens/titles/titles.dart";
import "package:frontend/screens/titles/titles_row.dart";
import "package:frontend/widgets/input_listener.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const version = String.fromEnvironment("ATLAS_VERSION");

  static final tiles = [
    TileData(
      name: "Movies",
      img: const AssetImage("img/popcorn.png"),
      onClick: () {
        router.push("/movie/titles");
      },
    ),
    TileData(
      name: "TV",
      img: const AssetImage("img/tv.png"),
      onClick: () {
        router.push("/tv/titles");
      },
    ),
    TileData(
      name: "Restart",
      img: const AssetImage("img/shutdown.png"),
      onClick: () {
        Process.run("reboot", []);
      },
    ),
  ];

  int index = 0;

  String? localIP;

  @override
  void initState() {
    super.initState();
    precacheRows();
    router.addListener(() {
      if (router.location == "/home") precacheRows();
    });
    NetworkInterface.list().then((interfaces) {
      setState(() {
        localIP = interfaces.asMap()[0]?.addresses.asMap()[0]?.address;
      });
    });
  }

  Future<void> precacheRows() async {
    await Future.wait([
      Titles.initRows("movie"),
      Titles.initRows("tv"),
    ]);
    for (final rows in Titles.rowsCache.values) {
      for (final row in rows.sublist(0, 2)) {
        for (final title in row.titles.sublist(0, TitlesRow.visibleTitles)) {
          _precacheImage(NetworkImage(
              "https://image.tmdb.org/t/p/w300_and_h450_bestv2${title.poster}"));
        }
      }
    }
  }

  void _precacheImage(NetworkImage img) {
    if (mounted) precacheImage(img, context);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeOfDay = now.hour >= 7 && now.hour <= 17 ? "day" : "night";
    final max = timeOfDay == "day" ? 4 : 23;
    final bgIndex = Random(now.day).nextInt(max);
    final img = AssetImage("img/bg/$timeOfDay/$bgIndex.webp");

    return InputListener(
      onKeyDown: onKeyDown,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: img,
                fit: BoxFit.cover,
              ),
            ),
            child: Padding(
              padding:
                  EdgeInsets.all(MediaQuery.of(context).size.height / 12 - 0.1),
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  for (int i = 0; i < tiles.length; i++)
                    Tile(tiles[i], active: i == index)
                ],
              ),
            ),
          ),
          const HomeInfo(),
          Container(
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.all(4),
            child: Row(
              children: [
                Text(
                  localIP ?? "",
                  style: const TextStyle(fontSize: 24),
                ),
                const Spacer(),
                const Text(
                  "Atlas v$version",
                  style: TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    switch (e.name) {
      case "Arrow Up":
        if (index % 2 == 1) setIndex(index - 1);
        break;
      case "Arrow Down":
        if (index % 2 == 0 && index + 1 < tiles.length) setIndex(index + 1);
        break;
      case "Arrow Left":
        if (index >= 2) setIndex(index - 2);
        break;
      case "Arrow Right":
        if (index + 2 < tiles.length) setIndex(index + 2);
        break;
      case "Enter":
        tiles[index].onClick();
        break;
      case "Browser Search":
        router.push("/search");
        break;
    }
  }

  void setIndex(int i) {
    setState(() {
      index = i;
    });
  }
}

class TileData {
  const TileData(
      {required this.name, required this.img, required this.onClick});

  final String name;
  final AssetImage img;
  final Function onClick;
}
