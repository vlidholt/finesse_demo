import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:una/una.dart';
import 'package:una_demo/app_state.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/screens/home_screen.dart';
import 'package:una_demo/screens/jobs_screen.dart';
import 'package:una_demo/screens/messages_screen.dart';
import 'package:una_demo/screens/network_screen.dart';
import 'package:una_demo/screens/notifications_screen.dart';
import 'package:una_demo/screens/profile_screen.dart';
import 'package:una_demo/screens/search_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/compose_dialog.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/search_bar.dart';
import 'package:una_demo/widgets/una_logo.dart';
import 'package:una_demo/widgets/user_menu.dart';

export 'package:una_demo/navigation.dart';

/// Demo's chrome: the app bar and navigation around the screen of the
/// selected [DemoDestination].
///
/// A [NavigationScaffold], so it follows the theme's form factor:
///
/// * **Desktop** — one app bar: logo, the search field (a
///   `DemoSearchBar`, which shows live results under itself), the five
///   top destinations, the dark-mode button and the avatar pill, which
///   opens the [UserMenu] (profile, saved items, settings, light/dark).
/// * **A narrow desktop** — a tablet held upright, a small window: below
///   [topBarFrom] the destinations leave the bar for a `NavigationRail`
///   down the start edge, under a round "Create post" button, and the bar
///   keeps its search field whole.
/// * **Phone** — a short app bar with the logo and three icon buttons
///   (search, notifications, messages), and a floating bottom bar with Home,
///   Network, the "Create post" action, Jobs and Me.
///
/// Choosing the destination that is already showing scrolls its page back
/// to the top.
///
/// ## How a screen plugs in
///
/// A screen is the widget [DemoShell] builds for its destination; it
/// returns page content — normally a `PageContainer` — and never touches
/// this file. The scaffold's bars are laid *over* the screen, and the
/// screen's `MediaQuery` padding already accounts for them, so a
/// `PageContainer`, a `ListView` or a `SafeArea` clears them by itself.
/// Screens stay alive once visited, so scroll position survives a round
/// trip.
///
/// To navigate, write to [demoDestinationProvider] — or call
/// `context.goTo(DemoDestination.jobs)`; from a page pushed over the
/// shell, `context.leaveTo(...)` closes the page on the way.
///
/// What more than one screen shows — the unread notifications the bell
/// counts, the conversations with something unread that the Messages badge
/// counts, the invitations, the recent searches, the settings — is in the
/// `DemoSession` (`session.dart`), reached with `context.demo`.
///
/// ## Full-screen routes
///
/// Some pages need the whole viewport: on a phone the Messages design is a
/// conversation with its own header and no bottom bar. Such a page is not a
/// destination. The screen pushes it as a route:
///
/// ```dart
/// context.pushFullScreen((context) => const ConversationScreen());
/// // which is
/// Navigator.of(context).push(
///   UnaPageRoute<void>(builder: (context) => const ConversationScreen()),
/// );
/// ```
///
/// and the page is a `Scaffold` with its own `AppBar` that calls
/// `Navigator.of(context).pop()` to go back. The route covers this shell's
/// bars; the theme, the form factor and every app-level provider (this
/// file's, and those in `app_state.dart`) reach it unchanged.
/// `SearchScreen` and `SettingsScreen` are working examples.
///
/// On a phone the shell shows no app bar over the Profile destination,
/// because the design's cover photo runs to the top of the screen.
class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  /// The width of the shell from which a desktop's destinations are in the
  /// top bar. Below it they are in a `NavigationRail`.
  static const topBarFrom = 1024.0;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  final _screens = GlobalKey<_ScreensState>();

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context, _) {
        final destinationSignal = demoDestinationProvider.of(context);
        final destination = destinationSignal.value;
        final dark = themeModeProvider.of(context).value == ThemeMode.dark;
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final portraitSize = (theme.navigationBarTheme.iconSize ?? 24) + 4;
        // Choosing the destination that is showing takes its page back to
        // the top, as a tab bar's selected tab does on a phone.
        void goTo(DemoDestination next) {
          if (next == destinationSignal.value) {
            _screens.currentState?.scrollToTop();
          } else {
            destinationSignal.value = next;
          }
        }

        final session = context.demo;
        final notifications = session.notifications;
        final unreadMessages = session.messages.unreadCount;

        // The bell counts the unread notifications and the Messages badge
        // the conversations with something unread; neither is a signal.
        Widget scaffold(NavigationLayout layout) => ListenableBuilder(
          listenable: session.badges,
          builder: (context, _) => NavigationScaffold(
            layout: layout,
            selectedIndex: destination.index,
            onDestinationSelected: (index) =>
                goTo(DemoDestination.values[index]),
            // In the order of [DemoDestination], so an index is an enum
            // value.
            destinations: [
              const NavigationDestination(
                icon: PhosphorIcon(PhosphorIconsRegular.house),
                selectedIcon: PhosphorIcon(PhosphorIconsFill.house),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: PhosphorIcon(PhosphorIconsRegular.usersThree),
                selectedIcon: PhosphorIcon(PhosphorIconsFill.usersThree),
                label: 'Network',
              ),
              const NavigationDestination(
                icon: PhosphorIcon(PhosphorIconsRegular.briefcase),
                selectedIcon: PhosphorIcon(PhosphorIconsFill.briefcase),
                label: 'Jobs',
              ),
              NavigationDestination(
                icon: const PhosphorIcon(PhosphorIconsRegular.chatCircleDots),
                selectedIcon: const PhosphorIcon(
                  PhosphorIconsFill.chatCircleDots,
                ),
                label: 'Messages',
                badgeCount: unreadMessages.value,
                // On a phone: the app bar's button.
                showInBottomBar: false,
              ),
              NavigationDestination(
                icon: const PhosphorIcon(PhosphorIconsRegular.bell),
                selectedIcon: const PhosphorIcon(PhosphorIconsFill.bell),
                label: 'Notifications',
                badgeCount: notifications.unreadCount,
                showInBottomBar: false,
              ),
              NavigationDestination(
                // A portrait reads smaller than a glyph in the same box, so
                // it is drawn a little over the bar's icon size.
                icon: PersonAvatar(People.me, size: portraitSize),
                selectedIcon: PersonAvatar(
                  People.me,
                  size: portraitSize,
                  ringColor: colors.tint,
                ),
                label: 'Me',
                // On a desktop: the avatar pill's menu.
                showInTopBar: false,
              ),
            ],
            // The logo and the search field together, as the bar's flexible
            // title rather than as `leading` + `title`: a leading widget is
            // laid out at its natural width, and the pair has to give way in
            // a narrow window (see [_BarStart]).
            title: _BarStart(onLogoPressed: () => goTo(DemoDestination.home)),
            actions: [
              IconButton.secondary(
                size: ButtonSize.lg,
                style: ButtonTheme(
                  // The design's `--fill`, one step quieter than the secondary
                  // button's own fill.
                  backgroundColor: colors.muted,
                  hoverBackgroundColor: colors.secondary,
                ),
                icon: PhosphorIcon(
                  dark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
                ),
                semanticLabel: 'Toggle dark mode',
                onPressed: () => toggleThemeMode(context),
              ),
              const _AvatarPill(),
            ],
            action: NavigationAction(
              icon: const PhosphorIcon(PhosphorIconsRegular.plus),
              label: 'Create post',
              onPressed: () => showComposeDialog(context),
            ),
            mobileAppBar: _MobileAppBar(
              destination: destination,
              unreadNotifications: notifications.unreadCount,
              unreadMessages: unreadMessages.value,
              onSelected: goTo,
            ),
            showMobileAppBar: destination != DemoDestination.profile,
            body: _Screens(key: _screens, destination: destination),
          ),
        );

        if (theme.formFactor != FormFactor.desktop) {
          return scaffold(NavigationLayout.auto);
        }
        // A desktop's top bar has room for the five destinations and a
        // search field from about a landscape tablet's width. Narrower
        // than that — a tablet held upright, a small window — they move
        // to a rail down the start edge, and the bar keeps the field.
        // Every signal is read above: a layout callback runs outside the
        // scope the `SignalBuilder` tracks.
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= DemoShell.topBarFrom) {
              return scaffold(NavigationLayout.auto);
            }
            return Theme(
              data: _railThemeOf(theme),
              child: scaffold(NavigationLayout.rail),
            );
          },
        );
      },
    );
  }
}

