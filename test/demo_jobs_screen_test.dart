import 'dart:ui' show Tristate;

import 'package:disco/disco.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/app_state.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/screens/jobs_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/jobs_detail.dart';
import 'package:una_demo/widgets/jobs_detail_page.dart';
import 'package:una_demo/widgets/jobs_job_card.dart';

import 'demo_support.dart';

const _desktop = Size(1440, 1000);
const _laptop = Size(1024, 800);
const _narrow = Size(768, 900);
const _phone = Size(390, 844);

/// Pumps fixed frames: enough for a route transition or a menu's entrance,
/// during which its items ignore the pointer.
Future<void> _settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps the Jobs screen on its own — not through the shell, which also
/// builds the other three screens — in a window of [size] logical pixels.
Future<void> _pumpJobs(
  WidgetTester tester, {
  Size size = _desktop,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      providers: [
        ...appProviders,
        demoDestinationProvider,
        demoSessionProvider,
      ],
      child: UnaApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(body: JobsScreen()),
      ),
    ),
  );
  await _settle(tester, frames: 4);
}

/// Scrolls [finder] to the middle of the viewport — clear of an app bar or a
/// bottom bar laid over the scroll view — and taps it.
Future<void> _scrollToAndTap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pump();
  await tester.tap(finder);
}

List<Job> _listedJobs(WidgetTester tester) => [
  for (final card in tester.widgetList<JobCard>(find.byType(JobCard))) card.job,
];

JobCard _card(WidgetTester tester, Job job) =>
    tester.widget<JobCard>(find.byKey(ValueKey(job.id)));

Finder _inCard(Job job, Finder finder) =>
    find.descendant(of: find.byKey(ValueKey(job.id)), matching: finder);

Finder _inDetail(Finder finder) =>
    find.descendant(of: find.byType(JobDetail), matching: finder);

DemoDestination _destination(WidgetTester tester) =>
    demoDestinationProvider.of(tester.element(find.byType(JobsScreen))).value;

