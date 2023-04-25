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

    final key = event.logicalKey.keyLabel;
    // the repeat interval is faster than the page transition, so don't repeat
    // keys that change the route
    if (!["Enter", "Escape"].contains(key)) {
      timer = Timer.periodic(const Duration(milliseconds: 300), (_) {
        widget.onKeyDown(key);
      });
    }

    widget.onKeyDown(key);
  }

  @override
  dispose() {
    focusNode.dispose();
    timer?.cancel();
    super.dispose();
  }
}
