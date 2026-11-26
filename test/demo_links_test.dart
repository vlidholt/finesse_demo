import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/applications_data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/data/network_data.dart';
import 'package:una_demo/demo_shell.dart';
import 'package:una_demo/screens/home_screen.dart';
import 'package:una_demo/screens/network_screen.dart';
import 'package:una_demo/screens/profile_screen.dart';
import 'package:una_demo/screens/search_screen.dart';
import 'package:una_demo/screens/settings_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/network_section_view.dart';
import 'package:una_demo/widgets/settings_controller.dart';

import 'demo_support.dart';
import 'support.dart';

// Everything the designs drew without designing a destination for — a
// shortcut, a "See all", a story, a footer link — leads somewhere. These go
// through the whole app, because most of them cross from one screen to
// another.

void main() {
  setUpAll(setUpFonts);

  DemoSession session(WidgetTester tester) =>
      demoSessionProvider.of(appContext(tester));

  DemoDestination destination(WidgetTester tester) =>
      demoDestinationProvider.of(appContext(tester)).value;

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  Future<void> goTo(WidgetTester tester, DemoDestination target) async {
    demoDestinationProvider.of(appContext(tester)).value = target;
    await settle(tester);
  }

  Finder inHome(Finder finder) =>
      find.descendant(of: find.byType(HomeScreen), matching: finder);

  group('on the home feed (1440)', () {
    testWidgets('the profile card\'s shortcuts open saved items, groups and '
        'events', (tester) async {
      await pumpApp(tester);

      await tapAndSettle(tester, inHome(find.text('Saved items')));
      final sheet = find.byType(Sheet);
      expect(sheet, findsOneWidget);
      expect(find.text('Posts and articles · 3'), findsOneWidget);
      // The jobs are the board's "Saved" column: its count, its first two.
      final saved = session(tester).applications.at(ApplicationStage.saved);
      expect(find.text('Jobs · ${saved.length}'), findsOneWidget);
      expect(find.text('See all ${saved.length} saved jobs'), findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text(saved[1].title)),
        findsOneWidget,
      );
      // A saved job leads to Jobs.
      await tester.tap(
        find.descendant(of: sheet, matching: find.text(saved.first.title)),
      );
      await settle(tester);
      expect(sheet, findsNothing);
      expect(destination(tester), DemoDestination.jobs);

      await goTo(tester, DemoDestination.home);
      await tapAndSettle(tester, inHome(find.text('Groups')));
      expect(find.byType(NetworkScreen), findsOneWidget);
      expect(session(tester).network.section, NetworkSection.groups);
      expect(find.text('You are in 3 groups'), findsOneWidget);

      await goTo(tester, DemoDestination.home);
      await tapAndSettle(tester, inHome(find.text('Events')));
      expect(session(tester).network.section, NetworkSection.events);
      expect(find.byType(NetworkSectionView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"See all" and "Show all suggestions" lead to Network', (
      tester,
    ) async {
      await pumpApp(tester);

      await tapAndSettle(tester, inHome(find.text('See all')));
      expect(session(tester).network.section, NetworkSection.groups);
      expect(destination(tester), DemoDestination.network);

      await goTo(tester, DemoDestination.home);
      await tapAndSettle(tester, inHome(find.text('Show all suggestions')));
      expect(destination(tester), DemoDestination.network);
    });

    testWidgets('a story, an author and an article open in place', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.bySemanticsLabel('Julian Reyes’s story').first);
      await settle(tester);
      expect(find.text('Reply to Julian'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Close'));
      await settle(tester);
      expect(find.text('Reply to Julian'), findsNothing);

      // The author of the first post.
      await tapAndSettle(
        tester,
        find
            .descendant(
              of: find.byKey(ValueKey(HomeData.onboardingWorkshop.id)),
              matching: find.text('Omar Rahimi'),
            )
            .first,
      );
      final dialog = find.byType(Dialog);
      expect(
        find.descendant(of: dialog, matching: find.text('Stockholm, Sweden')),
        findsOneWidget,
      );
      // Omar is a connection: nothing to request.
      expect(
        find.descendant(of: dialog, matching: find.text('Connected')),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsLabel('Close'));
      await settle(tester);

      await tapAndSettle(
        tester,
        inHome(find.textContaining('Designing for calm')),
      );
      expect(find.widgetWithText(Button, 'Save'), findsOneWidget);
      await tester.tap(find.widgetWithText(Button, 'Done'));
      await settle(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a comment can be answered and posted', (tester) async {
      await pumpApp(tester);

      await tapAndSettle(tester, inHome(find.text('Reply')).first);
      final field = find.widgetWithText(TextField, '@Freya Holm ');
      expect(field, findsOneWidget);

      await tester.enterText(field, '@Freya Holm It did, for two weeks.');
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await settle(tester);
      expect(find.text('Comment posted'), findsOneWidget);
      expect(find.widgetWithText(TextField, '@Freya Holm '), findsNothing);

      // "Send" offers people to send the post to.
      await tapAndSettle(tester, inHome(find.text('Send')).first);
      expect(find.text('Send to'), findsOneWidget);
      await tester.tap(find.text('Send').last);
      await settle(tester, frames: 4);
      expect(find.text('Sent'), findsOneWidget);
      await tester.tap(find.widgetWithText(Button, 'Done'));
      await dismissToasts(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the footer says what Demo is, or opens Settings', (
      tester,
    ) async {
      await pumpApp(tester);

      await tapAndSettle(tester, inHome(find.text('About')));
      expect(find.text('About Demo'), findsOneWidget);
      expect(
        find.textContaining('fictional professional network'),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(Button, 'Close'));
      await settle(tester);

      await tapAndSettle(tester, inHome(find.text('Privacy')));
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(session(tester).settings.section, SettingsSection.privacy);
      // A section header, in the style's overline case.
      expect(
        find.text(
          Theme.of(
            tester.element(find.byType(SettingsScreen)),
          ).style.overline.applyCase('Profile visibility'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Saved items" lists the jobs saved since, newest first', (
      tester,
    ) async {
      await pumpApp(tester);
      // Save a listing, as its bookmark on "Find jobs" does.
      final job = JobsData.jobs.first;
      session(tester).jobs.toggleSaved(job);
      await settle(tester, frames: 2);

      await tapAndSettle(tester, inHome(find.text('Saved items')));
      final sheet = find.byType(Sheet);
      expect(find.text('Jobs · 7'), findsOneWidget);
      expect(find.text('See all 7 saved jobs'), findsOneWidget);
      expect(
        find.descendant(of: sheet, matching: find.text(job.title)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the About dialog still closes when the footer it was '
        'opened from is gone', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, inHome(find.text('About')));
      expect(find.text('About Demo'), findsOneWidget);

      // The window narrows under the open dialog: the phone layout has no
      // right rail, so the footer that opened the dialog is unmounted.
      tester.view.physicalSize = mobileSize;
      await settle(tester, frames: 16);
      expect(find.text('About Demo'), findsOneWidget);
      expect(inHome(find.text('About')), findsNothing);

      await tester.tap(find.widgetWithText(Button, 'Close'));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('About Demo'), findsNothing);
    });
  });

  group('on the profile (1440)', () {
    testWidgets('editing leads to Settings, and "See all" to the Media tab', (
      tester,
    ) async {
      await pumpApp(tester);
      await goTo(tester, DemoDestination.profile);
      Finder inProfile(Finder finder) =>
          find.descendant(of: find.byType(ProfileScreen), matching: finder);

      await tapAndSettle(tester, inProfile(find.text('See all')));
      expect(inProfile(find.text('Featured')), findsNothing);

      await tapAndSettle(
        tester,
        inProfile(find.bySemanticsLabel('Edit profile')),
      );
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(session(tester).settings.section, SettingsSection.account);

      // "View profile" there closes the page and stays on the profile.
      await tapAndSettle(tester, find.widgetWithText(Button, 'View profile'));
      expect(find.byType(SettingsScreen), findsNothing);
      expect(destination(tester), DemoDestination.profile);

      await tapAndSettle(tester, inProfile(find.text('Share profile')));
      expect(find.text('Profile link copied'), findsOneWidget);
      await dismissToasts(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('on a phone (390x844)', () {
    testWidgets('a list of the network opens as a page over the feed', (
      tester,
    ) async {
      await pumpApp(tester, size: mobileSize);
      final shell = tester.element(find.byType(DemoShell));

      // What the home feed's "Events" shortcut does; a phone has no rail
      // to tap it in.
      demoSessionProvider
          .of(shell)
          .network
          .toggleAttending(
            NetworkData.events[1],
          );
      shell.pushFullScreen<void>(
        (context) => NetworkSectionPage(
          section: NetworkSection.events,
          controller: demoSessionProvider.of(context).network,
        ),
      );
      await settle(tester);

      expect(find.text('You are going to 2 events'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
      await tester.tap(find.byType(BackButton));
      await settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the magnifier opens search, and a result closes it', (
      tester,
    ) async {
      await pumpApp(tester, size: mobileSize);

      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(PhosphorIconsRegular.magnifyingGlass),
        ),
      );
      await settle(tester);
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.text('Trending searches'), findsOneWidget);

      await tester.tap(find.widgetWithText(Chip, 'Product designer'));
      await settle(tester);
      await tapAndSettle(
        tester,
        find.text('Product designer, Editor', findRichText: true),
      );
      expect(find.byType(SearchScreen), findsNothing);
      expect(destination(tester), DemoDestination.jobs);
    });
  });
}
