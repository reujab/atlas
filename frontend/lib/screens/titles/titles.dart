import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/const.dart";
import "package:frontend/http.dart";
import "package:frontend/router.dart";
import "package:frontend/screens/title_details/title_details.dart";
import "package:frontend/screens/titles/row_data.dart";
import "package:frontend/screens/titles/titles_row.dart";
import "package:frontend/title_data.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";
import "package:frontend/widgets/overview.dart";
import "package:frontend/widgets/poster.dart";

class Titles extends StatefulWidget {
  const Titles({super.key, required this.type});

  static Map<String, List<RowData>> rows = {};
  static List<Image> imgCache = [];

  final String type;

  static Future<void> initRows(String type) async {
    final client = HttpClient();
    List<dynamic>? json;
    try {
      json = await client.getJson("$host/rows/$type");
    } finally {
      client.close();
    }
    if (json == null) return;

    final myList = await getMyList(type);
    rows[type] = [];
    if (myList.isNotEmpty) {
      rows[type]!.add(RowData(name: "My list", titles: myList));
    }
    rows[type]!.addAll(json.map((j) => RowData.fromJson(j)));
  }

  static Future<List<TitleData>> getMyList(String type) async {
    final rows = await db!.rawQuery("""
      SELECT id, title, genres, overview, released, trailer, rating, poster
      FROM my_list
      WHERE type = ?
      ORDER BY ts DESC
    """, [type]);
    return rows
        .map((row) => TitleData(
              id: row["id"] as int,
              type: type,
              title: row["title"] as String,
              genres: (row["genres"] as String).split(","),
              overview: row["overview"] as String,
              released: row["released"] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(row["released"] as int),
              trailer: row["trailer"] as String?,
              rating: row["rating"] as String?,
              poster: row["poster"] as String,
            ))
        .toList();
  }

  @override
  State<Titles> createState() => _TitlesState();
}

class _TitlesState extends State<Titles> {
  final scrollController = ScrollController();
  final poster = GlobalKey<PosterState>();

  Timer? timer;
  List<RowData>? rows;
  int index = 0;
  bool alreadyScrolled = false;
  double rowHeight = 0;

  RowData? get row {
    return rows?[index];
  }

  TitleData? get title {
    return row?.titles[row!.index];
  }

  @override
  void initState() {
    super.initState();

    if (Titles.rows[widget.type] == null) {
      timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        _setFromCache();
        if (rows != null) timer.cancel();
      });
    } else {
      _setFromCache();
    }
  }

  void _setFromCache() {
    setState(() {
      rows = Titles.rows[widget.type];
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
            Header(
              title?.title ?? (widget.type == "movie" ? "Movies" : "TV"),
              search: true,
            ),
            ...(rows == null || title == null
                ? [
                    const Expanded(
                      child: SpinKitRipple(color: Colors.white, size: 256),
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
                              key: ObjectKey(rows[i]),
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

  void onKeyDown(InputEvent e) {
    if (e.name == "Browser Home") {
      router.go("/home");
      return;
    }

    if (e.name == "Escape") {
      router.pop();
      return;
    }

    final rows = this.rows, row = this.row;
    if (rows == null || row == null) return;
    switch (e.name) {
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
      case "Browser Search":
        router.push("/search");
        break;
      case "Enter":
        router.push("/title").then((_) async {
          title?.posterKey.currentState?.updatePercent();

          final myList = await Titles.getMyList(widget.type);
          final myListRow = RowData(name: "My list", titles: myList);
          if (rows[0].name == "My list") {
            if (myList.isEmpty) {
              Titles.rows[widget.type]!.removeAt(0);
            } else {
              Titles.rows[widget.type]![0] = myListRow;
            }
          } else if (myList.isNotEmpty) {
            Titles.rows[widget.type]!.insert(0, myListRow);
            index++;
          } else {
            return;
          }
          _setFromCache();
          scroll();
        });
        break;
      case " ":
        router.push("/search");
        break;
    }

    TitleDetails.title = title;
  }

  void setIndex(int i) {
    setState(() {
      index = i;
    });
    scroll();
  }

  void setRowIndex(int i) {
    setState(() {
      row!.index = i;
    });
  }

  void scroll() {
    scrollController.animateTo(
      rowHeight * index.toDouble(),
      duration: scrollDuration,
      curve: Curves.ease,
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
