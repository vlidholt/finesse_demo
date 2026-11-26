import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/app_state.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/screens/search_screen.dart';
import 'package:una_demo/widgets/home_post_comments.dart';
import 'package:una_demo/widgets/search_bar.dart';

import 'support.dart';

// The desktop app bar's search, in the whole app: when its panel is open,
// where the keyboard goes from it, and what its global shortcut may take.

final _panel = find.byWidgetPredicate(
  (widget) =>
      widget is Semantics && widget.properties.label == 'Search suggestions',
  // The panel is in the page navigator's overlay.
  skipOffstage: false,
);

final _bar = find.byType(DemoSearchBar);

const _desktops = TargetPlatformVariant({
  TargetPlatform.macOS,
  TargetPlatform.windows,
});

bool _focusIsInside(Finder finder) {
  final focus = FocusManager.instance.primaryFocus?.context;
  if (focus == null) return false;
  final target = finder.evaluate().toSet();
  var inside = false;
  focus.visitAncestorElements((element) {
    if (target.contains(element)) {
      inside = true;
      return false;
    }
    return true;
  });
  return inside;
}

bool get _apple =>
    defaultTargetPlatform == TargetPlatform.macOS ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Presses K with [modifier] held.
Future<void> _chord(WidgetTester tester, LogicalKeyboardKey modifier) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
  await tester.sendKeyUpEvent(modifier);
  await settle(tester);
}

/// The platform's search shortcut: ⌘K on an Apple platform, Ctrl+K
/// elsewhere.
Future<void> _searchShortcut(WidgetTester tester) => _chord(
  tester,
  _apple ? LogicalKeyboardKey.metaLeft : LogicalKeyboardKey.controlLeft,
);

/// Tab until the focus is neither in the field nor in the panel.
Future<void> _tabAway(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (!_focusIsInside(_bar) && !_focusIsInside(_panel)) return;
  }
  fail('the focus never left the search bar');
}

