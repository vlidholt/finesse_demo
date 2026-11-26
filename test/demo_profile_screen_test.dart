import 'package:disco/disco.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/app_state.dart';
import 'package:una_demo/data/profile_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/screens/profile_screen.dart';
import 'package:una_demo/screens/search_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/profile_about_cards.dart';
import 'package:una_demo/widgets/profile_common.dart';
import 'package:una_demo/widgets/profile_experience.dart';
import 'package:una_demo/widgets/profile_header_card.dart';
import 'package:una_demo/widgets/profile_mobile_header.dart';
import 'package:una_demo/widgets/profile_rail.dart';
import 'package:una_demo/widgets/profile_tab_content.dart';
import 'package:una_demo/widgets/user_menu.dart';

const _desktop = Size(1440, 1000);
const _laptop = Size(1024, 800);
const _tablet = Size(768, 900);
const _phone = Size(390, 844);

/// Pumps the Profile screen on its own — not through the shell, which
/// imports the other screens — below the providers it reads.
Future<void> _pumpProfile(
  WidgetTester tester, {
  required Size size,
  Brightness brightness = Brightness.light,
  FakeViewPadding padding = FakeViewPadding.zero,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      providers: [
        ...appProviders,
        demoDestinationProvider,
        demoSessionProvider,
      ],
      child: UnaApp(
        theme: ThemeData(brightness: brightness),
        home: const Scaffold(body: ProfileScreen()),
      ),
    ),
  );
  await _settle(tester, frames: 2);
}

/// Pumps fixed frames: enough for a menu's entrance, during which its items
/// ignore the pointer.
Future<void> _settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

BuildContext _context(WidgetTester tester) =>
    tester.element(find.byType(ProfileScreen));

Finder _tab(String label) => find.descendant(
  of: find.byType(TabBar<ProfileTab>),
  matching: find.text(label),
);

/// One of the phone bar's three round buttons.
Finder _coverButton(String label) => find.descendant(
  of: find.byType(ProfileMobileBar),
  matching: find.byWidgetPredicate(
    (widget) => widget is IconButton && widget.semanticLabel == label,
  ),
);

/// The page's scroll position on a phone.
ScrollPosition _pagePosition(WidgetTester tester) =>
    tester.state<ScrollableState>(find.byType(Scrollable).first).position;

/// A run of text that mixes weights, such as "1,284 followers".
Finder _richText(String pattern) =>
    find.textContaining(pattern, findRichText: true);

