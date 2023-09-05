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

    if (widget.magnet != null) {
      initStream();
    } else if (widget.url != null) {
      spawnOverlay(widget.url);
    }
  }

  Future<void> initStream() async {
    try {
      stream = await getJson(
          "$host/init?magnet=${Uri.encodeComponent(widget.magnet!)}${widget.season == null ? "" : "&s=${widget.season!}&e=${widget.episode}"}");
      if (!mounted) {
        _deleteStream();
        return;
      }
    } catch (err) {
      pop();
      rethrow;
    }

    spawnOverlay("$host${stream!["video"]}");
  }

  Future<void> spawnOverlay(url) async {
    final List<String> opts = [
      "--title=${title.title}",
      "--video=$url",
      ...(stream?["subs"] == null ? [] : ["--subs=${stream!["subs"]}"]),
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
    _deleteStream();
    overlay?.kill();
    super.dispose();
  }

  void _deleteStream() {
    if (stream != null) deleteStream("$host${stream!["delete"]!}");
  }

  static void deleteStream(String deleteUri) async {
    var uri = Uri.parse(deleteUri);
    var res = await http.delete(uri);
    if (res.statusCode != 200) {
      throw "Failed to delete stream: ${res.statusCode}";
    }
  }
}
