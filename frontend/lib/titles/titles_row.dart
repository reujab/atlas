import "package:flutter/widgets.dart" hide Title;
import "package:frontend/const.dart";
import "package:frontend/widgets/poster.dart";
import "package:frontend/title.dart";

const visibleTitles = 6, scale = 1.1, shadow = 3;

class TitlesRow extends StatefulWidget {
  const TitlesRow({
    super.key,
    required this.name,
    required this.titles,
    required this.active,
    required this.index,
    required this.onRowHeight,
  });

  static double imgWidth = 0;

  final String name;
  final List<Title> titles;
  final bool active;
  final int index;
  final Function(double) onRowHeight;

  @override
  State<TitlesRow> createState() => _TitlesRowState();
}

class _TitlesRowState extends State<TitlesRow> with TickerProviderStateMixin {
  static final _curve = CurveTween(curve: Curves.ease);

  final scrollController = ScrollController();

  late final controllers = List.generate(
    widget.titles.length,
    (i) => AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..animateTo(1),
  );

  late final animations = List.generate(
    widget.titles.length,
    (i) => controllers[i].drive(_curve).drive(Tween<double>(
        begin: 0, end: widget.active && i == widget.index ? scale : 1)),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRowHeight((context.findRenderObject() as RenderBox).size.height);
      scroll();
    });
  }

  @override
  void didUpdateWidget(TitlesRow oldRow) {
    super.didUpdateWidget(oldRow);
    if (oldRow.index != widget.index) {
      animate(oldRow.index, 1);
      scroll();
    }
    if (oldRow.index != widget.index || oldRow.active != widget.active) {
      animate(widget.index, widget.active ? scale : 1);
    }
  }

  void animate(int index, double end) {
    final value = animations[index].value;
    animations[index] = controllers[index]
        .drive(_curve)
        .drive(Tween<double>(begin: value, end: end));
    controllers[index].value = 1 - value;
    controllers[index].animateTo(1);
  }

  double getImgWidthScaled() {
    TitlesRow.imgWidth =
        ((MediaQuery.of(context).size.width - mainPadX * 2) / visibleTitles);
    return TitlesRow.imgWidth;
  }

  @override
  Widget build(BuildContext context) {
    final imgWidthScaled = getImgWidthScaled();
    final imgPadX = imgWidthScaled * (scale - 1) / 2 + shadow;
    final imgWidth = imgWidthScaled - imgPadX * 2;
    final imgHeight = 450 / 300 * imgWidth;
    final imgPadY = imgHeight * (scale - 1) / 2 + shadow + 8;
    final posters = [
      for (int i = 0; i < widget.titles.length; i++)
        Padding(
          padding: EdgeInsets.symmetric(vertical: imgPadY, horizontal: imgPadX),
          child: ScaleTransition(
            scale: animations[i],
            child: Poster(title: widget.titles[i], width: imgWidth),
          ),
        ),
    ];

    return Column(children: [
      Align(
        alignment: Alignment.topLeft,
        child: Text(
          widget.name,
          style: const TextStyle(fontSize: 72),
          textAlign: TextAlign.start,
        ),
      ),
      SizedBox(
        height: imgHeight + imgPadY * 2,
        child: ListView(
          scrollDirection: Axis.horizontal,
          controller: scrollController,
          children: posters,
        ),
      ),
    ]);
  }

  void scroll() {
    scrollController.animateTo(
      widget.index * getImgWidthScaled(),
      duration: duration,
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    scrollController.dispose();
    for (final controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
