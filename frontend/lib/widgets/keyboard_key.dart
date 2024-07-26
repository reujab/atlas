import "package:flutter/widgets.dart";
import "package:frontend/animation_mixin.dart";
import "package:frontend/ui.dart";

class KeyboardKey extends StatefulWidget {
  const KeyboardKey({
    super.key,
    required this.active,
    required this.depressed,
    required this.border,
    required this.child,
  });

  static const size = 112.0;
  static const margin = 16.0;

  final bool active;
  final bool depressed;
  final bool border;
  final Widget child;

  @override
  State<KeyboardKey> createState() => _KeyboardKeyState();
}

class _KeyboardKeyState extends State<KeyboardKey>
    with TickerProviderStateMixin, AnimationMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      animate(widget.active ? 1.2 : 1);
    });
  }

  @override
  void didUpdateWidget(KeyboardKey oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active ||
        widget.depressed != oldWidget.depressed) {
      animate(
        widget.depressed
            ? 0.8
            : widget.active
                ? 1.2
                : 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      filterQuality: FilterQuality.medium,
      child: AnimatedContainer(
        width: KeyboardKey.size,
        height: KeyboardKey.size,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(KeyboardKey.margin),
        duration: scaleDuration,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          boxShadow: boxShadow,
          color: Colors.white,
          border: widget.border
              ? Border.all(color: const Color(0xFF93c5fd), width: 5)
              : null,
        ),
        child: widget.child,
      ),
    );
  }
}
