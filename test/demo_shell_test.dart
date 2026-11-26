import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/demo_shell.dart';
import 'package:una_demo/main.dart';
import 'package:una_demo/screens/home_screen.dart';
import 'package:una_demo/screens/jobs_screen.dart';
import 'package:una_demo/screens/messages_screen.dart';
import 'package:una_demo/screens/network_screen.dart';
import 'package:una_demo/screens/notifications_screen.dart';
import 'package:una_demo/screens/profile_screen.dart';
import 'package:una_demo/screens/search_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_logo.dart';
import 'package:una_demo/widgets/person_avatar.dart';

import 'support.dart';

void main() {
  setUpAll(setUpFonts);

  Finder inTopBar(Finder finder) =>
      find.descendant(of: find.byType(NavigationBar), matching: finder);
  Finder inBottomBar(Finder finder) =>
      find.descendant(of: find.byType(BottomNavigationBar), matching: finder);
  Finder inAppBar(Finder finder) =>
      find.descendant(of: find.byType(AppBar), matching: finder);

  DemoDestination destination(WidgetTester tester) =>
      demoDestinationProvider.of(appContext(tester)).value;

  /// Opens the menu behind [trigger] and waits out its entrance animation,
  /// during which the items ignore the pointer.
  Future<void> openMenu(WidgetTester tester, Finder trigger) async {
    await tester.tap(trigger);
    await settle(tester);
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  group('on a desktop (1440x900)', () {
    testWidgets('the app opens on Demo with the top navigation', (
      tester,
    ) async {
      await pumpApp(tester);

      expect(find.byType(DemoShell), findsOneWidget);
      expect(Theme.of(appContext(tester)).formFactor, FormFactor.desktop);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      // Logo, search, the five destinations with their unread counts.
      expect(inAppBar(find.byType(DemoLogo)), findsOneWidget);
      expect(find.text('demo'), findsOneWidget);
      expect(inAppBar(find.byType(SearchField)), findsOneWidget);
      expect(find.text('Search people, posts, jobs'), findsOneWidget);
      // The key cap names the platform's chord: Ctrl K off Apple's.
      expect(find.text(SearchField.shortcutLabel), findsOneWidget);
      for (final label in [
        'Home',
        'Network',
        'Jobs',
        'Messages',
        'Notifications',
      ]) {
        expect(inTopBar(find.text(label)), findsOneWidget, reason: label);
      }
      expect(inTopBar(find.text('Me')), findsNothing);
      // Two conversations have something unread; twelve notifications do.
      expect(inTopBar(find.text('2')), findsOneWidget);
      expect(inTopBar(find.text('12')), findsOneWidget);
      // Home is selected: its filled icon, the others regular.
      expect(inTopBar(find.byIcon(PhosphorIconsFill.house)), findsOneWidget);
      expect(
        inTopBar(find.byIcon(PhosphorIconsRegular.briefcase)),
        findsOneWidget,
      );
      // The dark-mode button and the avatar pill.
      expect(inAppBar(find.byIcon(PhosphorIconsRegular.moon)), findsOneWidget);
      expect(inAppBar(find.byType(PersonAvatar)), findsOneWidget);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping a destination switches screens', (tester) async {
      await pumpApp(tester);

      await tapAndSettle(tester, inTopBar(find.text('Jobs')));
      expect(destination(tester), DemoDestination.jobs);
      expect(find.byType(JobsScreen), findsOneWidget);
      // Still alive, but offstage.
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(HomeScreen, skipOffstage: false), findsOneWidget);
      expect(
        inTopBar(find.byIcon(PhosphorIconsFill.briefcase)),
        findsOneWidget,
      );

      await tapAndSettle(tester, inTopBar(find.text('Messages')));
      expect(find.byType(MessagesScreen), findsOneWidget);

      await tapAndSettle(tester, inTopBar(find.text('Network')));
      expect(find.byType(NetworkScreen), findsOneWidget);
      expect(find.text('People you may know'), findsOneWidget);

      await tapAndSettle(tester, inTopBar(find.text('Notifications')));
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.text('12 unread notifications.'), findsOneWidget);
      // No destination is a placeholder any more.
      expect(
        find.textContaining('not part of the Demo designs'),
        findsNothing,
      );

      // The logo goes home.
      await tapAndSettle(tester, find.byType(DemoLogo));
      expect(destination(tester), DemoDestination.home);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the bell counts the unread notifications', (tester) async {
      await pumpApp(tester);
      final notifications = demoSessionProvider
          .of(appContext(tester))
          .notifications;
      expect(inTopBar(find.text('12')), findsOneWidget);

      await tapAndSettle(tester, inTopBar(find.text('Notifications')));
      // Opening a row reads it.
      await tapAndSettle(tester, find.textContaining('mentioned you').first);
      expect(notifications.unreadCount, 11);
      expect(destination(tester), DemoDestination.home);
      expect(inTopBar(find.text('11')), findsOneWidget);
      expect(inTopBar(find.text('12')), findsNothing);

      await tapAndSettle(tester, inTopBar(find.text('Notifications')));
      await tapAndSettle(
        tester,
        find.widgetWithText(Button, 'Mark all as read'),
      );
      // No count, no badge; the messages' "2" is untouched.
      expect(inTopBar(find.text('11')), findsNothing);
      expect(inTopBar(find.text('2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the avatar menu leads to the profile, saved items, settings '
        'and dark mode', (tester) async {
      await pumpApp(tester);
      final pill = inAppBar(find.byIcon(PhosphorIconsRegular.caretDown));

      await openMenu(tester, pill);
      // Once in the menu's header and once on the Home feed's profile card.
      expect(find.text('Noor Haddad'), findsNWidgets(2));
      // The Home rail has saved items and settings of its own.
      expect(find.text('Saved items'), findsWidgets);
      expect(find.text('Dark mode'), findsOneWidget);

      await tapAndSettle(tester, find.text('View profile'));
      expect(destination(tester), DemoDestination.profile);
      expect(find.byType(ProfileScreen), findsOneWidget);
      // Profile is not a top-bar destination, so nothing reads as selected.
      expect(inTopBar(find.byIcon(PhosphorIconsFill.house)), findsNothing);

      await openMenu(tester, pill);
      await tapAndSettle(tester, find.text('Dark mode'));
      expect(Theme.of(appContext(tester)).brightness, Brightness.dark);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the dark-mode button flips the whole app', (tester) async {
      await pumpApp(tester);
      expect(Theme.of(appContext(tester)).brightness, Brightness.light);

      await tapAndSettle(
        tester,
        inAppBar(find.byIcon(PhosphorIconsRegular.moon)),
      );
      expect(Theme.of(appContext(tester)).brightness, Brightness.dark);
      expect(inAppBar(find.byIcon(PhosphorIconsRegular.sun)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a full-screen route covers the shell, and keeps the theme '
        'and the providers', (tester) async {
      await pumpApp(tester);

      // What a screen does: push from its own context.
      final screen = tester.element(find.byType(HomeScreen));
      screen.pushFullScreen<void>((context) => const SearchScreen());
      await settle(tester);

      expect(find.byType(SearchScreen), findsOneWidget);
      // The shell's chrome is underneath.
      expect(find.byType(NavigationBar), findsNothing);

      // The route follows the app's theme mode live…
      final route = tester.element(find.byType(SearchScreen));
      toggleThemeMode(route);
      await settle(tester);
      expect(
        Theme.of(tester.element(find.byType(SearchScreen))).brightness,
        Brightness.dark,
      );
      // …and can navigate the shell beneath it.
      route.goTo(DemoDestination.jobs);
      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byType(JobsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the app bar gives way without overflowing at every width '
        'down to the phone breakpoint', (tester) async {
      for (final width in [1280.0, 1100.0, 1024.0, 960.0, 840.0, 768.0]) {
        await pumpApp(tester, size: Size(width, 800));
        // The destinations are in the top bar while it has room for them,
        // and in a rail down the start edge below that.
        final inTopBar = width >= DemoShell.topBarFrom;
        expect(
          find.byType(NavigationBar),
          inTopBar ? findsOneWidget : findsNothing,
          reason: '$width',
        );
        expect(
          find.byType(NavigationRail),
          inTopBar ? findsNothing : findsOneWidget,
          reason: '$width',
        );
        expect(tester.takeException(), isNull, reason: 'at $width');
      }
    });

    testWidgets('the rail lists the five destinations and the compose '
        'action, switches screens, and is wide enough for its labels', (
      tester,
    ) async {
      await pumpApp(tester, size: const Size(900, 1100));
      Finder inRail(Finder finder) =>
          find.descendant(of: find.byType(NavigationRail), matching: finder);

      for (final label in [
        'Home',
        'Network',
        'Jobs',
        'Messages',
        'Notifications',
      ]) {
        expect(inRail(find.text(label)), findsOneWidget, reason: label);
      }
      // A step wider than the package's rail, so "Notifications" fits.
      expect(
        tester.getSize(find.byType(NavigationRail)).width,
        greaterThan(ThemeData().navigationRailTheme.width!),
      );
      expect(inRail(find.text('Me')), findsNothing);
      // The unread counts ride along.
      expect(inRail(find.text('2')), findsOneWidget);
      expect(inRail(find.text('12')), findsOneWidget);
      // With the rail, the bar has room for the search field itself.
      expect(inAppBar(find.byType(SearchField)), findsOneWidget);

      await tapAndSettle(tester, inRail(find.text('Jobs')));
      expect(destination(tester), DemoDestination.jobs);
      expect(find.byType(JobsScreen), findsOneWidget);

      // The round button at the top of the rail composes a post.
      await tapAndSettle(
        tester,
        inRail(find.byIcon(PhosphorIconsRegular.plus)),
      );
      expect(find.text('Create post'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a screen keeps its state when the window is resized between '
        'the top bar and the rail', (tester) async {
      await pumpApp(tester, size: const Size(1280, 900));
      final home = tester.element(find.byType(HomeScreen));
      tester.view.physicalSize = const Size(900, 900);
      await settle(tester);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.element(find.byType(HomeScreen)), same(home));
      tester.view.physicalSize = const Size(1280, 900);
      await settle(tester);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.element(find.byType(HomeScreen)), same(home));
      expect(tester.takeException(), isNull);
    });

    testWidgets('choosing the destination that is showing scrolls it back '
        'to the top', (tester) async {
      await pumpApp(tester);
      final position = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(HomeScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      position.jumpTo(600);
      await settle(tester, frames: 2);
      expect(position.pixels, 600);

      await tapAndSettle(tester, inTopBar(find.text('Home')));
      await settle(tester);
      expect(position.pixels, 0);
      expect(destination(tester), DemoDestination.home);

      // On a phone, from the bottom bar.
      await pumpApp(tester, size: mobileSize);
      final phone = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(HomeScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      phone.jumpTo(400);
      await settle(tester, frames: 2);
      await tapAndSettle(
        tester,
        inBottomBar(find.byIcon(PhosphorIconsFill.house)),
      );
      await settle(tester);
      expect(phone.pixels, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search is reachable at every width: the field, then a '
        'magnifier in the bar', (tester) async {
      for (final width in [
        1280.0,
        1100.0,
        1024.0,
        960.0,
        900.0,
        840.0,
        768.0,
      ]) {
        await pumpApp(tester, size: Size(width, 800));
        // Either the field itself or the magnifier that opens the page, and
        // never both.
        final field = inAppBar(find.byType(SearchField)).hitTestable();
        final magnifier = inAppBar(
          find.widgetWithIcon(
            IconButton,
            PhosphorIconsRegular.magnifyingGlass,
          ),
        ).hitTestable();
        expect(
          field.evaluate().length + magnifier.evaluate().length,
          1,
          reason: 'at $width',
        );
        expect(tester.takeException(), isNull, reason: 'at $width');
      }

      // Where the top bar is at its narrowest the field is a magnifier,
      // which opens the search page.
      await pumpApp(tester, size: const Size(1024, 800));
      await tapAndSettle(
        tester,
        inAppBar(
          find.widgetWithIcon(
            IconButton,
            PhosphorIconsRegular.magnifyingGlass,
          ),
        ).hitTestable(),
      );
      expect(find.byType(SearchScreen), findsOneWidget);
    });
  });

  group('on a phone (390x844)', () {
    testWidgets('the app opens on Demo with the bottom navigation', (
      tester,
    ) async {
      await pumpApp(tester, size: mobileSize);

      expect(find.byType(DemoShell), findsOneWidget);
      expect(Theme.of(appContext(tester)).formFactor, FormFactor.mobile);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // The app bar: logo, then search, notifications (12), messages (2).
      expect(inAppBar(find.byType(DemoLogo)), findsOneWidget);
      expect(find.byType(SearchField), findsNothing);
      expect(
        inAppBar(find.byIcon(PhosphorIconsRegular.magnifyingGlass)),
        findsOneWidget,
      );
      expect(inAppBar(find.byIcon(PhosphorIconsRegular.bell)), findsOneWidget);
      expect(
        inAppBar(find.byIcon(PhosphorIconsRegular.chatCircleDots)),
        findsOneWidget,
      );
      expect(inAppBar(find.text('12')), findsOneWidget);
      expect(inAppBar(find.text('2')), findsOneWidget);
      expect(
        tester.getSize(
          find.ancestor(
            of: find.byIcon(PhosphorIconsRegular.bell),
            matching: find.byType(IconButton),
          ),
        ),
        const Size.square(44),
      );

      // The bottom bar: Home, Network, Create post, Jobs, Me.
      expect(inBottomBar(find.byIcon(PhosphorIconsFill.house)), findsOneWidget);
      expect(
        inBottomBar(find.byIcon(PhosphorIconsRegular.usersThree)),
        findsOneWidget,
      );
      expect(
        inBottomBar(find.byIcon(PhosphorIconsRegular.plus)),
        findsOneWidget,
      );
      expect(
        inBottomBar(find.byIcon(PhosphorIconsRegular.briefcase)),
        findsOneWidget,
      );
      expect(inBottomBar(find.byType(PersonAvatar)), findsOneWidget);
      expect(
        inBottomBar(find.byIcon(PhosphorIconsRegular.chatCircleDots)),
        findsNothing,
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the bars switch screens', (tester) async {
      await pumpApp(tester, size: mobileSize);

      await tapAndSettle(
        tester,
        inBottomBar(find.byIcon(PhosphorIconsRegular.briefcase)),
      );
      expect(find.byType(JobsScreen), findsOneWidget);

      await tapAndSettle(
        tester,
        inBottomBar(find.byIcon(PhosphorIconsRegular.usersThree)),
      );
      expect(find.byType(NetworkScreen), findsOneWidget);

      // Messages and notifications live in the app bar on a phone.
      await tapAndSettle(
        tester,
        inAppBar(find.byIcon(PhosphorIconsRegular.chatCircleDots)),
      );
      expect(destination(tester), DemoDestination.messages);
      expect(find.byType(MessagesScreen), findsOneWidget);

      await tapAndSettle(
        tester,
        inAppBar(find.byIcon(PhosphorIconsRegular.bell)),
      );
      expect(destination(tester), DemoDestination.notifications);
      expect(find.byType(NotificationsScreen), findsOneWidget);

      // "Me" opens the profile, which has no app bar over its cover.
      await tapAndSettle(tester, inBottomBar(find.byType(PersonAvatar)));
      expect(destination(tester), DemoDestination.profile);
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      await tapAndSettle(
        tester,
        inBottomBar(find.byIcon(PhosphorIconsRegular.house)),
      );
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('search opens as a full-screen route', (tester) async {
      await pumpApp(tester, size: mobileSize);

      await tapAndSettle(
        tester,
        inAppBar(find.byIcon(PhosphorIconsRegular.magnifyingGlass)),
      );
      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(SearchField), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);

      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.byType(SearchScreen), findsNothing);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the create-post action opens the composer', (tester) async {
      await pumpApp(tester, size: mobileSize);

      await tapAndSettle(
        tester,
        inBottomBar(find.byIcon(PhosphorIconsRegular.plus)),
      );
      expect(find.text('Create post'), findsOneWidget);
      expect(find.text('Start a post, Noor…'), findsOneWidget);

      await tapAndSettle(tester, find.text('Cancel'));
      expect(find.text('Create post'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("the profile's menu is the phone's user menu", (
      tester,
    ) async {
      await pumpApp(tester, size: mobileSize);
      await tapAndSettle(tester, inBottomBar(find.byType(PersonAvatar)));

      await openMenu(tester, find.byIcon(PhosphorIconsRegular.dotsThree));
      expect(find.text('View profile'), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);

      await tapAndSettle(tester, find.text('Dark mode'));
      expect(Theme.of(appContext(tester)).brightness, Brightness.dark);
      expect(tester.takeException(), isNull);
    });
  });
}
