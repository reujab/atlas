import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/ui.dart";
import "package:frontend/widgets/input_listener.dart";

/// Handles a scrollable list view. Must be inside a flexible object.
class ScrollableList<T> extends StatefulWidget {
  const ScrollableList({
    super.key,
    required this.items,
    required this.builder,
    required this.onSelect,
  });

  final List<T> items;
  final Widget Function(T item, bool active) builder;
  final Function(int index) onSelect;

  @override
  State<StatefulWidget> createState() => _ScrollableListState<T>();
}

class _ScrollableListState<T> extends State<ScrollableList<T>> {
  final scrollController = ScrollController();

  int itemIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          InputListener(onKeyDown: onKeyDown, handleNavigation: true),
          Expanded(
            child: widget.items.isEmpty
                ? const SpinKitRipple(color: Colors.white, size: 256)
                : ListView(
                    controller: scrollController,
                    children: [
                      for (int i = 0; i < widget.items.length; i++)
                        AnimatedContainer(
                          clipBehavior: Clip.antiAlias,
                          curve: Curves.ease,
                          duration: scaleDuration,
                          height: itemHeight,
                          margin: itemMarginInset,
                          transform: i == itemIndex
                              ? (Matrix4.identity()..scale(1.1, 1.1))
                              : Matrix4.identity(),
                          transformAlignment: FractionalOffset.center,
                          decoration: const BoxDecoration(
                            borderRadius: itemRadius,
                            boxShadow: boxShadow,
                            color: Colors.white,
                          ),
                          child: DefaultTextStyle(
                            style: DefaultTextStyle.of(context)
                                .style
                                .copyWith(color: Colors.black),
                            child: widget.builder(
                              widget.items[i],
                              i == itemIndex,
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    switch (e.name) {
      case "Arrow Up":
        if (itemIndex > 0) {
          setState(() {
            itemIndex--;
          });
          scroll();
        }
        break;
      case "Arrow Down":
        if (itemIndex < widget.items.length - 1) {
          setState(() {
            itemIndex++;
          });
          scroll();
        }
        break;
      case "Enter":
        widget.onSelect(itemIndex);
        break;
    }
  }

  void scroll() {
    scrollController.animateTo(itemIndex * (itemHeight + itemMargin * 2),
        duration: scrollDuration, curve: Curves.ease);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
