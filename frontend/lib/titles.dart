import "const.dart";
import "dart:convert";
import "dart:io";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart" hide Title, Row;
import "package:http/http.dart" as http;
import "row.dart";
import "row_data.dart";

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

  RowData? get row {
    return rows?[index];
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
    final rows = this.rows;
    if (rows == null) return const Text("loading...");

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
          const Align(
            alignment: Alignment.topLeft,
            child: Text("Movies", style: TextStyle(fontSize: 96)),
          ),
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                for (var i = 0; i < rows.length; i++)
                  Row(
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
    final rows = this.rows, row = this.row;
    if (event is! KeyDownEvent || rows == null || row == null) return;

    switch (event.logicalKey.keyLabel) {
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
      duration: const Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}
