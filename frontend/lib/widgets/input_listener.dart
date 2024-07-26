import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";
import "package:frontend/router.dart";

class InputListener extends StatefulWidget {
  const InputListener({
    super.key,
    required this.child,
    this.onKeyDown,
    this.handleNavigation = false,
  });

  final Widget child;
  final Function(InputEvent e)? onKeyDown;
  final bool handleNavigation;

  @override
  State<InputListener> createState() => _InputListenerState();
}

class _InputListenerState extends State<InputListener> {
  Timer? timer;

  final focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: widget.child,
    );
  }

  void onKeyEvent(KeyEvent event) {
    if (event is KeyRepeatEvent) return;

    timer?.cancel();
    timer = null;

    if (event is! KeyDownEvent) return;

    final key = event.logicalKey.keyLabel;
    // the repeat interval is faster than the page transition, so don't repeat
    // keys that change the route
    if (key.startsWith("Arrow") || key == "Backspace") {
      timer = Timer.periodic(scrollDuration, (_) {
        handleInput(InputEvent(
          name: key,
          character: event.character,
          time: DateTime.now(),
        ));
      });
    }

    handleInput(InputEvent(
      name: key == "Browser Back" ? "Escape" : key,
      character: event.character,
      time: DateTime.now(),
    ));
  }

  void handleInput(InputEvent event) {
    if (widget.handleNavigation) {
      if (event.name == "Browser Home") {
        router.go("/home");
        return;
      } else if (event.name == "Escape") {
        router.pop();
        return;
      }
    }
    if (widget.onKeyDown != null) widget.onKeyDown!(event);
  }

  @override
  void dispose() {
    focusNode.dispose();
    timer?.cancel();
    super.dispose();
  }
}

class InputEvent {
  const InputEvent({
    required this.name,
    required this.character,
    required this.time,
  });

  final String name;
  final String? character;
  final DateTime time;
}
