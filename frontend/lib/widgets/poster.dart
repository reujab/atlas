import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
import "package:frontend/title_data.dart";

class Poster extends StatelessWidget {
  const Poster({super.key, required this.title, this.width});

  final TitleData title;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(boxShadow: boxShadow),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        child: Image(
          image: NetworkImage(
              "https://image.tmdb.org/t/p/w300_and_h450_bestv2${title.poster}"),
          width: width,
        ),
      ),
    );
  }
}
