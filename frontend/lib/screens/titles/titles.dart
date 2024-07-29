import "dart:async";

import "package:flutter/widgets.dart";
import "package:flutter_spinkit/flutter_spinkit.dart";
import "package:frontend/ui.dart";
import "package:frontend/http.dart";
import "package:frontend/main.dart";
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

  static Map<String, Future<List<RowData>>> rows = {};
  static List<Image> imgCache = [];

  final String type;

  static Future<void> initRows(String type) async {
    final client = HttpClient();
    rows[type] = client.getJson("$server/$type/rows.json").then((json) async {
      final myList = await getMyList(type);
      final List<RowData> rows = [];
      if (myList.isNotEmpty) {
        rows.add(RowData(name: "My list", titles: myList));
      }
      rows.addAll((json as List<dynamic>).map((j) => RowData.fromJson(j)));
      return rows;
    });
    rows[type]!.whenComplete(() => client.close());
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

  static Future<void> updateMyList(String type) async {
    final myList = await Titles.getMyList(type);
    final myListRow = RowData(name: "My list", titles: myList);
    final rows = await Titles.rows[type]!;
    if (rows[0].name == "My list") {
      if (myList.isEmpty) {
        rows.removeAt(0);
      } else {
        rows[0] = myListRow;
      }
    } else if (myList.isNotEmpty) {
      rows.insert(0, myListRow);
    } else {
      return;
    }
  }

  @override
  State<Titles> createState() => _TitlesState();
}

class _TitlesState extends State<Titles> {
  final scrollController = ScrollController();
  final poster = GlobalKey<PosterState>();

  Timer? timer;
  List<RowData>? rows;
  int rowIndex = 0;
  bool alreadyScrolled = false;
  double rowHeight = 0;

  RowData? get row {
    return rows?[rowIndex];
  }

  TitleData? get title {
    return row?.titles[row!.titleIndex];
  }

  @override
  void initState() {
    super.initState();
    updateRows();
  }

  Future<void> updateRows({int? originalRows}) async {
    final rows = await Titles.rows[widget.type]!;
    if (!mounted) return;
    if (originalRows != null && rows.length != originalRows) {
      setState(() {
        rowIndex += rows.length - originalRows;
        if (rowIndex < 0) rowIndex = 0;
      });
      scroll();
    }
    setState(() {
      this.rows = rows;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rows = this.rows, title = this.title;

    return InputListener(
      onKeyDown: onKeyDown,
      handleNavigation: true,
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
                              titleIndex: rows[i].titleIndex,
                              name: rows[i].name,
                              titles: rows[i].titles,
                              active: i == rowIndex,
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

  Future<void> onKeyDown(InputEvent e) async {
    final rows = this.rows, row = this.row;
    if (rows == null || row == null) return;
    switch (e.name) {
      case "Arrow Up":
        setIndex(rowIndex > 0 ? rowIndex - 1 : rows.length - 1);
        break;
      case "Arrow Down":
        setIndex(rowIndex < rows.length - 1 ? rowIndex + 1 : 0);
        break;
      case "Arrow Left":
        setRowIndex(
            row.titleIndex > 0 ? row.titleIndex - 1 : row.titles.length - 1);
        break;
      case "Arrow Right":
        setRowIndex(
            row.titleIndex < row.titles.length - 1 ? row.titleIndex + 1 : 0);
        break;
      case "Browser Search":
      case " ":
        final originalRows = rows.length;
        await router.push("/search");
        update(originalRows);
        break;
      case "Enter":
        TitleDetails.title = title;
        final originalRows = rows.length;
        await router.push("/title");
        update(originalRows);
        break;
    }
  }

  void setIndex(int i) {
    setState(() {
      rowIndex = i;
    });
    scroll();
  }

  void setRowIndex(int i) {
    setState(() {
      row!.titleIndex = i;
    });
  }

  void scroll() {
    scrollController.animateTo(
      rowHeight * rowIndex.toDouble(),
      duration: scrollDuration,
      curve: Curves.ease,
    );
  }

  Future<void> update(int originalRows) async {
    await updateRows(originalRows: originalRows);
    title?.posterKey.currentState?.updatePercent();
  }

  @override
  void dispose() {
    timer?.cancel();
    scrollController.dispose();
    super.dispose();
  }
}
