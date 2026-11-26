import 'dart:io';

import 'package:disco/disco.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/app_state.dart';
import 'package:una_demo/data/applications_data.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/screens/jobs_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/jobs_board.dart';
import 'package:una_demo/widgets/jobs_board_card.dart';
import 'package:una_demo/widgets/jobs_board_controller.dart';
import 'package:una_demo/widgets/jobs_board_view.dart';
import 'package:una_demo/widgets/jobs_job_card.dart';
import 'package:una_demo/widgets/jobs_state.dart';

import 'demo_support.dart';
import 'support.dart' show pumpApp, setUpFonts;

const _desktop = Size(1440, 1000);
const _laptop = Size(1024, 760);
const _narrow = Size(768, 900);
const _phone = Size(390, 844);

/// A real typeface: flutter_test's own draws every glyph a full em wide,
/// about twice the width of body text, and labels that fit any real font
/// overflow in it. JetBrains Mono ships with the example and, being
/// monospaced, is still wider than the fonts the app uses.
const _font = 'JobsBoardTest';

Future<void> _loadFont() async {
  final loader = FontLoader(_font);
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    final bytes = File('fonts/JetBrainsMono-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Pumps fixed frames: a drop lands, a menu opens, a route settles.
Future<void> _settle(WidgetTester tester, {int frames = 16}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps the Jobs screen on its own, showing [view].
Future<void> _pumpJobs(
  WidgetTester tester, {
  Size size = _desktop,
  Brightness brightness = Brightness.light,
  JobsView view = JobsView.applications,
  bool provideView = true,
  TextDirection textDirection = TextDirection.ltr,
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
        if (provideView) jobsViewProvider,
      ],
      child: UnaApp(
        theme: ThemeData(
          brightness: brightness,
          textTheme: TextTheme(family: _font),
        ),
        home: Directionality(
          textDirection: textDirection,
          child: const Scaffold(body: JobsScreen()),
        ),
      ),
    ),
  );
  await _settle(tester, frames: 4);
  if (provideView && view != JobsView.find) {
    jobsViewProvider.of(tester.element(find.byType(JobsScreen))).value = view;
    await _settle(tester, frames: 4);
  }
}

Finder _card(String title) => find.ancestor(
  of: find.text(title),
  matching: find.byType(ApplicationCard),
);

/// The stage whose column [title]'s card is drawn in.
ApplicationStage _stageOf(WidgetTester tester, String title) {
  final card = tester.getRect(_card(title).first);
  final rtl =
      Directionality.of(tester.element(find.byType(JobsBoard))) ==
      TextDirection.rtl;
  ApplicationStage? found;
  double? edge;
  for (final stage in ApplicationStage.values) {
    final header = find.text(stage.label);
    if (header.evaluate().isEmpty) continue;
    final rect = tester.getRect(header.first);
    // The header nearest the card, on its leading side.
    final leading = rtl ? rect.right : rect.left;
    final before = rtl ? leading >= card.center.dx : leading <= card.center.dx;
    final nearer = edge == null || (rtl ? leading < edge : leading > edge);
    if (before && nearer) {
      found = stage;
      edge = leading;
    }
  }
  return found!;
}

/// The titles in [stage]'s column that are built, top to bottom.
List<String> _titlesIn(WidgetTester tester, ApplicationStage stage) {
  final cards = [
    for (final element in find.byType(ApplicationCard).evaluate())
      (element.widget as ApplicationCard).application,
  ];
  final inStage =
      [
        for (final application in cards)
          if (_stageOf(tester, application.title) == stage) application,
      ]..sort(
        (a, b) => tester
            .getTopLeft(_card(a.title).first)
            .dy
            .compareTo(tester.getTopLeft(_card(b.title).first).dy),
      );
  return [for (final application in inStage) application.title];
}

/// The number in [stage]'s header.
String _countOf(WidgetTester tester, ApplicationStage stage) {
  final header = tester.getRect(find.text(stage.label).first);
  final counts = find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        widget.data != null &&
        int.tryParse(widget.data!) != null,
  );
  for (final element in counts.evaluate()) {
    final rect = tester.getRect(find.byElementPredicate((e) => e == element));
    if ((rect.center.dy - header.center.dy).abs() < 12 &&
        rect.left > header.right &&
        rect.left - header.right < 40) {
      return (element.widget as Text).data!;
    }
  }
  fail('no count beside ${stage.label}');
}

