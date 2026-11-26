import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:una_demo/demo_shell.dart';
import 'package:una_demo/main.dart';

/// The designs' two canvases.
const desktopSize = Size(1440, 900);
const mobileSize = Size(390, 844);

/// The `setUpAll` of every test that builds the app.
///
/// Turns off google_fonts' network fetching: there is no network in tests,
/// and the log lines it prints for each face it cannot fetch are noise.
/// Geist is then never found, so the app's text is set in the test font.
Future<void> setUpFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Pumps fixed frames. `pumpAndSettle` is unusable in this app: the typing
/// indicator, skeletons and spinners animate for as long as they show.
Future<void> settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps the whole [App] in a window of [size] logical pixels.
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = desktopSize,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const App());
  await settle(tester, frames: 8);
}

/// A context below the app's providers and its theme: the shell's, which
/// stays mounted — off stage — under any route pushed over it.
BuildContext appContext(WidgetTester tester) =>
    tester.element(find.byType(DemoShell, skipOffstage: false));
