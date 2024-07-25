import "dart:async";
import "dart:convert";

import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/http.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/const.dart";
import "package:frontend/screens/seasons/episode.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/overview.dart";
import "package:frontend/screens/seasons/season_data.dart";
import "package:frontend/screens/seasons/season_pill.dart";
import "package:frontend/screens/title_details/title_details.dart";
import "package:frontend/router.dart";

class Seasons extends StatefulWidget {
  const Seasons({super.key});

  static List<SeasonData>? seasons;

  @override
  State<Seasons> createState() => _SeasonsState();
}

class _SeasonsState extends State<Seasons> {
  final title = TitleDetails.title!;
  final client = HttpClient();
  final episodeKey = GlobalKey<EpisodeState>();

  final pillScrollController = ScrollController();

  int seasonIndex = 0;
  List<SeasonData> seasons = Seasons.seasons ?? [];

  Timer? initTimer;
  Timer? uuidTimer;

  SeasonData get season => seasons[seasonIndex];
  EpisodeData get episode => season.episodes[season.episodeIndex];

  late final ScrollController scrollController = ScrollController(
    onAttach: (_) async {
      final rows = await db!.rawQuery("""
        SELECT season, episode
        FROM title_progress
        WHERE type = 'tv'
        AND id = ?1
        AND season != -1
        AND episode != -1
        ORDER BY ts DESC
        LIMIT 1
      """, [title.id]);
      if (rows.isNotEmpty) {
        setState(() {
          seasonIndex = seasons
              .indexWhere((season) => season.number == rows[0]["season"]);
          seasons[seasonIndex].episodeIndex = seasons[seasonIndex]
              .episodes
              .indexWhere((episode) => episode.number == rows[0]["episode"]);
        });
      }
      scrollX();
    },
  );

  @override
  void initState() {
    super.initState();

    if (seasons.isEmpty) {
      initTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (Seasons.seasons == null) return;
        timer.cancel();
        setState(() {
          seasons = Seasons.seasons!;
        });
        getUUID();
      });
    } else {
      getUUID();
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
                          SeasonPill(
                            seasons[i].number,
                            active: i == seasonIndex,
                          )
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
                                    key: season.episodes[i].key,
                                    titleId: title.id,
                                    season: season,
                                    episode: season.episodes[i],
                                    active: season.episodeIndex == i,
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
        if (seasons[seasonIndex].episodeIndex > 0) {
          setEpisodeIndex(seasons[seasonIndex].episodeIndex - 1);
        }
        break;
      case "Arrow Down":
        if (seasons[seasonIndex].episodeIndex <
            seasons[seasonIndex].episodes.length - 1) {
          setEpisodeIndex(seasons[seasonIndex].episodeIndex + 1);
        }
        break;
      case "Arrow Left":
        if (seasonIndex > 0) setIndex(seasonIndex - 1);
        break;
      case "Arrow Right":
        if (seasonIndex < seasons.length - 1) setIndex(seasonIndex + 1);
        break;
      case "Enter":
        if (episode.uuid != null) {
          router
              .push(
                  "/play?uuid=${episode.uuid}&s=${season.number}&e=${episode.number}&title=${episode.name}")
              .then((_) {
            for (final episode in season.episodes) {
              episode.key.currentState?.updatePercent();
            }
          });
        }
        break;
      case "Browser Search":
        router.push("/search");
        break;
      case "Browser Home":
        router.go("/home");
        break;
      case "Escape":
        router.pop();
        break;
    }
  }

  void setIndex(int i) {
    setState(() {
      seasonIndex = i;
    });
    scrollX();
    getUUID();
  }

  void setEpisodeIndex(int i) {
    setState(() {
      seasons[seasonIndex].episodeIndex = i;
    });
    scrollY();
    getUUID();
  }

  void scrollX() {
    pillScrollController.animateTo(
      seasonIndex.toDouble() * (SeasonPill.width + SeasonPill.marginX * 2),
      duration: scrollDuration,
      curve: Curves.ease,
    );
    scrollController.animateTo(
      MediaQuery.of(context).size.width * seasonIndex,
      duration: scrollDuration,
      curve: Curves.ease,
    );
    scrollY();
  }

  void scrollY() {
    if (!seasons[seasonIndex].scrollController.hasClients) {
      Timer(const Duration(milliseconds: 50), scrollY);
      return;
    }

    final y = (Episode.height + Episode.padY * 2) *
        seasons[seasonIndex].episodeIndex.toDouble();
    seasons[seasonIndex]
        .scrollController
        .animateTo(y, duration: scrollDuration, curve: Curves.ease);
  }

  void getUUID() {
    uuidTimer?.cancel();
    // Only actually get the UUID after 1 second of hovering to prevent spamming
    // requests while scrolling.
    uuidTimer = Timer(const Duration(seconds: 1), _getUUID);
  }

  Future<void> _getUUID() async {
    final episode = this.episode;
    if (episode.uuid != null || episode.unavailable) return;

    final cleanTitle =
        Uri.encodeComponent(title.title.replaceAll(nonSearchableChars, ""));
    final res = await client.get(
        "$host/get-uuid/tv/$cleanTitle?s=${season.number}&e=${episode.number}");
    if (!mounted || res == null) return;
    if (res.statusCode == 404) {
      setState(() {
        episode.unavailable = true;
      });
      return;
    }

    final Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      episode.uuid = json["uuid"];
      // If `json["episode"] == null`, this uuid refers to one or more seasons,
      // so update the relevant seasons with the UUID.
      if (json["episode"] != null) return;
      for (final seasonNum in json["seasons"]) {
        final season = seasons.firstWhere((s) => s.number == seasonNum);
        for (final episode in season.episodes) {
          episode.uuid = json["uuid"];
        }
      }
    });
  }

  @override
  void dispose() {
    client.close();
    initTimer?.cancel();
    uuidTimer?.cancel();
    pillScrollController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