/// The theme the shell is built in when its destinations are in a rail.
///
/// The package's rail is as wide as its icons need, and its longest label
/// here — "Notifications" — is a few pixels wider than that leaves. The
/// rail is given one more step of the gap scale. Derived once per ambient
/// theme: `ThemeData.copyWith` builds every component theme again.
final _railThemes = Expando<ThemeData>('DemoShell rail theme');

ThemeData _railThemeOf(ThemeData theme) =>
    _railThemes[theme] ??= theme.copyWith(
      navigationRailTheme: NavigationRailTheme(
        width: (theme.navigationRailTheme.width ?? 72) + theme.gap(GapSize.md),
      ),
    );

/// The start of the desktop app bar: the logo, then the search field.
///
/// The bar gives this zone whatever is left beside the centred navigation —
/// 396 logical pixels in the designs' 1440 window, where everything fits,
/// and next to nothing just above the phone breakpoint. So it sheds in
/// order: the search field narrows to its magnifier (it collapses itself),
/// then the logo drops its wordmark so the magnifier can stay — search has
/// no other entry on a desktop — and only when even that does not fit does
/// search go.
class _BarStart extends StatelessWidget {
  const _BarStart({required this.onLogoPressed});

  final VoidCallback onLogoPressed;

  /// The least the search bar needs to draw anything: its magnifier.
  static const _searchMinWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    // The gap the app bar itself puts between a leading widget and a title.
    final gap = (Theme.of(context).appBarTheme.gap ?? 24) - 4;
    final logoWidth = UnaLogo.widthOf(context);
    final markWidth = UnaLogo.widthOf(context, showWordmark: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth;
        final searchBesideLogo = room >= logoWidth + gap + _searchMinWidth;
        final searchBesideMark = room >= markWidth + gap + _searchMinWidth;
        final showWordmark =
            searchBesideLogo || (!searchBesideMark && room >= logoWidth);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            UnaLogo(onPressed: onLogoPressed, showWordmark: showWordmark),
            if (searchBesideLogo || searchBesideMark) ...[
              Gap.raw(gap),
              const Flexible(child: DemoSearchBar()),
            ],
          ],
        );
      },
    );
  }
}

