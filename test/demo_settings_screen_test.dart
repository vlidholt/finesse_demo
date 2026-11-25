import 'dart:ui' show Tristate;

import 'package:finesse_demo/app_state.dart';
import 'package:finesse_demo/screens/settings_screen.dart';
import 'package:finesse_demo/widgets/settings_controller.dart';
import 'package:finesse_demo/widgets/settings_sections.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_support.dart';
import 'support.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = demoDesktop,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => pumpDemoScreen(
  tester,
  const SettingsScreen(),
  size: size,
  brightness: brightness,
  textScale: textScale,
  appBar: false,
);

SettingsController _settings(WidgetTester tester) =>
    demoSession(tester).settings;

Future<void> _open(WidgetTester tester, SettingsSection section) async {
  final settings = _settings(tester);
  settings.update(() => settings.section = section);
  await settleFrames(tester, frames: 4);
}

/// The switch of the row titled [title]: the row is one semantic node. In
/// a `SwitchListTile` the row takes the tap and the switch is its picture,
/// so those are tapped by their title.
Finder _switch(String title) => find.descendant(
  of: find.ancestor(
    of: find.text(title),
    matching: find.byType(MergeSemantics),
  ),
  matching: find.byType(Switch),
);

/// The chips that choose a page on a phone. The Account page's skills are
/// chips too, with a button to remove them.
final _sectionChips = find.byWidgetPredicate(
  (widget) => widget is Chip && widget.onDeleted == null,
);

