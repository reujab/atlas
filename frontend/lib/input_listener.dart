import "dart:async";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

class InputListener extends StatefulWidget {
  const InputListener(
      {super.key, required this.child, required this.onKeyDown});

  final Widget child;

  final Function(String key) onKeyDown;

  @override
  createState() => _InputListenerState();
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

  _onKeyEvent(KeyEvent event) {
    if (event is KeyRepeatEvent) return;

    timer?.cancel();
    timer = null;

    if (event is! KeyDownEvent) return;

    // it appears the keyup doesn't register for the enter key
    if (event.logicalKey.keyLabel != "Enter") {
      timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        widget.onKeyDown(event.logicalKey.keyLabel);
      });
    }

    widget.onKeyDown(event.logicalKey.keyLabel);
  }
}
