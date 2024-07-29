import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/ui.dart";
import "package:frontend/animation_mixin.dart";
import "package:frontend/main.dart";
import "package:frontend/screens/seasons/season_data.dart";
import "package:frontend/widgets/progress_overlay.dart";

class Episode extends StatefulWidget {
  const Episode({
    super.key,
    required this.titleId,
    required this.season,
    required this.episode,
    required this.active,
  });

  static const height = 127.0 + 2, imgWidth = 227.0, padY = 22.0;

  final SeasonData season;
  final EpisodeData episode;
  final int titleId;
  final bool active;

  @override
  State<Episode> createState() => EpisodeState();
}

class EpisodeState extends State<Episode>
    with TickerProviderStateMixin, AnimationMixin {
  double percent = 0;

  @override
  void initState() {
    super.initState();
    updatePercent();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      animate(widget.active ? 1.1 : 1);
    });
  }

  void updatePercent() async {
    final row = await db!.rawQuery("""
      SELECT percent
      FROM title_progress
      WHERE type = 'tv'
      AND id = ?
      AND season = ?
      AND episode = ?
      LIMIT 1
    """, [widget.titleId, widget.season.number, widget.episode.number]);
    if (row.isEmpty) return;

    setState(() {
      percent = row[0]["percent"] as double;
    });
  }

  @override
  void didUpdateWidget(Episode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      animate(widget.active ? 1.1 : 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      filterQuality: FilterQuality.medium,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(Episode.padY)),
          boxShadow: boxShadow,
          color: Colors.white,
          // workaround to cover white flickering gap when an episode is animating
          border: Border.all(color: const Color(0xFF333333)),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(
            horizontal: mainPadX, vertical: Episode.padY),
        height: Episode.height,
        child: Row(
          children: [
            /**
             * Still
             */
            widget.episode.still == null
                ? const SizedBox.shrink()
                // Workaround flickering during scaling animation.
                // Doesn't look perfect.
                : Transform.scale(
                    scale: 1.02,
                    child: SizedBox(
                      width: Episode.imgWidth,
                      height: Episode.height,
                      child: ProgressOverlay(
                        width: Episode.imgWidth,
                        percent: percent,
                        child: CachedNetworkImage(
                          imageUrl:
                              "https://image.tmdb.org/t/p/w227_and_h127_bestv2${widget.episode.still}",
                        ),
                      ),
                    ),
                  ),
            const SizedBox(width: 48),
            Expanded(
              /**
               * Episode name
               */
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
            /**
             * Loading/play
             */
            widget.active
                ? widget.episode.available == null
                    ? const SpinKitRipple(
                        color: Colors.black,
                        size: Episode.height * 0.5,
                      )
                    : FaIcon(
                        widget.episode.available == true
                            ? FontAwesomeIcons.play
                            : FontAwesomeIcons.ban,
                        size: Episode.height * 0.5,
                      )
                : const SizedBox.shrink(),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
