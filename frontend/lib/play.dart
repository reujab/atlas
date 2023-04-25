import "dart:convert";
import "dart:io";

import "package:flutter/widgets.dart" hide Title;
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/background.dart";
import "package:frontend/const.dart";
import "package:frontend/header.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/router.dart" as router;
import "package:frontend/title.dart";
import "package:frontend/title_details.dart";
import "package:http/http.dart" as http;

class Play extends StatefulWidget {
  const Play({super.key, required this.magnet});

  final String magnet;

  @override
  createState() => _PlayState();
}

class _PlayState extends State<Play> {
  @override
  initState() {
    print("init state");
    super.initState();
    initStream();
  }

  Map<String, dynamic>? stream;

  Process? mpv;

  initStream() async {
    print(widget.magnet);
    var client = http.Client();
    print("init stream");
    try {
      var uri = Uri.parse(
          "$host/init?magnet=${Uri.encodeComponent(widget.magnet)}&key=$key");
      print("getting");
      var res = await client.get(uri);
      print("got ${res.statusCode}");
      if (res.statusCode != 200) {
        // TODO: handle err
        return;
      }
      stream = jsonDecode(utf8.decode(res.bodyBytes));
      print(stream);
    } catch (err) {
      print("err $err");
    } finally {
      client.close();
    }

    if (stream != null) spawnMPV();
  }

  spawnMPV() async {
    print("spawning mpv");
    final stream = this.stream!;
    final subs = stream["subs"] == null ? [] : ["--sub-file=${stream["subs"]}"];
    mpv = await Process.start("mpv", [
      "--audio-device=${Platform.environment["AUDIO_DEVICE"] ?? "alsa/plughw:CARD=PCH,DEV=3"}",
      "--input-ipc-server=/tmp/mpv",
      "--network-timeout=300",
      "--hwdec=vaapi",
      "--vo=gpu",
      ...subs,
      "$host${stream["video"]}?key=$key",
    ]);
    mpv!.stdout.transform(utf8.decoder).forEach(print);
    mpv!.stderr.transform(utf8.decoder).forEach(print);
    print("Mpv exited with ${await mpv!.exitCode}");
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
    if (stream != null) deleteStream("$host${stream!["delete"]!}?key=$key");
    mpv?.kill();
    super.dispose();
  }

  static deleteStream(String deleteUri) async {
    var client = http.Client();
    try {
      var uri = Uri.parse(deleteUri);
      var res = await client.delete(uri);
      print("got ${res.statusCode}");
      if (res.statusCode != 200) {
        print("deleting $deleteUri failed with ${res.statusCode}");
        return;
      }
    } catch (err) {
      print("err $err");
    } finally {
      client.close();
    }
  }
}
