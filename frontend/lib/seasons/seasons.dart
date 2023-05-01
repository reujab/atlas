import "dart:async";
import "dart:convert";

import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/http.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/const.dart";
import "package:frontend/seasons/episode.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/overview.dart";
import "package:frontend/seasons/season_data.dart";
import "package:frontend/seasons/season_pill.dart";
import "package:frontend/title_details/title_details.dart";
import "package:frontend/router.dart";

class Seasons extends StatefulWidget {
  const Seasons({super.key});

  static List<SeasonData>? seasons;

  @override
  State<Seasons> createState() => _SeasonsState();
}

class _SeasonsState extends State<Seasons> {
  final title = TitleDetails.title!;

  final pillScrollController = ScrollController();
  final scrollController = ScrollController();

  int index = 0;
  List<SeasonData> seasons = Seasons.seasons ?? [];

  Timer? timer;

  SeasonData get season => seasons[index];

  EpisodeData get episode => season.episodes[season.index];

  @override
  void initState() {
    super.initState();

    if (seasons.isEmpty) {
      timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (Seasons.seasons == null) return;
        timer.cancel();
        setState(() {
          seasons = Seasons.seasons!;
        });
        getMagnet();
      });
    } else {
      getMagnet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      child: Background(
        padding: 0,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: mainPadX),
            child: Header(title.title),
          ),
          ...(seasons.isEmpty
              ? const [
                  Expanded(
                    child: SpinKitRipple(color: Colors.white, size: 256),
                  )
                ]
              : [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: mainPadX),
                    child: Overview(
                      overview: episode.overview ?? "",
                      maxLines: 3,
                    ),
                  ),
                  Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: mainPadX),
                    // margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      controller: pillScrollController,
                      children: [
                        for (int i = 0; i < seasons.length; i++)
                          SeasonPill(seasons[i].number, active: i == index)
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      controller: scrollController,
                      children: [
                        for (final season in seasons)
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: ListView(
                              controller: season.scrollController,
                              children: [
                                for (int i = 0; i < season.episodes.length; i++)
                                  Episode(
                                    season.episodes[i],
                                    active: season.index == i,
                                  ),
                                // spacer
                                SizedBox(
                                  height: MediaQuery.of(context).size.height,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
        ]),
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    switch (e.name) {
      case "Arrow Up":
        if (seasons[index].index > 0) setEpisodeIndex(seasons[index].index - 1);
        break;
      case "Arrow Down":
        if (seasons[index].index < seasons[index].episodes.length - 1) {
          setEpisodeIndex(seasons[index].index + 1);
        }
        break;
      case "Arrow Left":
        if (index > 0) setIndex(index - 1);
        break;
      case "Arrow Right":
        if (index < seasons.length - 1) setIndex(index + 1);
        break;
      case "Enter":
        if (episode.magnet != null) {
          router.push(
              "/play?magnet=${Uri.encodeComponent(episode.magnet!)}&s=${season.number}&e=${episode.number}");
        }
        break;
      case "Escape":
        router.pop();
        break;
    }
  }

  void setIndex(int i) {
    setState(() {
      index = i;
    });
    scrollX();
    getMagnet();
  }

  void setEpisodeIndex(int i) {
    setState(() {
      seasons[index].index = i;
    });
    scrollY();
    getMagnet();
  }

  void scrollX() {
    pillScrollController.animateTo(
      index.toDouble() * (SeasonPill.width + SeasonPill.marginX * 2),
      duration: scrollDuration,
      curve: Curves.ease,
    );
    scrollController.animateTo(
      MediaQuery.of(context).size.width * index,
      duration: scrollDuration,
      curve: Curves.ease,
    );
    scrollY();
  }

  void scrollY() {
    if (!seasons[index].scrollController.hasClients) {
      Timer(const Duration(milliseconds: 50), scrollY);
      return;
    }

    final y =
        (Episode.height + Episode.padY * 2) * seasons[index].index.toDouble();
    seasons[index]
        .scrollController
        .animateTo(y, duration: scrollDuration, curve: Curves.ease);
  }

  Future<void> getMagnet() async {
    if (episode.magnet != null || episode.unavailable) return;

    final res = await get(
        "$host/tv/magnet?q=${Uri.encodeComponent(title.title)}&s=${season.number}&e=${episode.number}&key=$key");
    if (res.statusCode == 404) {
      setState(() {
        episode.unavailable = true;
      });
      return;
    }

    final Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      episode.magnet = json["magnet"];
      for (final seasonNum in json["seasons"] ?? []) {
        final season = seasons.firstWhere((s) => s.number == seasonNum);
        for (final episode in season.episodes) {
          episode.magnet = json["magnet"];
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pillScrollController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
