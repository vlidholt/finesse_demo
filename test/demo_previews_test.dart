import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/widgets/demo_previews.dart';

import 'demo_support.dart';
import 'support.dart';

// The person and company previews: two buttons side by side in a dialog
// capped at 400, which have to go somewhere when the text is large.

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required double textScale,
}) => pumpDemoScreen(
  tester,
  const SizedBox.expand(),
  size: size,
  textScale: textScale,
  appBar: false,
);

void main() {
  setUpAll(() async {
    await loadDemoTestFont();
    await setUpFonts();
  });

  // 1.6 is the top of the theme editor's "Text Scale". The test font is
  // monospaced, so wider than the default Geist — but the Press preset is
  // set in it, so its widths are real ones.
  for (final size in const [demoDesktop, demoPhone]) {
    for (final scale in const [1.0, 1.3, 1.6]) {
      final where = '${size.width.toInt()} wide, ${scale}x text';

      testWidgets('a company preview fits at $where, before and after '
          '"Follow"', (tester) async {
        await _pump(tester, size: size, textScale: scale);
        final context = demoContext(tester);
        for (final company in Companies.all) {
          showCompanyPreview(context, company);
          await settleFrames(tester, frames: 14);
          expect(tester.takeException(), isNull, reason: company.name);
          final follow = find.widgetWithText(Button, 'Follow');
          final following = find.widgetWithText(Button, 'Following');
          final wasFollowing = follow.evaluate().isEmpty;
          await tester.tap((wasFollowing ? following : follow).first);
          await settleFrames(tester, frames: 4);
          expect(
            tester.takeException(),
            isNull,
            reason: '${company.name}, after the toggle',
          );
          expect(wasFollowing ? follow : following, findsOneWidget);
          // Neither label is cut short to make it fit.
          for (final button in tester.widgetList<Text>(
            find.descendant(
              of: find.byType(Dialog),
              matching: find.descendant(
                of: find.byType(Button),
                matching: find.byType(Text),
              ),
            ),
          )) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.byWidget(button),
            );
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: '"${button.data}" in ${company.name}',
            );
          }
          Navigator.of(context, rootNavigator: true).pop();
          await settleFrames(tester, frames: 14);
        }
      });

      testWidgets('a person preview fits at $where', (tester) async {
        await _pump(tester, size: size, textScale: scale);
        final context = demoContext(tester);
        for (final person in [People.irina, People.julian, People.sara]) {
          showPersonPreview(context, person);
          await settleFrames(tester, frames: 14);
          expect(tester.takeException(), isNull, reason: person.name);
          expect(find.widgetWithText(Button, 'Message'), findsOneWidget);
          Navigator.of(context, rootNavigator: true).pop();
          await settleFrames(tester, frames: 14);
        }
      });
    }
  }

  testWidgets('at the default size the two buttons are side by side, and '
      'on a phone the main one is on top', (tester) async {
    await _pump(tester, size: demoDesktop, textScale: 1);
    showCompanyPreview(demoContext(tester), Companies.all.first);
    await settleFrames(tester, frames: 14);
    final roles = find.ancestor(
      of: find.byIcon(PhosphorIconsRegular.briefcase),
      matching: find.byType(Button),
    );
    // "Follow", or "Following" for a page the user follows already.
    final follow = find.descendant(
      of: find.byType(Dialog),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Button &&
            widget.child is Text &&
            (widget.child as Text).data!.startsWith('Follow'),
      ),
    );
    expect(tester.getCenter(roles).dy, tester.getCenter(follow).dy);
    expect(tester.getCenter(roles).dx, lessThan(tester.getCenter(follow).dx));
    Navigator.of(demoContext(tester), rootNavigator: true).pop();
    await settleFrames(tester, frames: 14);

    tester.view.physicalSize = demoPhone;
    await settleFrames(tester, frames: 4);
    showCompanyPreview(demoContext(tester), Companies.all.first);
    await settleFrames(tester, frames: 14);
    expect(tester.getCenter(follow).dy, lessThan(tester.getCenter(roles).dy));
    expect(tester.getSize(follow).width, tester.getSize(roles).width);
    expect(tester.takeException(), isNull);
  });
}
