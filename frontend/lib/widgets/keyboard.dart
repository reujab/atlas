import "dart:async";
import "dart:math";

import "package:flutter/material.dart" show Icon, Icons;
import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/ui.dart";
import "package:frontend/animation_mixin.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/keyboard_key.dart";

class Keyboard extends StatefulWidget {
  const Keyboard({
    super.key,
    required this.active,
    required this.onKey,
    required this.onSubmit,
    required this.inputEvent,
    this.onExit,
    this.submitIcon = FontAwesomeIcons.magnifyingGlass,
  });

  final bool active;
  final Function(String key) onKey;
  final Function() onSubmit;
  final InputEvent? inputEvent;
  final Function()? onExit;
  final IconData submitIcon;

  @override
  State<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<Keyboard>
    with TickerProviderStateMixin, AnimationMixin {
  static const rows = 3;
  static const height = rows * (KeyboardKey.size + KeyboardKey.margin * 2);

  int page = 0;
  int x = 0;
  int y = 0;
  dynamic depressed;
  Timer? depressedTimer;
  bool caps = false;

  late final keyboard = [
    [
      ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", backspace],
      [shift, "A", "S", "D", "F", "G", "H", "J", "K", "L", submit],
      [swap, "Z", "X", "C", "V", "B", "N", "M", " "],
    ],
    [
      ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", backspace],
      ["_", "-", "/", ":", ";", "+", "=", "\$", "&", "@", "*"],
      [swap, "|", ".", ",", "?", "!", "^", "%", "#"],
    ],
  ];

  void _animate() => animate(widget.active ? 0 : height + KeyboardKey.margin);

  @override
  void initState() {
    super.initState();
    animate(widget.active ? 128 : height + KeyboardKey.margin,
        duration: Duration.zero);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animate();
    });
  }

  @override
  void didUpdateWidget(Keyboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) _animate();
    if (widget.inputEvent != oldWidget.inputEvent &&
        widget.inputEvent != null) {
      onKeyDown(widget.inputEvent!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, animation.value - KeyboardKey.margin),
        child: child,
      ),
      child: Column(children: [
        for (int i = 0; i < keyboard[page].length; i++)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int j = 0; j < keyboard[page][i].length; j++)
                KeyboardKey(
                  active: i == y && j == x,
                  depressed: depressed == keyboard[page][i][j],
                  border: caps && keyboard[page][i][j] == shift,
                  child: getKeyWidget(keyboard[page][i][j]),
                ),
            ],
          )
      ]),
    );
  }

  Widget getKeyWidget(dynamic key) {
    if (key is String) {
      if (key == " ") {
        return const Padding(
          padding: EdgeInsets.only(top: 38),
          child: Icon(Icons.space_bar, size: 56),
        );
      }
      return Text(
        key,
        style: const TextStyle(fontSize: 64, color: Colors.black),
      );
    }

    if (key == swap) {
      return Text(
        page == 0 ? "123" : "ABC",
        style: const TextStyle(fontSize: 48, color: Colors.black),
      );
    }

    late final IconData icon;
    if (key == backspace) {
      icon = FontAwesomeIcons.chevronLeft;
    } else if (key == shift) {
      icon = FontAwesomeIcons.arrowUp;
    } else if (key == submit) {
      icon = widget.submitIcon;
    } else {
      throw UnimplementedError();
    }

    return FaIcon(icon, size: 48);
  }

  void onKeyDown(InputEvent e) {
    if (!widget.active) return;

    switch (e.name) {
      case "Arrow Up":
        if (y == 0 && widget.onExit != null) {
          Timer.run(widget.onExit!);
          return;
        }
        setY(y > 0 ? y - 1 : rows - 1);
        break;
      case "Arrow Down":
        setY(y < rows - 1 ? y + 1 : 0);
        break;
      case "Arrow Left":
        setX(x > 0 ? x - 1 : keyboard[page][y].length - 1);
        break;
      case "Arrow Right":
        setX(x < keyboard[page][y].length - 1 ? x + 1 : 0);
        break;
      case "Caps Lock":
        shift();
        break;
      case "Backspace":
        setDepressed(backspace);
        break;
      case "Enter":
        final key = keyboard[page][y][x];
        setDepressed(key);
        break;
      default:
        if (e.name.length == 1) setDepressed(e.name);
    }
  }

  void setDepressed(dynamic key) {
    if (key is String) {
      Timer.run(() {
        widget.onKey(caps ? key : key.toLowerCase());
      });
    } else if (key is Function()) {
      key();
    }

    setState(() {
      depressed = key;
    });

    depressedTimer?.cancel();
    depressedTimer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        depressed = null;
      });
    });
  }

  void setX(int x) {
    setState(() {
      this.x = x;
    });
  }

  void setY(int y) {
    final oldY = this.y;
    setState(() {
      this.y = y;
      if (y == 2) {
        x--;
      } else if (oldY == 2) {
        x++;
      }
      x = min(keyboard[page][y].length - 1, max(0, x));
    });
  }

  void backspace() {
    Timer.run(() {
      widget.onKey("\b");
    });
  }

  void shift() {
    setState(() {
      caps = !caps;
    });
  }

  void submit() => Timer.run(widget.onSubmit);

  void swap() {
    setState(() {
      page = 1 - page;
    });
  }
}