void main() {
  setUpAll(() async {
    await loadDemoTestFont();
    await setUpFonts();
  });

  group('builds without overflowing', () {
    for (final size in demoSizes) {
      for (final brightness in Brightness.values) {
        testWidgets('at ${size.width.toInt()}x${size.height.toInt()}, '
            '${brightness.name}', (tester) async {
          await _pump(tester, size: size, brightness: brightness);
          for (final section in SettingsSection.values) {
            await _open(tester, section);
            expect(find.byType(SettingsSectionView), findsOneWidget);
            await scrollThrough(tester);
            expect(tester.takeException(), isNull, reason: section.label);
          }
        });
      }
    }

    testWidgets('at 1.3x text, on every form factor', (tester) async {
      for (final size in const [demoDesktop, Size(900, 800), demoPhone]) {
        await _pump(tester, size: size, textScale: 1.3);
        for (final section in SettingsSection.values) {
          await _open(tester, section);
          await scrollThrough(tester);
          expect(tester.takeException(), isNull, reason: '$size $section');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('the page', () {
    testWidgets('lists its four pages beside the cards when wide', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.text('Settings'), findsOneWidget);
      expect(_sectionChips, findsNothing);
      for (final section in SettingsSection.values) {
        expect(
          find.widgetWithText(Button, section.label),
          findsOneWidget,
          reason: section.label,
        );
      }
      // Opens on Account.
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Sign-in and security'), findsOneWidget);

      await tester.tap(find.widgetWithText(Button, 'Privacy'));
      await settleFrames(tester, frames: 4);
      expect(
        find.text('Who can open your profile and find it in search.'),
        findsOneWidget,
      );
      expect(find.text('Sign-in and security'), findsNothing);
      expect(_settings(tester).section, SettingsSection.privacy);
    });

    testWidgets('lists them as chips on a phone', (tester) async {
      await _pump(tester, size: demoPhone);

      expect(_sectionChips, findsNWidgets(4));
      // The last chip is off the end of the strip until it is scrolled to.
      await scrollToAndTap(tester, find.widgetWithText(Chip, 'Appearance'));
      expect(find.text('Theme'), findsOneWidget);
      expect(
        tester.widget<Chip>(find.widgetWithText(Chip, 'Appearance')).selected,
        isTrue,
      );
    });

    testWidgets('Account: saving is offered once something changed', (
      tester,
    ) async {
      await _pump(tester);
      final save = find.widgetWithText(Button, 'Save changes');
      final discard = find.widgetWithText(Button, 'Discard');
      expect(tester.widget<Button>(save).enabled, isFalse);

      final headline = find.descendant(
        of: find.bySemanticsLabel('Headline'),
        matching: find.byType(TextField),
      );
      await tester.enterText(headline, 'Design lead at Halcyon');
      await tester.pump();
      expect(tester.widget<Button>(save).enabled, isTrue);

      // Discard puts the saved text back.
      await scrollToAndTap(tester, discard);
      expect(
        find.widgetWithText(TextField, 'Senior product designer at Halcyon'),
        findsOneWidget,
      );
      expect(tester.widget<Button>(save).enabled, isFalse);

      await tester.enterText(headline, 'Design lead at Halcyon');
      await tester.pump();
      await scrollToAndTap(tester, save);
      expect(_settings(tester).headline, 'Design lead at Halcyon');
      expect(find.text('Your changes are saved'), findsOneWidget);
      expect(tester.widget<Button>(save).enabled, isFalse);
      await dismissToasts(tester);
    });

    testWidgets('Account: an unsaved edit survives the layout rearranging', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1100, 900));
      final save = find.widgetWithText(Button, 'Save changes');
      final edited = find.widgetWithText(TextField, 'Noor H.');
      await tester.enterText(find.byType(TextField).first, 'Noor H.');
      await settleFrames(tester, frames: 4);
      expect(edited, findsOneWidget);
      expect(tester.widget<Button>(save).enabled, isTrue);
      // The pages are a rail beside the cards.
      expect(_sectionChips, findsNothing);

      // Narrower, still a desktop: the rail becomes a strip of chips, and
      // the page moves from a row to a column.
      tester.view.physicalSize = const Size(800, 900);
      await settleFrames(tester, frames: 6);
      expect(Theme.of(demoContext(tester)).formFactor, FormFactor.desktop);
      expect(_sectionChips, findsWidgets);
      expect(edited, findsOneWidget);
      expect(tester.widget<Button>(save).enabled, isTrue);

      // A phone, and back to where it started.
      tester.view.physicalSize = demoPhone;
      await settleFrames(tester, frames: 6);
      expect(Theme.of(demoContext(tester)).formFactor, FormFactor.mobile);
      expect(edited, findsOneWidget);
      tester.view.physicalSize = const Size(1100, 900);
      await settleFrames(tester, frames: 6);
      expect(_sectionChips, findsNothing);
      expect(edited, findsOneWidget);
      expect(tester.widget<Button>(save).enabled, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Account: the field being typed in keeps the focus when its '
        'grid changes from two columns to one', (tester) async {
      await _pump(tester, size: const Size(1100, 900));
      final name = find.descendant(
        of: find.bySemanticsLabel('Name'),
        matching: find.byType(TextField),
      );
      final email = find.descendant(
        of: find.bySemanticsLabel('Email'),
        matching: find.byType(TextField),
      );
      bool sideBySide() =>
          tester.getTopLeft(name).dy == tester.getTopLeft(email).dy;
      bool emailFocused() {
        final focus = FocusManager.instance.primaryFocus?.context;
        if (focus == null) return false;
        var inside = false;
        final field = tester.element(email);
        focus.visitAncestorElements((element) {
          inside = element == field;
          return !inside;
        });
        return inside;
      }

      await tester.tap(email);
      await settleFrames(tester, frames: 4);
      expect(sideBySide(), isTrue);
      expect(emailFocused(), isTrue);

      // Too narrow for two fields in a row, with or without the rail.
      for (final width in const [800.0, 500.0]) {
        tester.view.physicalSize = Size(width, 900);
        await settleFrames(tester, frames: 6);
        expect(emailFocused(), isTrue, reason: 'at $width');
      }
      expect(sideBySide(), isFalse);
      tester.view.physicalSize = const Size(1100, 900);
      await settleFrames(tester, frames: 6);
      expect(sideBySide(), isTrue);
      expect(emailFocused(), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Privacy: the radio group, switches and select are live', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester, SettingsSection.privacy);
      final settings = _settings(tester);

      expect(find.byType(RadioListTile<ProfileVisibility>), findsNWidgets(3));
      await tester.tap(find.text('Connections'));
      await settleFrames(tester, frames: 4);
      expect(settings.visibility, ProfileVisibility.connections);

      expect(settings.readReceipts, isTrue);
      await scrollToAndTap(tester, find.text('Read receipts'));
      expect(settings.readReceipts, isFalse);

      await scrollToAndTap(tester, find.byType(Select<MessagePolicy>));
      await tester.tap(find.text('Connections only').last);
      await settleFrames(tester);
      expect(settings.messages, MessagePolicy.connections);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Notifications: a checkbox per topic and channel', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester, SettingsSection.notifications);
      final settings = _settings(tester);

      expect(
        find.byType(Checkbox),
        findsNWidgets(NotificationTopic.values.length * 2),
      );
      expect(settings.emailed.contains(NotificationTopic.mentions), isFalse);
      await scrollToAndTap(tester, find.bySemanticsLabel('Mentions, email'));
      expect(settings.emailed.contains(NotificationTopic.mentions), isTrue);

      // Pausing disables every one of them.
      await scrollToAndTap(tester, find.text('Pause all notifications'));
      expect(settings.pauseAll, isTrue);
      expect(find.textContaining('Paused.'), findsOneWidget);
      expect(
        tester
            .widgetList<Checkbox>(find.byType(Checkbox))
            .every(
              (box) => !box.enabled,
            ),
        isTrue,
      );
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('a labelled control is announced once, under its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      // Account: the fields, and a switch with its sentence.
      for (final label in ['Name', 'Email', 'Headline', 'Language']) {
        expect(announced(tester, label), hasLength(1), reason: label);
      }
      final twoStep = announced(tester, 'Two-step verification');
      expect(twoStep, hasLength(1));
      // The one node is the switch: it has the state and takes the tap.
      expect(twoStep.single.flagsCollection.isToggled, isNot(Tristate.none));
      expect(twoStep.single.hasAction(SemanticsAction.tap), isTrue);
      // Its sentence is part of the same stop.
      expect(twoStep.single.label, contains('\n'));

      await _open(tester, SettingsSection.notifications);
      final pause = announced(tester, 'Pause all notifications');
      expect(pause, hasLength(1));
      expect(pause.single.flagsCollection.isToggled, isNot(Tristate.none));

      await _open(tester, SettingsSection.appearance);
      expect(announced(tester, 'Mode'), hasLength(1));
      expect(announced(tester, 'Text size'), hasLength(1));
      expect(announced(tester, 'Compact feed'), hasLength(1));
      handle.dispose();
    });

    testWidgets('a setting is still set when the page is opened again', (
      tester,
    ) async {
      await _pump(tester);
      await _open(tester, SettingsSection.appearance);
      // A row of a grouped list: the whole row is the switch.
      await scrollToAndTap(tester, find.text('Compact feed'));
      expect(_settings(tester).compactFeed, isTrue);

      // A new page, the same session.
      await _pump(tester);
      expect(find.text('Compact feed'), findsOneWidget);
      expect(tester.widget<Switch>(_switch('Compact feed')).value, isTrue);
    });
  });

  group('in the app', () {
    Future<void> openFromMenu(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(PhosphorIconsRegular.caretDown),
        ),
      );
      await settle(tester);
      await tester.tap(find.text('Settings'));
      await settle(tester);
    }

    testWidgets('the avatar menu opens it, over the shell', (tester) async {
      await pumpApp(tester);
      await openFromMenu(tester);

      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(SettingsScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Appearance drives the real theme', (tester) async {
      await pumpApp(tester);
      await openFromMenu(tester);
      await tester.tap(find.widgetWithText(Button, 'Appearance'));
      await settle(tester);
      final page = tester.element(find.byType(SettingsScreen));
      expect(Theme.of(page).brightness, Brightness.light);

      await tester.tap(find.text('Dark'));
      await settle(tester);
      expect(themeModeProvider.of(page).value, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(SettingsScreen))).brightness,
        Brightness.dark,
      );

      // The slider is the app's text scale.
      final slider = find.byType(Slider);
      await tester.drag(slider, const Offset(400, 0));
      await settle(tester);
      expect(textScaleProvider.of(page).value, 1.3);
      expect(find.text('130%'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("the text-size slider follows the app's text scale", (
      tester,
    ) async {
      await pumpApp(tester);
      await openFromMenu(tester);
      await tester.tap(find.widgetWithText(Button, 'Appearance'));
      await settle(tester);
      final slider = find.descendant(
        of: find.byType(SettingsScreen),
        matching: find.byType(Slider),
      );
      double thumb() => tester.widget<Slider>(slider).value!;
      expect(find.text('100%'), findsOneWidget);
      expect(thumb(), 1.0);

      // Set from elsewhere.
      final scale = textScaleProvider.of(appContext(tester));
      scale.value = 1.2;
      await settle(tester);
      expect(find.text('120%'), findsWidgets);
      expect(thumb(), closeTo(1.2, .001));

      // Beyond the slider's range the thumb stops at its end.
      scale.value = 1.6;
      await settle(tester);
      expect(find.text('160%'), findsWidgets);
      expect(thumb(), closeTo(1.3, .001));
      expect(scale.value, 1.6);

      // And back.
      scale.value = 1;
      await settle(tester);
      expect(thumb(), closeTo(1, .001));
      expect(tester.takeException(), isNull);
    });
  });
}
