import "dart:io";

String? localIP;

Future<void> waitUntilOnline() async {
  if (localIP != null) return;
  while (true) {
    final interfaces = await NetworkInterface.list();
    localIP = interfaces.asMap()[0]?.addresses.asMap()[0]?.address;
    if (localIP != null) return;
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
