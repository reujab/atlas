import "dart:async";
import "dart:convert";
import "dart:io";
import "package:flutter/widgets.dart" hide Title;
import "package:frontend/background.dart";
import "package:frontend/header.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/overview.dart";
import "package:frontend/router.dart" as router;
import "package:frontend/row_data.dart";
import "package:frontend/title.dart";
import "package:frontend/title_details.dart";
import "package:frontend/titles_row.dart";
import "package:http/http.dart" as http;

class Titles extends StatefulWidget {
  const Titles({super.key, required this.type});

  final String type;

  @override
  State<Titles> createState() => _TitlesState();
}

class _TitlesState extends State<Titles> {
  static Map<String, List<RowData>> rowsCache = {};

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
    if (rowsCache[widget.type] != null) {
      rows = rowsCache[widget.type];
      return;
    }

    var client = http.Client();
    try {
      var res = await client.get(Uri.parse(
          "${Platform.environment["SEEDBOX_HOST"]}/${widget.type}/rows?key=${Platform.environment["SEEDBOX_KEY"]}"));
      List<dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
      rowsCache[widget.type] = json.map((j) => RowData.fromJson(j)).toList();
      setState(() {
        rows = rowsCache[widget.type];
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
    if (rows == null || title == null) {
      return const Background(child: Text("loading..."));
    }

    return InputListener(
      onKeyDown: onKeyDown,
      child: Background(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Header(widget.type == "movie" ? "Movies" : "TV", search: true),
            Overview(title: title, maxLines: 3),
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
                    ),
                  SizedBox(height: MediaQuery.of(context).size.height)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void onKeyDown(String key) {
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
      case "Enter":
        router.push("/title");
        break;
      case "Escape":
        router.pop();
        break;
    }

    TitleDetails.title = title;
  }

  void scroll() {
    scrollController.animateTo(
      rowHeight * index.toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    inputTimer?.cancel();
    focusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
