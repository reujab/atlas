import "package:flutter/widgets.dart";
import "package:frontend/home/home.dart";
import "package:frontend/play.dart";
import "package:frontend/seasons/seasons.dart";
import "package:frontend/title_details/title_details.dart";
import "package:frontend/titles/titles.dart";
import "package:go_router/go_router.dart";

final router = GoRouter(
  initialLocation: "/home",
  routes: [
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
          magnet: state.queryParams["magnet"],
          url: state.queryParams["url"],
          season: state.queryParams["s"],
          episode: state.queryParams["e"],
        ),
      ),
    ),
  ],
);

CustomTransitionPage<Page> Function(BuildContext, GoRouterState)
    _getPageBuilder(Widget Function(GoRouterState) cb) {
  return (context, state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: cb(state),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
          child: child,
        );
      },
    );
  };
}
