import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/data/search_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/screens/search_screen.dart';
import 'package:finesse_demo/widgets/search_bar.dart';
import 'package:finesse_demo/widgets/search_results.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_support.dart';
import 'support.dart';

/// Pumps the search page on its own, as a route's page would be.
Future<void> _pumpPage(
  WidgetTester tester, {
  Size size = demoPhone,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  String query = '',
}) => pumpDemoScreen(
  tester,
  SearchScreen(initialQuery: query),
  size: size,
  brightness: brightness,
  textScale: textScale,
  appBar: false,
);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(SearchField), text);
  await settleFrames(tester, frames: 4);
}

/// A heading — "People · 3" — of the results, as opposed to the chip of the
/// same words over them.
Finder _heading(String text) => find.descendant(
  of: find.byType(SearchResultsView),
  matching: find.text(text),
);

/// The text a [HighlightedText] sets apart, in order.
List<String> _highlights(WidgetTester tester, Finder finder) {
  final rich = tester.widget<RichText>(
    find.descendant(of: finder, matching: find.byType(RichText)).first,
  );
  final matches = <String>[];
  rich.text.visitChildren((span) {
    if (span is TextSpan && span.style?.backgroundColor != null) {
      matches.add(span.text ?? '');
    }
    return true;
  });
  return matches;
}