/// The phone's app bar: the logo, then search, notifications and messages.
///
/// The buttons name no variant: the bar gives them its own look — bare
/// glyphs on its surface, the last one's glyph (not its box) on the page
/// margin, as in the designs; plain icons on one capsule of Liquid Glass,
/// whose edge is on the margin.
class _MobileAppBar extends StatelessWidget {
  const _MobileAppBar({
    required this.destination,
    required this.unreadNotifications,
    required this.unreadMessages,
    required this.onSelected,
  });

  final DemoDestination destination;
  final int unreadNotifications;
  final int unreadMessages;
  final ValueChanged<DemoDestination> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget action({
      required DemoDestination target,
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required int count,
    }) {
      final selected = destination == target;
      return IndicatorBadge(
        count: count,
        // Inside the button's box, 2 below its top edge, as in the designs.
        overhang: 0,
        offset: const Offset(0, 2),
        semanticLabel: '$count unread',
        child: IconButton(
          icon: PhosphorIcon(selected ? selectedIcon : icon),
          style: ButtonTheme(
            foregroundColor: selected ? theme.colorScheme.tint : null,
          ),
          semanticLabel: label,
          onPressed: () => onSelected(target),
        ),
      );
    }

    return AppBar(
      actionsGap: 0,
      leading: UnaLogo(onPressed: () => onSelected(DemoDestination.home)),
      actions: [
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
          semanticLabel: 'Search',
          onPressed: () =>
              context.pushFullScreen<void>((context) => const SearchScreen()),
        ),
        action(
          target: DemoDestination.notifications,
          icon: PhosphorIconsRegular.bell,
          selectedIcon: PhosphorIconsFill.bell,
          label: 'Notifications',
          count: unreadNotifications,
        ),
        action(
          target: DemoDestination.messages,
          icon: PhosphorIconsRegular.chatCircleDots,
          selectedIcon: PhosphorIconsFill.chatCircleDots,
          label: 'Messages',
          count: unreadMessages,
        ),
      ],
    );
  }
}

