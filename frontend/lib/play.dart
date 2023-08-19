import "dart:convert";
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
import "package:frontend/title_details/title_details.dart";
import "package:http/http.dart" as http;

class Play extends StatefulWidget {
  const Play({super.key, this.magnet, this.url, this.season, this.episode});

  final String? magnet;
  final String? url;
  final String? season;
  final String? episode;

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

    final url = widget.url;
    if (widget.magnet != null) {
      initStream();
    } else if (url != null) {
      spawnOverlay(url);
    }
  }

  Future<void> initStream() async {
    try {
      stream = await getJson(
          "$host/init?magnet=${Uri.encodeComponent(widget.magnet!)}${widget.season == null ? "" : "&s=${widget.season!}&e=${widget.episode}"}&key=$key");
      if (!mounted) _deleteStream();
    } catch (err) {
      log.severe(err);
      router.pop();
      return;
    }

    if (stream != null) spawnOverlay("$host${stream!["video"]}?key=$key");
  }

  Future<void> spawnOverlay(url) async {
    final subs = stream?["subs"] == null ? [] : ["--subs=${stream!["subs"]}"];
    overlay = await Process.start("atlas-overlay", [
      "--title=${title.title}",
      "--video=$url",
      ...subs,
    ]);
    overlay!.stdout.transform(utf8.decoder).forEach(log.fine);
    overlay!.stderr.transform(utf8.decoder).forEach(log.warning);
    log.info("overlay exited with ${await overlay!.exitCode}");
    overlay = null;
    if (router.location.startsWith("/play")) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      child: Background(
        child: Column(
          children: [
            Header(title.title),
            const Spacer(),
            const SpinKitRipple(color: Colors.white, size: 256),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    if (e.name == "Browser Home") router.go("/home");
    if (e.name == "Escape") router.pop();
  }

  @override
  void dispose() {
    _deleteStream();
    overlay?.kill();
    super.dispose();
  }

  void _deleteStream() {
    if (stream != null) deleteStream("$host${stream!["delete"]!}?key=$key");
  }

  static void deleteStream(String deleteUri) async {
    try {
      var uri = Uri.parse(deleteUri);
      var res = await http.delete(uri);
      if (res.statusCode != 200) {
        log.severe("deleting $deleteUri failed with ${res.statusCode}");
      }
    } catch (err) {
      log.severe(err);
    }
  }
}
