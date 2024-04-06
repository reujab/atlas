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
  int index = 0;

  String? uuid;

  final title = TitleDetails.title!;

  late final buttons = [
    ButtonData(
      title.type == "tv" ? "View" : "Play",
      icon: FontAwesomeIcons.play,
      onClick: () {
        if (title.type == "tv") {
          router.push("/seasons");
        } else if (uuid != null) {
          router.push("/play?uuid=$uuid");
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
  ];

  @override
  void initState() {
    super.initState();

    if (title.type == "tv") {
      getSeasons();
    } else {
      getUUID();
    }
  }

  Future<void> getSeasons() async {
    Seasons.seasons = null;

    final List<dynamic> json = await getJson("$host/seasons/${title.id}");

    Seasons.seasons = json.map((j) => SeasonData.fromJson(j)).toList();
  }

  Future<void> getUUID() async {
    Map<String, dynamic> json;
    try {
      var res = await get(
          "$host/movie/uuid?q=${Uri.encodeComponent("${title.title} ${title.released?.year ?? ""}")}");
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
                      Poster(title: title, width: TitlesRow.imgWidth),
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
                    active: i == index,
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
}

class ButtonData {
  ButtonData(this.name, {required this.icon, required this.onClick});

  String name;
  IconData? icon;
  final Function onClick;
}
