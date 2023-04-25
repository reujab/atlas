import "dart:io";

import "package:flutter/widgets.dart";

const boxShadow = [
  BoxShadow(blurRadius: 3, color: Color(0x77555555), spreadRadius: 3),
];

const lightBoxShadow = [
  BoxShadow(blurRadius: 3, color: Color(0x55AAAAAA), spreadRadius: 3),
];

const duration = Duration(milliseconds: 300);

const mainPadX = 192.0;

class Colors {
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const text = Color(0xFFEEEEEE);
}

final host = Platform.environment["SEEDBOX_HOST"]!;
final key = Platform.environment["SEEDBOX_KEY"]!;
