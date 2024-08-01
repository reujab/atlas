import "dart:async";

import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/http.dart";
import "package:frontend/main.dart";
import "package:frontend/router.dart";
import "package:frontend/screens/seasons/season_data.dart";
import "package:frontend/screens/seasons/seasons.dart";
import "package:frontend/screens/titles/titles.dart";
import "package:frontend/screens/titles/titles_row.dart";
import "package:frontend/title_data.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/button.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/overview.dart";
import "package:frontend/widgets/poster.dart";
import "package:intl/intl.dart";

class ButtonData {
  ButtonData(this.name, {required this.icon, required this.onClick});

  String name;
  IconData icon;
  final Function onClick;
}

class TitleDetails extends StatefulWidget {
  static TitleData? title;
  static double? imgWidth;

  const TitleDetails({super.key});

  @override
  State<TitleDetails> createState() => _TitleDetailsState();
}

class _TitleDetailsState extends State<TitleDetails> {
  final title = TitleDetails.title!;
  final poster = GlobalKey<PosterState>();
  final client = HttpClient();

  int buttonIndex = 0;
  bool inMyList = false;
  bool? movieIsAvailable;

  late final List<ButtonData> buttons = [
    ButtonData(
      title.type == "tv" ? "View" : "Play",
      icon: FontAwesomeIcons.play,
      onClick: () {
        if (title.type == "tv") {
          router.push("/seasons").then((_) {
            poster.currentState?.updatePercent();
          });
        } else if (movieIsAvailable == true) {
          router.push("/play?type=movie&id=${title.id}").then((_) {
            poster.currentState?.updatePercent();
          });
        }
      },
    ),
    ...(title.trailer == null
        ? []
        : [
            ButtonData(
              "Watch trailer",
              icon: FontAwesomeIcons.youtube,
              onClick: () {
                router.push("/play?trailer=ytdl://${title.trailer}");
              },
            )
          ]),
    ButtonData(
      "Add to list",
      icon: FontAwesomeIcons.plus,
      onClick: toggleInMyList,
    ),
  ];

  @override
  void initState() {
    super.initState();

    setInMyList();
    if (title.type == "movie") {
      setMovieIsAvailable();
    } else {
      getSeasons();
    }
  }

  void setInMyList() async {
    final rows = await db!.rawQuery("""
      SELECT EXISTS (
        SELECT 1
        FROM my_list
        WHERE type = ?
        AND id = ?
      )
    """, [title.type, title.id]);
    inMyList = rows[0].values.first == 1;
    if (inMyList) {
      setState(() {
        buttons.last.icon = FontAwesomeIcons.check;
      });
    }
  }

  Future<void> setMovieIsAvailable() async {
    bool? available;
    try {
      available =
          await client.getJson("$server/movie/${title.id}/available.json");
    } catch (err) {
      if (!mounted) rethrow;
      setState(() {
        movieIsAvailable = false;
        buttons[0].icon = FontAwesomeIcons.bug;
        buttons[0].name = "Error";
      });
      rethrow;
    }
    if (!mounted || available == null) return;
    setState(() {
      movieIsAvailable = available;
      if (available == false) {
        buttons[0].icon = FontAwesomeIcons.faceSadTear;
        buttons[0].name = "Unavailable";
      }
    });
  }

  void getSeasons() {
    Seasons.seasons?.then((seasons) {
      if (seasons == null) return;
      for (final season in seasons) {
        season.scrollController.dispose();
      }
    });
    Seasons.seasons = client
        .getJson<List<dynamic>>("$server/tv/${title.id}/seasons.json")
        .then((json) => json?.map((j) => SeasonData.fromJson(j)).toList());
  }

  @override
  Widget build(BuildContext context) {
    final released = title.released == null
        ? []
        : [Text(DateFormat.yMMMMd("en_US").format(title.released!))];

    return InputListener(
      onKeyDown: onKeyDown,
      handleNavigation: true,
      child: Background(
        child: Column(
          children: [
            Header(title.title),
            const Spacer(),
            IntrinsicHeight(
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Poster(
                        key: poster,
                        title: title,
                        width: TitlesRow.imgWidth,
                      ),
                      const SizedBox(height: 32),
                      ...released,
                    ],
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Overview(
                      rating: title.rating,
                      genres: title.genres,
                      overview: title.overview,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < buttons.length; i++)
                  Button(
                    buttons[i].name,
                    icon: buttons[i].icon,
                    active: i == buttonIndex,
                    loading: title.type == "movie" &&
                        i == 0 &&
                        movieIsAvailable == null,
                  ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    switch (e.name) {
      case "Arrow Left":
        if (buttonIndex > 0) {
          setState(() {
            buttonIndex--;
          });
        }
        break;
      case "Arrow Right":
        if (buttonIndex < buttons.length - 1) {
          setState(() {
            buttonIndex++;
          });
        }
        break;
      case "Enter":
        buttons[buttonIndex].onClick();
        break;
      case "Browser Search":
        router.push("/search");
        break;
    }
  }

  void toggleInMyList() {
    inMyList = !inMyList;

    if (inMyList) {
      db!.execute("""
        INSERT INTO my_list (type, id, title, genres, overview, released, trailer, rating, poster)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      """, [
        title.type,
        title.id,
        title.title,
        title.genres.join(","),
        title.overview,
        title.released?.millisecondsSinceEpoch,
        title.trailer,
        title.rating,
        title.poster
      ]);
    } else {
      db!.execute("""
        DELETE FROM my_list
        WHERE type = ?
        AND id = ?
      """, [title.type, title.id]);
    }
    setState(() {
      buttons.last.icon =
          inMyList ? FontAwesomeIcons.check : FontAwesomeIcons.plus;
    });

    Titles.updateMyList(title.type);
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}
