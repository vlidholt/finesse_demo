import 'package:finesse_demo/app_state.dart';
import 'package:finesse_demo/screens/settings_screen.dart';
import 'package:finesse_demo/widgets/settings_controller.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_support.dart';

// Settings on the controls the package grew after the page was written:
// the segmented control, the tag field, the pickers, the stepper, the
// control list tiles and the button that waits.

Future<void> _pump(
  WidgetTester tester, {
  Size size = demoDesktop,
  SettingsSection section = SettingsSection.account,
}) async {
  await pumpDemoScreen(
    tester,
    const SettingsScreen(),
    size: size,
    appBar: false,
  );
  final settings = _settings(tester);
  settings.update(() => settings.section = section);
  await settleFrames(tester, frames: 4);
}

SettingsController _settings(WidgetTester tester) =>
    demoSession(tester).settings;

Finder _field(String label) => find.bySemanticsLabel(label);

void main() {
  setUpAll(loadDemoTestFont);

  group('Account', () {
    testWidgets('"Save changes" spins while it saves, then says so', (
      tester,
    ) async {
      await _pump(tester);
      final save = find.widgetWithText(Button, 'Save changes');
      await tester.enterText(
        find.descendant(
          of: _field('Headline'),
          matching: find.byType(TextField),
        ),
        'Design lead at Halcyon',
      );
      await tester.pump();
      await Scrollable.ensureVisible(tester.element(save), alignment: .5);
      await tester.pump();
      await tester.tap(save);
      await tester.pump();

      // On its way: nothing is saved yet, and the button says it is busy.
      expect(tester.widget<Button>(save).loading, isTrue);
      expect(_settings(tester).headline, isNot('Design lead at Halcyon'));
      expect(
        tester.widget<Button>(find.widgetWithText(Button, 'Discard')).enabled,
        isFalse,
      );

      await tester.pump(const Duration(milliseconds: 600));
      await settleFrames(tester);
      expect(tester.widget<Button>(save).loading, isFalse);
      expect(_settings(tester).headline, 'Design lead at Halcyon');
      expect(find.text('Your changes are saved'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await dismissToasts(tester);
    });

    testWidgets('a save still lands when the page is left while it is on '
        'its way', (tester) async {
      await _pump(tester);
      final settings = _settings(tester);
      await tester.enterText(
        find.descendant(of: _field('Name'), matching: find.byType(TextField)),
        'Noor H.',
      );
      await tester.pump();
      final save = find.widgetWithText(Button, 'Save changes');
      await Scrollable.ensureVisible(tester.element(save), alignment: .5);
      await tester.pump();
      await tester.tap(save);
      await tester.pump();
      // Another page of Settings takes the card away.
      settings.update(() => settings.section = SettingsSection.privacy);
      await settleFrames(tester);
      expect(settings.name, 'Noor H.');
      expect(tester.takeException(), isNull);
    });

    testWidgets('skills are tags: typed, suggested, removed and saved', (
      tester,
    ) async {
      await _pump(tester);
      final settings = _settings(tester);
      final skills = find.byType(TagField<String>);
      expect(skills, findsOneWidget);
      final before = List.of(settings.skills);
      expect(tester.widget<TagField<String>>(skills).values, before);

      final input = find.descendant(
        of: skills,
        matching: find.byType(EditableText),
      );
      await Scrollable.ensureVisible(tester.element(skills), alignment: .5);
      await tester.pump();
      // A comma ends a tag, as Enter does.
      await tester.enterText(input, 'Workshop facilitation,');
      await settleFrames(tester, frames: 4);
      expect(
        tester.widget<TagField<String>>(skills).values,
        [...before, 'Workshop facilitation'],
      );
      // Not saved until it is saved.
      expect(settings.skills, before);
      expect(
        tester
            .widget<Button>(find.widgetWithText(Button, 'Save changes'))
            .enabled,
        isTrue,
      );

      // A tag's own button takes it out.
      final first = find.descendant(
        of: skills,
        matching: find.widgetWithText(Chip, before.first),
      );
      tester.widget<Chip>(first).onDeleted!();
      await settleFrames(tester, frames: 4);

      await tester.tap(find.widgetWithText(Button, 'Save changes'));
      await tester.pump(const Duration(milliseconds: 700));
      await settleFrames(tester);
      expect(settings.skills, [
        ...before.skip(1),
        'Workshop facilitation',
      ]);
      await dismissToasts(tester);
    });

    testWidgets('the birthday opens a calendar on a desktop and wheels in a '
        'sheet on a phone', (tester) async {
      await _pump(tester);
      final picker = find.byType(DatePicker);
      await Scrollable.ensureVisible(tester.element(picker), alignment: .5);
      await tester.pump();
      await tester.tap(picker);
      await settleFrames(tester);
      expect(find.byType(Calendar), findsOneWidget);
      expect(find.byType(Sheet), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleFrames(tester);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, size: demoPhone);
      await Scrollable.ensureVisible(
        tester.element(find.byType(DatePicker)),
        alignment: .5,
      );
      await tester.pump();
      await tester.tap(find.byType(DatePicker));
      await settleFrames(tester);
      expect(find.byType(Sheet), findsOneWidget);
      expect(find.byType(DateWheelPicker), findsOneWidget);
      expect(find.byType(Calendar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a phone the language is chosen from a sheet', (
      tester,
    ) async {
      await _pump(tester, size: demoPhone);
      final select = find.byType(Select<String>);
      await Scrollable.ensureVisible(tester.element(select), alignment: .5);
      await tester.pump();
      await tester.tap(select);
      await settleFrames(tester);
      expect(find.byType(Sheet), findsOneWidget);
      await tester.tap(find.text('Dansk').last);
      await settleFrames(tester);
      expect(find.byType(Sheet), findsNothing);
      // Chosen, and waiting to be saved with the rest.
      expect(find.text('Dansk'), findsOneWidget);
      expect(_settings(tester).language, 'English');
      expect(
        tester
            .widget<Button>(find.widgetWithText(Button, 'Save changes'))
            .enabled,
        isTrue,
      );
    });
  });

  group('Privacy', () {
    for (final (name, size) in [
      ('desktop', demoDesktop),
      ('phone', demoPhone),
    ]) {
      testWidgets('on a $name the visibility is a list of radio rows and the '
          'personalisation a list of checkbox rows', (tester) async {
        await _pump(tester, size: size, section: SettingsSection.privacy);
        final settings = _settings(tester);
        expect(find.byType(ListSection), findsNWidgets(3));
        expect(
          find.byType(RadioListTile<ProfileVisibility>),
          findsNWidgets(ProfileVisibility.values.length),
        );

        // The whole row takes the tap.
        await scrollToAndTap(
          tester,
          find.text(ProfileVisibility.members.detail),
        );
        expect(settings.visibility, ProfileVisibility.members);

        expect(
          find.byType(CheckboxListTile),
          findsNWidgets(Personalisation.values.length),
        );
        expect(
          settings.personalisation.contains(Personalisation.research),
          isFalse,
        );
        await scrollToAndTap(
          tester,
          find.text(Personalisation.research.label),
        );
        expect(
          settings.personalisation.contains(Personalisation.research),
          isTrue,
        );
        await scrollToAndTap(tester, find.text(Personalisation.jobs.label));
        expect(
          settings.personalisation.contains(Personalisation.jobs),
          isFalse,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('Notifications', () {
    testWidgets('quiet hours are two time pickers, off while the switch is', (
      tester,
    ) async {
      await _pump(tester, section: SettingsSection.notifications);
      final settings = _settings(tester);
      final pickers = find.byType(TimePicker);
      expect(pickers, findsNWidgets(2));
      expect(
        tester.widget<TimePicker>(pickers.first).value,
        settings.quietFrom,
      );
      expect(
        tester.widget<TimePicker>(pickers.last).value,
        settings.quietUntil,
      );
      expect(
        tester.widgetList<TimePicker>(pickers).every((p) => p.enabled),
        isTrue,
      );

      await scrollToAndTap(
        tester,
        find.descendant(
          of: find.ancestor(
            of: find.text('Keep quiet at night'),
            matching: find.byType(MergeSemantics),
          ),
          matching: find.byType(Switch),
        ),
      );
      expect(settings.quietHours, isFalse);
      expect(
        tester.widgetList<TimePicker>(pickers).any((p) => p.enabled),
        isFalse,
      );
    });

    testWidgets('a time opens a field in a popover on a desktop and wheels '
        'in a sheet on a phone', (tester) async {
      await _pump(tester, section: SettingsSection.notifications);
      await scrollToAndTap(tester, find.byType(TimePicker).first);
      expect(find.byType(TimeField), findsOneWidget);
      expect(find.byType(Sheet), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(
        tester,
        size: demoPhone,
        section: SettingsSection.notifications,
      );
      await scrollToAndTap(tester, find.byType(TimePicker).first);
      expect(find.byType(Sheet), findsOneWidget);
      expect(find.byType(TimeWheelPicker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the job emails a week are a stepper, kept between none and '
        'fourteen', (tester) async {
      await _pump(tester, section: SettingsSection.notifications);
      final settings = _settings(tester);
      final stepper = find.byType(NumberField);
      expect(stepper, findsOneWidget);
      expect(tester.widget<NumberField>(stepper).value, 3);
      await Scrollable.ensureVisible(tester.element(stepper), alignment: .5);
      await tester.pump();

      final plus = find.descendant(
        of: stepper,
        matching: find.byIcon(PhosphorIconsRegular.plus),
      );
      final minus = find.descendant(
        of: stepper,
        matching: find.byIcon(PhosphorIconsRegular.minus),
      );
      await tester.tap(plus);
      await tester.pump();
      expect(settings.jobEmailsPerWeek, 4);
      for (var i = 0; i < 6; i++) {
        await tester.tap(minus);
        await tester.pump();
      }
      expect(settings.jobEmailsPerWeek, 0);
      await settleFrames(tester);
    });

    testWidgets('the job-match slider shows its figure while it is dragged', (
      tester,
    ) async {
      await _pump(tester, section: SettingsSection.notifications);
      final slider = find.byType(Slider);
      expect(
        tester.widget<Slider>(slider).valueIndicator,
        SliderValueIndicator.whileDragging,
      );
      expect(tester.widget<Slider>(slider).valueLabel!(80), '80%');
    });
  });

  group('Appearance', () {
    testWidgets('the mode is a segmented control of three; Auto follows the '
        'device', (tester) async {
      await _pump(tester, section: SettingsSection.appearance);
      final control = find.byType(SegmentedControl<ThemeMode>);
      expect(control, findsOneWidget);
      expect(
        tester.widget<SegmentedControl<ThemeMode>>(control).segments,
        hasLength(3),
      );
      final mode = themeModeProvider.of(demoContext(tester));
      expect(mode.value, ThemeMode.light);

      await tester.tap(find.text('Auto'));
      await settleFrames(tester);
      expect(mode.value, ThemeMode.system);
      await tester.tap(find.text('Dark'));
      await settleFrames(tester);
      expect(mode.value, ThemeMode.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a phone the control takes a line of its own, across the '
        'card', (tester) async {
      await _pump(
        tester,
        size: demoPhone,
        section: SettingsSection.appearance,
      );
      final control = find.byType(SegmentedControl<ThemeMode>);
      final title = find.text('Mode');
      expect(
        tester.getTopLeft(control).dy,
        greaterThan(tester.getBottomLeft(title).dy),
      );
      expect(tester.getSize(control).width, greaterThan(300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the feed switches are rows of a grouped list', (tester) async {
      await _pump(tester, section: SettingsSection.appearance);
      final settings = _settings(tester);
      expect(find.byType(SwitchListTile), findsNWidgets(2));
      await scrollToAndTap(tester, find.text('Reduce motion'));
      expect(settings.reduceMotion, isTrue);
    });
  });

  testWidgets('on a phone the pages are a chip group of one choice that '
      'scrolls, and the arrow keys walk it', (tester) async {
    await _pump(tester, size: demoPhone);
    final group = find.byType(ChipGroup<SettingsSection>);
    expect(group, findsOneWidget);
    final widget = tester.widget<ChipGroup<SettingsSection>>(group);
    expect(widget.wrap, isFalse);
    // The unnamed constructor holds one value.
    expect(widget.onChanged, isNotNull);
    expect(widget.onValuesChanged, isNull);
    expect(widget.allowDeselection, isFalse);

    await tester.tap(find.widgetWithText(Chip, 'Privacy'));
    await settleFrames(tester, frames: 4);
    expect(_settings(tester).section, SettingsSection.privacy);
    // Tapping the chosen page again keeps it.
    await tester.tap(find.widgetWithText(Chip, 'Privacy'));
    await settleFrames(tester, frames: 4);
    expect(_settings(tester).section, SettingsSection.privacy);

    // From the keyboard: one Tab stop, the arrows between pages.
    tester
        .widget<Chip>(find.widgetWithText(Chip, 'Privacy'))
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await settleFrames(tester, frames: 4);
    expect(_settings(tester).section, SettingsSection.notifications);
    expect(tester.takeException(), isNull);
  });
}
