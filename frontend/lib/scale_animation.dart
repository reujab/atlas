import "package:flutter/widgets.dart";

mixin ScaleAnimation<T extends StatefulWidget> on TickerProviderStateMixin<T> {
  final _curve = CurveTween(curve: Curves.ease);

  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  late var animation = controller.drive(_curve);

  animate(double end) {
    final value = animation.value;
    animation =
        controller.drive(_curve).drive(Tween<double>(begin: value, end: end));
    controller.value = 1 - value;
    controller.animateTo(1);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
