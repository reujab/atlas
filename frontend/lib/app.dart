import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";
import "package:frontend/router.dart";
import "package:frontend/widgets/error_banner.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color: Colors.white,
        fontFamily: "Cantarell",
        fontSize: 36,
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              WidgetsApp.router(
                title: "Atlas",
                color: Colors.transparent,
                routerConfig: router,
              ),
              const ErrorBanner(),
            ],
          ),
        ),
      ),
    );
  }
}
