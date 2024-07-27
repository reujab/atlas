import "dart:io";

import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/main.dart";
import "package:frontend/screens/seasons/seasons.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/ui.dart";
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
    this.epName,
  });

  final String? uuid;
  final String? season;
  final String? episode;
  final String? epName;

  final String? trailer;

  @override
  State<Play> createState() => _PlayState();
}

class _PlayState extends State<Play> {
  final TitleData title = TitleDetails.title!;
  final client = HttpClient();

  Map<String, dynamic>? stream;
  Process? couple;

  @override
  void initState() {
    super.initState();

    if (widget.uuid != null) {
      initStream();
    } else if (widget.trailer != null) {
      spawnCouple(widget.trailer!);
    }
  }

  Future<void> initStream() async {
    try {
      stream = await client.getJson(
          "$server/init/${widget.uuid}${widget.season == null ? "" : "?s=${widget.season!}&e=${widget.episode}"}");
      if (!mounted || stream == null) return;
    } catch (err) {
      pop();
      rethrow;
    }

    spawnCouple("$server${stream!["video"]}");
  }

  Future<void> spawnCouple(String url) async {
    final overlayTitle = getTitle();
    final startTime = await getStartTime();
    final List<String> mpvOpts = [
      "mpv",
      "--audio-device=${Platform.environment["AUDIO_DEVICE"]!}",
      "--fullscreen",
      "--hwdec=vaapi",
      "--input-ipc-server=/tmp/mpv",
      "--log-file=/tmp/mpv.log",
      "--network-timeout=300",
      "--start=$startTime",
      "--vo=gpu",
      "--ytdl-format=bestvideo[height<=?720][fps<=?30][vcodec!=?vp9]+bestaudio/best",
      ...(stream?["subs"] == null ? [] : ["--sub-file=${stream!["subs"]}"]),
      url,
      "---",
    ];
    final List<String> overlayOpts = [
      "atlas-overlay",
      "--title=$overlayTitle",
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

    if (widget.uuid != null) {
      updateProgress();
      updateSeriesProgress();
    }
  }

  String getTitle() {
    String t = title.title;
    if (widget.uuid == null) {
      t += " Trailer";
    } else if (widget.season != null) {
      final season = widget.season.toString().padLeft(2, "0");
      final episode = widget.episode.toString().padLeft(2, "0");
      t += " S${season}E$episode ${widget.epName}";
    }
    return t;
  }

  Future<String> getStartTime() async {
    final rows = await db!.rawQuery("""
      SELECT percent
      FROM title_progress
      WHERE type = ? AND id = ?
      -- Use LIKE to compare strings and numbers.
      AND season LIKE ? AND episode LIKE ?
      LIMIT 1
    """, [title.type, title.id, widget.season ?? "-1", widget.episode ?? "-1"]);
    if (rows.isEmpty) return "0";
    final percent = 100.0 * (rows[0]["percent"] as double);
    if (percent == 100) return "0";
    final roundedPercent = percent.floor();
    return "$roundedPercent%";
  }

  void updateProgress() {
    final file = File("/tmp/progress");
    final progress = double.parse(file.readAsStringSync());
    file.delete();
    db!.execute("""
        INSERT INTO title_progress (type, id, season, episode, percent)
        VALUES (?1, ?2, ?3, ?4, ?5)
        ON CONFLICT (type, id, season, episode)
        DO UPDATE
        SET percent = ?5, ts = CURRENT_TIMESTAMP
      """, [
      title.type,
      title.id,
      widget.season ?? "-1",
      widget.episode ?? "-1",
      progress,
    ]);
  }

  Future<void> updateSeriesProgress() async {
    if (title.type != "tv") return;
    final seasons = await Seasons.seasons!;
    if (seasons == null) return;
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

  void pop() {
    if (router.location.startsWith("/play")) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    return InputListener(
      handleNavigation: true,
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

  @override
  void dispose() {
    client.close();
    couple?.kill();
    super.dispose();
  }
}
