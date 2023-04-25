import "package:flutter/widgets.dart" hide Title;
import "package:frontend/const.dart";
import "package:frontend/title.dart";

class Overview extends StatelessWidget {
  const Overview({super.key, required this.title, this.maxLines});

  final Title title;

  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.text),
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
            margin: const EdgeInsets.only(right: 8),
            // padding: const EdgeInsets.all(2),
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
            child: Text(
              title.rating ?? "NR",
              style: const TextStyle(fontSize: 24),
            ),
          ),
          Text(
            title.genres.join(" • "),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          ),
        ]),
        const SizedBox(height: 8),
        Text(
          "${title.overview}${maxLines == null ? "" : "\n\n"}",
          style: const TextStyle(fontWeight: FontWeight.w400),
          maxLines: maxLines,
          overflow:
              maxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
