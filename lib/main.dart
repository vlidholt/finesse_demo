import 'package:disco/disco.dart';
import 'package:finesse/finesse.dart';
import 'package:finesse_demo/app_state.dart';
import 'package:finesse_demo/demo_shell.dart';
import 'package:finesse_demo/session.dart';
import 'package:finesse_demo/widgets/jobs_board_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:google_fonts/google_fonts.dart';

export 'package:finesse_demo/app_state.dart';
export 'package:finesse_demo/navigation.dart'
    show DemoDestination, demoDestinationProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SolidartConfig.devToolsEnabled = false;
  // finesse bundles no fonts. Fetch Geist before the first frame, so the app
  // does not open in the fallback font and then reflow. On iOS and macOS,
  // bars, menus, sheets and controls are drawn with Liquid Glass: load its
  // shaders now too, so the first glass surfaces are not a frame late.
  await Future.wait([
    loadAppFont(timeout: const Duration(seconds: 3)),
    LiquidGlass.initialize(),
  ]);
  runApp(const App());
}

/// The weights the text roles use. Fetching them up front means the text
/// reflows once, not once per weight as each arrives.
const _weights = [
  FontWeight.w400,
  FontWeight.w500,
  FontWeight.w600,
  FontWeight.w700,
  FontWeight.w800,
];

/// The app's text theme: every role in Geist, the face the designs use.
///
/// One object for the whole run. `GoogleFonts.geist` is a static tear-off,
/// so the theme compares equal however often it is built, but building it
/// once is cheaper still.
final appTextTheme = TextTheme.fromGoogleFont(GoogleFonts.geist);

/// Fetches Geist's faces and completes once they are registered, or when
/// fetching fails or is disabled (offline, tests): the text then renders in
/// the fallback face, which is the best there is.
Future<void> loadAppFont({
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    for (final weight in _weights) {
      GoogleFonts.geist(fontWeight: weight);
    }
    // The text theme itself asks for an italic (its blockquote), which no
    // weight above covers.
    appTextTheme;
    await GoogleFonts.pendingFonts().timeout(timeout);
  } on Object {
    // Keep the fallback.
  }
}

/// The package's default look, set in Geist: the theme the designs were
/// drawn in. Built once; `FinesseApp` switches between the two.
final appTheme = ThemeData(
  brightness: Brightness.light,
  textTheme: appTextTheme,
);
final appDarkTheme = ThemeData(
  brightness: Brightness.dark,
  textTheme: appTextTheme,
);

/// Every app-level provider: the settings in `app_state.dart`, the shell's
/// selected destination, the session and the Jobs screen's view. They sit
/// above [FinesseApp], so every route can read them.
final demoProviders = <InstantiableProvider>[
  ...appProviders,
  demoDestinationProvider,
  demoSessionProvider,
  jobsViewProvider,
];

/// Demo: a fictional professional network, built with finesse.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: demoProviders,
      child: SignalBuilder(
        builder: (context, _) {
          final themeMode = themeModeProvider.of(context).value;
          final textScale = textScaleProvider.of(context).value;
          return FinesseApp(
            title: 'Demo',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: appTheme,
            darkTheme: appDarkTheme,
            home: const DemoShell(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
