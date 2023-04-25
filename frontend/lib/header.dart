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
          size: 56, color: Colors.text),
    ];

    return Row(children: [
      const FaIcon(FontAwesomeIcons.arrowLeft, size: 56, color: Colors.text),
      const SizedBox(width: 32),
      Expanded(
        child: Text(title, style: const TextStyle(fontSize: 96)),
      ),
      ...(search ? searchWidgets : []),
    ]);
  }
}
