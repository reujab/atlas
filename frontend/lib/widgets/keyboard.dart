import "dart:async";
import "dart:math";

import "package:flutter/material.dart" show Icon, Icons;
import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/const.dart";
import "package:frontend/animation_mixin.dart";
import "package:frontend/widgets/input_listener.dart";

class Keyboard extends StatefulWidget {
  const Keyboard({
    super.key,
    required this.active,
    required this.onKey,
    required this.onSubmit,
    required this.inputEvent,
    this.onExit,
  });

  final bool active;
  final Function(String key) onKey;
  final Function() onSubmit;
  final InputEvent? inputEvent;
  final Function()? onExit;

  @override
  State<Keyboard> createState() => _KeyboardState();
}

class _KeyboardState extends State<Keyboard>
    with TickerProviderStateMixin, AnimationMixin {
  static const rows = 3;
  static const height = rows * (_Key.size + _Key.margin * 2);

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
  int page = 0;
  int x = 0;
  int y = 0;
  dynamic depressed;
  Timer? depressedTimer;

  void _animate() => animate(widget.active ? 0 : height + _Key.margin);

  @override
  void initState() {
    super.initState();
    controller.value = 0.7;
    _animate();
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
    return InputListener(
      onKeyDown: onKeyDown,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, animation.value - _Key.margin),
          child: child,
        ),
        child: Column(children: [
          for (int i = 0; i < keyboard[page].length; i++)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int j = 0; j < keyboard[page][i].length; j++)
                  _Key(
                    active: i == y && j == x,
                    depressed: depressed == keyboard[page][i][j],
                    child: getKeyWidget(keyboard[page][i][j]),
                  ),
              ],
            )
        ]),
      ),
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
        style: const TextStyle(
            fontSize: 64, color: Colors.black, fontWeight: FontWeight.normal),
      );
    }

    if (key == swap) {
      return Text(
        page == 0 ? "123" : "ABC",
        style: const TextStyle(
            fontSize: 48, color: Colors.black, fontWeight: FontWeight.normal),
      );
    }

    late final IconData icon;
    if (key == backspace) {
      icon = FontAwesomeIcons.chevronLeft;
    } else if (key == shift) {
      icon = FontAwesomeIcons.arrowUp;
    } else if (key == submit) {
      icon = FontAwesomeIcons.magnifyingGlass;
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
        widget.onKey(key.toLowerCase());
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
    // TODO
  }

  void submit() => Timer.run(widget.onSubmit);

  void swap() {
    setState(() {
      page = 1 - page;
    });
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.active,
    required this.depressed,
    required this.child,
  });

  static const size = 112.0;
  static const margin = 16.0;

  final bool active;
  final bool depressed;
  final Widget child;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key>
    with TickerProviderStateMixin, AnimationMixin {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      animate(widget.active ? 1.2 : 1);
    });
  }

  @override
  void didUpdateWidget(_Key oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active ||
        widget.depressed != oldWidget.depressed) {
      animate(
        widget.depressed
            ? 0.8
            : widget.active
                ? 1.2
                : 1,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: animation,
      filterQuality: FilterQuality.medium,
      child: Container(
        width: _Key.size,
        height: _Key.size,
        alignment: Alignment.center,
        margin: const EdgeInsets.all(_Key.margin),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          boxShadow: boxShadow,
          color: Colors.white,
        ),
        child: widget.child,
      ),
    );
  }
}