void main() {
  group('builds without overflowing', () {
    for (final (name, size) in [
      ('1440x1000', _desktop),
      ('1024x800', _laptop),
      ('768x900', _narrow),
      ('390x844', _phone),
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets('at $name, ${brightness.name}', (tester) async {
          await _pumpJobs(tester, size: size, brightness: brightness);

          expect(tester.takeException(), isNull);
          expect(find.text('Jobs'), findsOneWidget);
          expect(find.byType(JobCard), findsWidgets);

          // The whole page, not only the first screenful.
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -3000),
          );
          await _settle(tester, frames: 4);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('the detail page, on a phone and in a narrow window', (
      tester,
    ) async {
      for (final size in [_phone, _narrow]) {
        for (final brightness in Brightness.values) {
          await _pumpJobs(tester, size: size, brightness: brightness);
          await _scrollToAndTap(
            tester,
            find.byKey(ValueKey(JobsData.quill.id)),
          );
          await _settle(tester);

          expect(find.byType(JobDetailPage), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  });

  group('on a desktop', () {
    testWidgets('shows the header, the search card and the stats', (
      tester,
    ) async {
      await _pumpJobs(tester);

      expect(
        find.text('12 new roles match your profile since Monday.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(Button, 'Job alerts'), findsOneWidget);
      expect(find.widgetWithText(Button, 'Post a job'), findsOneWidget);

      expect(find.widgetWithText(TextField, 'Product designer'), findsOne);
      expect(find.widgetWithText(TextField, 'Copenhagen, Denmark'), findsOne);
      expect(find.widgetWithText(Button, 'Search'), findsOneWidget);

      for (final label in [
        'Remote',
        'Hybrid',
        'Senior',
        'Posted this week',
        '€70k+',
        'Easy apply',
        'Under 50 applicants',
        'All filters',
      ]) {
        expect(find.widgetWithText(Chip, label), findsOneWidget, reason: label);
      }
      expect(
        tester.widget<Chip>(find.widgetWithText(Chip, 'Remote')).selected,
        isTrue,
      );

      for (final (value, label) in [
        ('6', 'Saved jobs'),
        ('4', 'Applications sent'),
        ('1', 'Interview this week'),
        ('18', 'Recruiter profile views'),
      ]) {
        final tile = find.widgetWithText(StatTile, label);
        expect(tile, findsOneWidget, reason: label);
        expect(
          find.descendant(of: tile, matching: find.text(value)),
          findsOneWidget,
          reason: label,
        );
      }
    });

    testWidgets('lists the five jobs, the first one selected', (tester) async {
      await _pumpJobs(tester);

      expect(
        find.text('248 results for product designer', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Most relevant'), findsOneWidget);
      expect(_listedJobs(tester), JobsData.jobs);
      expect(_card(tester, JobsData.kestrel).selected, isTrue);
      expect(_card(tester, JobsData.quill).selected, isFalse);

      const job = JobsData.birchline;
      for (final text in [
        'Design lead, Onboarding',
        'Birchline',
        'Stockholm · Hybrid',
        '€85k – €105k',
        '3 connections work here',
        'Posted 1d ago · 67 applicants',
      ]) {
        expect(_inCard(job, find.text(text)), findsOneWidget, reason: text);
      }
      // Birchline is not an "Easy apply" role; Tidewater is, and has the
      // design's singular connection line.
      expect(_inCard(job, find.text('Easy apply')), findsNothing);
      expect(
        _inCard(JobsData.tidewater, find.text('Easy apply')),
        findsOneWidget,
      );
      expect(
        _inCard(JobsData.tidewater, find.text('1 connection work here')),
        findsOneWidget,
      );
      expect(_inCard(job, find.byType(AvatarGroup)), findsOneWidget);
    });

    testWidgets('a job card is a selectable button around its bookmark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpJobs(tester);

      Card card(Job job) =>
          tester.widget<Card>(_inCard(job, find.byType(Card)));
      expect(card(JobsData.kestrel).selected, isTrue);
      expect(card(JobsData.quill).selected, isFalse);
      expect(card(JobsData.quill).onTap, isNotNull);

      final node = tester.getSemantics(
        find.byKey(ValueKey(JobsData.kestrel.id)),
      );
      expect(node.label, startsWith(JobsData.kestrel.title));
      expect(node, isSemantics(isButton: true, isSelected: true));
      // The bookmark stays a button of its own inside each card.
      expect(
        find.bySemanticsLabel('Save job'),
        findsNWidgets(JobsData.jobs.length),
      );
      semantics.dispose();
    });

    testWidgets('details the selected job beside the list', (tester) async {
      await _pumpJobs(tester);

      for (final text in [
        'Kestrel Health',
        'Health tech · 1,200 employees',
        'Senior product designer, Design systems',
        'Copenhagen, Denmark · Posted 2 days ago · 41 applicants',
        'Easy Apply',
        'Save',
        'Follow',
        'Salary',
        '€78k – €95k a year',
        'Workplace',
        'Hybrid, 2 days in office',
        'Team',
        '4 designers, 12 engineers',
        'Response time',
        'Usually within a week',
        'Strong match for your profile',
        'You have 8 of 10 skills listed in this role',
        '80%',
        'Meet the hiring team',
        'Message',
        'About the role',
        'What you’ll do',
        'Run monthly critiques and office hours with product teams',
        'About Kestrel Health',
        '1,200 employees',
        'Offices in 4 Nordic cities',
        'kestrel.health',
      ]) {
        expect(_inDetail(find.text(text)), findsOneWidget, reason: text);
      }
      expect(
        _inDetail(find.text('Julian Reyes · 2nd', findRichText: true)),
        findsOneWidget,
      );
      expect(
        tester.widget<ProgressBar>(_inDetail(find.byType(ProgressBar))).value,
        .8,
      );

      // Six matched skills, two missing ones on a dashed outline.
      final skills = tester.widgetList<Chip>(_inDetail(find.byType(Chip)));
      expect(skills, hasLength(8));
      expect(
        skills.where((chip) => chip.variant == ChipVariant.dashed),
        hasLength(2),
      );
      expect(
        tester
            .widget<Chip>(_inDetail(find.widgetWithText(Chip, 'Healthcare')))
            .variant,
        ChipVariant.dashed,
      );
    });

    testWidgets('selecting a card changes the detail pane', (tester) async {
      await _pumpJobs(tester);

      await _scrollToAndTap(
        tester,
        _inCard(JobsData.orbital, find.text('Orbital')),
      );
      await tester.pump();

      expect(_card(tester, JobsData.orbital).selected, isTrue);
      expect(_card(tester, JobsData.kestrel).selected, isFalse);
      expect(
        _inDetail(find.text('Principal designer, Platform')),
        findsOneWidget,
      );
      expect(_inDetail(find.text('Orbital')), findsOneWidget);
      expect(_inDetail(find.text('€95k – €120k a year')), findsOneWidget);
      expect(_inDetail(find.text('About Orbital')), findsOneWidget);
      // Selecting is enough on a desktop: nothing is pushed.
      expect(find.byType(JobDetailPage), findsNothing);
    });

    testWidgets('"All filters" lists a switch per filter, each announced '
        'once and live', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpJobs(tester);
      await tester.tap(find.widgetWithText(Chip, 'All filters'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);

      for (final filter in JobsData.filters) {
        // The chip behind the dialog is hidden from the semantics by the
        // modal barrier; what is left is the dialog's row.
        final row = find.ancestor(
          of: find.descendant(of: dialog, matching: find.text(filter.label)),
          matching: find.byType(MergeSemantics),
        );
        expect(row, findsOneWidget, reason: filter.label);
        final node = tester.getSemantics(row);
        expect(node.label, filter.label);
        expect(
          node.getSemanticsData().flagsCollection.isToggled,
          isNot(Tristate.none),
          reason: filter.label,
        );
        expect(
          find.descendant(of: row, matching: find.byType(Switch)),
          findsOneWidget,
        );
        // Nothing else in the dialog carries the same name.
        expect(
          find.descendant(
            of: dialog,
            matching: find.bySemanticsLabel(filter.label),
          ),
          findsOneWidget,
          reason: filter.label,
        );
      }

      final hybrid = find.descendant(
        of: find.ancestor(
          of: find.descendant(of: dialog, matching: find.text('Hybrid')),
          matching: find.byType(MergeSemantics),
        ),
        matching: find.byType(Switch),
      );
      expect(tester.widget<Switch>(hybrid).value, isFalse);
      await tester.tap(hybrid);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<Switch>(hybrid).value, isTrue);
      handle.dispose();
    });

    testWidgets('filter chips toggle', (tester) async {
      await _pumpJobs(tester);

      bool selected(String label) =>
          tester.widget<Chip>(find.widgetWithText(Chip, label)).selected;

      await tester.tap(find.widgetWithText(Chip, 'Hybrid'));
      await tester.pump();
      expect(selected('Hybrid'), isTrue);
      expect(selected('Remote'), isTrue);

      await tester.tap(find.widgetWithText(Chip, 'Remote'));
      await tester.pump();
      expect(selected('Remote'), isFalse);
    });

    testWidgets('saving a job fills its bookmark and counts it', (
      tester,
    ) async {
      await _pumpJobs(tester);

      const job = JobsData.quill;
      final savedTile = find.widgetWithText(StatTile, 'Saved jobs');
      Finder count(String value) =>
          find.descendant(of: savedTile, matching: find.text(value));

      expect(
        _inCard(job, find.byIcon(PhosphorIconsRegular.bookmarkSimple)),
        findsOneWidget,
      );
      expect(count('6'), findsOneWidget);

      await tester.tap(_inCard(job, find.byType(IconButton)));
      await tester.pump();

      expect(
        _inCard(job, find.byIcon(PhosphorIconsFill.bookmarkSimple)),
        findsOneWidget,
      );
      expect(count('7'), findsOneWidget);
      // The bookmark is its own target: the card was not selected by it.
      expect(_card(tester, job).selected, isFalse);

      await tester.tap(_inCard(job, find.byType(IconButton)));
      await tester.pump();
      expect(
        _inCard(job, find.byIcon(PhosphorIconsRegular.bookmarkSimple)),
        findsOneWidget,
      );
      expect(count('6'), findsOneWidget);
    });

    testWidgets('Save in the detail pane and on the card are one state', (
      tester,
    ) async {
      await _pumpJobs(tester);

      await tester.tap(_inDetail(find.widgetWithText(Button, 'Save')));
      await tester.pump();

      expect(_inDetail(find.text('Saved')), findsOneWidget);
      expect(_card(tester, JobsData.kestrel).saved, isTrue);
    });

    testWidgets('Follow toggles', (tester) async {
      await _pumpJobs(tester);

      await tester.tap(_inDetail(find.widgetWithText(Button, 'Follow')));
      await tester.pump();
      expect(_inDetail(find.text('Following')), findsOneWidget);
      expect(_inDetail(find.text('Follow')), findsNothing);

      await tester.tap(_inDetail(find.widgetWithText(Button, 'Following')));
      await tester.pump();
      expect(_inDetail(find.text('Follow')), findsOneWidget);
    });

    testWidgets('Easy Apply marks the job applied and counts it', (
      tester,
    ) async {
      await _pumpJobs(tester);

      await tester.tap(_inDetail(find.widgetWithText(Button, 'Easy Apply')));
      await _settle(tester);
      await completeEasyApply(tester);

      expect(_inDetail(find.text('View application')), findsOneWidget);
      expect(
        find.descendant(
          of: find.widgetWithText(StatTile, 'Applications sent'),
          matching: find.text('5'),
        ),
        findsOneWidget,
      );
      await dismissToasts(tester);
    });

    testWidgets('the sort menu reorders the list', (tester) async {
      await _pumpJobs(tester);

      await tester.tap(find.text('Most relevant'));
      await _settle(tester);
      await tester.tap(find.text('Most recent'));
      await _settle(tester);

      expect(_listedJobs(tester).first, JobsData.quill);
      expect(_listedJobs(tester).last, JobsData.orbital);
      // The trigger now reads the chosen order.
      expect(find.text('Most recent'), findsOneWidget);
      expect(find.text('Most relevant'), findsNothing);
    });

    testWidgets('searching updates the results line', (tester) async {
      await _pumpJobs(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Product designer'),
        'UX researcher',
      );
      await tester.tap(find.widgetWithText(Button, 'Search'));
      await tester.pump();

      expect(
        find.text('248 results for ux researcher', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('Message opens the Messages destination', (tester) async {
      await _pumpJobs(tester);
      expect(_destination(tester), DemoDestination.home);

      await _scrollToAndTap(tester, find.widgetWithText(Button, 'Message'));
      await tester.pump();

      expect(_destination(tester), DemoDestination.messages);
    });
  });

  group('in a window too narrow for two columns (768)', () {
    testWidgets('shows the list alone and opens the detail as a page', (
      tester,
    ) async {
      await _pumpJobs(tester, size: _narrow);

      expect(
        Theme.of(tester.element(find.byType(JobsScreen))).formFactor,
        FormFactor.desktop,
      );
      expect(_listedJobs(tester), JobsData.jobs);
      expect(find.byType(JobDetail), findsNothing);
      // Still the desktop arrangement above the list.
      expect(find.widgetWithText(Button, 'Search'), findsOneWidget);
      expect(find.byType(StatTile), findsNWidgets(4));

      await _scrollToAndTap(tester, find.byKey(ValueKey(JobsData.quill.id)));
      await _settle(tester);

      final page = find.byType(JobDetailPage);
      expect(page, findsOneWidget);
      expect(
        find.descendant(of: page, matching: find.byType(AppBar)),
        findsOneWidget,
      );
      expect(_inDetail(find.text('Product designer, Editor')), findsOneWidget);
      // No phone-style bottom bar here: the actions stay under the title.
      expect(_inDetail(find.text('Easy Apply')), findsOneWidget);
    });
  });

  group('on a phone', () {
    testWidgets('shows the title, the search panel and the top picks', (
      tester,
    ) async {
      await _pumpJobs(tester, size: _phone);

      expect(find.text('Jobs'), findsOneWidget);
      // The desktop-only parts are gone.
      expect(find.text(JobsData.subtitle), findsNothing);
      expect(find.text('Post a job'), findsNothing);
      expect(find.widgetWithText(Button, 'Search'), findsNothing);
      expect(find.byType(StatTile), findsNothing);
      expect(find.byType(JobDetail), findsNothing);

      expect(find.byType(Glass), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Product designer'), findsOne);
      expect(find.widgetWithText(TextField, 'Copenhagen, Denmark'), findsOne);

      expect(find.text('Top picks for you'), findsOneWidget);
      expect(find.text('Based on your profile'), findsOneWidget);
      expect(_listedJobs(tester), [
        JobsData.kestrel,
        JobsData.quill,
        JobsData.tidewater,
      ]);

      // The filter chips are a bar between the search panel and the list,
      // which scrolls sideways out to the screen's edges.
      final bar = find.byType(ChipGroup<String>);
      expect(bar, findsOneWidget);
      expect(tester.widget<ChipGroup<String>>(bar).wrap, isFalse);
      expect(
        tester.getTopLeft(bar).dy,
        greaterThan(tester.getBottomLeft(find.byType(Glass)).dy),
      );
      expect(
        tester.getTopLeft(find.text('Top picks for you')).dy,
        greaterThan(tester.getBottomLeft(bar).dy),
      );
      expect(tester.getTopRight(bar).dx, _phone.width);
    });

    testWidgets('a card opens the detail page, which pops back', (
      tester,
    ) async {
      await _pumpJobs(tester, size: _phone);

      await _scrollToAndTap(tester, find.byKey(ValueKey(JobsData.quill.id)));
      await _settle(tester);

      final page = find.byType(JobDetailPage);
      Finder inPage(Finder finder) =>
          find.descendant(of: page, matching: finder);
      Finder inBar(Finder finder) => find.descendant(
        of: inPage(find.byType(AppBar)),
        matching: finder,
      );

      expect(page, findsOneWidget);
      expect(inBar(find.text('Quill')), findsOneWidget);
      expect(inBar(find.byType(BackButton)), findsOne);
      expect(inBar(find.byIcon(PhosphorIconsRegular.bookmarkSimple)), findsOne);
      expect(inBar(find.byIcon(PhosphorIconsRegular.export)), findsOne);
      expect(_inDetail(find.text('Product designer, Editor')), findsOneWidget);
      expect(_inDetail(find.text('Meet the hiring team')), findsOneWidget);

      // "Easy Apply" lives in the glass bar at the bottom, not in the body.
      expect(_inDetail(find.text('Easy Apply')), findsNothing);
      final apply = find.descendant(
        of: inPage(find.byType(Glass)),
        matching: find.widgetWithText(Button, 'Easy Apply'),
      );
      expect(apply, findsOneWidget);
      await tester.tap(apply);
      await _settle(tester);
      await completeEasyApply(tester);
      expect(inPage(find.text('View application')), findsOneWidget);
      await dismissToasts(tester);

      // Saving from the app bar reaches the card underneath.
      await tester.tap(inBar(find.byIcon(PhosphorIconsRegular.bookmarkSimple)));
      await tester.pump();
      expect(inBar(find.byIcon(PhosphorIconsFill.bookmarkSimple)), findsOne);

      // The page scrolls clear of the apply bar, whatever its height.
      await tester.drag(
        inPage(find.byType(SingleChildScrollView)).first,
        const Offset(0, -5000),
      );
      await _settle(tester, frames: 4);
      expect(
        tester.getBottomLeft(_inDetail(find.text('kestrel.health'))).dy,
        lessThan(tester.getTopLeft(inPage(find.byType(Glass))).dy),
      );

      await tester.tap(inBar(find.byType(BackButton)));
      await _settle(tester);

      expect(find.byType(JobDetailPage), findsNothing);
      expect(_card(tester, JobsData.quill).saved, isTrue);
      expect(_card(tester, JobsData.quill).selected, isTrue);
    });

    testWidgets('Message leaves the detail page for Messages', (tester) async {
      await _pumpJobs(tester, size: _phone);

      await _scrollToAndTap(tester, find.byKey(ValueKey(JobsData.kestrel.id)));
      await _settle(tester);

      await _scrollToAndTap(tester, find.widgetWithText(Button, 'Message'));
      await _settle(tester);

      expect(find.byType(JobDetailPage), findsNothing);
      expect(_destination(tester), DemoDestination.messages);
    });
  });
}
