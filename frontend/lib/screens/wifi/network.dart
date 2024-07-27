import "package:flutter/material.dart" as material;
import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/ui.dart";
import "package:frontend/widgets/cursor.dart";

class NetworkData {
  NetworkData({
    required this.mac,
    required this.name,
    required this.secure,
    required this.strength,
  });

  String mac;
  String name;
  bool secure;
  int strength;
}

class Network extends StatelessWidget {
  const Network(
    this.network, {
    super.key,
    required this.active,
    required this.selected,
    required this.hidden,
    required this.passwordLength,
    required this.connecting,
    required this.known,
  });

  final NetworkData network;
  final bool active;
  final bool selected;
  final bool hidden;
  final int passwordLength;
  final bool connecting;
  final bool known;

  @override
  Widget build(BuildContext context) {
    var transform = Matrix4.identity();
    if (active) {
      transform.scale(1.1, 1.1);
    }
    if (hidden) {
      transform.translate(0.0, MediaQuery.of(context).size.height * 2);
    }
    if (selected) {
      transform.scale(1.1, 1.1);
    }

    IconData strengthIcon;
    final strength = network.strength;
    if (strength >= 75) {
      strengthIcon = material.Icons.network_wifi_3_bar;
    } else if (strength >= 67) {
      strengthIcon = material.Icons.network_wifi_2_bar;
    } else if (strength >= 33) {
      strengthIcon = material.Icons.network_wifi_1_bar;
    } else {
      strengthIcon = material.Icons.signal_wifi_0_bar;
    }

    return AnimatedContainer(
      clipBehavior: Clip.antiAlias,
      curve: Curves.ease,
      duration: scaleDuration,
      margin: itemMarginInset,
      transform: transform,
      transformAlignment: FractionalOffset.center,
      decoration: const BoxDecoration(
        borderRadius: itemRadius,
        boxShadow: boxShadow,
        color: Colors.white,
      ),
      child: Column(
        children: [
          SizedBox(
            height: itemHeight,
            child: Row(
              children: [
                const SizedBox(width: 48),
                /**
                 * SSID
                 */
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.fade,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: network.name.isNotEmpty
                              ? network.name
                              : network.mac,
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                      style: DefaultTextStyle.of(context).style,
                    ),
                    // softWrap: true,
                  ),
                ),
                /**
                 * Icons
                 */
                connecting
                    ? const Padding(
                        padding: EdgeInsets.only(right: 24),
                        child: SpinKitRipple(color: Colors.black, size: 56),
                      )
                    : const SizedBox.shrink(),
                Stack(children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(strengthIcon, size: 56),
                  ),
                  network.secure
                      ? Positioned(
                          bottom: 10,
                          right: 4,
                          child: Icon(
                            known
                                ? material.Icons.vpn_key
                                : material.Icons.lock,
                            size: 20,
                          ))
                      : const SizedBox.shrink(),
                ]),
                const SizedBox(width: 48),
              ],
            ),
          ),
          /**
           * Password entry
           */
          AnimatedSize(
            duration: scaleDuration,
            curve: Curves.ease,
            child: Container(
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: 48,
                        right: 48,
                        bottom: 48,
                      ),
                      child: Row(
                        children: [
                          Text(
                            "*" * passwordLength,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 42),
                          ),
                          Cursor(
                            blinking: selected && !connecting,
                            size: 42,
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
