import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/const.dart";
import "package:frontend/scale_animation.dart";
import "package:frontend/season_data.dart";

class Episode extends StatefulWidget {
  const Episode(this.episode, {super.key, required this.active});

  static const double scale = 1.1, height = 127, imgWidth = 227, padY = 22;

  final EpisodeData episode;
  final bool active;

  @override
  State<Episode> createState() => _EpisodeState();
}

class _EpisodeState extends State<Episode>
    with TickerProviderStateMixin, ScaleAnimation {
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      animate(widget.active ? Episode.scale : 1);
    });
  }

  @override
  void didUpdateWidget(Episode oldEpisode) {
    super.didUpdateWidget(oldEpisode);
    if (widget.active != oldEpisode.active) {
      animate(widget.active ? Episode.scale : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(Episode.padY)),
          boxShadow: boxShadow,
          color: Colors.text,
          // workaround to cover white flickering gap when an episode is animating
          border: Border.all(color: const Color(0xFF333333)),
        ),
        margin: const EdgeInsets.symmetric(
            horizontal: mainPadX, vertical: Episode.padY),
        height: Episode.height,
        child: Row(
          children: [
            ...(widget.episode.still == null
                ? []
                : [
                    SizedBox(
                      width: Episode.imgWidth,
                      height: Episode.height,
                      child: Transform.scale(
                        scale: 1.1,
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://image.tmdb.org/t/p/w${Episode.imgWidth.toInt()}_and_h${Episode.height.toInt()}_bestv2${widget.episode.still}",
                        ),
                      ),
                    ),
                  ]),
            const SizedBox(width: 48),
            Expanded(
              child: Text(
                widget.episode.name,
                style: const TextStyle(color: Colors.black),
                overflow: TextOverflow.fade,
                // softWrap: true,
              ),
            ),
            ...(widget.active
                ? [
                    const SpinKitRipple(
                      color: Colors.black,
                      size: Episode.height * 0.5,
                    ),
                  ]
                : []),
            const SizedBox(width: 48)
          ],
        ),
      ),
    );
  }
}
