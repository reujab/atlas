import "package:flutter/widgets.dart" hide Title;
import "package:frontend/const.dart";

class Overview extends StatelessWidget {
  const Overview({
    super.key,
    required this.overview,
    this.rating,
    this.genres,
    this.maxLines,
  });

  final String? rating;
  final List<String>? genres;
  final int? maxLines;
  final String overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...(genres == null
            ? []
            : [
                Row(children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                    child: Text(
                      rating ?? "NR",
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  Text(
                    genres!.join(" • "),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w400),
                  ),
                ]),
              ]),
        const SizedBox(height: 8),
        Text(
          "$overview${maxLines == null ? "" : "\n\n"}",
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
