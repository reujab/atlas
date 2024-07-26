import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";
import "package:frontend/widgets/poster.dart";
import "package:frontend/title_data.dart";

class TitlesRow extends StatefulWidget {
  const TitlesRow({
    super.key,
    required this.name,
    required this.titles,
    required this.active,
    required this.titleIndex,
    required this.onRowHeight,
  });

  static const visibleTitles = 6;

  static double imgWidth = 256;

  final String name;
  final List<TitleData> titles;
  final bool active;
  final int titleIndex;
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
        begin: 0, end: widget.active && i == widget.titleIndex ? 1.1 : 1)),
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
    if (oldRow.titleIndex != widget.titleIndex) {
      animate(oldRow.titleIndex, 1);
      scroll();
    }
    if (oldRow.titleIndex != widget.titleIndex ||
        oldRow.active != widget.active) {
      animate(widget.titleIndex, widget.active ? 1.1 : 1);
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
    TitlesRow.imgWidth = ((MediaQuery.of(context).size.width - mainPadX * 2) /
        TitlesRow.visibleTitles);
    return TitlesRow.imgWidth;
  }

  @override
  Widget build(BuildContext context) {
    final imgWidthScaled = getImgWidthScaled();
    final imgPadX = imgWidthScaled * (1.1 - 1) / 2 + shadowRadius;
    final imgWidth = imgWidthScaled - imgPadX * 2;
    final imgHeight = 450 / 300 * imgWidth;
    final imgPadY = imgHeight * (1.1 - 1) / 2 + shadowRadius + 8;
    final posters = [
      for (int i = 0; i < widget.titles.length; i++)
        Padding(
          key: ObjectKey(widget.titles[i]),
          padding: EdgeInsets.symmetric(vertical: imgPadY, horizontal: imgPadX),
          child: ScaleTransition(
            scale: animations[i],
            child: Poster(
              key: widget.titles[i].posterKey,
              title: widget.titles[i],
              width: imgWidth,
            ),
          ),
        ),
    ];

    return Column(children: [
      Align(
        alignment: Alignment.topLeft,
        child: Text(
          widget.name,
          style: const TextStyle(fontSize: 72, fontWeight: FontWeight.w200),
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
      widget.titleIndex * getImgWidthScaled(),
      duration: scrollDuration,
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
