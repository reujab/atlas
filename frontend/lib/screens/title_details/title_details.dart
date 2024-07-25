import "dart:convert";

import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/const.dart";
import "package:frontend/http.dart";
import "package:frontend/router.dart";
import "package:frontend/screens/seasons/season_data.dart";
import "package:frontend/screens/seasons/seasons.dart";
import "package:frontend/screens/titles/titles_row.dart";
import "package:frontend/title_data.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/button.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/overview.dart";
import "package:frontend/widgets/poster.dart";
import "package:intl/intl.dart";

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
  String? uuid;
  bool inMyList = false;

  late final List<ButtonData> buttons = [
    ButtonData(
      title.type == "tv" ? "View" : "Play",
      icon: FontAwesomeIcons.play,
      onClick: () {
        if (title.type == "tv") {
          router.push("/seasons").then((_) {
            poster.currentState?.updatePercent();
          });
        } else if (uuid != null) {
          router.push("/play?uuid=$uuid").then((_) {
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
    ButtonData("Add to list",
        icon: FontAwesomeIcons.plus, onClick: toggleInMyList),
  ];

  @override
  void initState() {
    super.initState();

    if (title.type == "tv") {
      getSeasons();
    } else {
      getUUID();
    }

    db!.rawQuery("""
      SELECT EXISTS (
        SELECT 1
        FROM my_list
        WHERE type = ?
        AND id = ?
      )
    """, [title.type, title.id]).then((rows) {
      inMyList = rows[0].values.first == 1;
      if (inMyList) {
        setState(() {
          buttons.last.icon = FontAwesomeIcons.check;
        });
      }
    });
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
  }

  Future<void> getSeasons() async {
    if (Seasons.seasons != null) {
      for (final season in Seasons.seasons!) {
        season.scrollController.dispose();
      }
    }
    Seasons.seasons = null;

    final List<dynamic>? json =
        await client.getJson("$host/seasons/${title.id}");
    if (json == null) return;

    Seasons.seasons = json.map((j) => SeasonData.fromJson(j)).toList();
  }

  Future<void> getUUID() async {
    Map<String, dynamic> json;
    try {
      final cleanTitle = title.title.replaceAll(nonSearchableChars, "");
      final encodedTitle =
          Uri.encodeComponent("$cleanTitle ${title.released?.year ?? ""}")
              .trimRight();
      var res = await client.get("$host/get-uuid/movie/$encodedTitle");
      if (res == null) return;
      if (res.statusCode == 404) {
        _setState(() {
          buttons[0].name = "Unavailable";
          buttons[0].icon = FontAwesomeIcons.faceSadTear;
        });
        return;
      }
      json = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (err) {
      _setState(() {
        buttons[0].name = "Error";
        buttons[0].icon = FontAwesomeIcons.bug;
      });
      rethrow;
    }

    _setState(() {
      uuid = json["uuid"];
    });
  }

  _setState(Function() cb) {
    if (mounted) setState(cb);
  }

  @override
  Widget build(BuildContext context) {
    final released = title.released == null
        ? []
        : [Text(DateFormat.yMMMMd("en_US").format(title.released!))];

    return InputListener(
      onKeyDown: onKeyDown,
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
                        uuid == null &&
                        buttons[i].icon == FontAwesomeIcons.play,
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
      case "Browser Home":
        router.go("/home");
        break;
      case "Escape":
        router.pop();
        break;
    }
  }

  @override
  void dispose() {
    client.close();
    super.dispose();
  }
}

class ButtonData {
  ButtonData(this.name, {required this.icon, required this.onClick});

  String name;
  IconData icon;
  final Function onClick;
}
