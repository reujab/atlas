import "dart:async";

import "package:flutter/widgets.dart";
import "package:frontend/const.dart";

class Cursor extends StatefulWidget {
  const Cursor({super.key, this.blinking = true});

  final bool blinking;

  @override
  State<Cursor> createState() => _CursorState();
}

class _CursorState extends State<Cursor> {
  double opacity = 1;

  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      timer = Timer.periodic(const Duration(milliseconds: 333), (timer) {
        if (!mounted || timer.tick % 3 == 0) return;
        setState(() {
          opacity = widget.blinking ? timer.tick % 3 - 1 : 0;
        });
      });
    });
  }

  @override
  void didUpdateWidget(Cursor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.blinking != widget.blinking) {
      setState(() {
        opacity = widget.blinking ? 1 : 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: Duration(milliseconds: opacity == 0 ? 333 : 250),
      curve: Curves.ease,
      child: Container(width: 4, height: 72, color: Colors.black),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
