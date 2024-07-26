import "package:flutter/widgets.dart";

class Colors {
  static const transparent = Color(0x00000000);
  static const black = Color(0xFF000000);
  static const gray = Color(0xFF888888);
  static const white = Color(0xFFEEEEEE);
  static const red = Color(0xFFB91C1C);
}

const scrollDuration = Duration(milliseconds: 300);
const scaleDuration = Duration(milliseconds: 500);

const mainPadX = 192.0;

const fullyRounded = BorderRadius.all(Radius.circular(1024));

const itemHeight = 128.0, itemMargin = 29.0;
const itemRadius = BorderRadius.all(Radius.circular(itemMargin));
const itemMarginInset =
    EdgeInsets.symmetric(horizontal: mainPadX, vertical: 29);

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
