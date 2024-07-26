import "dart:io";

import "package:flutter/widgets.dart";
import "package:frontend/app.dart";
import "package:logging/logging.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

final log = Logger("atlas");

final isInitialized =
    Process.runSync("nmcli", ["-t", "-f=NAME", "connection", "show"])
        .stdout
        .toString()
        .trim()
        .split("\n")
        .where((name) => name != "lo")
        .isNotEmpty;

Database? db;

main() async {
  sqfliteFfiInit();
  db = await databaseFactoryFfi.openDatabase(
      Platform.environment["DATABASE_URL"]!.replaceFirst("sqlite://", ""));

  Paint.enableDithering = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    var out = record.level.value >= Level.WARNING.value ? stderr : stdout;
    out.writeln(
        "[${record.time}] [${record.level.name}] [${record.loggerName}] ${record.message}");
  });
  runApp(const App());
}
