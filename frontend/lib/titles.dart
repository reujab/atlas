import "dart:async";

import "package:flutter/widgets.dart" hide Title;
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/background.dart";
import "package:frontend/const.dart";
import "package:frontend/header.dart";
import "package:frontend/http.dart";
import "package:frontend/input_listener.dart";
import "package:frontend/overview.dart";
import "package:frontend/router.dart";
import "package:frontend/row_data.dart";
import "package:frontend/title.dart";
import "package:frontend/title_details.dart";
import "package:frontend/titles_row.dart";

class Titles extends StatefulWidget {
  const Titles({super.key, required this.type});

  static Map<String, List<RowData>> rowsCache = {};
  static List<Image> imgCache = [];

  final String type;

  static Future<void> initRows(String type) async {
    try {
      List<dynamic> json = await getJson("$host/$type/rows?key=$key");
      rowsCache[type] = json.map((j) => RowData.fromJson(j)).toList();
    } catch (err) {
      // TODO: handle err;
    }
  }

  @override
  State<Titles> createState() => _TitlesState();
}

class _TitlesState extends State<Titles> {
  final scrollController = ScrollController();

  Timer? timer;

  List<RowData>? rows;

  int index = 0;

  bool alreadyScrolled = false;

  double rowHeight = 0;

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
      timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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
                      child: SpinKitRipple(color: Colors.text, size: 256),
                    ),
                  ]
                : [
                    Overview(
                      rating: title.rating,
                      genres: title.genres,
                      overview: title.overview,
                      maxLines: 3,
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
                                if (!alreadyScrolled) {
                                  alreadyScrolled = true;
                                  scroll();
                                }
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
      duration: duration,
      curve: Curves.ease,
    );
  }

  @override
  dispose() {
    timer?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
