import "dart:io";

import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/screens/seasons/seasons.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/const.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/http.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/router.dart";
import "package:frontend/title_data.dart";
import "package:frontend/screens/title_details/title_details.dart";

class Play extends StatefulWidget {
  const Play({
    super.key,
    this.uuid,
    this.season,
    this.episode,
    this.trailer,
    this.title,
  });

  final String? uuid;
  final String? season;
  final String? episode;

  final String? trailer;
  final String? title;

  @override
  State<Play> createState() => _PlayState();
}

class _PlayState extends State<Play> {
  final TitleData title = TitleDetails.title!;

  Map<String, dynamic>? stream;
  Process? couple;

  @override
  void initState() {
    super.initState();

    if (widget.uuid != null) {
      initStream();
    } else if (widget.trailer != null) {
      // TODO: remove exclamation point after upgrading to Dart 3.2
      spawnCouple(widget.trailer!);
    }
  }

  Future<void> initStream() async {
    try {
      stream = await getJson(
          "$host/init/${widget.uuid}${widget.season == null ? "" : "?s=${widget.season!}&e=${widget.episode}"}");
      if (!mounted) return;
    } catch (err) {
      pop();
      rethrow;
    }

    spawnCouple("$host${stream!["video"]}");
  }

  Future<void> spawnCouple(String url) async {
    final startTime = await getStartTime();
    final episode = widget.season == null
        ? ""
        : " S${widget.season.toString().padLeft(2, "0")}E${widget.episode.toString().padLeft(2, "0")} ${widget.title}";
    final List<String> mpvOpts = [
      "mpv",
      "--audio-device=${Platform.environment["AUDIO_DEVICE"]!}",
      "--log-file=/tmp/mpv.log",
      "--input-ipc-server=/tmp/mpv",
      "--network-timeout=300",
      "--ytdl-format=bestvideo[height<=?720][fps<=?30][vcodec!=?vp9]+bestaudio/best",
      "--hwdec=vaapi",
      "--vo=gpu",
      "--fullscreen",
      "--start=$startTime",
      ...(stream?["subs"] == null ? [] : ["--sub-file=${stream!["subs"]}"]),
      url,
      "---",
    ];
    final List<String> overlayOpts = [
      "atlas-overlay",
      "--title=${title.title}$episode",
      ...(widget.uuid == null ? [] : ["--uuid=${widget.uuid}"]),
      "---",
    ];
    couple = await Process.start(
      "couple.sh",
      [...mpvOpts, ...overlayOpts],
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await couple!.exitCode;
    couple = null;
    pop();
    if (exitCode != 0) throw "Couple exit code: $exitCode";

    // Update movie/episode progress.
    if (widget.uuid == null) return;
    final file = File("/tmp/progress");
    try {
      final progress = file.readAsLinesSync().map(double.parse).toList();
      db!.execute("""
        INSERT INTO title_progress (type, id, season, episode, percent, position)
        VALUES (?1, ?2, ?3, ?4, ?5, ?6)
        ON CONFLICT (type, id, season, episode)
        DO UPDATE
        SET percent = ?5, position = ?6, ts = CURRENT_TIMESTAMP
      """, [
        title.type,
        title.id,
        widget.season,
        widget.episode,
        progress[0],
        progress[1]
      ]);
    } finally {
      file.delete();
    }

    // Update series progress.
    if (title.type == "tv") {
      final seasons = Seasons.seasons!;
      int totalEpisodes = 0;
      int currentEpisode = 0;
      for (final season in seasons) {
        for (final episode in season.episodes) {
          totalEpisodes++;
          if (season.number.toString() == widget.season &&
              episode.number.toString() == widget.episode) {
            currentEpisode = totalEpisodes;
          }
        }
      }
      final seriesPercent = currentEpisode / totalEpisodes;
      db!.execute("""
        INSERT INTO title_progress (type, id, percent)
        VALUES ('tv', ?1, ?2)
        ON CONFLICT (type, id, season, episode)
        DO UPDATE
        SET percent = ?2, ts = CURRENT_TIMESTAMP
      """, [title.id, seriesPercent]);
    }
  }

  Future<double> getStartTime() async {
    final rows = await db!.rawQuery("""
      SELECT position
      FROM title_progress
      WHERE type = ? AND id = ?
      -- NULL will not be casted.
      AND season IS CAST(? AS INT)
      AND episode IS CAST(? AS INT)
      LIMIT 1
    """, [title.type, title.id, widget.season, widget.episode]);
    if (rows.isEmpty) return 0;
    return rows[0]["position"] as double;
  }

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      child: Background(
        child: Column(
          children: [
            Header(title.title),
            const Expanded(
              child: SpinKitRipple(color: Colors.white, size: 256),
            ),
          ],
        ),
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    if (e.name == "Browser Home") router.go("/home");
    if (e.name == "Escape") router.pop();
  }

  void pop() {
    if (router.location.startsWith("/play")) router.pop();
  }

  @override
  void dispose() {
    couple?.kill();
    super.dispose();
  }
}
