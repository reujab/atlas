import "package:flutter/widgets.dart";
import "package:frontend/screens/home/date.dart";
import "package:frontend/screens/home/weather.dart";

class HomeInfo extends StatelessWidget {
  const HomeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(right: 64),
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Color(0xB34B5563),
        ),
        child: const IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Date(),
              Weather(),
            ],
          ),
        ),
      ),
    );
  }
}
