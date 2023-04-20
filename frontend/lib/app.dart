import "package:flutter/widgets.dart";
import "router.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color: Color(0xFFEEEEEE),
        fontFamily: "Cantarell",
        fontSize: 48,
        fontWeight: FontWeight.w200,
      ),
      child: WidgetsApp.router(
        title: "Atlas",
        color: const Color(0x00000000),
        routerConfig: router,
      ),
    );
  }
}
