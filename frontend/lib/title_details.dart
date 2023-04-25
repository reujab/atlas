import "dart:convert";
import "dart:io";

import "package:flutter/widgets.dart" hide Title;
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/background.dart";
import "package:frontend/button.dart";
import "package:frontend/header.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/overview.dart";
import "package:frontend/play.dart";
import "package:frontend/poster.dart";
import "package:frontend/router.dart" as router;
import "package:frontend/title.dart";
import "package:frontend/titles_row.dart";
import "package:http/http.dart" as http;
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
      "Play",
      icon: FontAwesomeIcons.play,
      onClick: () {
        if (magnet != null) {
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
                // TODO
              },
            )
          ]),
  ];

  @override
  initState() {
    super.initState();
    getMagnet();
  }

  getMagnet() async {
    var client = http.Client();
    try {
      var uri = Uri.parse(
          "${Platform.environment["SEEDBOX_HOST"]}/${title.type}/magnet?q=${Uri.encodeComponent("${title.title} ${title.released?.year ?? ""}")}&key=${Platform.environment["SEEDBOX_KEY"]}");
      var res = await client.get(uri);
      if (res.statusCode == 404) {
        // TODO: unavailable
        return;
      } else if (res.statusCode != 200) {
        // TODO: handle err
        return;
      }
      Map<String, dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
      setState(() {
        magnet = json["magnet"];
      });
    } catch (err) {
      print("err $err");
    } finally {
      client.close();
    }
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
                Expanded(child: Overview(title: title)),
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
                    loading: i == 0 && magnet == null,
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
  const ButtonData(this.name, {required this.icon, required this.onClick});

  final String name;
  final IconData icon;
  final Function onClick;
}
