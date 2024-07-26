import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";

class SeasonPill extends StatelessWidget {
  const SeasonPill(this.number, {super.key, required this.active});

  static const width = 192.0, marginX = 16.0, marginY = 22.0;

  final int number;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      transform:
          active ? (Matrix4.identity()..scale(1.1, 1.1)) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      duration: scaleDuration,
      curve: Curves.ease,
      decoration: const BoxDecoration(
        boxShadow: boxShadow,
        borderRadius: fullyRounded,
        color: Colors.white,
      ),
      width: width,
      margin: const EdgeInsets.symmetric(
        vertical: marginY,
        horizontal: marginX,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child:
          Text("Season $number", style: const TextStyle(color: Colors.black)),
    );
  }
}
