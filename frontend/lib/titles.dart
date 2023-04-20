import "const.dart";
import "dart:async";
import "dart:convert";
import "dart:io";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart" hide Title;
import "package:http/http.dart" as http;
import "row_data.dart";
import "title.dart";
import "titles_row.dart";

class Titles extends StatefulWidget {
  const Titles({super.key});

  @override
  State<Titles> createState() => _TitlesState();
}

class _TitlesState extends State<Titles> {
  final focusNode = FocusNode();

  final scrollController = ScrollController();

  List<RowData>? rows;

  int index = 0;

  double rowHeight = 0;

  Timer? inputTimer;

  RowData? get row {
    return rows?[index];
  }

  Title? get title {
    return row?.titles[row!.index];
  }

  @override
  void initState() {
    super.initState();
    initRows();
  }

  Future<void> initRows() async {
    var client = http.Client();
    try {
      var res = await client.get(Uri.parse(
          "${Platform.environment["SEEDBOX_HOST"]}/movie/rows?key=${Platform.environment["SEEDBOX_KEY"]}"));
      List<dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
      setState(() {
        rows = json.map((j) => RowData.fromJson(j)).toList();
      });
    } catch (err) {
      print("err $err");
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = this.rows, title = this.title;
    if (rows == null || title == null) return const Text("loading...");

    return KeyboardListener(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: onKeyEvent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.2, -1),
            end: Alignment(.2, 1),
            colors: [Color(0xFF444444), Color(0xFF1A1A1A)],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: mainPadX),
        child: Column(children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Movies",
                style: TextStyle(fontSize: 96),
              ),
              Text(
                title.genres.join(" • "),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 10),
              Text(
                // minLines: 3
                "${title.overview}\n\n",
                style:
                    const TextStyle(fontSize: 30, fontWeight: FontWeight.w400),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
            ],
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                for (var i = 0; i < rows.length; i++)
                  TitlesRow(
                    index: rows[i].index,
                    name: rows[i].name,
                    titles: rows[i].titles,
                    active: i == index,
                    onRowHeight: (double height) {
                      rowHeight = height;
                    },
                  )
              ],
            ),
          ),
        ]),
      ),
    );
  }

  onKeyEvent(KeyEvent event) {
    if (event is! KeyRepeatEvent) {
      inputTimer?.cancel();
      inputTimer = null;
    }

    if (event is! KeyDownEvent) return;

    inputTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      handleKey(event.logicalKey.keyLabel);
    });

    handleKey(event.logicalKey.keyLabel);
  }

  void handleKey(String key) {
    final rows = this.rows, row = this.row;
    if (rows == null || row == null) return;
    switch (key) {
      case "Arrow Up":
        setState(() {
          if (index > 0) {
            index--;
          } else {
            index = rows.length - 1;
          }
        });
        scroll();
        break;
      case "Arrow Down":
        setState(() {
          if (index < rows.length - 1) {
            index++;
          } else {
            index = 0;
          }
        });
        scroll();
        break;
      case "Arrow Left":
        setState(() {
          if (row.index > 0) {
            row.index--;
          } else {
            row.index = row.titles.length - 1;
          }
        });
        break;
      case "Arrow Right":
        setState(() {
          if (row.index < row.titles.length - 1) {
            row.index++;
          } else {
            row.index = 0;
          }
        });
        break;
    }
  }

  void scroll() {
    scrollController.animateTo(
      rowHeight * index.toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }
}
