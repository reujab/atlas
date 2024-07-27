import "package:flutter/widgets.dart";
import "package:frontend/widgets/background.dart";
import "package:frontend/widgets/header.dart";
import "package:frontend/widgets/input_listener.dart";

class Attributions extends StatelessWidget {
  const Attributions({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputListener(
      handleNavigation: true,
      child: Background(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Header("Attributions"),
            SizedBox(height: 29),
            Text("Pawel Czerwinski @pawel_czerwinski - Backgrounds"),
            Text("flaticon.com @FreePik - Home Screen Icons"),
            Text("UNIVERSFIELD - Chime"),
          ],
        ),
      ),
    );
  }
}
