import 'package:disco/disco.dart';
import 'package:finesse_demo/app_state.dart';
import 'package:finesse_demo/data/applications_data.dart';
import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/screens/jobs_screen.dart';
import 'package:finesse_demo/session.dart';
import 'package:finesse_demo/widgets/jobs_board_card.dart';
import 'package:finesse_demo/widgets/jobs_board_view.dart';
import 'package:finesse_demo/widgets/jobs_detail.dart';
import 'package:finesse_demo/widgets/jobs_detail_page.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_support.dart';

// The package's widgets as the Jobs screen uses them: the filter chips are
// a `ChipGroup`, "Easy Apply" is a `Stepper` in a dialog, and what a menu
// or a submission did is said in a toast of the matching variant.

const _desktop = Size(1440, 1000);
const _phone = Size(390, 844);

Future<void> _pumpJobs(WidgetTester tester, {Size size = _desktop}) async {
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
        jobsViewProvider,
      ],
      child: FinesseApp(
        theme: ThemeData(textTheme: TextTheme(family: demoTestFont)),
        home: const Scaffold(body: JobsScreen()),
      ),
    ),
  );
  await settleFrames(tester, frames: 4);
}

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(JobsScreen));

DemoSession _session(WidgetTester tester) =>
    demoSessionProvider.of(_context(tester));

JobsView _view(WidgetTester tester) =>
    jobsViewProvider.of(_context(tester)).value;

Finder _chip(String label) => find.widgetWithText(Chip, label);

bool _chosen(WidgetTester tester, String label) =>
    tester.widget<Chip>(_chip(label)).selected;

Finder _inDialog(Finder finder) =>
    find.descendant(of: find.byType(Dialog), matching: finder);

