import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";

class Button extends StatefulWidget {
  const Button(this.name,
      {super.key, required this.icon, required this.active});

  final String name;
  final IconData icon;
  final bool active;

  @override
  createState() => _ButtonState();
}

class _ButtonState extends State<Button> with TickerProviderStateMixin {
  late final controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    value: 1,
  );

  late var animation = controller
      .drive(CurveTween(curve: Curves.ease))
      .drive(Tween<double>(begin: 0, end: widget.active ? 1.1 : 1));

  animate(double end) {
    final value = animation.value;
    animation = controller
        .drive(CurveTween(curve: Curves.ease))
        .drive(Tween<double>(begin: value, end: end));
    controller.value = 1 - value;
    controller.animateTo(1);
  }

  @override
  didUpdateWidget(Button oldButton) {
    super.didUpdateWidget(oldButton);
    if (oldButton.active != widget.active) {
      animate(widget.active ? 1.1 : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          borderRadius: BorderRadius.all(Radius.circular(1024)),
          boxShadow: [
            BoxShadow(blurRadius: 3, color: Color(0x77555555), spreadRadius: 3)
          ],
        ),
        padding: const EdgeInsets.all(42),
        child: Row(
          children: [
            FaIcon(widget.icon, size: 56),
            const SizedBox(width: 32),
            Text(widget.name,
                style: const TextStyle(fontSize: 56, color: Color(0xFF000000))),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
