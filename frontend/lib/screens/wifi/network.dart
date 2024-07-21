import "package:flutter/material.dart" as material;
import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/const.dart";
import "package:frontend/screens/wifi/network_data.dart";
import "package:frontend/widgets/cursor.dart";

class Network extends StatefulWidget {
  static const double margin = 29.0, height = 128.0;

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
  State<Network> createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  @override
  Widget build(BuildContext context) {
    var transform = Matrix4.identity();
    if (widget.active) {
      transform.scale(1.1, 1.1);
    }
    if (widget.hidden) {
      transform.translate(0, MediaQuery.of(context).size.height * 2);
    }
    if (widget.selected) {
      transform.scale(1.1, 1.1);
    }

    IconData strengthIcon;
    final strength = widget.network.strength;
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
      duration: scaleDuration,
      transform: transform,
      curve: Curves.ease,
      transformAlignment: FractionalOffset.center,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(Network.margin)),
        boxShadow: boxShadow,
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(
          horizontal: mainPadX, vertical: Network.margin),
      child: Column(
        children: [
          SizedBox(
            height: Network.height,
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
                          text: widget.network.name.isNotEmpty
                              ? widget.network.name
                              : widget.network.mac,
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
                widget.connecting
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
                  widget.network.secure
                      ? Positioned(
                          bottom: 10,
                          right: 4,
                          child: Icon(
                            widget.known
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
              child: widget.selected
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: 48,
                        right: 48,
                        bottom: 48,
                      ),
                      child: Row(
                        children: [
                          Text(
                            "*" * widget.passwordLength,
                            style: const TextStyle(
                                color: Colors.black, fontSize: 42),
                          ),
                          Cursor(
                            blinking: widget.selected && !widget.connecting,
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