void main() {
  setUpAll(() async {
    await loadDemoTestFont();
    await setUpFonts();
  });

  group('SearchData.search', () {
    test('a blank query finds nothing', () {
      expect(SearchData.search('').isEmpty, isTrue);
      expect(SearchData.search('   ').isEmpty, isTrue);
    });

    test('finds people, jobs, posts and companies in the app\'s data', () {
      final results = SearchData.search('birchline');
      expect(results.people, [People.omar, People.sara, People.irina]);
      expect(results.jobs, [JobsData.birchline]);
      expect(results.companies.single.company, Companies.birchline);
      // Never the signed-in user.
      expect(SearchData.search('noor').people, isEmpty);
    });

    test('every word has to match, in any order and any case', () {
      expect(SearchData.search('LEAD design').people, [
        People.omar,
        People.tobias,
      ]);
      expect(SearchData.search('design lead').jobs, [JobsData.birchline]);
      expect(SearchData.search('design zebra').isEmpty, isTrue);
    });

    test('a name is found without its diacritics, and with them', () {
      final hanna = SearchData.people.firstWhere(
        (person) => person.name.contains('ø'),
      );
      expect(SearchData.search('sorensen').people, contains(hanna));
      expect(SearchData.search('SØRENSEN').people, contains(hanna));
      expect(SearchData.search('Sørensen').people, contains(hanna));
      expect(SearchData.search('sorensenn').people, isEmpty);
    });

    test('folding keeps every offset where it was', () {
      // What the highlighting relies on: one code unit in, one out.
      for (final text in [
        'Hanna Sørensen',
        'Halcyon, Nørrebro',
        'ÀÉÎÕÜ àéîõü Łódź Ærø ß İ',
        'Design 👏 systems',
        '',
      ]) {
        expect(SearchData.fold(text).length, text.length, reason: text);
      }
      expect(SearchData.fold('Hanna Sørensen'), 'hanna sorensen');
      expect(SearchData.fold('ÀÉÎÕÜ Łódź'), 'aeiou lodz');
      // Letters that would become two are left alone, as is an emoji.
      expect(SearchData.fold('Ærø 👏'), 'æro 👏');
    });

    test('every suggested search finds something', () {
      for (final query in [...SearchData.trending, ...SearchData.recents]) {
        expect(SearchData.search(query).isEmpty, isFalse, reason: query);
      }
    });

    test('a long post is cut to the stretch around the match', () {
      final post = SearchData.search('activation').posts;
      expect(post, isEmpty, reason: 'comments are not searched');
      final excerpt = SearchData.excerpt(
        SearchData.posts.first.text,
        'prototype',
      );
      expect(excerpt, startsWith('…'));
      expect(excerpt.toLowerCase(), contains('prototype'));
    });
  });

  group('builds without overflowing', () {
    for (final size in demoSizes) {
      for (final brightness in Brightness.values) {
        testWidgets('at ${size.width.toInt()}x${size.height.toInt()}, '
            '${brightness.name}', (tester) async {
          // Suggestions, results and the empty state.
          for (final query in ['', 'design', 'zzzz']) {
            await _pumpPage(
              tester,
              size: size,
              brightness: brightness,
              query: query,
            );
            await scrollThrough(tester);
            expect(tester.takeException(), isNull, reason: '"$query"');
            await tester.pumpWidget(const SizedBox.shrink());
          }
        });
      }
    }

    testWidgets('at 1.3x text, on every form factor', (tester) async {
      for (final size in const [demoDesktop, Size(900, 800), demoPhone]) {
        for (final query in ['', 'design']) {
          await _pumpPage(tester, size: size, textScale: 1.3, query: query);
          await scrollThrough(tester);
          expect(tester.takeException(), isNull, reason: '$size "$query"');
          await tester.pumpWidget(const SizedBox.shrink());
        }
      }
    });
  });

  group('the search page', () {
    testWidgets('opens on the recent and the trending searches', (
      tester,
    ) async {
      await _pumpPage(tester);

      expect(find.text('Recent'), findsOneWidget);
      for (final recent in SearchData.recents) {
        expect(find.text(recent), findsOneWidget, reason: recent);
      }
      expect(find.text('Trending searches'), findsOneWidget);
      expect(find.widgetWithText(Chip, 'Config Nordics'), findsOneWidget);
      expect(find.byType(SearchResultsView), findsNothing);

      // A recent search can be removed, and all of them cleared.
      await tester.tap(find.bySemanticsLabel('Remove Kestrel Health'));
      await tester.pump();
      expect(find.text('Kestrel Health'), findsNothing);
      await tester.tap(find.text('Clear'));
      await tester.pump();
      expect(find.text('Recent'), findsNothing);
      expect(find.text('Trending searches'), findsOneWidget);
    });

    testWidgets('lists what matches as it is typed, under each kind', (
      tester,
    ) async {
      await _pumpPage(tester);

      await _type(tester, 'birch');
      expect(find.text('5 results for birch', findRichText: true), findsOne);
      expect(_heading('People · 3'), findsOneWidget);
      expect(_heading('Jobs · 1'), findsOneWidget);
      expect(_heading('Companies · 1'), findsOneWidget);
      expect(_heading('Posts · 0'), findsNothing);
      expect(
        find.text('Design lead at Birchline', findRichText: true),
        findsOneWidget,
      );
      expect(
        _highlights(
          tester,
          find.widgetWithText(
            HighlightedText,
            'Design lead at Birchline',
          ),
        ),
        ['Birch'],
      );

      // A name typed without its diacritic is found, and marked as it
      // is written.
      await _type(tester, 'sorensen');
      expect(
        _highlights(
          tester,
          find.widgetWithText(HighlightedText, 'Hanna Sørensen'),
        ),
        ['Sørensen'],
      );

      // Narrowing the query narrows the list, live.
      await _type(tester, 'birch onboarding');
      expect(
        find.text('1 result for birch onboarding', findRichText: true),
        findsOne,
      );
      expect(_heading('People · 3'), findsNothing);
      expect(
        find.text('Design lead, Onboarding', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the kinds filter the results', (tester) async {
      await _pumpPage(tester, query: 'design');
      final results = SearchData.search('design');
      expect(results.people.length, greaterThan(3));

      // "All" previews three of a kind and offers the rest.
      expect(find.widgetWithText(Chip, 'All · ${results.total}'), findsOne);
      expect(find.text('See all ${results.people.length}'), findsOneWidget);

      await tester.tap(
        find.widgetWithText(Chip, 'People · ${results.people.length}'),
      );
      await settleFrames(tester, frames: 4);
      expect(_heading('Jobs · ${results.jobs.length}'), findsNothing);
      for (final person in results.people) {
        expect(
          find.text(person.name, findRichText: true, skipOffstage: false),
          findsOneWidget,
          reason: person.name,
        );
      }

      // A query the selected kind has nothing for falls back to "All".
      await _type(tester, 'tidewater ux');
      expect(SearchData.search('tidewater ux').people, isEmpty);
      expect(_heading('Jobs · 1'), findsOneWidget);
    });

    testWidgets('a wide window shows the kinds as a rail', (tester) async {
      await _pumpPage(tester, size: demoDesktop, query: 'design');

      expect(find.text('Show results for'), findsOneWidget);
      expect(find.byType(Chip), findsNothing);

      await tester.tap(find.widgetWithText(Button, 'Jobs'));
      await settleFrames(tester, frames: 4);
      expect(
        find.text('People · ${SearchData.search('design').people.length}'),
        findsNothing,
      );
      expect(find.textContaining('Jobs · '), findsOneWidget);
    });

    testWidgets('says so when nothing matches, and offers searches that do', (
      tester,
    ) async {
      await _pumpPage(tester);

      await _type(tester, 'zzzz');
      expect(find.text('No results for “zzzz”'), findsOneWidget);
      expect(find.byType(SearchResultsView), findsNothing);

      await tester.tap(find.widgetWithText(Button, 'Config Nordics'));
      await settleFrames(tester, frames: 4);
      expect(find.byType(SearchResultsView), findsOneWidget);
      expect(demoSession(tester).search.recents.first, 'Config Nordics');
    });

    testWidgets('a result leads somewhere, and the query is remembered', (
      tester,
    ) async {
      await _pumpPage(tester);
      await _type(tester, 'mei');

      // A person opens their preview; Connect there and in the row agree.
      await tester.tap(find.text('Mei Tanaka', findRichText: true));
      await settleFrames(tester);
      final dialog = find.byType(Dialog);
      expect(dialog, findsOneWidget);
      expect(demoSession(tester).search.recents.first, 'mei');
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.widgetWithText(Button, 'Connect'),
        ),
      );
      await settleFrames(tester, frames: 4);
      await tester.tap(find.bySemanticsLabel('Close'));
      await settleFrames(tester);
      expect(find.widgetWithText(DemoPillButton, 'Pending'), findsOneWidget);

      // A job leaves for Jobs.
      await _type(tester, 'tidewater ux');
      await tester.tap(find.text('Senior UX designer', findRichText: true));
      await settleFrames(tester);
      expect(demoDestination(tester), DemoDestination.jobs);
    });
  });

  group('in the app', () {
    Finder inAppBar(Finder finder) =>
        find.descendant(of: find.byType(AppBar), matching: finder);
    final panel = find.byWidgetPredicate(
      (widget) =>
          widget is Semantics &&
          widget.properties.label == 'Search suggestions',
    );

    testWidgets('the desktop field opens a panel of live results', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(inAppBar(find.byType(DemoSearchBar)), findsOneWidget);
      expect(panel, findsNothing);

      await tester.tap(find.byType(SearchField));
      await settleFrames(tester);
      expect(panel, findsOneWidget);
      expect(find.text('Recent'), findsOneWidget);
      expect(find.text('Trending searches'), findsOneWidget);

      await tester.enterText(find.byType(SearchField), 'kestrel');
      await settleFrames(tester, frames: 4);
      Finder inPanel(Finder finder) =>
          find.descendant(of: panel, matching: finder);
      expect(inPanel(find.text('People')), findsOneWidget);
      expect(inPanel(find.text('Jobs')), findsOneWidget);
      expect(
        inPanel(find.text('VP Design at Kestrel Health', findRichText: true)),
        findsOneWidget,
      );
      final total = SearchData.search('kestrel').total;
      expect(inPanel(find.text('See all $total results')), findsOneWidget);

      // Escape closes it; the shell is untouched.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleFrames(tester);
      expect(panel, findsNothing);
      expect(find.byType(SearchScreen), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Return opens the page on the same query', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(SearchField));
      await settleFrames(tester);
      await tester.enterText(find.byType(SearchField), 'accessibility');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settleFrames(tester);

      final page = find.byType(SearchScreen);
      expect(page, findsOneWidget);
      expect(panel, findsNothing);
      expect(
        find.descendant(
          of: page,
          matching: find.widgetWithText(SearchField, 'accessibility'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('Accessibility lead at Orbital', findRichText: true),
        findsOneWidget,
      );

      // Back, and the search is among the recent ones.
      await tester.tap(find.byType(BackButton));
      await settleFrames(tester);
      expect(page, findsNothing);
      await tester.tap(find.byType(SearchField));
      await settleFrames(tester);
      expect(
        find.descendant(of: panel, matching: find.text('accessibility')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tap outside closes the panel', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byType(SearchField));
      await settleFrames(tester);
      expect(panel, findsOneWidget);

      await tester.tapAt(const Offset(1200, 700));
      await settleFrames(tester);
      expect(panel, findsNothing);
    });

    testWidgets('a trending topic on the home feed searches for it', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('#DesignSystems'));
      await settleFrames(tester);

      final page = find.byType(SearchScreen);
      expect(page, findsOneWidget);
      expect(
        find.descendant(
          of: page,
          matching: find.widgetWithText(SearchField, 'Design systems'),
        ),
        findsOneWidget,
      );
      expect(find.byType(SearchResultsView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
