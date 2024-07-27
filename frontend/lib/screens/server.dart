import "dart:io";

import "package:flutter/material.dart" as material;
import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/http.dart";
import "package:frontend/main.dart" as main;
import "package:frontend/router.dart";
import "package:frontend/ui.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/cursor.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/keyboard.dart";

class Server extends StatefulWidget {
  const Server({super.key});

  static const path = "${main.localPath}/server";

  @override
  State<StatefulWidget> createState() => _ServerState();
}

class _ServerState extends State<Server> {
  InputEvent? inputEvent;
  String server = "http://";
  bool loading = false;

  bool get canNavigate => !loading && main.isInitialized;

  @override
  void initState() {
    super.initState();
    initServer();
  }

  void initServer() {
    try {
      server = File(Server.path).readAsStringSync();
    } on PathNotFoundException catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      handleNavigation: canNavigate,
      child: Stack(
        children: [
          Background(
            child: Column(
              children: [
                Header("Server", back: canNavigate),
                Container(
                  height: 156,
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
                  decoration: const BoxDecoration(
                    boxShadow: lightBoxShadow,
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        server,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 56,
                        ),
                      ),
                      const Cursor(),
                      const Expanded(child: SizedBox.expand()),
                      loading
                          ? const SpinKitRipple(color: Colors.black, size: 56)
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            right: 0,
            child: Keyboard(
              active: true,
              onKey: onKey,
              onSubmit: onSubmit,
              inputEvent: inputEvent,
              submitIcon: material.Icons.keyboard_return,
            ),
          ),
        ],
      ),
    );
  }

  void onKeyDown(InputEvent e) {
    setState(() {
      inputEvent = e;
    });
  }

  void onKey(String key) {
    if (loading) return;
    if (key == "\b") {
      if (server.isEmpty) return;
      setState(() {
        server = server.substring(0, server.length - 1);
      });
    } else {
      setState(() {
        server += key;
      });
    }
  }

  void onSubmit() async {
    if (loading) return;

    setState(() {
      loading = true;
    });

    final client = HttpClient();
    try {
      final res = await client.get("$server/version");
      if (res!.statusCode != 200) {
        throw "This is not an Atlas server.";
      }
    } finally {
      setState(() {
        loading = false;
      });
      client.close();
    }

    await File(Server.path).writeAsString(server);
    main.server = server;
    router.go("/home");
  }
}