void main() {
  setUpAll(loadDemoTestFont);

  group('the filter chips', () {
    testWidgets('wrap under the desktop search, "All filters" ending the row', (
      tester,
    ) async {
      await _pumpJobs(tester);

      final group = find.byType(ChipGroup<String>);
      expect(group, findsOneWidget);
      expect(tester.widget<ChipGroup<String>>(group).wrap, isTrue);
      // "All filters" is not a filter of the group but its action, at the
      // end of its first row.
      final chipGroup = tester.widget<ChipGroup<String>>(group);
      expect(
        chipGroup.items.map((item) => (item.label as Text).data),
        isNot(contains('All filters')),
      );
      expect(
        find.descendant(
          of: find.byWidget(chipGroup.trailing!),
          matching: find.text('All filters'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(_chip('All filters')).dx,
        greaterThan(tester.getTopRight(_chip('Under 50 applicants')).dx),
      );
      expect(
        tester.getTopLeft(_chip('All filters')).dy,
        tester.getTopLeft(_chip('Remote')).dy,
      );

      // A tap reports the new set, which the session keeps.
      expect(_chosen(tester, 'Remote'), isTrue);
      await tester.tap(_chip('Hybrid'));
      await tester.pump();
      expect(_session(tester).jobs.filters, {'Remote', 'Hybrid'});
      expect(_chosen(tester, 'Hybrid'), isTrue);
      await tester.tap(_chip('Remote'));
      await tester.pump();
      expect(_session(tester).jobs.filters, {'Hybrid'});

      // "All filters" switches the same filters.
      await tester.tap(_chip('All filters'));
      await settleFrames(tester);
      final dialog = find.byType(Dialog);
      final row = find.ancestor(
        of: find.descendant(of: dialog, matching: find.text('Senior')),
        matching: find.byType(MergeSemantics),
      );
      await tester.tap(
        find.descendant(of: row, matching: find.byType(Switch)),
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(Button, 'Show results'));
      await settleFrames(tester);
      expect(_chosen(tester, 'Senior'), isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('are a bar on a phone that scrolls to the screen edge, with '
        '"All filters" held at its start', (tester) async {
      await _pumpJobs(tester, size: _phone);

      final group = find.byType(ChipGroup<String>);
      expect(tester.widget<ChipGroup<String>>(group).wrap, isFalse);
      // The bar runs out to the edge of the screen; "All filters" stands
      // in the page margin.
      expect(tester.getTopRight(group).dx, _phone.width);
      final margin = Theme.of(
        _context(tester),
      ).layoutTheme.pagePadding!.resolve(TextDirection.ltr).left;
      final allFilters = find.bySemanticsLabel('All filters');
      expect(tester.getTopLeft(_chip('Filters')).dx, margin);

      // The chips scroll sideways under it; it stays where it is.
      final before = tester.getTopLeft(_chip('Senior')).dx;
      final filtersAt = tester.getTopLeft(_chip('Filters'));
      await tester.drag(_chip('Senior'), const Offset(-120, 0));
      await settleFrames(tester, frames: 4);
      expect(tester.getTopLeft(_chip('Senior')).dx, lessThan(before));
      expect(tester.getTopLeft(_chip('Filters')), filtersAt);
      expect(allFilters, findsOneWidget);

      // A chip that has scrolled along can be chosen.
      await tester.tap(_chip('Senior'));
      await tester.pump();
      expect(_session(tester).jobs.filters, contains('Senior'));
      expect(tester.takeException(), isNull);
    });
  });

  group('Easy Apply', () {
    testWidgets('is three steps in a stepper, and Next waits for a reachable '
        'email', (tester) async {
      await _pumpJobs(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(JobDetail),
          matching: find.widgetWithText(Button, 'Easy Apply'),
        ),
      );
      await settleFrames(tester);

      final stepper = find.byType(Stepper);
      expect(stepper, findsOneWidget);
      expect(tester.widget<Stepper>(stepper).steps, hasLength(3));
      expect(tester.widget<Stepper>(stepper).currentStep, 0);
      expect(_inDialog(find.text('Apply to Kestrel Health')), findsOneWidget);
      // The email and phone are filled in from the profile.
      expect(
        find.widgetWithText(
          TextField,
          _session(tester).settings.email,
        ),
        findsOneWidget,
      );

      Button next() => tester.widget<Button>(
        find.widgetWithText(Button, 'Next'),
      );
      await tester.enterText(
        find.widgetWithText(TextField, _session(tester).settings.email),
        'noor',
      );
      await tester.pump();
      expect(next().enabled, isFalse);
      await tester.enterText(
        find.widgetWithText(TextField, 'noor'),
        'noor@example.com',
      );
      await tester.pump();
      expect(next().enabled, isTrue);

      await tester.tap(find.widgetWithText(Button, 'Next'));
      await settleFrames(tester);
      expect(tester.widget<Stepper>(stepper).currentStep, 1);
      // The step behind says what was entered.
      expect(_inDialog(find.text('noor@example.com')), findsOneWidget);

      // A résumé is one of two, the first chosen.
      final resumes = find.byType(RadioListTile<(String, String)>);
      expect(resumes, findsNWidgets(2));
      await tester.tap(find.text(JobsData.resumes.last.$1));
      await tester.pump();

      // Back, and forward again by the step's own header.
      await tester.tap(find.widgetWithText(Button, 'Back'));
      await settleFrames(tester);
      expect(tester.widget<Stepper>(stepper).currentStep, 0);
      await tester.tap(_inDialog(find.text('Review')));
      await settleFrames(tester);
      expect(tester.widget<Stepper>(stepper).currentStep, 2);
      expect(_inDialog(find.text(JobsData.resumes.last.$1)), findsWidgets);
      expect(_inDialog(find.text('Follow Kestrel Health')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('submits after a moment, says so in a success toast, and '
        'the toast and the button lead to the board', (tester) async {
      await _pumpJobs(tester);
      await tester.tap(find.text('Easy Apply').first);
      await settleFrames(tester);
      for (var step = 0; step < 2; step++) {
        await tester.tap(find.widgetWithText(Button, 'Next'));
        await settleFrames(tester);
      }
      await tester.tap(find.widgetWithText(Button, 'Submit application'));
      await tester.pump();
      await tester.pump();
      // Waiting for the pretend server.
      expect(
        tester
            .widget<Button>(
              find.widgetWithText(Button, 'Submit application'),
            )
            .loading,
        isTrue,
      );
      await tester.pump(const Duration(seconds: 1));
      await settleFrames(tester);

      expect(find.byType(Dialog), findsNothing);
      const job = JobsData.kestrel;
      final session = _session(tester);
      expect(session.jobs.hasApplied(job), isTrue);
      expect(session.jobs.isFollowing(job), isTrue);
      expect(
        session.applications.stageOf(job.id),
        ApplicationStage.applied,
      );
      final toast = tester.widget<Toast>(find.byType(Toast));
      expect(toast.variant, ToastVariant.success);
      expect(find.text('Application sent'), findsOneWidget);

      await tester.tap(find.widgetWithText(Button, 'View'));
      await settleFrames(tester);
      expect(_view(tester), JobsView.applications);
      expect(
        demoDestinationProvider.of(_context(tester)).value,
        DemoDestination.jobs,
      );

      // Back on "Find jobs", the applied listing's button leads there too.
      jobsViewProvider.of(_context(tester)).value = JobsView.find;
      await settleFrames(tester);
      await tester.tap(find.widgetWithText(Button, 'View application'));
      await settleFrames(tester);
      expect(_view(tester), JobsView.applications);
      await dismissToasts(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('from the phone\'s detail page, "View" closes the page on '
        'the way to the board', (tester) async {
      await _pumpJobs(tester, size: _phone);
      await scrollToAndTap(tester, find.byKey(ValueKey(JobsData.quill.id)));
      expect(find.byType(JobDetailPage), findsOneWidget);

      await tester.tap(find.widgetWithText(Button, 'Easy Apply'));
      await settleFrames(tester);
      // A phone runs the steps down the dialog.
      expect(find.byType(Stepper), findsOneWidget);
      await completeEasyApply(tester);
      // The toast clears the page's apply bar.
      final bar = find.ancestor(
        of: find.widgetWithText(Button, 'View application'),
        matching: find.byType(Glass),
      );
      expect(
        tester.getBottomLeft(find.byType(Toast)).dy,
        lessThanOrEqualTo(tester.getTopLeft(bar.first).dy),
      );

      await tester.tap(find.widgetWithText(Button, 'View'));
      await settleFrames(tester);
      expect(find.byType(JobDetailPage), findsNothing);
      expect(_view(tester), JobsView.applications);
      await dismissToasts(tester);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('"Archive all" says what it moved, with an Undo that puts it '
      'back', (tester) async {
    await _pumpJobs(tester, size: const Size(2200, 1000));
    jobsViewProvider.of(_context(tester)).value = JobsView.applications;
    await settleFrames(tester);
    final applications = _session(tester).applications;
    final saved = [...applications.at(ApplicationStage.saved)];
    expect(saved, isNotEmpty);

    await tester.tap(find.bySemanticsLabel('Saved options'));
    await settleFrames(tester, frames: 14);
    await tester.tap(find.text('Archive all'));
    await settleFrames(tester);
    expect(applications.at(ApplicationStage.saved), isEmpty);
    expect(find.text('Moved to Archived'), findsOneWidget);
    expect(
      tester.widget<Toast>(find.byType(Toast)).variant,
      ToastVariant.neutral,
    );

    await tester.tap(find.widgetWithText(Button, 'Undo'));
    await settleFrames(tester);
    expect(
      [for (final a in applications.at(ApplicationStage.saved)) a.id],
      [for (final a in saved) a.id],
    );
    expect(find.byType(ApplicationCard), findsWidgets);

    // Clearing the archive is the destructive kind.
    await tester.tap(find.bySemanticsLabel('Archived options'));
    await settleFrames(tester, frames: 14);
    await tester.tap(find.text('Clear the archive'));
    await settleFrames(tester);
    expect(applications.at(ApplicationStage.archived), isEmpty);
    expect(
      tester.widget<Toast>(find.byType(Toast).last).variant,
      ToastVariant.destructive,
    );
    await dismissToasts(tester);
    expect(tester.takeException(), isNull);
  });
}
