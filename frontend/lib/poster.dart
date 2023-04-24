import "package:flutter/widgets.dart" hide Title;
import "package:frontend/title.dart";

class Poster extends StatelessWidget {
  const Poster({super.key, required this.title, this.width});

  final Title title;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(boxShadow: [
        BoxShadow(
          blurRadius: 3,
          color: Color(0x77555555),
          spreadRadius: 3,
        )
      ]),
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
