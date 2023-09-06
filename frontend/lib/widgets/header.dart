import "package:flutter/widgets.dart";
import "package:font_awesome_flutter/font_awesome_flutter.dart";
import "package:frontend/const.dart";

class Header extends StatelessWidget {
  const Header(this.title, {super.key, this.search = false});

  final String title;
  final bool search;

  @override
  Widget build(BuildContext context) {
    final searchWidgets = [
      const SizedBox(width: 32),
      const FaIcon(FontAwesomeIcons.magnifyingGlass,
          size: 56, color: Colors.white),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const FaIcon(FontAwesomeIcons.arrowLeft, size: 56, color: Colors.white),
        const SizedBox(width: 32),
        const Text("", style: TextStyle(height: 1.35, fontSize: 96)),
        Expanded(
          child: FractionalTranslation(
            translation: const Offset(0, -0.08),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                height: 1.35,
                fontSize: title.length >= 28 ? 72 : 96,
                fontWeight: FontWeight.w200,
              ),
            ),
          ),
        ),
        ...(search ? searchWidgets : []),
      ],
    );
  }
}
