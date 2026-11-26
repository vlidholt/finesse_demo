import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/main.dart';
import 'package:una_demo/widgets/demo_pieces.dart';

import 'demo_support.dart' show dismissToasts;
import 'support.dart';

/// A toast and Demo's bottom bar: the app's toaster is above the shell's
/// navigator, and the shell's scaffold tells it what is at the bottom of
/// the screen.
void main() {
  setUpAll(setUpFonts);

  Future<void> openNetwork(WidgetTester tester) async {
    demoDestinationProvider.of(appContext(tester)).value =
        DemoDestination.network;
    await settle(tester);
  }

  /// Accepts the first invitation: "You and … are now connected".
  Future<void> connect(WidgetTester tester) async {
    // On a phone the invitations are a tab; the teaser is a shortcut to it.
    final teaser = find.text('3 invitations waiting');
    if (teaser.evaluate().isNotEmpty) {
      await tester.tap(teaser);
      await settle(tester, frames: 4);
    }
    final pill = find.widgetWithText(DemoPillButton, 'Accept').first;
    // To the middle of the page: clear of the bars at both ends.
    await Scrollable.ensureVisible(tester.element(pill), alignment: .5);
    await settle(tester, frames: 4);
    await tester.tap(pill);
    await settle(tester, frames: 30);
    expect(find.textContaining('are now connected'), findsOneWidget);
  }

  testWidgets('on a phone, the toast after connecting on the Network '
      'screen sits above the floating bottom bar', (tester) async {
    await pumpApp(tester, size: mobileSize);
    await openNetwork(tester);
    expect(Theme.of(appContext(tester)).formFactor, FormFactor.mobile);
    final bar = tester.getRect(find.byType(BottomNavigationBar));
    expect(bar.bottom, mobileSize.height);

    await connect(tester);
    final toast = tester.getRect(find.byType(Toast));
    final gap = Theme.of(
      appContext(tester),
    ).toasterTheme.padding!.resolve(TextDirection.ltr).bottom;
    expect(toast.bottom, moreOrLessEquals(bar.top - gap, epsilon: .5));
    expect(toast.overlaps(bar), isFalse);
    await dismissToasts(tester);
  });

  testWidgets('on a desktop, with nothing at the bottom, it sits in the '
      'corner as before', (tester) async {
    await pumpApp(tester);
    await openNetwork(tester);
    expect(find.byType(BottomNavigationBar), findsNothing);

    await connect(tester);
    final toast = tester.getRect(find.byType(Toast));
    final padding = Theme.of(
      appContext(tester),
    ).toasterTheme.padding!.resolve(TextDirection.ltr);
    expect(
      toast.bottom,
      moreOrLessEquals(desktopSize.height - padding.bottom, epsilon: .5),
    );
    expect(
      toast.right,
      moreOrLessEquals(desktopSize.width - padding.right, epsilon: .5),
    );
    await dismissToasts(tester);
  });
}
