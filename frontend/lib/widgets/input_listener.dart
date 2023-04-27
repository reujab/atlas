import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:frontend/const.dart";

class InputListener extends StatefulWidget {
  const InputListener(
      {super.key, required this.child, required this.onKeyDown});

  final Widget child;

  final Function(String key) onKeyDown;

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
    if (!["Enter", "Escape"].contains(key)) {
      timer = Timer.periodic(duration, (_) {
        widget.onKeyDown(key);
      });
    }

    widget.onKeyDown(key);
  }

  @override
  void dispose() {
    focusNode.dispose();
    timer?.cancel();
    super.dispose();
  }
}
