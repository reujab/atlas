import "dart:io";

String? localIP;

Future<void> waitUntilOnline() async {
  await Process.run("nm-online", ["-s"]);

  while (localIP == null) {
    final interfaces = await NetworkInterface.list();
    localIP = interfaces.asMap()[0]?.addresses.asMap()[0]?.address;
  }
}
