import "dart:async";

import "package:flutter/widgets.dart";
import "package:intl/intl.dart";

class Date extends StatefulWidget {
  const Date({super.key});

  @override
  State<Date> createState() => _DateState();
}

class _DateState extends State<Date> {
  DateTime date = DateTime.now();

  @override
  void initState() {
    super.initState();

    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final now = DateTime.now();
      if (date.second != now.second) {
        setState(() {
          date = now;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat.jms("en_US").format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          DateFormat("EEEE").format(date),
          style: const TextStyle(fontSize: 32),
        ),
        Text(
          DateFormat.yMMMd("en_US").format(date),
          style: const TextStyle(fontSize: 48),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: time.characters
              .map(
                (char) => Container(
                  width: int.tryParse(char) == null ? null : 38,
                  alignment: Alignment.center,
                  child: Text(char, style: const TextStyle(fontSize: 64)),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
