import "package:flutter/widgets.dart";
import "package:frontend/const.dart";

class Setting extends StatelessWidget {
  const Setting({super.key, required this.data, required this.active});

  final SettingData data;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: scaleDuration,
      curve: Curves.ease,
      height: 128,
      transform:
          active ? (Matrix4.identity()..scale(1.1, 1.1)) : Matrix4.identity(),
      transformAlignment: FractionalOffset.center,
      decoration: const BoxDecoration(
        boxShadow: boxShadow,
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      margin: const EdgeInsets.symmetric(horizontal: mainPadX, vertical: 29),
      child: Row(children: [
        Icon(data.icon, size: 48),
        const SizedBox(width: 50),
        Text(
          data.name,
          style: const TextStyle(color: Colors.black),
        ),
      ]),
    );
  }
}

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
