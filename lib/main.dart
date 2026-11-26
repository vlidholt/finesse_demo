import 'package:disco/disco.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:una/una.dart';
import 'package:una_demo/app_state.dart';
import 'package:una_demo/demo_shell.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/teal_color_scheme.dart';
import 'package:una_demo/widgets/jobs_board_view.dart';

export 'package:una_demo/app_state.dart';
export 'package:una_demo/navigation.dart'
    show DemoDestination, demoDestinationProvider;
export 'package:una_demo/teal_color_scheme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SolidartConfig.devToolsEnabled = false;
  // una bundles no fonts. Fetch Geist before the first frame, so the app
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

/// The package's default style on the Demo's teal palette, set in Geist:
/// the theme the designs were drawn in. Built once; `UnaApp` switches
/// between the two.
final appTheme = ThemeData(
  colorScheme: const TealColorScheme.light(),
  textTheme: appTextTheme,
);
final appDarkTheme = ThemeData(
  colorScheme: const TealColorScheme.dark(),
  textTheme: appTextTheme,
);

/// Every app-level provider: the settings in `app_state.dart`, the shell's
/// selected destination, the session and the Jobs screen's view. They sit
/// above [UnaApp], so every route can read them.
final demoProviders = <InstantiableProvider>[
  ...appProviders,
  demoDestinationProvider,
  demoSessionProvider,
  jobsViewProvider,
];

/// Una: a fictional professional network, the demo app of the una package.
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
          return UnaApp(
            title: 'Una',
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
