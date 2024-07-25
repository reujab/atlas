import "package:flutter/widgets.dart";
import "package:frontend/const.dart";

// This mixin will cause the animation to always start in an initial state (1),
// which means the user will always see an animation when navigating to a new
// screen (e.g. when the home screen loads, you see the icon scale up animation
// rather than already being in the final state).
// I created this because I was unfamiliar with Flutter's animation widgets and
// kept it because I liked the effect. New animation should probably just use
// AnimatedContainer.
mixin AnimationMixin<T extends StatefulWidget> on TickerProviderStateMixin<T> {
  final _curve = CurveTween(curve: Curves.ease);

  late final controller = AnimationController(
    vsync: this,
    duration: scaleDuration,
    value: 1,
  );

  late var animation = controller.drive(_curve);

  void animate(double end, {Duration? duration}) {
    final begin = animation.value;
    setState(() {
      animation =
          controller.drive(_curve).drive(Tween<double>(begin: begin, end: end));
    });
    controller.value = 0;
    controller.animateTo(1, duration: duration);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
