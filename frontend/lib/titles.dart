import "const.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart" hide Title, Row;
import "row.dart";
import "title.dart";

const List<Title> titles = [
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/t6HIqrRAclMCA60NsSmeqe9RmNV.jpg")),
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/A3ZbZsmsvNGdprRi2lKgGEeVLEH.jpg")),
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/s1VzVhXlqsevi8zeCMG9A16nEUf.jpg")),
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/9JBEPLTPSm0d1mbEcLxULjJq9Eh.jpg")),
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/vZloFAK7NmvMGKE7VkF5UHaz0I.jpg")),
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/gOnmaxHo0412UVr1QM5Nekv1xPi.jpg")),
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/gbGHezV6yrhua0KfAgwrknSOiIY.jpg")),
  Title(
      img: NetworkImage(
          "https://image.tmdb.org/t/p/w300_and_h450_bestv2/rzRb63TldOKdKydCvWJM8B6EkPM.jpg")),
];

class Titles extends StatefulWidget {
  const Titles({super.key});

  @override
  State<Titles> createState() => _TitlesState();
}

class _TitlesState extends State<Titles> {
  int index = 0;

  final focusNode = FocusNode();

  final rows = [
    RowData(name: "Trending", titles: List.from(titles)..addAll(titles)),
    RowData(
      name: "Top rated",
      titles: List.from(titles.reversed.toList())
        ..addAll(titles.reversed.toList()),
    ),
  ];

  RowData get row {
    return rows[index];
  }

  @override
  Widget build(BuildContext context) {
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
              children: [
                for (var i = 0; i < rows.length; i++)
                  Row(
                    index: rows[i].index,
                    name: rows[i].name,
                    titles: rows[i].titles,
                    active: i == index,
                  )
              ],
            ),
          ),
        ]),
      ),
    );
  }

  onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey.keyLabel) {
      case "Arrow Up":
        setState(() {
          if (index > 0) {
            index--;
          } else {
            index = 1;
          }
        });
        break;
      case "Arrow Down":
        setState(() {
          if (index < 1) {
            index++;
          } else {
            index = 0;
          }
        });
        break;
      case "Arrow Left":
        setState(() {
          if (row.index > 0) {
            row.index--;
          } else {
            row.index = titles.length * 2 - 1;
          }
        });
        break;
      case "Arrow Right":
        setState(() {
          if (row.index < titles.length * 2 - 1) {
            row.index++;
          } else {
            row.index = 0;
          }
        });
        break;
    }
  }
}

class RowData {
  RowData({required this.name, required this.titles, this.index = 0});

  final String name;
  final List<Title> titles;
  int index;
}
