import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
import "package:frontend/router.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.text,
        fontFamily: "Cantarell",
        fontSize: 36,
        fontWeight: FontWeight.w200,
      ),
      child: WidgetsApp.router(
        title: "Atlas",
        color: Colors.transparent,
        routerConfig: router,
      ),
    );
  }
}
