import "dart:async";
import "dart:io";

import "package:flutter/material.dart" as material;
import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import 'package:frontend/ui.dart';
import "package:frontend/main.dart";
import "package:frontend/router.dart";
import "package:frontend/screens/wifi/network.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/keyboard.dart";

class Wifi extends StatefulWidget {
  const Wifi({
    super.key,
  });

  @override
  State<Wifi> createState() => _WifiState();
}

class _WifiState extends State<Wifi> {
  final scrollController = ScrollController();
  final knownNetworks =
      Process.runSync("nmcli", ["-t", "-f=NAME", "connection", "show"])
          .stdout
          .toString()
          .trim()
          .split("\n");

  List<NetworkData> networks = [];
  int networkIndex = 0;
  bool selected = false;
  Timer? timer;
  InputEvent? inputEvent;
  String password = "";
  bool connecting = false;

  @override
  void initState() {
    super.initState();
    updateNetworks();
  }

  void updateNetworks() async {
    final nmcli = await Process.run("nmcli", ["-t", "dev", "wifi"]);
    // In case the user selects a network or navigates right after invoking nmcli.
    if (selected || !mounted) return;
    timer = Timer(const Duration(seconds: 10), updateNetworks);

    if (nmcli.exitCode != 0) {
      throw "NetworkManager exit code: ${nmcli.exitCode}";
    }

    final output = nmcli.stdout.toString().trimRight();
    if (output.isEmpty) {
      return;
    }

    final selectedMAC = networks.isEmpty ? null : networks[networkIndex].mac;
    setState(() {
      networks = output.split("\n").map((line) {
        final parts = line.split(":");
        return NetworkData(
            mac: parts.sublist(1, 7).join(":").replaceAll(r"\", ""),
            name: parts[7],
            secure: parts[13] != "",
            strength: int.parse(parts[11]));
      }).toList();
      if (networkIndex == 0) return;
      networkIndex = 0;
      for (int i = 0; i < networks.length; i++) {
        if (networks[i].mac == selectedMAC) {
          networkIndex = i;
          break;
        }
      }
      scroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      child: Stack(
        children: [
          Background(
            child: Column(
              children: [
                Header(
                  "Wifi",
                  back: !connecting && (isInitialized || selected),
                ),
                Expanded(
                  child: networks.isEmpty
                      ? const SpinKitRipple(color: Colors.white, size: 256)
                      : ListView(
                          controller: scrollController,
                          children: [
                            for (int i = 0; i < networks.length; i++)
                              Network(
                                networks[i],
                                active: i == networkIndex,
                                selected: i == networkIndex && selected,
                                hidden: selected && i > networkIndex,
                                passwordLength: password.length,
                                connecting: i == networkIndex && connecting,
                                known: knownNetworks.contains(networks[i].name),
                              ),
                            SizedBox(
                                height: MediaQuery.of(context).size.height),
                          ],
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Keyboard(
              active: selected && !connecting,
              onKey: onKey,
              onSubmit: connect,
              inputEvent: inputEvent,
              submitIcon: material.Icons.keyboard_return,
            ),
          ),
        ],
      ),
    );
  }

  onKeyDown(InputEvent e) {
    if (connecting) return;

    if (e.name == "Escape") {
      if (selected) {
        setState(() {
          selected = false;
        });
        updateNetworks();
      } else if (isInitialized) {
        router.pop();
      }
      return;
    }

    if (selected) {
      setState(() {
        inputEvent = e;
      });
      return;
    }

    switch (e.name) {
      case "Arrow Up":
        if (networkIndex > 0) {
          setState(() {
            networkIndex--;
          });
          scroll();
        }
        break;
      case "Arrow Down":
        if (networkIndex < networks.length - 1) {
          setState(() {
            networkIndex++;
          });
          scroll();
        }
        break;
      case "Enter":
        timer?.cancel();

        if (knownNetworks.contains(networks[networkIndex].name)) {
          connect();
          break;
        }

        setState(() {
          password = "";
          selected = true;
        });
        break;
      case "Context Menu":
        forget(networks[networkIndex].name);
        break;
    }
  }

  void scroll() {
    scrollController.animateTo(networkIndex * (itemHeight + itemMargin * 2),
        duration: scrollDuration, curve: Curves.ease);
  }

  void onKey(String key) {
    setState(() {
      if (key == "\b") {
        if (password.isNotEmpty) {
          password = password.substring(0, password.length - 1);
        }
      } else {
        password += key;
      }
    });
  }

  void connect() async {
    if (selected && password.length < 8) return;

    setState(() {
      connecting = true;
    });

    final args = ["dev", "wifi", "connect"];
    final network = networks[networkIndex];
    if (network.name.isNotEmpty) {
      args.add(network.name);
    } else {
      args.add(network.mac);
    }
    if (selected) {
      args.addAll(["password", password]);
    }
    final nmcli = await Process.run("nmcli", args);
    setState(() {
      connecting = false;
    });
    if (nmcli.exitCode != 0) await forget(network.name);

    if (nmcli.exitCode == 3) {
      throw "Timed out";
    }
    if (nmcli.exitCode == 4) {
      throw "Failed to connect to network";
    }
    if (nmcli.exitCode != 0) {
      throw "NetworkManager exit code: ${nmcli.exitCode}";
    }
    router.go("/home");
  }

  Future<ProcessResult> forget(String ssid) async {
    setState(() {
      knownNetworks.remove(ssid);
    });
    return Process.run("nmcli", ["connection", "delete", ssid]);
  }

  @override
  void dispose() {
    timer?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
