import "dart:io";

import "package:flutter/widgets.dart";
import "package:frontend/app.dart";
import "package:logging/logging.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";

const localPath = String.fromEnvironment("LOCAL_PATH");

final log = Logger("atlas");

Database? db;
String? server;

bool get isInitialized => server != null;

main() async {
  print("localPath $localPath");
  sqfliteFfiInit();
  db = await databaseFactoryFfi.openDatabase("$localPath/atlas.db");

  try {
    server = File("$localPath/server").readAsStringSync();
  } on PathNotFoundException catch (_) {}

  Paint.enableDithering = true;
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    var out = record.level.value >= Level.WARNING.value ? stderr : stdout;
    out.writeln(
        "[${record.time}] [${record.level.name}] [${record.loggerName}] ${record.message}");
  });
  runApp(const App());
}