void main() {
  group('builds without overflowing', () {
    for (final size in [_desktop, _laptop, _tablet, _phone]) {
      for (final brightness in Brightness.values) {
        testWidgets('at ${size.width.toInt()}x${size.height.toInt()}, '
            '${brightness.name}', (tester) async {
          await _pumpProfile(tester, size: size, brightness: brightness);

          expect(tester.takeException(), isNull);
          // On a phone the name is the bar's title, which draws it twice:
          // large on the cover and small in the toolbar.
          expect(
            _richText('Noor Haddad'),
            size == _phone ? findsNWidgets(2) : findsOneWidget,
          );

          // Every tab, not only the designed one.
          final tabs = size == _phone ? ProfileTab.mobile : ProfileTab.values;
          for (final tab in tabs) {
            await tester.tap(_tab(tab.label));
            await _settle(tester, frames: 2);
            expect(tester.takeException(), isNull, reason: tab.label);
          }
        });
      }
    }
  });

  testWidgets('does not overflow at any width from a small phone to the '
      'design\'s desktop', (tester) async {
    await _pumpProfile(tester, size: const Size(320, 800));
    for (var width = 320.0; width <= 1440; width += 16) {
      tester.view.physicalSize = Size(width, 800);
      // Long enough for the theme to finish changing form factor.
      await _settle(tester, frames: 6);
      expect(tester.takeException(), isNull, reason: 'at $width wide');
    }
  });

  group('on a desktop', () {
    testWidgets('shows the designed header', (tester) async {
      await _pumpProfile(tester, size: _desktop);

      expect(find.byType(ProfileHeaderCard), findsOneWidget);
      expect(find.byType(ProfileMobileHeader), findsNothing);
      for (final text in [
        'Edit cover',
        'Share profile',
        'Noor Haddad',
        'she/her',
        ProfileData.headline,
        'noorhaddad.design',
        'Halcyon',
        'Open to',
        'Add section',
        'Resources',
        'Open to work',
        'Design lead and principal designer roles · Remote or Copenhagen',
        'Show details',
        'Available for talks',
        'Design systems, research ops and accessible product design',
        'Get in touch',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(
        _richText('connections · Omar, Sara and 18 others you know'),
        findsOneWidget,
      );
      // The meta row; the Experience card under it repeats the city.
      expect(
        find.descendant(
          of: find.byType(ProfileHeaderCard),
          matching: find.text('Copenhagen, Denmark'),
        ),
        findsOneWidget,
      );
      expect(find.byType(AvatarGroup), findsOneWidget);
      for (final tab in ProfileTab.values) {
        expect(_tab(tab.label), findsOneWidget, reason: tab.label);
      }
      expect(
        tester
            .widget<TabBar<ProfileTab>>(find.byType(TabBar<ProfileTab>))
            .value,
        ProfileTab.about,
      );
    });

    testWidgets('shows the About tab\'s cards', (tester) async {
      await _pumpProfile(tester, size: const Size(1440, 2400));

      for (final text in [
        'Analytics',
        'Private to you',
        '1,128',
        'Profile viewers this month',
        '24,310',
        'Post impressions',
        '312',
        'Search appearances',
        '12%',
        '38%',
        '6%',
        ProfileData.about,
        'Top skills',
        ...ProfileData.skills,
        'Featured',
        'See all',
        'Talk',
        'Calm by default: designing for focus',
        'Config Nordics · 2.4k views',
        'Case study',
        'Rebuilding onboarding in two days',
        'Post · 812 reactions',
        'Article',
        'What we learned from 40 interviews',
        'Article · 6 min read',
        'Senior product designer',
        'Halcyon · Full-time · Hybrid',
        'Jan 2023 – Present · 3 yrs',
        'Product designer',
        'Birchline · Full-time',
        'Mar 2020 – Dec 2022 · 2 yrs 10 mos',
        'Stockholm, Sweden',
        'UX designer',
        'Lumen Labs · Full-time',
        'Aug 2017 – Feb 2020 · 2 yrs 7 mos',
        'Amman, Jordan',
        'Education',
        'MA, Interaction Design',
        '2015 – 2017',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.byType(Chip), findsNWidgets(ProfileData.skills.length));
      expect(find.byType(Timeline), findsOneWidget);
      // The meta row and the Education card.
      expect(find.text('Nordhavn School of Design'), findsNWidgets(2));
    });

    testWidgets('shows the rail', (tester) async {
      await _pumpProfile(tester, size: _desktop);

      for (final text in [
        'Profile language',
        'English',
        'Public profile and URL',
        'demo.app/in/noorhaddad',
        'People also viewed',
        'Sara Lindqvist',
        'Head of Research at Birchline',
        'Omar Rahimi',
        'Irina Volkova',
        'Mateo Alvarez',
        'Follow',
        'Message',
        'Your groups',
        'Design Systems Guild',
        '18,402 members',
        'Copenhagen Product Circle',
        'Accessibility Collective',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(find.text('Connect'), findsNWidgets(2));
    });

    testWidgets('puts the rail beside the main column, centred at 1200', (
      tester,
    ) async {
      await _pumpProfile(tester, size: _desktop);

      final header = tester.getRect(find.byType(ProfileHeaderCard));
      final rail = tester.getRect(find.byType(ProfileSettingsCard));
      // (1440 - 1200) / 2 + the 24 page margin.
      expect(header.left, 144);
      expect(header.width, 788);
      expect(rail.left, header.right + 24);
      expect(rail.width, 340);
      expect(rail.top, header.top);
    });

    testWidgets('moves the rail under the main column when they do not fit', (
      tester,
    ) async {
      await _pumpProfile(tester, size: const Size(768, 4000));

      final header = tester.getRect(find.byType(ProfileHeaderCard));
      final education = tester.getRect(find.byType(ProfileEducationCard));
      final rail = tester.getRect(find.byType(ProfileSettingsCard));
      expect(header.width, 768 - 48);
      expect(rail.width, header.width);
      expect(rail.top, greaterThan(education.bottom));
    });

    testWidgets('keeps both columns at 1024', (tester) async {
      await _pumpProfile(tester, size: _laptop);

      final header = tester.getRect(find.byType(ProfileHeaderCard));
      final rail = tester.getRect(find.byType(ProfileSettingsCard));
      expect(rail.left, header.right + 24);
      expect(rail.width, 340);
    });

    testWidgets('the tabs switch the cards under the header', (tester) async {
      await _pumpProfile(tester, size: const Size(1440, 2400));
      expect(find.byType(ProfileAnalyticsCard), findsOneWidget);

      await tester.tap(_tab('Experience'));
      await _settle(tester, frames: 2);
      expect(find.byType(ProfileAnalyticsCard), findsNothing);
      expect(find.byType(ProfileAboutCard), findsNothing);
      expect(find.byType(ProfileExperienceCard), findsOneWidget);
      expect(find.byType(ProfileEducationCard), findsOneWidget);
      // The header and the rail stay.
      expect(find.byType(ProfileHeaderCard), findsOneWidget);
      expect(find.byType(ProfilePeopleCard), findsOneWidget);

      await tester.tap(_tab('Posts'));
      await _settle(tester, frames: 2);
      expect(
        find.byType(ProfilePostCard),
        findsNWidgets(ProfileData.posts.length),
      );
      expect(find.byType(ProfileExperienceCard), findsNothing);

      await tester.tap(_tab('Activity'));
      await _settle(tester, frames: 2);
      expect(find.byType(ProfileActivityCard), findsOneWidget);
      expect(_richText('Commented on Omar Rahimi’s post'), findsOneWidget);

      await tester.tap(_tab('Media'));
      await _settle(tester, frames: 2);
      expect(find.byType(ProfileMediaCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ProfileMediaCard),
          matching: find.byType(Image),
        ),
        findsNWidgets(ProfileData.media.length),
      );

      await tester.tap(_tab('About'));
      await _settle(tester, frames: 2);
      expect(find.byType(ProfileAnalyticsCard), findsOneWidget);
      expect(find.byType(ProfileFeaturedCard), findsOneWidget);
    });

    testWidgets('Follow and Connect toggle', (tester) async {
      await _pumpProfile(tester, size: _desktop);

      await tester.tap(find.text('Follow'));
      await _settle(tester, frames: 2);
      expect(find.text('Follow'), findsNothing);
      expect(find.text('Following'), findsOneWidget);

      await tester.tap(find.text('Following'));
      await _settle(tester, frames: 2);
      expect(find.text('Follow'), findsOneWidget);
      expect(find.text('Following'), findsNothing);

      await tester.tap(find.text('Connect').first);
      await _settle(tester, frames: 2);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('Message opens Messages', (tester) async {
      await _pumpProfile(tester, size: _desktop);
      final destination = demoDestinationProvider.of(_context(tester));
      destination.value = DemoDestination.profile;

      await tester.tap(find.text('Message'));
      await _settle(tester, frames: 2);
      expect(destination.value, DemoDestination.messages);
    });

    testWidgets('a post\'s like button toggles', (tester) async {
      await _pumpProfile(tester, size: const Size(1440, 2400));
      await tester.tap(_tab('Posts'));
      await _settle(tester, frames: 2);

      expect(find.text('812'), findsOneWidget);
      await tester.tap(find.text('812'));
      await _settle(tester, frames: 2);
      expect(find.text('813'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsFill.heart), findsOneWidget);

      await tester.tap(find.text('813'));
      await _settle(tester, frames: 2);
      expect(find.text('812'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsFill.heart), findsNothing);
    });
  });

  group('on a phone', () {
    testWidgets('shows the designed screen', (tester) async {
      await _pumpProfile(tester, size: const Size(390, 1400));

      expect(find.byType(ProfileMobileBar), findsOneWidget);
      expect(find.byType(ProfileMobileHeader), findsOneWidget);
      expect(find.byType(ProfileHeaderCard), findsNothing);
      // The name is the bar's title: large on the cover, small in the
      // toolbar.
      expect(
        find.descendant(
          of: find.byType(SliverAppBar),
          matching: _richText('Noor Haddad'),
        ),
        findsNWidgets(2),
      );
      for (final text in [
        'Copenhagen',
        '+18 mutual',
        'Product designer at Halcyon. Building calmer tools for busy teams.',
        'Open to',
        'Edit profile',
        'Open to work',
        'Design lead roles · Remote or Copenhagen',
        ProfileData.aboutShort,
        'Design systems',
        'Interaction design',
        'User research',
        'Prototyping',
        'Accessibility',
        'Senior product designer',
        'Halcyon · Full-time · Hybrid',
        'Amman, Jordan',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(_richText('followers ·'), findsOneWidget);
      for (final label in ['Back', 'Search', 'More options']) {
        expect(_coverButton(label), findsOneWidget, reason: label);
      }

      // Four tabs and five skills; none of the desktop-only sections.
      expect(
        tester.widget<TabBar<ProfileTab>>(find.byType(TabBar<ProfileTab>)).tabs,
        hasLength(4),
      );
      expect(_tab('Activity'), findsNothing);
      expect(find.byType(Chip), findsNWidgets(5));
      for (final text in [
        'Figma',
        'Analytics',
        'Featured',
        'Show details',
        'People also viewed',
        'Add experience',
      ]) {
        expect(find.text(text), findsNothing, reason: text);
      }
      expect(find.byType(ProfileAnalyticsCard), findsNothing);
      expect(find.byType(ProfilePeopleCard), findsNothing);
      // The phone's Experience card has no descriptions.
      expect(find.textContaining('Lead designer for'), findsNothing);
    });

    testWidgets('the cover runs to the top of the screen, under the status '
        'bar', (tester) async {
      await _pumpProfile(
        tester,
        size: _phone,
        padding: const FakeViewPadding(top: 47),
      );

      final cover = tester.getRect(
        find.descendant(
          of: find.byType(ProfileMobileBar),
          matching: find.bySemanticsLabel(ProfileData.coverLabel),
        ),
      );
      expect(cover.topLeft, Offset.zero);
      expect(cover.width, 390);
      // The status bar, the toolbar and the cover's own height under it.
      expect(
        cover.height,
        greaterThanOrEqualTo(47 + ProfileMobileBar.coverHeight + 44),
      );

      // The buttons clear the status bar, 12 in from the edge.
      final back = tester.getRect(_coverButton('Back'));
      expect(back.top, greaterThanOrEqualTo(47));
      expect(back.left, 12);
      expect(back.size, const Size.square(44));
      final more = tester.getRect(_coverButton('More options'));
      expect(more.right, 390 - 12);
    });

    testWidgets('scrolling collapses the name into the toolbar, and the '
        'buttons stay', (tester) async {
      await _pumpProfile(tester, size: _phone);
      // The two titles of the bar: large first, as it is laid out.
      Finder names() => find.descendant(
        of: find.byType(SliverAppBar),
        matching: _richText('Noor Haddad'),
      );
      double opacityOf(Finder finder) {
        var opacity = 1.0;
        finder.evaluate().single.visitAncestorElements((element) {
          final widget = element.widget;
          if (widget is Opacity) opacity *= widget.opacity;
          if (widget is FadeTransition) opacity *= widget.opacity.value;
          return widget is! SliverAppBar;
        });
        return opacity;
      }

      final expandedTop = tester.getTopLeft(names().first).dy;
      expect(expandedTop, greaterThan(60), reason: 'under the toolbar');

      _pagePosition(tester).jumpTo(500);
      await _settle(tester, frames: 8);

      // The toolbar is still at the top, with its buttons, and the page
      // has moved under it.
      for (final label in ['Back', 'Search', 'More options']) {
        final button = tester.getRect(_coverButton(label));
        expect(button.top, greaterThanOrEqualTo(0), reason: label);
        expect(button.bottom, lessThan(70), reason: label);
      }
      expect(
        tester.getTopLeft(find.byType(ProfileMobileHeader)).dy,
        lessThan(0),
      );
      // A title is in the toolbar's row now.
      final inToolbar = [
        for (final element in names().evaluate())
          tester.getRect(find.byElementPredicate((e) => e == element)),
      ].where((rect) => rect.top >= 0 && rect.bottom < 70);
      expect(inToolbar, isNotEmpty);
      expect(opacityOf(names().last), greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a swipe turns to the next tab, and the bar follows', (
      tester,
    ) async {
      await _pumpProfile(tester, size: const Size(390, 1400));
      TabsController<ProfileTab> controller() => tester
          .widget<TabBar<ProfileTab>>(find.byType(TabBar<ProfileTab>))
          .controller!;
      expect(controller().value, ProfileTab.about);

      await tester.fling(
        find.text(ProfileData.aboutShort),
        const Offset(-300, 0),
        1200,
      );
      await _settle(tester);
      expect(controller().value, ProfileTab.experience);
      expect(find.byType(ProfileEducationCard), findsOneWidget);

      // And back.
      await tester.fling(
        find.byType(TabBarView<ProfileTab>),
        const Offset(300, 0),
        1200,
      );
      await _settle(tester);
      expect(controller().value, ProfileTab.about);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaves room for the bottom bar', (tester) async {
      const barInset = 92.0;
      await _pumpProfile(
        tester,
        size: _phone,
        padding: const FakeViewPadding(bottom: barInset),
      );

      final position = _pagePosition(tester);
      position.jumpTo(position.maxScrollExtent);
      await _settle(tester, frames: 4);

      final card = tester.getRect(find.byType(ProfileExperienceCard));
      expect(card.bottom, lessThanOrEqualTo(844 - barInset - 16 + .5));
    });

    testWidgets('the tabs switch the content', (tester) async {
      await _pumpProfile(tester, size: const Size(390, 1400));

      await tester.tap(_tab('Experience'));
      await _settle(tester, frames: 2);
      expect(find.text(ProfileData.aboutShort), findsNothing);
      expect(find.byType(ProfileEducationCard), findsOneWidget);
      expect(find.textContaining('Lead designer for'), findsOneWidget);

      await tester.tap(_tab('Media'));
      await _settle(tester, frames: 2);
      expect(find.byType(ProfileMediaCard), findsOneWidget);

      await tester.tap(_tab('Posts'));
      await _settle(tester, frames: 2);
      expect(find.byType(ProfilePostCard), findsWidgets);

      await tester.tap(_tab('About'));
      await _settle(tester, frames: 2);
      expect(find.text(ProfileData.aboutShort), findsOneWidget);
    });

    testWidgets('Back goes Home', (tester) async {
      await _pumpProfile(tester, size: _phone);
      final destination = demoDestinationProvider.of(_context(tester));
      destination.value = DemoDestination.profile;

      await tester.tap(_coverButton('Back'));
      await _settle(tester, frames: 2);
      expect(destination.value, DemoDestination.home);
    });

    testWidgets('Search pushes the search page', (tester) async {
      await _pumpProfile(tester, size: _phone);

      await tester.tap(_coverButton('Search'));
      await _settle(tester);
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('More options opens the user menu', (tester) async {
      await _pumpProfile(tester, size: _phone);
      final context = _context(tester);
      expect(find.byType(UserMenu), findsOneWidget);

      await tester.tap(_coverButton('More options'));
      await _settle(tester);
      expect(find.text('View profile'), findsNothing);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Dark mode'), findsOneWidget);

      await tester.tap(find.text('Dark mode'));
      await _settle(tester);
      expect(themeModeProvider.of(context).value, ThemeMode.dark);
    });
  });

  group('takes its measurements from the package', () {
    testWidgets('a card\'s heading is centred on its button, a gap above '
        'the content', (tester) async {
      await _pumpProfile(tester, size: const Size(1440, 2400));
      final gap = Theme.of(
        tester.element(find.byType(ProfileAboutCard)),
      ).layoutTheme.gap(GapSize.md);

      Finder inAbout(Finder finder) => find.descendant(
        of: find.byType(ProfileAboutCard),
        matching: finder,
      );
      final heading = tester.getRect(inAbout(find.text('About')));
      final action = tester.getRect(inAbout(find.byType(ProfileHeaderAction)));
      final text = tester.getRect(inAbout(find.byType(ProfileAboutText)));
      expect(heading.center.dy, action.center.dy);
      expect(text.top, action.bottom + gap);

      // Without a button the heading is a line of its own.
      final education = tester.getRect(
        find.descendant(
          of: find.byType(ProfileEducationCard),
          matching: find.text('Education'),
        ),
      );
      final school = tester.getRect(
        find.descendant(
          of: find.byType(ProfileEducationCard),
          matching: find.byType(ProfileLogo),
        ),
      );
      expect(school.top, education.bottom + gap);
    });

    testWidgets('the mutual connections\' faces line up with the text, their '
        'rings outside the stack', (tester) async {
      await _pumpProfile(tester, size: _desktop);

      final stack = tester.getRect(find.byType(AvatarGroup));
      // Four faces half the theme's avatar, each a quarter under the one
      // before it.
      final face = Theme.of(
        tester.element(find.byType(AvatarGroup)),
      ).avatarXs;
      expect(stack.size, Size(face + face * .75 * 3, face));
      expect(stack.left, tester.getRect(find.text('Noor Haddad')).left);
    });

    testWidgets('on a phone the skill tags and the tabs keep the theme\'s '
        'sizes', (tester) async {
      await _pumpProfile(tester, size: const Size(390, 1400));

      for (final chip in tester.widgetList<Chip>(find.byType(Chip))) {
        expect(chip.height, isNull);
      }
      expect(tester.getSize(find.byType(Chip).first).height, 32);
      // Faces half the theme's avatar.
      final theme = Theme.of(tester.element(find.byType(AvatarGroup)));
      expect(tester.getSize(find.byType(AvatarGroup)).height, theme.avatarXs);

      final tabs = tester.getRect(find.byType(TabBar<ProfileTab>));
      // 48 of tabs and the hairline under them.
      expect(tabs.height, 49);
      for (final label in ['Posts', 'About']) {
        final style = tester.renderObject<RenderParagraph>(_tab(label));
        expect(
          style.text.style?.fontSize,
          theme.textTheme.large.fontSize,
          reason: label,
        );
      }
    });
  });

  testWidgets('keeps the selected tab across the form factors', (tester) async {
    await _pumpProfile(tester, size: _desktop);
    await tester.tap(_tab('Media'));
    await _settle(tester, frames: 2);

    tester.view.physicalSize = _phone;
    await _settle(tester, frames: 4);
    expect(find.byType(ProfileMobileHeader), findsOneWidget);
    expect(find.byType(ProfileMediaCard), findsOneWidget);
    expect(
      tester
          .widget<TabBar<ProfileTab>>(find.byType(TabBar<ProfileTab>))
          .controller!
          .value,
      ProfileTab.media,
    );

    // Activity has no tab on a phone: About stands in for it.
    tester.view.physicalSize = _desktop;
    await _settle(tester, frames: 4);
    await tester.tap(_tab('Activity'));
    await _settle(tester, frames: 2);
    tester.view.physicalSize = _phone;
    await _settle(tester, frames: 4);
    expect(
      tester
          .widget<TabBar<ProfileTab>>(find.byType(TabBar<ProfileTab>))
          .controller!
          .value,
      ProfileTab.about,
    );
    expect(find.text(ProfileData.aboutShort), findsOneWidget);
  });
}
