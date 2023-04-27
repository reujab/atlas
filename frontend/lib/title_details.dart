import "dart:convert";

import "package:flutter/widgets.dart" hide Title;
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/background.dart";
import "package:frontend/button.dart";
import "package:frontend/const.dart";
import "package:frontend/header.dart";
import "package:frontend/http.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/overview.dart";
import "package:frontend/poster.dart";
import "package:frontend/router.dart" as router;
import "package:frontend/season_data.dart";
import "package:frontend/seasons.dart";
import "package:frontend/title.dart";
import "package:frontend/titles_row.dart";
import "package:intl/intl.dart";

class TitleDetails extends StatefulWidget {
  static Title? title;
  static double? imgWidth;

  const TitleDetails({super.key});

  @override
  State<TitleDetails> createState() => _TitleDetailsState();
}

class _TitleDetailsState extends State<TitleDetails> {
  int index = 0;

  String? magnet;

  final title = TitleDetails.title!;

  late final buttons = [
    ButtonData(
      title.type == "tv" ? "View" : "Play",
      icon: FontAwesomeIcons.play,
      onClick: () {
        if (title.type == "tv") {
          router.push("/seasons");
        } else if (magnet != null) {
          router.push("/play?magnet=${Uri.encodeComponent(magnet!)}");
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
                router.push("/play?url=ytdl://${title.trailer}");
              },
            )
          ]),
  ];

  @override
  initState() {
    super.initState();

    if (title.type == "tv") {
      getSeasons();
    } else {
      getMagnet();
    }
  }

  getSeasons() async {
    Seasons.seasons = null;

    List<dynamic> json;
    try {
      json = await getJson("$host/seasons/${title.id}?key=$key");
    } catch (err) {
      return;
    }

    Seasons.seasons = json.map((j) => SeasonData.fromJson(j)).toList();
  }

  getMagnet() async {
    Map<String, dynamic> json;
    try {
      var res = await get(
          "$host/${title.type}/magnet?q=${Uri.encodeComponent("${title.title} ${title.released?.year ?? ""}")}&key=$key");
      if (res.statusCode == 404) {
        setState(() {
          buttons[0].name = "Unavailable";
          buttons[0].icon = FontAwesomeIcons.faceSadTear;
        });
        return;
      }
      json = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (err) {
      setState(() {
        buttons[0].name = "Error";
        buttons[0].icon = FontAwesomeIcons.bug;
      });
      return;
    }

    setState(() {
      magnet = json["magnet"];
    });
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  Poster(title: title, width: TitlesRow.imgWidth),
                  const SizedBox(height: 32),
                  ...released,
                ]),
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
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int i = 0; i < buttons.length; i++)
                  Button(
                    buttons[i].name,
                    icon: buttons[i].icon,
                    active: i == index,
                    loading: title.type == "movie" &&
                        i == 0 &&
                        magnet == null &&
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

  onKeyDown(String key) {
    switch (key) {
      case "Arrow Left":
        if (index > 0) {
          setState(() {
            index--;
          });
        }
        break;
      case "Arrow Right":
        if (index < buttons.length - 1) {
          setState(() {
            index++;
          });
        }
        break;
      case "Enter":
        buttons[index].onClick();
        break;
      case "Escape":
        router.pop();
        break;
    }
  }
}

class ButtonData {
  ButtonData(this.name, {required this.icon, required this.onClick});

  String name;
  IconData? icon;
  final Function onClick;
}
