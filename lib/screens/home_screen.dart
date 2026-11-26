import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/home_composer_card.dart';
import 'package:una_demo/widgets/home_feed_refresh.dart';
import 'package:una_demo/widgets/home_feed_scope.dart';
import 'package:una_demo/widgets/home_feed_tabs.dart';
import 'package:una_demo/widgets/home_groups_card.dart';
import 'package:una_demo/widgets/home_post_card.dart';
import 'package:una_demo/widgets/home_profile_card.dart';
import 'package:una_demo/widgets/home_stories.dart';
import 'package:una_demo/widgets/home_suggestions_card.dart';
import 'package:una_demo/widgets/home_trending_card.dart';

/// The Home destination of the Demo shell: the feed.
///
/// * **Desktop** — three columns under the shell's app bar. A left rail
///   (profile summary, "Your groups"), the feed (stories, the composer, the
///   For you / Following / Trending control, posts) and a right rail
///   ("Add to your network", "Trending in design", footer links). The rails
///   drop away as the window narrows — the right one first — before the
///   feed gets tight.
/// * **Phone** — one column: a stories row that scrolls sideways, a
///   full-width segmented control and compact post cards.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HomeFeedScope(
      model: context.demo.feed,
      child: FormFactorBuilder(
        mobile: (context) => const _MobileHome(),
        desktop: (context) => const _DesktopHome(),
      ),
    );
  }
}

class _DesktopHome extends StatefulWidget {
  const _DesktopHome();

  @override
  State<_DesktopHome> createState() => _DesktopHomeState();
}

class _DesktopHomeState extends State<_DesktopHome> {
  bool _suggestionsDismissed = false;

  // The designs' column widths: the rails are 260 and 320 and may give up
  // 20 and 40 of that before the feed, which wants 520, is squeezed.
  static const _leftWidth = 260.0;
  static const _leftMinWidth = 240.0;
  static const _rightWidth = 320.0;
  static const _rightMinWidth = 280.0;
  static const _feedWidth = 520.0;

  // The content widths from which each rail is shown: what a 1100- and an
  // 860-point window leave between the page margins. Below the first the
  // feed would drop under 480 beside both rails; below the second it would
  // beside the left one alone.
  static const _rightRailFrom = 1052.0;
  static const _leftRailFrom = 812.0;

  @override
  Widget build(BuildContext context) {
    final gap = Theme.of(context).layoutTheme.gap(GapSize.xl);

    return HomeFeedRefresh(
      child: PageContainer(
        scrollable: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final showRight = width >= _rightRailFrom;
            final showLeft = width >= _leftRailFrom;

            // How far the rails have shrunk towards their minimum: 0 where
            // all three columns fit at full width, 1 where they no longer do.
            final full = _leftWidth + _rightWidth + _feedWidth + gap * 2;
            final least = _leftMinWidth + _rightMinWidth + _feedWidth + gap * 2;
            final squeeze = showRight
                ? ((full - width) / (full - least)).clamp(0.0, 1.0)
                : 0.0;

            // Each column is keyed: the rails come and go with the width,
            // and without keys the feed between them is matched by position
            // — dropping both rails at once would rebuild it from nothing,
            // with the focus and everything else its cards hold.
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: gap,
              children: [
                if (showLeft)
                  SizedBox(
                    key: const ValueKey(_Column.left),
                    width: _leftWidth - (_leftWidth - _leftMinWidth) * squeeze,
                    child: const UnaColumn(
                      gap: GapSize.lg,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [HomeProfileCard(), HomeGroupsCard()],
                    ),
                  ),
                const Expanded(key: ValueKey(_Column.feed), child: _Feed()),
                if (showRight)
                  SizedBox(
                    key: const ValueKey(_Column.right),
                    width:
                        _rightWidth - (_rightWidth - _rightMinWidth) * squeeze,
                    child: UnaColumn(
                      gap: GapSize.lg,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_suggestionsDismissed)
                          HomeSuggestionsCard(
                            onDismissed: () =>
                                setState(() => _suggestionsDismissed = true),
                          ),
                        const HomeTrendingCard(),
                        const HomeFooterLinks(),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The desktop home's three columns.
enum _Column { left, feed, right }

/// The desktop feed column.
class _Feed extends StatelessWidget {
  const _Feed();

  @override
  Widget build(BuildContext context) {
    return const UnaColumn(
      gap: GapSize.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeStories(),
        HomeComposerCard(),
        HomeFeedTabs(),
        _Posts(),
      ],
    );
  }
}

class _MobileHome extends StatelessWidget {
  const _MobileHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final margin = (theme.layoutTheme.pagePadding ?? const EdgeInsets.all(16))
        .resolve(Directionality.of(context));

    return HomeFeedRefresh(
      child: PageContainer(
        scrollable: true,
        // The phone design starts 14 below the app bar and spaces the
        // stories, the control and the posts 14 apart: between the theme's
        // 12 and 16.
        padding: EdgeInsets.symmetric(vertical: theme.gap(GapSize.md)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: theme.gap(GapSize.md),
          children: [
            const HomeStories(),
            Padding(
              padding: EdgeInsets.only(left: margin.left, right: margin.right),
              child: const HomeFeedTabs(),
            ),
            Padding(
              // Post cards sit 4 closer to the screen's edges than the page
              // margin the stories and the control keep.
              padding: EdgeInsets.symmetric(
                horizontal: theme.gap(GapSize.md),
              ),
              child: const _Posts(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The posts of the selected feed, or a note when the list is empty.
class _Posts extends StatelessWidget {
  const _Posts();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = HomeFeedScope.of(context);
    final posts = model.posts;

    if (posts.isEmpty) {
      return Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing here yet',
              style: theme.textTheme.large.copyWith(
                color: theme.colorScheme.foreground,
              ),
            ),
            const Gap.xs(),
            Text(
              'Follow people to see their posts in this feed.',
              style: theme.textTheme.muted,
            ),
          ],
        ),
      );
    }

    return UnaColumn(
      gap: GapSize.lg,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final post in posts) HomePostCard(post, key: ValueKey(post.id)),
      ],
    );
  }
}
