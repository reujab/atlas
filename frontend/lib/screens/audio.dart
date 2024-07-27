import "dart:io";

import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/scrollable_list.dart";

class AudioDevice {
  AudioDevice({required this.id, required this.name});

  final String id;
  final String name;
}

class Audio extends StatefulWidget {
  const Audio({super.key});

  @override
  State<StatefulWidget> createState() => _AudioState();
}

class _AudioState extends State<Audio> {
  final List<AudioDevice> devices = [];

  String currentDevice = "auto";

  @override
  void initState() {
    super.initState();
    initDevices();
  }

  void initDevices() async {
    try {
      currentDevice = await File("/var/local/audio-device").readAsString();
    } on PathNotFoundException catch (_) {}

    final cmd = await Process.run("mpv", ["--audio-device=help"]);
    final stdout = cmd.stdout as String;
    final regex = RegExp(r"^\s+'(.*)' \((.*)\)$", multiLine: true);
    final matches = regex.allMatches(stdout);
    setState(() {
      devices.addAll(matches.map(
        (match) => AudioDevice(
          id: match[1]!,
          name: match[2]!.split(", ").last,
        ),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Column(
        children: [
          const Header("Audio device"),
          ScrollableList(
            items: devices,
            builder: (device, active) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      device.name,
                    ),
                  ),
                  device.id == currentDevice
                      ? const Icon(FontAwesomeIcons.check, size: 32)
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            onSelect: onSelect,
          ),
        ],
      ),
    );
  }

  void onSelect(index) {
    setState(() {
      currentDevice = devices[index].id;
    });
    File("/var/local/audio-device").writeAsString(currentDevice);
    playChime();
  }

  void playChime() {
    Process.run("mpv", [
      "--audio-device=$currentDevice",
      "--no-video",
      "/usr/share/sounds/chime.ogg",
    ]);
  }
}
