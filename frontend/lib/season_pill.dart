import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
import "package:frontend/scale_animation.dart";

class SeasonPill extends StatefulWidget {
  const SeasonPill(this.number, {super.key, required this.active});

  static const width = 192.0, marginX = 16.0, marginY = 22.0;

  final int number;
  final bool active;

  @override
  State<SeasonPill> createState() => _SeasonPillState();
}

class _SeasonPillState extends State<SeasonPill>
    with TickerProviderStateMixin, ScaleAnimation {
  static const scale = 1.1;

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      animate(widget.active ? scale : 1);
    });
  }

  @override
  void didUpdateWidget(SeasonPill oldPill) {
    super.didUpdateWidget(oldPill);
    if (oldPill.active != widget.active) animate(widget.active ? scale : 1);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        decoration: const BoxDecoration(
          boxShadow: boxShadow,
          borderRadius: BorderRadius.all(Radius.circular(1024)),
          color: Colors.text,
        ),
        width: SeasonPill.width,
        margin: const EdgeInsets.symmetric(
          vertical: SeasonPill.marginY,
          horizontal: SeasonPill.marginX,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        alignment: Alignment.center,
        child: Text("Season ${widget.number}",
            style: const TextStyle(color: Colors.black)),
      ),
    );
  }
}
