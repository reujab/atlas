import "const.dart";
import "package:flutter/widgets.dart" hide Title, Row;
import "title.dart";

const visibleTitles = 6, scale = 1.1;

class Row extends StatefulWidget {
  const Row({
    super.key,
    required this.name,
    required this.titles,
    required this.active,
    required this.index,
    required this.onRowHeight,
  });

  final String name;
  final List<Title> titles;
  final bool active;
  final int index;
  final Function(double) onRowHeight;

  @override
  State<Row> createState() => _RowState();
}

class _RowState extends State<Row> with TickerProviderStateMixin {
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
    (i) => controllers[i]
        .drive(_curve)
        .drive(Tween<double>(begin: 0, end: i == widget.index ? scale : 1)),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRowHeight((context.findRenderObject() as RenderBox).size.height);
      scroll();
    });
  }

  @override
  void didUpdateWidget(Row oldRow) {
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
    return ((MediaQuery.of(context).size.width - mainPadX * 2) / visibleTitles);
  }

  @override
  Widget build(BuildContext context) {
    final imgWidthScaled = getImgWidthScaled();
    final imgPadX = imgWidthScaled * (scale - 1) / 2;
    final imgWidth = imgWidthScaled - imgPadX * 2;
    final imgHeight = 450 / 300 * imgWidth;
    final imgPadY = imgHeight * (scale - 1) / 2;
    final posters = [
      for (int i = 0; i < widget.titles.length; i++)
        Padding(
          padding: EdgeInsets.symmetric(vertical: imgPadY, horizontal: imgPadX),
          child: ScaleTransition(
            scale: animations[i],
            child: Image(
              image: NetworkImage(
                  "https://image.tmdb.org/t/p/w300_and_h450_bestv2${widget.titles[i].poster}"),
              width: imgWidth,
            ),
          ),
        )
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
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView(
            scrollDirection: Axis.horizontal,
            controller: scrollController,
            children: posters,
          ),
        ),
      ),
    ]);
  }

  void scroll() {
    scrollController.animateTo(
      widget.index * getImgWidthScaled(),
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
