import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:frontend/const.dart";

class InputListener extends StatefulWidget {
  const InputListener(
      {super.key, required this.child, required this.onKeyDown});

  final Widget child;

  final Function(InputEvent e) onKeyDown;

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
      onKeyEvent: _onKeyEvent,
      child: widget.child,
    );
  }

  void _onKeyEvent(KeyEvent event) {
    if (event is KeyRepeatEvent) return;

    timer?.cancel();
    timer = null;

    if (event is! KeyDownEvent) return;

    final key = event.logicalKey.keyLabel;
    // the repeat interval is faster than the page transition, so don't repeat
    // keys that change the route
    if (key.startsWith("Arrow") || key == "Backspace") {
      timer = Timer.periodic(scrollDuration, (_) {
        widget.onKeyDown(InputEvent(
          name: key,
          character: event.character,
          time: DateTime.now(),
        ));
      });
    }

    widget.onKeyDown(InputEvent(
      name: key,
      character: event.character,
      time: DateTime.now(),
    ));
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
