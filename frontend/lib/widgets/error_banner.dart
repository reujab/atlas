import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/widgets.dart";
import "package:frontend/ui.dart";
import "package:frontend/main.dart";

class ErrorBanner extends StatefulWidget {
  const ErrorBanner({super.key});

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner> {
  bool active = false;

  Timer? activeTimer;

  String title = "";
  String description = "";

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (details) {
      log.shout(details);
      show(details.exceptionAsString());
    };
    PlatformDispatcher.instance.onError = (exception, stackTrace) {
      log.shout(exception);
      log.shout(stackTrace);
      show(exception.toString());
      return true;
    };
  }

  void show(String error) {
    // Set state next frame in case the error occured while building ErrorBanner.
    Timer.run(() {
      setState(() {
        final index = error.indexOf(":");
        if (index == -1) {
          title = "";
          description = error;
        } else {
          title = error.substring(0, index);
          description = error.substring(index + 1).trim();
        }
        active = true;
      });
      activeTimer?.cancel();
      activeTimer = Timer(const Duration(seconds: 10), () {
        setState(() {
          active = false;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: scaleDuration,
      curve: Curves.ease,
      top: active ? 16 : -192,
      left: 128,
      right: 128,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xE6F87171),
            borderRadius: fullyRounded,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.isEmpty ? "Error" : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 24),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