Future<void> _dragCard(
  WidgetTester tester,
  String title,
  Offset to, {
  PointerDeviceKind kind = PointerDeviceKind.mouse,
}) async {
  final from = tester.getCenter(find.text(title).first);
  final gesture = await tester.startGesture(from, kind: kind);
  addTearDown(gesture.removePointer);
  if (kind == PointerDeviceKind.touch) {
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
  }
  const steps = 10;
  for (var i = 0; i < steps; i++) {
    await gesture.moveBy((to - from) / steps.toDouble());
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await _settle(tester);
}

Future<void> _openMenu(WidgetTester tester, ApplicationStage stage) async {
  await tester.tap(find.bySemanticsLabel('${stage.label} options'));
  await _settle(tester, frames: 12);
}

void main() {
  setUpAll(() async {
    await setUpFonts();
    await _loadFont();
  });

  group('the switch', () {
    testWidgets('Jobs opens on the designed screen', (tester) async {
      await _pumpJobs(tester, view: JobsView.find);
      expect(find.text(ApplicationsData.findTab), findsOneWidget);
      expect(find.text(ApplicationsData.boardTab), findsOneWidget);
      expect(find.byType(JobCard), findsWidgets);
      expect(find.byType(JobsBoard), findsNothing);
    });

    testWidgets('My applications shows the board, Find jobs goes back', (
      tester,
    ) async {
      await _pumpJobs(tester, view: JobsView.find);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 6);
      expect(find.byType(JobsBoard), findsOneWidget);
      expect(find.byType(JobCard), findsNothing);
      // The title stays; the search card does not.
      expect(find.text(JobsData.title), findsOneWidget);
      for (final stage in ApplicationStage.values.take(4)) {
        expect(find.text(stage.label), findsOneWidget);
      }

      await tester.tap(find.text(ApplicationsData.findTab));
      await _settle(tester, frames: 6);
      expect(find.byType(JobsBoard), findsNothing);
      expect(find.byType(JobCard), findsWidgets);
    });

    testWidgets('works on a screen built without the app providers', (
      tester,
    ) async {
      await _pumpJobs(tester, provideView: false);
      expect(find.byType(JobCard), findsWidgets);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 6);
      expect(find.byType(JobsBoard), findsOneWidget);
    });

    testWidgets('another screen can open the board', (tester) async {
      await pumpApp(tester);
      final context = tester.element(find.byType(Scaffold).first);
      expect(find.byType(JobsBoard), findsNothing);
      context.openApplications();
      await _settle(tester);
      expect(
        demoDestinationProvider.of(context).value,
        DemoDestination.jobs,
      );
      expect(find.byType(JobsBoard), findsOneWidget);
      // Fonts the app asked for never arrive in a test.
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('the board builds without overflowing', () {
    for (final (name, size) in [
      ('1440x1000', _desktop),
      ('1024x760', _laptop),
      ('768x900', _narrow),
      ('390x844', _phone),
    ]) {
      for (final brightness in Brightness.values) {
        testWidgets('at $name, ${brightness.name}', (tester) async {
          await _pumpJobs(tester, size: size, brightness: brightness);
          expect(tester.takeException(), isNull);
          expect(find.byType(JobsBoard), findsOneWidget);
          expect(find.byType(ApplicationCard), findsWidgets);

          // The board does not scroll as a page: it ends inside the window.
          final board = tester.getRect(find.byType(JobsBoard));
          expect(board.bottom, lessThanOrEqualTo(size.height));
          expect(board.left, 0);
          expect(board.right, size.width);
        });
      }
    }

    testWidgets('right to left', (tester) async {
      await _pumpJobs(tester, textDirection: TextDirection.rtl);
      expect(tester.takeException(), isNull);
      final saved = tester.getRect(find.text(ApplicationStage.saved.label));
      final applied = tester.getRect(
        find.text(ApplicationStage.applied.label),
      );
      expect(saved.left, greaterThan(applied.left));
    });

    testWidgets('the first column lines up with the title', (tester) async {
      await _pumpJobs(tester);
      final title = tester.getRect(find.text(JobsData.title));
      final column = tester.getRect(
        find
            .ancestor(
              of: find.text(ApplicationStage.saved.label),
              matching: find.byWidgetPredicate(
                (w) => '${w.runtimeType}'.startsWith('_BoardColumnView'),
              ),
            )
            .first,
      );
      expect(column.left, moreOrLessEquals(title.left, epsilon: 2));
    });
  });

  group('the board holds what the Jobs tiles count', () {
    testWidgets('six saved, four applied, and they are those roles', (
      tester,
    ) async {
      await _pumpJobs(tester);
      expect(_countOf(tester, ApplicationStage.saved), '6');
      expect(_countOf(tester, ApplicationStage.applied), '4');
      expect(_countOf(tester, ApplicationStage.interviewing), '2');
      expect(_countOf(tester, ApplicationStage.offer), '1');
      expect(
        _titlesIn(tester, ApplicationStage.applied),
        [
          for (final application
              in ApplicationsData.initial[ApplicationStage.applied]!)
            application.title,
        ],
      );
    });

    testWidgets('a column with many cards scrolls on its own', (tester) async {
      // A short phone, with no bars around the screen to take the room.
      await _pumpJobs(tester, size: const Size(390, 620));
      final scrollable = find
          .descendant(
            of: find.byType(JobsBoard),
            matching: find.byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            ),
          )
          .first;
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0));
      final first = ApplicationsData.initial[ApplicationStage.saved]!.first;
      final top = tester.getTopLeft(find.text(first.title)).dy;
      await tester.drag(find.text(first.title), const Offset(0, -150));
      await _settle(tester, frames: 6);
      expect(position.pixels, greaterThan(50));
      expect(
        find.text(first.title).evaluate().isEmpty ||
            tester.getTopLeft(find.text(first.title)).dy < top,
        isTrue,
      );
    });
  });

  group('dragging', () {
    testWidgets('a card moves to another stage and takes its status', (
      tester,
    ) async {
      await _pumpJobs(tester);
      const title = 'Staff product designer';
      expect(_stageOf(tester, title), ApplicationStage.saved);
      final target = tester.getCenter(
        find.text('Senior designer, Platform').first,
      );
      await _dragCard(tester, title, target);

      expect(tester.takeException(), isNull);
      expect(_stageOf(tester, title), ApplicationStage.applied);
      expect(_countOf(tester, ApplicationStage.saved), '5');
      expect(_countOf(tester, ApplicationStage.applied), '5');
      // It landed where it was dropped, not at the end.
      final applied = _titlesIn(tester, ApplicationStage.applied);
      expect(applied.indexOf(title), inInclusiveRange(1, 2));
      // And reads as an application now.
      expect(
        find.descendant(of: _card(title), matching: find.text('Now')),
        findsOneWidget,
      );
      // Nothing is left in the air.
      expect(
        find.byType(ApplicationCard),
        findsNWidgets(
          find.byType(ApplicationCard).evaluate().length,
        ),
      );
    });

    testWidgets('a card is reordered within its stage', (tester) async {
      await _pumpJobs(tester);
      final before = _titlesIn(tester, ApplicationStage.saved);
      final third = tester.getCenter(find.text(before[2]).first);
      await _dragCard(tester, before[0], third + const Offset(0, 20));
      final after = _titlesIn(tester, ApplicationStage.saved);
      expect(after.take(3), [before[1], before[2], before[0]]);
      expect(_countOf(tester, ApplicationStage.saved), '6');
    });

    testWidgets('on a phone a long press picks a card up', (tester) async {
      await _pumpJobs(tester, size: _phone);
      final before = _titlesIn(tester, ApplicationStage.saved);
      final second = tester.getCenter(find.text(before[1]).first);
      await _dragCard(
        tester,
        before[0],
        second + const Offset(0, 30),
        kind: PointerDeviceKind.touch,
      );
      expect(tester.takeException(), isNull);
      final after = _titlesIn(tester, ApplicationStage.saved);
      expect(after.take(2), [before[1], before[0]]);
    });

    testWidgets('from the keyboard', (tester) async {
      await _pumpJobs(tester);
      const title = 'Staff product designer';
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      Focus.of(tester.element(_card(title))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _settle(tester);
      expect(_stageOf(tester, title), ApplicationStage.interviewing);
      expect(_countOf(tester, ApplicationStage.interviewing), '3');
    });
  });

  group('column menus and the add row', () {
    testWidgets('sort a column by company', (tester) async {
      await _pumpJobs(tester);
      await _openMenu(tester, ApplicationStage.saved);
      await tester.tap(find.text('Sort by company'));
      await _settle(tester);
      final saved = ApplicationsData.initial[ApplicationStage.saved]!;
      final byCompany = [...saved]
        ..sort((a, b) => a.company.name.compareTo(b.company.name));
      expect(
        _titlesIn(tester, ApplicationStage.saved),
        [for (final application in byCompany) application.title],
      );
    });

    testWidgets('archive a whole column', (tester) async {
      await _pumpJobs(tester);
      await _openMenu(tester, ApplicationStage.applied);
      await tester.tap(find.text('Archive all'));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      expect(_countOf(tester, ApplicationStage.applied), '0');
      expect(_titlesIn(tester, ApplicationStage.applied), isEmpty);
    });

    testWidgets('Add from job alerts adds cards, then points to Find jobs', (
      tester,
    ) async {
      await _pumpJobs(tester);
      for (final (index, suggestion) in ApplicationsData.suggestions.indexed) {
        await tester.tap(find.text(ApplicationsData.addLabel));
        await _settle(tester);
        expect(_countOf(tester, ApplicationStage.saved), '${7 + index}');
        expect(
          _titlesIn(tester, ApplicationStage.saved).first,
          suggestion.title,
        );
      }
      expect(find.text(ApplicationsData.addLabel), findsNothing);
      await tester.tap(find.text(ApplicationsData.findMoreLabel));
      await _settle(tester, frames: 6);
      expect(find.byType(JobsBoard), findsNothing);
      expect(find.byType(JobCard), findsWidgets);
    });
  });

  group('the two sides share their state', () {
    testWidgets('a listing saved on Find jobs is a card under Saved', (
      tester,
    ) async {
      await _pumpJobs(tester, view: JobsView.find);
      final job = JobsData.jobs.first;
      await tester.tap(
        find
            .descendant(
              of: find.byKey(ValueKey(job.id)),
              matching: find.bySemanticsLabel('Save job'),
            )
            .first,
      );
      await _settle(tester, frames: 4);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 6);
      expect(_countOf(tester, ApplicationStage.saved), '7');
      expect(_titlesIn(tester, ApplicationStage.saved).first, job.title);

      // Dragged along, it stays put when the listing is un-saved.
      await tester.tap(find.text(ApplicationsData.findTab));
      await _settle(tester, frames: 6);
      await tester.tap(
        find
            .descendant(
              of: find.byKey(ValueKey(job.id)),
              matching: find.bySemanticsLabel('Remove from saved jobs'),
            )
            .first,
      );
      await _settle(tester, frames: 4);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 6);
      expect(_countOf(tester, ApplicationStage.saved), '6');
      expect(find.text(job.title), findsNothing);
    });

    testWidgets('the Jobs tiles count the board\'s columns, whatever moved '
        'the cards', (tester) async {
      await _pumpJobs(tester);
      String tile(String label) => tester
          .widget<Text>(
            find
                .descendant(
                  of: find.widgetWithText(StatTile, label),
                  matching: find.byWidgetPredicate(
                    (w) => w is Text && int.tryParse(w.data ?? '') != null,
                  ),
                )
                .first,
          )
          .data!;
      Future<void> expectTiles(String saved, String applied) async {
        await tester.tap(find.text(ApplicationsData.findTab));
        await _settle(tester, frames: 6);
        expect(tile('Saved jobs'), saved);
        expect(tile('Applications sent'), applied);
        await tester.tap(find.text(ApplicationsData.boardTab));
        await _settle(tester, frames: 6);
        expect(_countOf(tester, ApplicationStage.saved), saved);
        expect(_countOf(tester, ApplicationStage.applied), applied);
      }

      await expectTiles('6', '4');

      // "Add from job alerts": a card the Find jobs side knows nothing of.
      await tester.tap(find.text(ApplicationsData.addLabel));
      await _settle(tester, frames: 6);
      await expectTiles('7', '4');

      // A drag from Saved to Applied.
      await _dragCard(
        tester,
        'Staff product designer',
        tester.getCenter(find.text('Senior designer, Platform').first),
      );
      await expectTiles('6', '5');

      await _openMenu(tester, ApplicationStage.saved);
      await tester.tap(find.text('Archive all'));
      await _settle(tester);
      await expectTiles('0', '5');
      expect(tester.takeException(), isNull);
    });

    testWidgets('the board keeps its order while Find jobs is showing', (
      tester,
    ) async {
      await _pumpJobs(tester);
      await _openMenu(tester, ApplicationStage.saved);
      await tester.tap(find.text('Sort by company'));
      await _settle(tester);
      final sorted = _titlesIn(tester, ApplicationStage.saved);
      await tester.tap(find.text(ApplicationsData.findTab));
      await _settle(tester, frames: 6);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 6);
      expect(_titlesIn(tester, ApplicationStage.saved), sorted);
    });
  });

  // A listing's card follows what is done to *that listing*: saving it,
  // un-saving it, applying to it. Anything else `JobsState` announces —
  // another listing selected, a filter, the sort, the alerts — leaves the
  // board as the user arranged it.
  group('the board is not re-synced by unrelated changes', () {
    test('a card cleared from the archive is not re-added', () {
      final state = JobsState();
      final board = ApplicationsController();
      void trackListings() {
        for (final job in JobsData.jobs) {
          board.track(
            job,
            saved: state.isSaved(job),
            applied: state.hasApplied(job),
          );
        }
      }

      state.addListener(trackListings);
      final job = JobsData.jobs.first;
      state.toggleSaved(job);
      expect(board.stageOf(job.id), ApplicationStage.saved);
      board
        ..archiveAll(ApplicationStage.saved)
        ..clearArchive();
      expect(board.stageOf(job.id), isNull);

      state
        ..select(JobsData.jobs[1])
        ..setSort(JobSort.salary)
        ..toggleAlerts()
        ..toggleFilter(JobsData.filters.first)
        ..toggleSaved(JobsData.jobs[2]);
      expect(board.stageOf(job.id), isNull);

      // Saving it again is about this listing: the card is back.
      state
        ..toggleSaved(job)
        ..toggleSaved(job);
      expect(board.stageOf(job.id), ApplicationStage.saved);
    });

    test('a card moved back from Applied to Saved stays there', () {
      final state = JobsState();
      final board = ApplicationsController();
      state.addListener(() {
        for (final job in JobsData.jobs) {
          board.track(
            job,
            saved: state.isSaved(job),
            applied: state.hasApplied(job),
          );
        }
      });
      final job = JobsData.jobs.first;
      state.apply(job);
      expect(board.stageOf(job.id), ApplicationStage.applied);
      board.move(
        BoardMove<JobApplication>(
          item: board.at(ApplicationStage.applied).first,
          fromColumn: ApplicationStage.applied,
          fromIndex: 0,
          toColumn: ApplicationStage.saved,
          toIndex: 0,
        ),
      );
      expect(board.stageOf(job.id), ApplicationStage.saved);

      state
        ..select(JobsData.jobs[1])
        ..toggleFollowing(job);
      expect(board.stageOf(job.id), ApplicationStage.saved);
    });

    testWidgets('selecting another listing leaves a cleared card cleared', (
      tester,
    ) async {
      // Wide enough for all five columns of the board.
      await _pumpJobs(
        tester,
        size: const Size(2200, 1000),
        view: JobsView.find,
      );
      final job = JobsData.jobs.first;
      await tester.tap(
        find
            .descendant(
              of: find.byKey(ValueKey(job.id)),
              matching: find.bySemanticsLabel('Save job'),
            )
            .first,
      );
      await _settle(tester, frames: 4);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 8);
      expect(_card(job.title), findsOneWidget);

      await _openMenu(tester, ApplicationStage.saved);
      await tester.tap(find.text('Archive all'));
      await _settle(tester);
      await _openMenu(tester, ApplicationStage.archived);
      await tester.tap(find.text('Clear the archive'));
      await _settle(tester);
      expect(_card(job.title), findsNothing);

      await tester.tap(find.text(ApplicationsData.findTab));
      await _settle(tester, frames: 8);
      await tester.tap(find.byKey(ValueKey(JobsData.jobs[1].id)));
      await _settle(tester, frames: 4);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 8);

      expect(tester.takeException(), isNull);
      expect(_card(job.title), findsNothing);
    });

    testWidgets('selecting another listing leaves a card dragged back to '
        'Saved where it is', (tester) async {
      await _pumpJobs(tester, view: JobsView.find);
      final job = JobsData.jobs.first;
      // The first listing is selected: apply to it from the detail pane.
      await tester.tap(find.text('Easy Apply').first);
      await _settle(tester);
      await completeEasyApply(tester);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 8);
      expect(_stageOf(tester, job.title), ApplicationStage.applied);

      await _dragCard(
        tester,
        job.title,
        tester.getCenter(find.text('Staff product designer').first),
      );
      expect(_stageOf(tester, job.title), ApplicationStage.saved);

      await tester.tap(find.text(ApplicationsData.findTab));
      await _settle(tester, frames: 8);
      await tester.tap(find.byKey(ValueKey(JobsData.jobs[1].id)));
      await _settle(tester, frames: 4);
      await tester.tap(find.text(ApplicationsData.boardTab));
      await _settle(tester, frames: 8);

      expect(tester.takeException(), isNull);
      expect(_stageOf(tester, job.title), ApplicationStage.saved);
      await dismissToasts(tester);
    });
  });
}
