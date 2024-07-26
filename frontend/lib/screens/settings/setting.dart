import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";

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

class Setting extends StatelessWidget {
  const Setting({super.key, required this.data, required this.active});

  final SettingData data;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      curve: Curves.ease,
      duration: scaleDuration,
      height: itemHeight,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      transform:
          active ? (Matrix4.identity()..scale(1.1, 1.1)) : Matrix4.identity(),
      transformAlignment: FractionalOffset.center,
      decoration: const BoxDecoration(
        boxShadow: boxShadow,
        color: Colors.white,
        borderRadius: itemRadius,
      ),
      margin: itemMarginInset,
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
