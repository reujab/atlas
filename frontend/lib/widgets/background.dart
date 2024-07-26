import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";

class Background extends StatelessWidget {
  const Background({super.key, required this.child, this.padding = mainPadX});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(-0.2, -1),
          end: Alignment(0.2, 1),
          colors: [Color(0xFF444444), Color(0xFF1A1A1A)],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: child,
    );
  }
}