/// The desktop app bar's last action: the signed-in user's portrait and a
/// caret in a glass pill, opening the [UserMenu].
class _AvatarPill extends StatelessWidget {
  const _AvatarPill();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UserMenu(
      builder: (context, controller, _) => Pressable(
        onPressed: controller.toggle,
        semanticLabel: 'Your profile',
        builder: (context, states) => FocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: theme.radii.full,
          child: Glass(
            // On the app bar, which has blurred the page already.
            frosted: false,
            level: GlassLevel.strong,
            borderRadius: theme.radii.full,
            // The pill hugs its portrait.
            padding: EdgeInsetsDirectional.fromSTEB(
              theme.gap(GapSize.xs),
              theme.gap(GapSize.xs),
              theme.gap(GapSize.sm),
              theme.gap(GapSize.xs),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                PersonAvatar(People.me, size: theme.avatarSm),
                const Gap.xs(),
                PhosphorIcon(
                  PhosphorIconsRegular.caretDown,
                  size: theme.iconBeside(theme.textTheme.caption),
                  color: theme.colorScheme.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The screens, one per destination.
///
/// A `DestinationStack`: a screen is built the first time its destination
/// is shown and kept alive from then on, so going back to it finds it where
/// it was left; the screens that are not showing are off stage and do not
/// tick; and the one that is switched to comes in from the side its
/// destination is on.
class _Screens extends StatefulWidget {
  const _Screens({required this.destination, super.key});

  final DemoDestination destination;

  @override
  State<_Screens> createState() => _ScreensState();
}

class _ScreensState extends State<_Screens> {
  // One per destination, so the page that is showing can be found again:
  // see [scrollToTop].
  final _keys = [
    for (final destination in DemoDestination.values)
      GlobalKey(debugLabel: destination.name),
  ];

  static Widget _screen(DemoDestination destination) => switch (destination) {
    DemoDestination.home => const HomeScreen(),
    DemoDestination.network => const NetworkScreen(),
    DemoDestination.jobs => const JobsScreen(),
    DemoDestination.messages => const MessagesScreen(),
    DemoDestination.notifications => const NotificationsScreen(),
    DemoDestination.profile => const ProfileScreen(),
  };

  /// Takes the screen that is showing back to its top: what choosing the
  /// selected destination again does.
  ///
  /// The page's scroll view is the first vertical one in the screen — a
  /// screen may have others inside it (a pane of a card, a list in a
  /// column), and those keep their place.
  void scrollToTop() {
    final root = _keys[widget.destination.index].currentContext;
    if (root == null) return;
    ScrollPosition? page;
    void visit(Element element) {
      if (page != null) return;
      if (element
          case StatefulElement(
            :final ScrollableState state,
          )
          when state.axisDirection == AxisDirection.down) {
        page = state.position;
        return;
      }
      element.visitChildren(visit);
    }

    root.visitChildElements(visit);
    final position = page;
    if (position == null || position.pixels <= position.minScrollExtent) {
      return;
    }
    final motion = Motion.of(context);
    if (motion.reduced || motion.slow == Duration.zero) {
      position.jumpTo(position.minScrollExtent);
    } else {
      position.animateTo(
        position.minScrollExtent,
        duration: motion.slow,
        curve: motion.emphasized,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DestinationStack(
      index: widget.destination.index,
      builders: [
        for (final destination in DemoDestination.values)
          (context) => KeyedSubtree(
            key: _keys[destination.index],
            child: _screen(destination),
          ),
      ],
    );
  }
}
