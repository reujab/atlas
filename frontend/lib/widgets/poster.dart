import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/const.dart";
import "package:frontend/title_data.dart";
import "package:frontend/widgets/progress_overlay.dart";

class Poster extends StatefulWidget {
  const Poster({super.key, required this.title, required this.width});

  final TitleData title;
  final double width;

  @override
  State<StatefulWidget> createState() => PosterState();
}

class PosterState extends State<Poster> {
  double percent = 0;

  @override
  void initState() {
    super.initState();
    updatePercent();
  }

  void updatePercent() async {
    final row = await db!.rawQuery("""
      SELECT percent, position
      FROM title_progress
      WHERE type = ?
      AND id = ?
      AND season = -1
      AND episode = -1
      LIMIT 1
    """, [widget.title.type, widget.title.id]);
    if (row.isEmpty) return;

    setState(() {
      percent = row[0]["percent"] as double;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(boxShadow: boxShadow),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        child: ProgressOverlay(
          width: widget.width,
          percent: percent,
          child: CachedNetworkImage(
            imageUrl:
                "https://image.tmdb.org/t/p/w300_and_h450_bestv2${widget.title.poster}",
            width: widget.width,
            errorWidget: (context, url, error) {
              log.shout("Error loading $url: $error");
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleExclamation,
                    size: 64,
                    color: Colors.white,
                  ),
                  Text("Error"),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
