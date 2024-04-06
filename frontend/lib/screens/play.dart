import "dart:io";

import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
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
    this.trailer,
    this.season,
    this.episode,
    this.title,
  });

  final String? uuid;
  final String? trailer;
  final String? season;
  final String? episode;
  final String? title;

  @override
  State<Play> createState() => _PlayState();
}

class _PlayState extends State<Play> {
  final TitleData title = TitleDetails.title!;

  Map<String, dynamic>? stream;
  Process? overlay;

  @override
  void initState() {
    super.initState();

    if (widget.uuid != null) {
      initStream();
    } else if (widget.trailer != null) {
      // TODO: remove exclamation point after upgrading to Dart 3.2
      spawnOverlay(widget.trailer!);
    }
  }

  Future<void> initStream() async {
    try {
      stream = await getJson(
          "$host/init?uuid=${widget.uuid}${widget.season == null ? "" : "&s=${widget.season!}&e=${widget.episode}"}");
      if (!mounted) return;
    } catch (err) {
      pop();
      rethrow;
    }

    spawnOverlay("$host${stream!["video"]}");
  }

  Future<void> spawnOverlay(String url) async {
    final episode = widget.season == null
        ? ""
        : " S${widget.season.toString().padLeft(2, "0")}E${widget.episode.toString().padLeft(2, "0")} ${widget.title}";
    final List<String> opts = [
      "--title=${title.title}$episode",
      "--video=$url",
      ...(widget.uuid == null ? [] : ["--uuid=${widget.uuid}"]),
      ...(stream?["subs"] == null ? [] : ["--subs=$host${stream!["subs"]}"]),
    ];
    log.info("atlas-overlay ${opts.map((a) => "'$a'").join(" ")}");
    overlay = await Process.start(
      "atlas-overlay",
      opts,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await overlay!.exitCode;
    overlay = null;
    pop();
    if (exitCode != 0) throw "Overlay exit code: $exitCode";
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
    overlay?.kill();
    super.dispose();
  }
}