void main() {
  setUpAll(setUpFonts);

  testWidgets('the panel is a popover that leaves the focus in the field, '
      'as wide as the design draws it', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byType(SearchField));
    await settle(tester);
    final popover = tester.widget<Popover>(
      find.descendant(of: _bar, matching: find.byType(Popover)),
    );
    expect(popover.requestFocus, isFalse);
    expect(_focusIsInside(find.byType(SearchField)), isTrue);
    // The popover's surface, its padding included.
    expect(
      tester.getSize(_panel).width + 2 * 4,
      DemoSearchBar.panelWidth,
    );

    // Typing keeps the caret where it is while the results change.
    await tester.enterText(
      find.descendant(
        of: find.byType(SearchField),
        matching: find.byType(EditableText),
      ),
      'design',
    );
    await settle(tester);
    expect(_panel, findsOneWidget);
    expect(_focusIsInside(find.byType(SearchField)), isTrue);
    expect(find.textContaining('results'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('the panel is open while the focus is in the field or the panel', () {
    testWidgets(
      'tapping the field again after a tap outside reopens it',
      (
        tester,
      ) async {
        await pumpApp(tester);
        await tester.tap(find.byType(SearchField));
        await settle(tester);
        expect(_panel, findsOneWidget);

        await tester.tapAt(const Offset(10, 600));
        await settle(tester);
        expect(_panel, findsNothing);

        // On a touch platform the field kept the focus through the tap
        // outside, so there is no focus change to open the panel on.
        await tester.tap(find.byType(SearchField));
        await settle(tester);
        expect(_panel, findsOneWidget);
      },
      variant: const TargetPlatformVariant({
        TargetPlatform.macOS,
        TargetPlatform.iOS,
        TargetPlatform.android,
      }),
    );

    testWidgets('it closes when Tab takes the focus out of it', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(SearchField));
      await settle(tester);
      expect(_panel, findsOneWidget);
      expect(_focusIsInside(_bar), isTrue);

      await _tabAway(tester);
      await settle(tester);
      expect(_panel, findsNothing);

      // Whatever the focus landed on can be activated with nothing floating
      // over the page.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester);
      expect(_panel, findsNothing);
    }, variant: _desktops);

    testWidgets('a click on the panel itself keeps the focus in the field, '
        'and Escape still closes it', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(SearchField));
      await settle(tester);
      expect(_panel, findsOneWidget);

      // The panel's own heading: inside the panel, on nothing.
      await tester.tap(find.text('Trending searches'));
      await settle(tester, frames: 4);
      expect(_panel, findsOneWidget);
      expect(_focusIsInside(_bar), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(_panel, findsNothing);
    }, variant: _desktops);

    testWidgets('the results are the next Tab stop, and the arrow keys move '
        'between the field and the results', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.byType(SearchField));
      await settle(tester);
      await tester.enterText(find.byType(SearchField), 'kestrel');
      await settle(tester, frames: 4);
      expect(_panel, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusIsInside(_panel), isTrue);
      final first = FocusManager.instance.primaryFocus;
      expect(_panel, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_focusIsInside(_panel), isTrue);
      expect(FocusManager.instance.primaryFocus, isNot(first));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, first);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_focusIsInside(find.byType(SearchField)), isTrue);
      // The arrows stop at the ends rather than leave the panel.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_focusIsInside(find.byType(SearchField)), isTrue);
      expect(_panel, findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, first);

      // Escape closes it from a result too.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(_panel, findsNothing);
    }, variant: _desktops);
  });

  testWidgets('Escape is the bar\'s only while the panel is open', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.byType(SearchField));
    await settle(tester);
    expect(_panel, findsOneWidget);
    // On a touch platform a tap outside closes the panel and leaves the
    // focus in the field.
    await tester.tapAt(const Offset(10, 600));
    await settle(tester);
    expect(_panel, findsNothing);
    expect(_focusIsInside(find.byType(SearchField)), isTrue);

    // Nothing for the bar to close: it leaves the key, and the focus,
    // alone.
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester, frames: 2);
    expect(_focusIsInside(find.byType(SearchField)), isTrue);

    // Open, the bar takes it: the panel goes, and the focus with it.
    await tester.tap(find.byType(SearchField));
    await settle(tester);
    expect(_panel, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(_panel, findsNothing);
    expect(_focusIsInside(find.byType(SearchField)), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  group('the search shortcut', () {
    testWidgets('puts the cursor in the field and opens the panel', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(_panel, findsNothing);
      await _searchShortcut(tester);
      expect(_focusIsInside(find.byType(SearchField)), isTrue);
      expect(_panel, findsOneWidget);
    }, variant: _desktops);

    testWidgets('the key cap names the platform\'s chord', (tester) async {
      await pumpApp(tester);
      expect(
        find.descendant(
          of: find.byType(SearchField),
          matching: find.text(_apple ? '⌘K' : 'Ctrl K'),
        ),
        findsOneWidget,
      );
    }, variant: _desktops);

    testWidgets('does not pull the focus out of an open dialog', (
      tester,
    ) async {
      await pumpApp(tester);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      showDialog<void>(
        context: tester.element(_bar),
        builder: (context) => Dialog(
          title: const Text('A modal dialog'),
          child: TextField(controller: controller, autofocus: true),
        ),
      );
      await settle(tester);
      expect(find.text('A modal dialog'), findsOneWidget);
      expect(_focusIsInside(find.byType(Dialog)), isTrue);

      await _searchShortcut(tester);

      expect(
        _focusIsInside(find.byType(Dialog)),
        isTrue,
        reason: 'focus went to ${FocusManager.instance.primaryFocus}',
      );
      expect(_panel, findsNothing);
    }, variant: _desktops);

    testWidgets('does not open the search page under a dialog when the bar '
        'is collapsed to its magnifier', (tester) async {
      // Wide enough for the desktop bar with its labelled destinations,
      // and, with text a little larger than the platform's, too narrow for
      // the field beside them.
      await pumpApp(tester, size: const Size(1024, 900));
      textScaleProvider.of(tester.element(_bar)).value = 1.15;
      await settle(tester);
      expect(find.byType(SearchField), findsNothing);
      expect(_bar, findsOneWidget);

      showDialog<void>(
        context: tester.element(_bar),
        builder: (context) => const Dialog(title: Text('A modal dialog')),
      );
      await settle(tester);
      await _searchShortcut(tester);
      expect(find.byType(SearchScreen), findsNothing);

      // Without the dialog it does.
      Navigator.of(tester.element(_bar), rootNavigator: true).pop();
      await settle(tester);
      await _searchShortcut(tester);
      expect(find.byType(SearchScreen), findsOneWidget);
    }, variant: _desktops);

    testWidgets('is not taken while a full-screen page covers the bar', (
      tester,
    ) async {
      await pumpApp(tester);
      tester
          .element(_bar)
          .pushFullScreen<void>(
            (context) => const Scaffold(body: Text('A page over Demo')),
          );
      await settle(tester);
      await _searchShortcut(tester);
      expect(_panel, findsNothing);
      expect(_focusIsInside(_bar), isFalse);
    }, variant: _desktops);

    testWidgets('on macOS leaves Ctrl+K — delete to the end of the line — '
        'to the text field that has the focus', (tester) async {
      await pumpApp(tester);
      final field = find.descendant(
        of: find.byType(HomePostComments),
        matching: find.byType(TextField),
      );
      await Scrollable.ensureVisible(
        tester.element(field.first),
        alignment: .5,
      );
      await tester.pump();
      await tester.tap(field.first);
      await settle(tester, frames: 4);
      await tester.enterText(field.first, 'hello world');
      await tester.pump();
      expect(_focusIsInside(field.first), isTrue);

      await _chord(tester, LogicalKeyboardKey.controlLeft);

      expect(
        _focusIsInside(field.first),
        isTrue,
        reason: 'focus went to ${FocusManager.instance.primaryFocus}',
      );
      expect(_panel, findsNothing);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

    testWidgets('off Apple platforms is Ctrl+K only: not the Windows key, '
        'and not AltGr', (tester) async {
      await pumpApp(tester);
      await _chord(tester, LogicalKeyboardKey.metaLeft);
      expect(_panel, findsNothing);

      // AltGr reports Control and Alt together.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await settle(tester);
      expect(_panel, findsNothing);
      expect(_focusIsInside(_bar), isFalse);
    }, variant: TargetPlatformVariant.only(TargetPlatform.windows));
  });
}
