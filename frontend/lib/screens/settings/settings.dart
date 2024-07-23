import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/router.dart";
import "package:frontend/screens/settings/setting.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  static const settings = [
    SettingData(name: "Wi-Fi", icon: FontAwesomeIcons.wifi, path: "/wifi"),
    SettingData(
      name: "Attributions",
      icon: FontAwesomeIcons.info,
      path: "/attributions",
    ),
  ];

  final scrollController = ScrollController();

  int index = 0;

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      child: Background(
        child: Column(
          children: [
            const Header("Settings"),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  for (int i = 0; i < settings.length; i++)
                    Setting(data: settings[i], active: i == index)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    switch (e.name) {
      case "Browser Home":
        router.go("/home");
        break;
      case "Escape":
        router.pop();
        break;
      case "Arrow Up":
        if (index > 0) {
          setState(() {
            index--;
          });
        }
        break;
      case "Arrow Down":
        if (index < settings.length - 1) {
          setState(() {
            index++;
          });
        }
        break;
      case "Enter":
        router.push(settings[index].path);
        break;
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
