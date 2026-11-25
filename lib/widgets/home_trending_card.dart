import 'package:finesse_demo/data/home_data.dart';
import 'package:finesse_demo/widgets/home_pieces.dart';
import 'package:finesse_demo/widgets/demo_actions.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The right rail's "Trending in design" card: five ranked topics.
class HomeTrendingCard extends StatelessWidget {
  const HomeTrendingCard({super.key});

  /// What a topic searches for: its words, without the hash, the year or
  /// the filler, so that search — which wants every word — finds its posts.
  static const _queries = {
    '#DesignSystems': 'Design systems',
    'Config Nordics 2026': 'Config Nordics',
    'AI in user research': 'Research',
    'Accessibility audits': 'Accessibility',
    'Remote design teams': 'Remote',
  };

  static String _queryOf(Trend trend) => _queries[trend.title] ?? trend.title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // The rank's column and the glyphs that end the heading and each row:
    // the size of a glyph beside a row's title.
    final markSize = theme.iconBeside(theme.textTheme.h4);
    return HomeSectionCard(
      title: 'Trending in design',
      trailing: PhosphorIcon(
        PhosphorIconsRegular.sparkle,
        size: markSize,
        color: scheme.tint,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: theme.gap(GapSize.md),
        children: [
          for (final (index, trend) in HomeData.trends.indexed)
            Pressable(
              onPressed: () => openSearch(context, _queryOf(trend)),
              builder: (context, states) => FocusRing(
                visible: states.contains(WidgetState.focused),
                borderRadius: theme.radii.sm,
                child: FinesseRow(
                  gap: GapSize.md,
                  children: [
                    SizedBox(
                      width: markSize,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.mutedForeground,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            trend.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.p.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.foreground,
                              decoration: states.contains(WidgetState.hovered)
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                          Text(
                            trend.posts,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.caption,
                          ),
                        ],
                      ),
                    ),
                    PhosphorIcon(
                      PhosphorIconsRegular.trendUp,
                      size: markSize,
                      color: scheme.tint,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The links under the right rail: About, Accessibility, Privacy…
class HomeFooterLinks extends StatelessWidget {
  const HomeFooterLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.caption;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.gap(GapSize.sm),
        vertical: theme.gap(GapSize.xs),
      ),
      child: Wrap(
        spacing: theme.gap(GapSize.md),
        runSpacing: theme.gap(GapSize.xs),
        children: [
          for (final link in HomeData.footerLinks)
            HomeTextLink(
              link,
              onPressed: () => openFooterLink(context, link),
              style: style,
            ),
          Text(HomeData.copyright, style: style),
        ],
      ),
    );
  }
}
