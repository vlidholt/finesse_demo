import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/profile_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/screens/search_screen.dart';
import 'package:finesse_demo/widgets/profile_about_cards.dart';
import 'package:finesse_demo/widgets/profile_experience.dart';
import 'package:finesse_demo/widgets/profile_header_card.dart';
import 'package:finesse_demo/widgets/profile_mobile_header.dart';
import 'package:finesse_demo/widgets/profile_rail.dart';
import 'package:finesse_demo/widgets/profile_tab_content.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The Profile destination of the Demo shell: the signed-in user's own
/// profile.
///
/// * **Desktop** — a main column (the header card with the cover photo and
///   the tab bar, then the selected tab's cards) beside a rail of settings,
///   suggestions and groups. The rail moves under the main column when the
///   two no longer fit side by side.
/// * **Phone** — the cover photo runs under the status bar with the round
///   glass buttons on it (back, search, and the `UserMenu` behind "More
///   options"), then the identity block, the tab bar and the tab's content.
///
/// The designs show the About tab; the other tabs are built from the same
/// data.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileTab _tab = ProfileTab.about;

  /// The suggested people who have been followed or sent a request.
  final _done = <Person>{};

  void _selectTab(ProfileTab tab) => setState(() => _tab = tab);

  void _onSuggestionAction(ProfileSuggestion suggestion) {
    if (suggestion.action == SuggestionAction.message) {
      context.goTo(DemoDestination.messages);
      return;
    }
    setState(() {
      if (!_done.remove(suggestion.person)) _done.add(suggestion.person);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormFactorBuilder(
      mobile: (context) => _MobileProfile(tab: _tab, onTabSelected: _selectTab),
      desktop: (context) => _DesktopProfile(
        tab: _tab,
        onTabSelected: _selectTab,
        done: _done,
        onSuggestionAction: _onSuggestionAction,
      ),
    );
  }
}

class _DesktopProfile extends StatelessWidget {
  const _DesktopProfile({
    required this.tab,
    required this.onTabSelected,
    required this.done,
    required this.onSuggestionAction,
  });

  final ProfileTab tab;
  final ValueChanged<ProfileTab> onTabSelected;
  final Set<Person> done;
  final ValueChanged<ProfileSuggestion> onSuggestionAction;

  /// The profile is centred narrower than the app bar: 1200 with its
  /// margins, where the page's own maximum is 1280 plus margins.
  static const _maxWidth = 1200.0;

  /// The rail's width, and the least the main column is given beside it.
  static const _railWidth = 340.0;
  static const _mainMinWidth = 560.0;

  List<Widget> _sections() => switch (tab) {
    ProfileTab.posts => [
      for (final post in ProfileData.posts) ProfilePostCard(post),
    ],
    ProfileTab.about => [
      const ProfileAnalyticsCard(),
      const ProfileAboutCard(),
      ProfileFeaturedCard(onSeeAll: () => onTabSelected(ProfileTab.media)),
      const ProfileExperienceCard(),
      const ProfileEducationCard(),
    ],
    ProfileTab.experience => const [
      ProfileExperienceCard(),
      ProfileEducationCard(),
    ],
    ProfileTab.activity => const [ProfileActivityCard()],
    ProfileTab.media => const [ProfileMediaCard()],
  };

  @override
  Widget build(BuildContext context) {
    final columnGap = Theme.of(context).layoutTheme.gap(GapSize.xl);

    final main = FinesseColumn(
      gap: GapSize.lg,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileHeaderCard(tab: tab, onTabSelected: onTabSelected),
        ..._sections(),
      ],
    );
    final rail = FinesseColumn(
      gap: GapSize.lg,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ProfileSettingsCard(),
        ProfilePeopleCard(done: done, onAction: onSuggestionAction),
        const ProfileGroupsCard(),
      ],
    );

    return PageContainer(
      scrollable: true,
      maxWidth: _maxWidth,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sideBySide =
              constraints.maxWidth >= _mainMinWidth + columnGap + _railWidth;
          if (!sideBySide) {
            return FinesseColumn(
              gap: GapSize.lg,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [main, rail],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: columnGap,
            children: [
              Expanded(child: main),
              SizedBox(width: _railWidth, child: rail),
            ],
          );
        },
      ),
    );
  }
}

class _MobileProfile extends StatefulWidget {
  const _MobileProfile({required this.tab, required this.onTabSelected});

  final ProfileTab tab;
  final ValueChanged<ProfileTab> onTabSelected;

  @override
  State<_MobileProfile> createState() => _MobileProfileState();
}

class _MobileProfileState extends State<_MobileProfile> {
  /// The phone design has no Activity tab; a window narrowed while it was
  /// selected falls back to About.
  static ProfileTab _shown(ProfileTab tab) =>
      ProfileTab.mobile.contains(tab) ? tab : ProfileTab.about;

  // Shared by the bar and the pages, so the bar's line follows the finger
  // while a page is swiped. The screen's own selection follows it.
  late final _tabs = TabsController<ProfileTab>(value: _shown(widget.tab))
    ..addListener(_onTabChanged);

  void _onTabChanged() {
    if (_tabs.value != _shown(widget.tab)) widget.onTabSelected(_tabs.value);
  }

  @override
  void didUpdateWidget(_MobileProfile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab != oldWidget.tab) _tabs.select(_shown(widget.tab));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  static List<Widget> _sections(ProfileTab tab) => switch (tab) {
    ProfileTab.posts => [
      for (final post in ProfileData.posts) ProfilePostCard(post),
    ],
    ProfileTab.about || ProfileTab.activity => [
      const ProfileAboutText(ProfileData.aboutShort),
      ProfileSkills(
        ProfileData.skills.sublist(0, ProfileData.mobileSkillCount),
      ),
      const ProfileExperienceCard(compact: true),
    ],
    ProfileTab.experience => const [
      ProfileExperienceCard(compact: true, showDescriptions: true),
      ProfileEducationCard(),
    ],
    ProfileTab.media => const [ProfileMediaCard()],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pagePadding =
        theme.layoutTheme.pagePadding ?? const EdgeInsets.all(16);
    // The shell's floating bottom bar is in the bottom inset.
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      slivers: [
        ProfileMobileBar(
          onBack: () => context.goTo(DemoDestination.home),
          onSearch: () => context.pushFullScreen<void>(
            (context) => const SearchScreen(),
          ),
        ),
        SliverToBoxAdapter(
          // Its own layer, as in a `PageContainer`: a scroll then moves
          // the page instead of painting all of it again on every frame.
          child: RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ProfileMobileHeader(),
                const Gap.sm(),
                TabBar<ProfileTab>(
                  controller: _tabs,
                  tabs: [
                    for (final tab in ProfileTab.mobile)
                      Tab(value: tab, child: Text(tab.label)),
                  ],
                ),
                // A swipe turns to the next tab; the page is as tall as
                // the tab it shows.
                TabBarView<ProfileTab>(
                  controller: _tabs,
                  pages: {
                    for (final tab in ProfileTab.mobile)
                      tab: (context) => Padding(
                        padding: pagePadding.add(
                          EdgeInsets.only(bottom: bottomInset),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: theme.gap(GapSize.md),
                          children: _sections(tab),
                        ),
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
