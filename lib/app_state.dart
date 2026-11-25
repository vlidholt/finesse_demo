import 'package:disco/disco.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// The app-wide settings: light or dark, and the text size.
///
/// Both are provided above `FinesseApp` (see `App` in `main.dart`), so every
/// route — including full-screen ones a screen pushes — can read them. The
/// Settings screen writes them, and so does the shell's dark-mode button.

final themeModeProvider = Provider((_) => Signal(ThemeMode.light));

/// The text scale the whole app is shown at, in place of the platform's.
///
/// Applied through `MediaQuery` in `App`, not through the theme, so a drag
/// of the Settings slider builds no theme.
final textScaleProvider = Provider((_) => Signal(1.0));

/// Every provider above, for the `ProviderScope` at the root of the app (and
/// of a test that pumps part of it).
final appProviders = <Provider<Object>>[
  themeModeProvider,
  textScaleProvider,
];

/// Flips between light and dark.
void toggleThemeMode(BuildContext context) {
  themeModeProvider
      .of(context)
      .updateValue(
        (mode) => mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );
}
