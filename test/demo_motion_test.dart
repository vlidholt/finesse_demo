import 'package:finesse_demo/demo_shell.dart';
import 'package:finesse_demo/screens/home_screen.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// The shell's transition: a destination comes in from its side out of the
/// page colour, in one movement, with the page live from the first frame
/// and its state kept.
/// The cover and the slide of the package's `DestinationStack` found by
/// [finder].
({double cover, Offset offset}) _switchOf(WidgetTester tester, Finder finder) {
  // The cover is a box of the page colour painted at the cover's opacity,
  // after the page: the last box in the switch that takes no pointers.
  final cover = tester.widget<ColoredBox>(
    find
        .descendant(
          of: finder,
          matching: find.descendant(
            of: find.byType(IgnorePointer),
            matching: find.byType(ColoredBox),
          ),
        )
        .last,
  );
  final transform = tester.widget<Transform>(
    find.descendant(of: finder, matching: find.byType(Transform)).first,
  );
  final translation = transform.transform.getTranslation();
  return (
    cover: cover.color.a,
    offset: Offset(translation.x, translation.y),
  );
}

void main() {
  setUpAll(setUpFonts);

  group('the app', () {
    testWidgets('a destination switched to slides in from its side and the '
        'screens keep their state', (tester) async {
      await pumpApp(tester);
      final context = tester.element(find.byType(DemoShell));
      final home = tester.element(find.byType(HomeScreen));
      final shell = find.descendant(
        of: find.byType(DemoShell),
        matching: find.byType(DestinationStack),
      );

      demoDestinationProvider.of(context).value = DemoDestination.jobs;
      await tester.pump();
      final forward = _switchOf(tester, shell);
      expect(forward.cover, inExclusiveRange(.3, .8));
      // Jobs is after Home: from the end.
      expect(forward.offset.dx, greaterThan(0));
      await settle(tester);
      expect(_switchOf(tester, shell).cover, 0);

      demoDestinationProvider.of(context).value = DemoDestination.home;
      await tester.pump();
      expect(_switchOf(tester, shell).offset.dx, lessThan(0));
      await settle(tester);
      // The same Home screen as before, not a new one.
      expect(tester.element(find.byType(HomeScreen)), same(home));
    });
  });
}
