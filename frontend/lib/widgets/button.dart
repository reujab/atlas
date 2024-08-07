import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/ui.dart";
import "package:frontend/animation_mixin.dart";

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
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button>
    with TickerProviderStateMixin, AnimationMixin {
  @override
  void initState() {
    super.initState();
    animate(widget.active ? 1.1 : 1);
  }

  @override
  void didUpdateWidget(Button oldButton) {
    super.didUpdateWidget(oldButton);
    if (oldButton.active != widget.active) {
      animate(widget.active ? 1.1 : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      filterQuality: FilterQuality.medium,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: fullyRounded,
          boxShadow: boxShadow,
        ),
        padding: const EdgeInsets.all(42),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 56,
              child: widget.loading
                  ? const SpinKitRipple(color: Colors.black)
                  : Align(
                      alignment: Alignment.center,
                      child: FaIcon(widget.icon, size: 56)),
            ),
            const SizedBox(width: 16),
            Text(widget.name,
                style: const TextStyle(fontSize: 56, color: Colors.black)),
          ],
        ),
      ),
    );
  }
}
