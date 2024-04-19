import "dart:io";

import "package:flutter/widgets.dart";
import "package:frontend/app.dart";
import "package:logging/logging.dart";

main() async {
  Paint.enableDithering = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    var out = record.level.value >= Level.WARNING.value ? stderr : stdout;
    out.writeln(
        "[${record.time}] [${record.level.name}] [${record.loggerName}] ${record.message}");
  });
  runApp(const App());
}
