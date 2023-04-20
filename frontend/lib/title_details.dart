import "package:flutter/services.dart";
import "package:flutter/widgets.dart" hide Title;
import "package:frontend/background.dart";
import "package:frontend/header.dart";
import "package:frontend/router.dart" as router;
import "package:frontend/title.dart";

class TitleDetails extends StatelessWidget {
  static Title? title;

  TitleDetails({super.key});

  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: Background(
        child: Column(
          children: [Header(title!.title)],
        ),
      ),
    );
  }

  onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) router.pop();
  }
}
