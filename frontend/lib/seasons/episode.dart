import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/const.dart";
import "package:frontend/scale_animation.dart";
import "package:frontend/seasons/season_data.dart";

class Episode extends StatefulWidget {
  const Episode(this.episode, {super.key, required this.active});

  static const height = 127.0 + 2, imgWidth = 227.0, padY = 22.0;

  final EpisodeData episode;
  final bool active;

  @override
  State<Episode> createState() => _EpisodeState();
}

class _EpisodeState extends State<Episode>
    with TickerProviderStateMixin, ScaleAnimation {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      animate(widget.active ? scale : 1);
    });
  }

  @override
  void didUpdateWidget(Episode oldEpisode) {
    super.didUpdateWidget(oldEpisode);
    if (widget.active != oldEpisode.active) {
      animate(widget.active ? scale : 1);
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
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(
            horizontal: mainPadX, vertical: Episode.padY),
        height: Episode.height,
        child: Row(
          children: [
            ...(widget.episode.still == null
                ? []
                : [
                    // workaround to prevent animation flickering
                    Transform.scale(
                      scale: 1.02,
                      child: SizedBox(
                        width: Episode.imgWidth,
                        height: Episode.height,
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://image.tmdb.org/t/p/w227_and_h127_bestv2${widget.episode.still}",
                        ),
                      ),
                    ),
                  ]),
            const SizedBox(width: 48),
            Expanded(
              child: RichText(
                overflow: TextOverflow.fade,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text:
                          "E${widget.episode.number.toString().padLeft(2, "0")}",
                      style: const TextStyle(color: Colors.gray),
                    ),
                    const WidgetSpan(child: SizedBox(width: 20)),
                    TextSpan(
                      text: widget.episode.name,
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                  style: DefaultTextStyle.of(context).style,
                ),
                // softWrap: true,
              ),
            ),
            ...(widget.active
                ? [
                    widget.episode.magnet == null &&
                            widget.episode.unavailable == false
                        ? const SpinKitRipple(
                            color: Colors.black,
                            size: Episode.height * 0.5,
                          )
                        : FaIcon(
                            widget.episode.unavailable
                                ? FontAwesomeIcons.ban
                                : FontAwesomeIcons.play,
                            size: Episode.height * 0.5,
                          ),
                  ]
                : []),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
