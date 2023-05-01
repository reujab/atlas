import "dart:async";

import "package:flutter/widgets.dart";
import "package:frontend/const.dart";

class Cursor extends StatefulWidget {
  const Cursor({super.key});

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
      timer = Timer.periodic(const Duration(milliseconds: 333), (timer) {
        if (!mounted || timer.tick % 3 == 0) return;
        setState(() {
          opacity = 1 - opacity;
        });
      });
    });
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
