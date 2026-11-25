import 'package:disco/disco.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// The places the Demo shell can show.
///
/// Home, Jobs, Messages and Profile are the four designed screens. Network
/// and Notifications are in the designs' navigation but were never drawn;
/// they are built in the same style, from the same pieces.
enum DemoDestination { home, network, jobs, messages, notifications, profile }

/// The destination the Demo shell is showing.
///
/// Provided above the whole app, so a screen — or a full-screen route a
/// screen pushed — navigates by writing to it:
///
/// ```dart
/// demoDestinationProvider.of(context).value = DemoDestination.jobs;
/// // or, shorter:
/// context.goTo(DemoDestination.jobs);
/// ```
final demoDestinationProvider = Provider(
  (_) => Signal(DemoDestination.home),
);

/// Navigation shortcuts for the Demo screens.
extension DemoNavigation on BuildContext {
  /// Switches the Demo shell to [destination].
  void goTo(DemoDestination destination) =>
      demoDestinationProvider.of(this).value = destination;

  /// Switches the Demo shell to [destination] from anywhere, closing
  /// whatever full-screen routes are open over it — a search page, a
  /// settings page — on the way.
  ///
  /// Call it with the context of a screen or of a pushed page, not with a
  /// dialog's own: a dialog lives in another navigator, and closes itself.
  void leaveTo(DemoDestination destination) {
    Navigator.of(this).popUntil((route) => route.isFirst);
    goTo(destination);
  }
}

/// Routes for the Demo screens.
extension DemoRoutes on BuildContext {
  /// Pushes a page that takes the whole Demo viewport, covering the
  /// shell's app bar and bottom navigation — a conversation on a phone, a
  /// search page. See the note on full-screen routes in `demo_shell.dart`.
  ///
  /// The page should be a `Scaffold` with its own `AppBar`; it pops itself
  /// with `Navigator.of(context).pop()`.
  Future<T?> pushFullScreen<T>(WidgetBuilder builder) =>
      Navigator.of(this).push<T>(FinessePageRoute<T>(builder: builder));
}
