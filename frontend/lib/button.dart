import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/scale_animation.dart";

class Button extends StatefulWidget {
  const Button(
    this.name, {
    super.key,
    required this.icon,
    required this.active,
    this.loading = false,
  });

  final String name;
  final IconData icon;
  final bool active;
  final bool loading;

  @override
  createState() => _ButtonState();
}

class _ButtonState extends State<Button>
    with TickerProviderStateMixin, ScaleAnimation {
  static const scale = 1.1;

  @override
  initState() {
    super.initState();
    animate(widget.active ? scale : 1);
  }

  @override
  didUpdateWidget(Button oldButton) {
    super.didUpdateWidget(oldButton);
    if (oldButton.active != widget.active) {
      animate(widget.active ? scale : 1);
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
            SizedBox(
              width: 64,
              height: 56,
              child: widget.loading
                  ? const SpinKitRipple(color: Color(0xFF000000))
                  : Align(
                      alignment: Alignment.center,
                      child: FaIcon(widget.icon, size: 56)),
            ),
            const SizedBox(width: 16),
            Text(widget.name,
                style: const TextStyle(fontSize: 56, color: Color(0xFF000000))),
          ],
        ),
      ),
    );
  }
}
