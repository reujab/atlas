import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";

class ProgressOverlay extends StatelessWidget {
  const ProgressOverlay({
    super.key,
    required this.width,
    required this.percent,
    required this.child,
  });

  final double width;
  final double percent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: 0,
          left: 0,
          child: Container(
            height: 8,
            width: width * percent,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: percent == 0
                  ? BorderRadius.zero
                  : const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
