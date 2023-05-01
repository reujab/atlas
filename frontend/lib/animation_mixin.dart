import "package:flutter/widgets.dart";
import "package:frontend/const.dart";

mixin AnimationMixin<T extends StatefulWidget> on TickerProviderStateMixin<T> {
  final _curve = CurveTween(curve: Curves.ease);

  late final controller = AnimationController(
    vsync: this,
    duration: scaleDuration,
    value: 1,
  );

  late var animation = controller.drive(_curve);

  void animate(double end) {
    final value = animation.value;
    setState(() {
      animation =
          controller.drive(_curve).drive(Tween<double>(begin: value, end: end));
    });
    controller.value = 1 - value;
    controller.animateTo(1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
