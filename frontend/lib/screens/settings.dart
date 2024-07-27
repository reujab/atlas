import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/router.dart";
import "package:frontend/ui.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/scrollable_list.dart";

class SettingData {
  const SettingData({
    required this.name,
    required this.icon,
    required this.path,
  });

  final String name;
  final IconData icon;
  final String path;
}

class Settings extends StatelessWidget {
  const Settings({super.key});

  static const settings = [
    SettingData(name: "Wi-Fi", icon: FontAwesomeIcons.wifi, path: "/wifi"),
    SettingData(
      name: "Audio device",
      icon: FontAwesomeIcons.volumeHigh,
      path: "/audio",
    ),
    SettingData(
      name: "Server",
      icon: FontAwesomeIcons.server,
      path: "/server",
    ),
    SettingData(
      name: "Attributions",
      icon: FontAwesomeIcons.info,
      path: "/attributions",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Background(
      child: Column(
        children: [
          const Header("Settings"),
          ScrollableList(
            items: settings,
            builder: (setting, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                children: [
                  Icon(setting.icon, size: 48),
                  const SizedBox(width: 50),
                  Text(
                    setting.name,
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            onSelect: (index) => router.push(settings[index].path),
          ),
        ],
      ),
    );
  }
}
