import "package:flutter/widgets.dart";
import "package:frontend/main.dart";
import "package:frontend/screens/attributions.dart";
import "package:frontend/screens/audio.dart";
import "package:frontend/screens/home/home.dart";
import "package:frontend/screens/play.dart";
import "package:frontend/screens/search/search.dart";
import "package:frontend/screens/seasons/seasons.dart";
import "package:frontend/screens/server.dart";
import "package:frontend/screens/settings.dart";
import "package:frontend/screens/title_details/title_details.dart";
import "package:frontend/screens/titles/titles.dart";
import "package:frontend/screens/wifi/wifi.dart";
import "package:go_router/go_router.dart";

final router = GoRouter(
  initialLocation: isInitialized ? "/home" : "/wifi",
  routes: [
    GoRoute(
      path: "/wifi",
      pageBuilder: _getPageBuilder((_) => const Wifi()),
    ),
    GoRoute(
      path: "/home",
      pageBuilder: _getPageBuilder((_) => const Home()),
    ),
    GoRoute(
      path: "/:type/titles",
      pageBuilder:
          _getPageBuilder((state) => Titles(type: state.params["type"]!)),
    ),
    GoRoute(
      path: "/search",
      pageBuilder: _getPageBuilder((_) => const Search()),
    ),
    GoRoute(
      path: "/title",
      pageBuilder: _getPageBuilder((_) => const TitleDetails()),
    ),
    GoRoute(
      path: "/seasons",
      pageBuilder: _getPageBuilder((_) => const Seasons()),
    ),
    GoRoute(
      path: "/play",
      pageBuilder: _getPageBuilder(
        (state) => Play(
          uuid: state.queryParams["uuid"],
          trailer: state.queryParams["trailer"],
          season: state.queryParams["s"],
          episode: state.queryParams["e"],
          epName: state.queryParams["ep_name"],
        ),
      ),
    ),
    GoRoute(
      path: "/settings",
      pageBuilder: _getPageBuilder((_) => const Settings()),
    ),
    GoRoute(
      path: "/audio",
      pageBuilder: _getPageBuilder((_) => const Audio()),
    ),
    GoRoute(
      path: "/server",
      pageBuilder: _getPageBuilder((_) => const Server()),
    ),
    GoRoute(
      path: "/attributions",
      pageBuilder: _getPageBuilder((_) => const Attributions()),
    ),
  ],
);

CustomTransitionPage<Page> Function(BuildContext, GoRouterState)
    _getPageBuilder(Widget Function(GoRouterState) cb, {modal = false}) {
  return (context, state) {
    return CustomTransitionPage(
      fullscreenDialog: modal,
      opaque: !modal,
      key: state.pageKey,
      child: cb(state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return modal
            ? ScaleTransition(
                // opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
                scale:
                    CurveTween(curve: Curves.easeInOutCirc).animate(animation),
                child: child,
              )
            : FadeTransition(
                opacity:
                    CurveTween(curve: Curves.easeInOutCirc).animate(animation),
                child: child,
              );
      },
    );
  };
}
