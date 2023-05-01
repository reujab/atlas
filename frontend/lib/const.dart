import "dart:io";

import "package:flutter/widgets.dart";
import "package:logging/logging.dart";

const scrollDuration = Duration(milliseconds: 300);
const scaleDuration = Duration(milliseconds: 500);

const mainPadX = 192.0;

const scale = 1.1;

const shadowRadius = 3.0;
const boxShadow = [
  BoxShadow(
    blurRadius: shadowRadius,
    color: Color(0x77555555),
    spreadRadius: shadowRadius,
  ),
];
const lightBoxShadow = [
  BoxShadow(
    blurRadius: shadowRadius,
    color: Color(0x55AAAAAA),
    spreadRadius: shadowRadius,
  ),
];

class Colors {
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const gray = Color(0xFF888888);
  static const white = Color(0xFFEEEEEE);
}

final host = Platform.environment["SEEDBOX_HOST"]!;
final key = Platform.environment["SEEDBOX_KEY"]!;

final log = Logger("atlas");
