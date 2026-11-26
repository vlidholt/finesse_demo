import 'dart:io';

import 'package:disco/disco.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/app_state.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/messages_assistant.dart';

// What the tests of the screens built after the designs share: Network,
// Notifications, Search and Settings.

/// A real typeface for the layout checks.
///
/// flutter_test's default font draws every glyph a full em wide — about
/// twice the width of body text — so labels that fit comfortably in any
/// real font overflow and the "nothing overflows" tests fail for the wrong
/// reason. JetBrains Mono ships with the example and, being monospaced, is
/// still wider than the fonts the app uses: a layout that fits it has room
/// to spare.
const demoTestFont = 'DemoScreenTest';

Future<void> loadDemoTestFont() async {
  final loader = FontLoader(demoTestFont);
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    final bytes = File('fonts/JetBrainsMono-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

const demoDesktop = Size(1440, 1000);
const demoPhone = Size(390, 844);

/// The windows every screen is built in: the designs' two canvases and the
/// widths in between, where the columns drop away.
const demoSizes = [
  Size(1440, 1000),
  Size(1200, 900),
  Size(1100, 800),
  Size(1024, 800),
  Size(900, 800),
  Size(800, 800),
  Size(768, 900),
  Size(390, 844),
];

/// Pumps fixed frames: enough for a route transition or a menu's entrance,
/// during which its items ignore the pointer.
Future<void> settleFrames(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Lets every toast on screen run out, so no timer outlives the test.
Future<void> dismissToasts(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 8));
  await settleFrames(tester, frames: 6);
}

/// Pumps [screen] on its own — below the app's providers and inside a
/// `Scaffold`, but not inside the Demo shell — in a window of [size]
/// logical pixels, under [theme] or, without one, the package's default
/// theme in [demoTestFont].
Future<void> pumpDemoScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = demoDesktop,
  Brightness brightness = Brightness.light,
  double textScale = 1,
  bool appBar = true,
  ThemeData? theme,
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
        theme:
            theme ??
            ThemeData(
              brightness: brightness,
              textTheme: TextTheme(family: demoTestFont),
            ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(appBar: appBar ? const AppBar() : null, body: screen),
      ),
    ),
  );
  await settleFrames(tester, frames: 4);
}

/// Provides a [DemoSession] of this widget's own to [child], for a test
/// that pumps a screen without the app and needs to decide how the session
/// is made — who answers a message, and when.
///
/// The session lives and dies with this widget: the scope below disposes
/// of it as it would of one it had made itself (an override is disposed by
/// its provider's own `dispose`), so its timers are cancelled when the
/// test's tree is taken down, not after.
class DemoSessionHost extends StatefulWidget {
  const DemoSessionHost({
    required this.child,
    this.replies = const MessagesReplies.none(),
    super.key,
  });

  /// How the other side of every conversation answers. Nobody does, unless
  /// a test says otherwise.
  final MessagesReplies replies;

  final Widget child;

  @override
  State<DemoSessionHost> createState() => _DemoSessionHostState();
}

class _DemoSessionHostState extends State<DemoSessionHost> {
  late final _session = DemoSession(replies: widget.replies);

  @override
  Widget build(BuildContext context) => ProviderScopeOverride(
    overrides: [demoSessionProvider.overrideWithValue(_session)],
    child: widget.child,
  );
}

/// A context below the providers and the theme.
BuildContext demoContext(WidgetTester tester) =>
    tester.element(find.byType(Scaffold).first);

DemoSession demoSession(WidgetTester tester) =>
    demoSessionProvider.of(demoContext(tester));

DemoDestination demoDestination(WidgetTester tester) =>
    demoDestinationProvider.of(demoContext(tester)).value;

/// Scrolls [finder] to the middle of the viewport — clear of an app bar or
/// a bottom bar laid over the scroll view — and taps it.
Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
  await tester.pump();
  await tester.tap(finder);
  await settleFrames(tester);
}

/// Drags the page's scroll view to its end and back, so that everything on
/// it is laid out at least once.
Future<void> scrollThrough(WidgetTester tester) async {
  final scrollable = find.byType(SingleChildScrollView).first;
  await tester.drag(scrollable, const Offset(0, -4000));
  await settleFrames(tester, frames: 4);
  await tester.drag(scrollable, const Offset(0, 4000));
  await settleFrames(tester, frames: 4);
}

/// What a screen reader stops on whose name includes [text]: the semantic
/// nodes that are not merged into another, with the label the merge gives
/// them.
///
/// A control named by a visible label must come out of this once. Twice
/// means the label is in the tree beside a control that repeats it. Call
/// it with `tester.ensureSemantics()` in effect.
List<SemanticsData> announced(WidgetTester tester, String text) {
  final found = <SemanticsData>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent && !node.isInvisible) {
      final data = node.getSemanticsData();
      if (data.label.contains(text)) found.add(data);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  for (final view in tester.binding.renderViews) {
    final root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) visit(root);
  }
  return found;
}

/// Walks an open "Easy Apply" from its first step to "Submit application"
/// and lets the pretend server answer, which closes it and shows a toast.
Future<void> completeEasyApply(WidgetTester tester) async {
  for (var step = 0; step < 2; step++) {
    await tester.tap(find.widgetWithText(Button, 'Next'));
    await settleFrames(tester);
  }
  await tester.tap(find.widgetWithText(Button, 'Submit application'));
  await tester.pump(const Duration(seconds: 1));
  await settleFrames(tester);
}
