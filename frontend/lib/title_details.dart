import "package:flutter/widgets.dart" hide Title;
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/background.dart";
import "package:frontend/button.dart";
import "package:frontend/header.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/overview.dart";
import "package:frontend/poster.dart";
import "package:frontend/router.dart" as router;
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

  int buttonsNum = 0;

  @override
  Widget build(BuildContext context) {
    final title = TitleDetails.title!;

    final released = title.released == null
        ? []
        : [Text(DateFormat.yMMMMd("en_US").format(title.released!))];

    final buttons = [
      const ButtonData("Play", icon: FontAwesomeIcons.play),
    ];

    if (title.trailer != null) {
      buttons.add(
          const ButtonData("Watch trailer", icon: FontAwesomeIcons.youtube));
    }

    buttonsNum = buttons.length;

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
                  Button(buttons[i].name,
                      icon: buttons[i].icon, active: i == index)
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
        if (index < buttonsNum - 1) {
          setState(() {
            index++;
          });
        }
        break;
      case "Escape":
        router.pop();
        break;
    }
  }
}

class ButtonData {
  const ButtonData(this.name, {required this.icon});

  final String name;
  final IconData icon;
}
