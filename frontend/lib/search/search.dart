import "dart:async";
import "dart:math";

import "package:flutter/widgets.dart";
import "package:frontend/const.dart";
import "package:frontend/http.dart";
import "package:frontend/router.dart";
import "package:frontend/search/result.dart";
import "package:frontend/title_data.dart";
import "package:frontend/title_details/title_details.dart";
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
  bool keyboardActive = true;
  InputEvent? inputEvent;
  Map<String, List<TitleData>> cache = {};
  List<TitleData> results = [];
  int index = 0;

  int get visibleResults =>
      query.isEmpty ? 0 : min(results.length, keyboardActive ? 2 : 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                  color: Colors.white,
                ),
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(Result.topMargin),
                child: Column(children: [
                  Row(
                    children: [
                      Text(
                        query,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 72),
                      ),
                      Cursor(blinking: keyboardActive),
                    ],
                  ),
                  AnimatedContainer(
                    duration: scaleDuration,
                    curve: Curves.ease,
                    height: visibleResults * (Result.height + Result.topMargin),
                    child: Wrap(children: [
                      for (int i = 0; i < results.length; i++)
                        Result(
                          results[i],
                          active: !keyboardActive && i == index,
                        ),
                    ]),
                  ),
                ]),
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
            onSubmit: hideKeyboard,
            inputEvent: inputEvent,
            onExit: hideKeyboard,
          ),
        ),
      ]),
    );
  }

  void onKeyDown(InputEvent e) {
    setState(() {
      inputEvent = e;
    });

    if (e.name == "Escape") {
      if (keyboardActive) {
        router.pop();
      } else {
        setState(() {
          keyboardActive = true;
        });
      }
      return;
    }

    if (keyboardActive) return;

    switch (e.name) {
      case "Arrow Up":
        if (index > 0) {
          setState(() {
            index--;
          });
        }
        break;
      case "Arrow Down":
        if (index < visibleResults - 1) {
          setState(() {
            index++;
          });
        } else {
          Timer(const Duration(milliseconds: 20), () {
            setState(() {
              keyboardActive = true;
            });
          });
        }
        break;
      case "Enter":
        TitleDetails.title = results[index];
        router.push("/title");
        break;
    }
  }

  void onKey(String char) {
    final wasEmpty = query.isEmpty;

    setState(() {
      if (char == "\b") {
        if (query.isNotEmpty) {
          query = query.substring(0, query.length - 1);
        }
        return;
      }

      query += char;

      if (wasEmpty) {
        results = [];
      }
    });
    search();
  }

  void search() async {
    if (query.isEmpty) return;
    if (cache[query] != null) {
      setState(() {
        results = cache[query]!;
      });
      return;
    }

    // don't show any titles that have already appeared in the last two searches
    final blacklist = [];
    for (int i = 1; i < query.length - 1; i++) {
      final q = query.substring(0, i);
      final res = cache[q];
      if (res != null) {
        blacklist.addAll(res.sublist(0, min(res.length, 2)).map((t) => t.id));
      }
    }

    final List<dynamic> json = await getJson(
        "$host/search?q=${Uri.encodeComponent(query)}&blacklist=${blacklist.join(",")}&key=$key");
    cache[query] = json.map((j) => TitleData.fromJson(j)).toList();
    setState(() {
      results = cache[query]!;
    });
  }

  void hideKeyboard() {
    if (query.isEmpty || results.isEmpty) return;

    setState(() {
      index = min(visibleResults - 1, 1);
      keyboardActive = false;
    });
  }
}
