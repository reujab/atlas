import "package:flutter/widgets.dart";
import "package:frontend/home.dart";
import "package:frontend/title_details.dart";
import "package:frontend/titles.dart";
import "package:go_router/go_router.dart";

const root = "/home";

final location = [root];

final router = GoRouter(
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
      pageBuilder: _getPageBuilder((_) => TitleDetails()),
    ),
  ],
  initialLocation: root,
);

CustomTransitionPage<dynamic> Function(BuildContext, GoRouterState)
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

// workaround because router.pop() wasn't working
push(String uri) {
  location.add(uri);
  router.go(uri);
}

pop() {
  if (location.length == 1) {
    throw ErrorDescription("root page cannot pop");
  }

  location.removeLast();
  router.go(location.last);
}
