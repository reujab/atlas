import "dart:convert";
import "dart:io";

import "package:flutter/widgets.dart" hide Title;
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/background.dart";
import "package:frontend/const.dart";
import "package:frontend/header.dart";
import "package:frontend/http.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/router.dart";
import "package:frontend/title.dart";
import "package:frontend/title_details.dart";
import "package:http/http.dart" as http;

class Play extends StatefulWidget {
  const Play({super.key, this.magnet, this.url});

  final String? magnet;
  final String? url;

  @override
  createState() => _PlayState();
}

class _PlayState extends State<Play> {
  @override
  initState() {
    super.initState();

    final url = widget.url;
    if (widget.magnet != null) {
      initStream();
    } else if (url != null) {
      spawnMPV(url);
    }
  }

  Map<String, dynamic>? stream;

  Process? mpv;

  initStream() async {
    try {
      stream = await getJson(
          "$host/init?magnet=${Uri.encodeComponent(widget.magnet!)}&key=$key");
      if (!mounted) _deleteStream();
    } catch (err) {
      log.severe(err);
      router.pop();
      return;
    }

    if (stream != null) spawnMPV("$host${stream!["video"]}?key=$key");
  }

  spawnMPV(url) async {
    final subs =
        stream?["subs"] == null ? [] : ["--sub-file=${stream!["subs"]}"];
    mpv = await Process.start("mpv", [
      "--audio-device=${Platform.environment["AUDIO_DEVICE"] ?? "alsa/plughw:CARD=PCH,DEV=3"}",
      "--input-ipc-server=/tmp/mpv",
      "--network-timeout=300",
      "--hwdec=vaapi",
      "--vo=gpu",
      ...subs,
      url,
    ]);
    mpv!.stdout.transform(utf8.decoder).forEach(log.fine);
    mpv!.stderr.transform(utf8.decoder).forEach(log.warning);
    log.info("mpv exited with ${await mpv!.exitCode}");
    mpv = null;
    router.pop();
  }

  final Title title = TitleDetails.title!;

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      child: Background(
        child: Column(
          children: [
            Header(title.title),
            const Spacer(),
            const SpinKitRipple(color: Colors.text, size: 256),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  onKeyDown(String key) {
    if (key == "Escape") router.pop();
  }

  @override
  dispose() {
    _deleteStream();
    mpv?.kill();
    super.dispose();
  }

  _deleteStream() {
    if (stream != null) deleteStream("$host${stream!["delete"]!}?key=$key");
  }

  static deleteStream(String deleteUri) async {
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
