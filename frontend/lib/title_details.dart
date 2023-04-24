import "package:flutter/services.dart";
import "package:flutter/widgets.dart" hide Title;
import "package:frontend/background.dart";
import "package:frontend/header.dart";
import "package:frontend/overview.dart";
import "package:frontend/poster.dart";
import "package:frontend/router.dart" as router;
import "package:frontend/title.dart";
import "package:frontend/titles_row.dart";
import "package:intl/intl.dart";

class TitleDetails extends StatelessWidget {
  static Title? title;
  static double? imgWidth;

  TitleDetails({super.key});

  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    final released = title!.released == null
        ? []
        : [Text(DateFormat.yMMMMd("en_US").format(title!.released!))];

    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: Background(
        child: Column(
          children: [
            Header(title!.title),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  Poster(title: title!, width: TitlesRow.imgWidth),
                  const SizedBox(height: 32),
                  ...released,
                ]),
                const SizedBox(width: 32),
                Expanded(child: Overview(title: title!)),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) router.pop();
  }
}
