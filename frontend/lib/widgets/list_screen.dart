import "package:flutter/widgets.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/scrollable_list.dart";

abstract class ListScreen<T> extends StatelessWidget {
  const ListScreen({super.key});

  List<T> get items;
  String get title;

  Widget builder(T item, bool active);
  onSelect(int index);

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Column(
        children: [
          Header(title),
          ScrollableList(
            items: items,
            builder: builder,
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }
}
