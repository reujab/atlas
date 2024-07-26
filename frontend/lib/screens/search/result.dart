import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";
import "package:frontend/title_data.dart";

class Result extends StatelessWidget {
  const Result(this.title, {super.key, required this.active});

  static const height = 128.0, topMargin = 16.0;

  final TitleData title;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Result.height,
      margin: const EdgeInsets.only(top: Result.topMargin),
      child: Row(children: [
        AnimatedContainer(
          duration: scaleDuration,
          curve: Curves.ease,
          width: active ? Result.topMargin * 2 : 0,
        ),
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(24)),
          child: CachedNetworkImage(
            imageUrl:
                "https://image.tmdb.org/t/p/w300_and_h450_bestv2${title.poster}",
            width: 300.0 / 450.0 * Result.height,
          ),
        ),
        const SizedBox(width: Result.topMargin),
        Expanded(
          child: Text(
            title.title,
            style: const TextStyle(
              fontSize: 48,
              color: Colors.black,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        Text(
          title.released?.year.toString() ?? "",
          style: const TextStyle(fontSize: 48, color: Colors.gray),
        ),
      ]),
    );
  }
}
