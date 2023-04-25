import "package:flutter/widgets.dart";
import "package:frontend/home.dart";
import "package:frontend/scale_animation.dart";

class Tile extends StatefulWidget {
  const Tile(this.tile, {super.key, required this.active});

  final TileData tile;

  final bool active;

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile>
    with TickerProviderStateMixin, ScaleAnimation {
  static const scale = 1.1;

  @override
  void initState() {
    super.initState();
    animate(widget.active ? scale : 1);
  }

  @override
  didUpdateWidget(Tile oldTile) {
    super.didUpdateWidget(oldTile);
    if (oldTile.active != widget.active) {
      animate(widget.active ? scale : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.height / 4;

    return ScaleTransition(
      scale: animation,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEEEEEE),
          borderRadius: BorderRadius.all(Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              blurRadius: 3,
              color: Color(0x55AAAAAA),
              spreadRadius: 3,
            ),
          ],
        ),
        margin: EdgeInsets.all(size / 3),
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image(image: widget.tile.img, height: size * 5 / 8),
            Text(
              widget.tile.name,
              style: const TextStyle(color: Color(0xFF000000)),
            ),
          ],
        ),
      ),
    );
  }
}
