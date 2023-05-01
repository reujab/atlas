import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
import "package:frontend/home/home.dart";
import "package:frontend/animation_mixin.dart";

class Tile extends StatefulWidget {
  const Tile(this.tile, {super.key, required this.active});

  final TileData tile;

  final bool active;

  @override
  State<Tile> createState() => _TileState();
}

class _TileState extends State<Tile>
    with TickerProviderStateMixin, AnimationMixin {
  @override
  void initState() {
    super.initState();
    animate(widget.active ? scale : 1);
  }

  @override
  void didUpdateWidget(Tile oldTile) {
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
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          boxShadow: lightBoxShadow,
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
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
