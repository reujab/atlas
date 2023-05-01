import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
import "package:frontend/router.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/cursor.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/keyboard.dart";

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  String query = "";
  bool keyboardActive = false;
  InputEvent? inputEvent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        keyboardActive = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return InputListener(
      onKeyDown: onKeyDown,
      child: Stack(children: [
        Background(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Header("Search"),
              const SizedBox(height: 16),
              Container(
                decoration: const BoxDecoration(
                  boxShadow: boxShadow,
                  borderRadius: BorderRadius.all(Radius.circular(64)),
                  color: Colors.white,
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      query,
                      style: const TextStyle(color: Colors.black, fontSize: 72),
                    ),
                    const Cursor(),
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
            active: keyboardActive,
            onKey: onKey,
            onSubmit: onSubmit,
            inputEvent: inputEvent,
          ),
        ),
      ]),
    );
  }

  void onKeyDown(InputEvent e) {
    setState(() {
      inputEvent = e;
    });

    if (e.name == "Escape") router.pop();
  }

  void onKey(String char) {
    setState(() {
      if (char == "\b") {
        if (query.isNotEmpty) {
          query = query.substring(0, query.length - 1);
        }
        return;
      }

      query += char;
    });
  }

  void onSubmit() {
    // TODO
  }
}
