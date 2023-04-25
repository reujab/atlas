import "dart:io";
import "dart:math";
import "package:flutter/widgets.dart";
import "package:frontend/home_tile.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/router.dart" as router;
import "package:frontend/titles.dart";

class Home extends StatefulWidget {
  const Home({super.key});

  static int indexCache = 0;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
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

  int index = Home.indexCache;

  @override
  void initState() {
    super.initState();
    Titles.indexCache = 0;
    Titles.initRows("movie");
    Titles.initRows("tv");
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final timeOfDay = hour >= 7 && hour <= 17 ? "day" : "night";
    final max = timeOfDay == "day" ? 4 : 23;
    final rng = Random(now.day);
    final bgIndex = rng.nextInt(max);
    final img = AssetImage("img/bg/$timeOfDay/$bgIndex.webp");

    return InputListener(
      onKeyDown: onKeyDown,
      child: Container(
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
    );
  }

  onKeyDown(String key) {
    switch (key) {
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
    }
  }

  setIndex(int i) {
    Home.indexCache = i;
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
