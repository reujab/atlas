import "dart:async";
import "dart:convert";
import "dart:io";
import "package:flutter/widgets.dart" hide Title;
import "package:flutter_spinkit/flutter_spinkit.dart";
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

  static Map<String, List<RowData>> rowsCache = {};

  static initRows(String type) async {
    var client = http.Client();
    try {
      var res = await client.get(Uri.parse(
          "${Platform.environment["SEEDBOX_HOST"]}/$type/rows?key=${Platform.environment["SEEDBOX_KEY"]}"));
      List<dynamic> json = jsonDecode(utf8.decode(res.bodyBytes));
      rowsCache[type] = json.map((j) => RowData.fromJson(j)).toList();
    } catch (err) {
      print("err $err");
    } finally {
      client.close();
    }
  }

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
  initState() {
    super.initState();

    if (Titles.rowsCache[widget.type] == null) {
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        _setFromCache();
        if (rows != null) timer.cancel();
      });
    } else {
      _setFromCache();
    }
  }

  _setFromCache() {
    setState(() {
      rows = Titles.rowsCache[widget.type];
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = this.rows, title = this.title;

    return InputListener(
      onKeyDown: onKeyDown,
      child: Background(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Header(widget.type == "movie" ? "Movies" : "TV", search: true),
            ...(rows == null || title == null
                ? [
                    const Expanded(
                      child: SpinKitRipple(color: Color(0xFFEEEEEE), size: 256),
                    ),
                  ]
                : [
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
                  ]),
          ],
        ),
      ),
    );
  }

  onKeyDown(String key) {
    if (key == "Escape") {
      router.pop();
      return;
    }

    final rows = this.rows, row = this.row;
    if (rows == null || row == null) return;
    switch (key) {
      case "Arrow Up":
        setIndex(index > 0 ? index - 1 : rows.length - 1);
        break;
      case "Arrow Down":
        setIndex(index < rows.length - 1 ? index + 1 : 0);
        break;
      case "Arrow Left":
        setRowIndex(row.index > 0 ? row.index - 1 : row.titles.length - 1);
        break;
      case "Arrow Right":
        setRowIndex(row.index < row.titles.length - 1 ? row.index + 1 : 0);
        break;
      case "Enter":
        router.push("/title");
        break;
    }

    TitleDetails.title = title;
  }

  setIndex(int i) {
    setState(() {
      index = i;
    });
    scroll();
  }

  setRowIndex(int i) {
    setState(() {
      row!.index = i;
    });
  }

  scroll() {
    scrollController.animateTo(
      rowHeight * index.toDouble(),
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  @override
  dispose() {
    inputTimer?.cancel();
    focusNode.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
