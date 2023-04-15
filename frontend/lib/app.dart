import "package:flutter/widgets.dart";
import "titles.dart";

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
      child: WidgetsApp(
        title: "Atlas",
        color: const Color(0xFF000000),
        home: const Titles(),
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) =>
            PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (BuildContext context, Animation<double> _,
                  Animation<double> __) =>
              builder(context),
        ),
      ),
    );
  }
}
