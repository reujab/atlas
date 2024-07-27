import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/router.dart";
import "package:frontend/ui.dart";
import "package:frontend/widgets/list_screen.dart";

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

class Settings extends ListScreen<SettingData> {
  const Settings({super.key});

  @override
  get title => "Settings";

  @override
  get items => const [
        SettingData(name: "Wi-Fi", icon: FontAwesomeIcons.wifi, path: "/wifi"),
        SettingData(
          name: "Audio device",
          icon: FontAwesomeIcons.volumeHigh,
          path: "/audio",
        ),
        SettingData(
          name: "Attributions",
          icon: FontAwesomeIcons.info,
          path: "/attributions",
        ),
      ];

  @override
  Widget builder(item, bool active) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Row(
          children: [
            Icon(item.icon, size: 48),
            const SizedBox(width: 50),
            Text(
              item.name,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      );

  @override
  onSelect(int index) {
    router.push(items[index].path);
  }
}
