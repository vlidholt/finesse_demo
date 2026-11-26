import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_feed_refresh.dart';
import 'package:una_demo/widgets/home_feed_scope.dart';

/// The feed's segmented control — For you, Following, Trending.
///
/// On a desktop it hugs its labels and shares the row with the "Sort by"
/// menu, which also refreshes the feed; on a phone it fills the width and
/// the menu is left out (the feed is pulled down to refresh it).
class HomeFeedTabs extends StatelessWidget {
  const HomeFeedTabs({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = HomeFeedScope.of(context);
    final mobile = theme.formFactor == FormFactor.mobile;

    // On a phone the three tabs share the width, and a label that does
    // not fit its third shrinks to it.
    final tabs = Semantics(
      label: 'Feed',
      container: true,
      child: Tabs<HomeFeed>(
        value: model.feed,
        expandTabs: mobile,
        onChanged: (feed) => model.feed = feed,
        tabs: [
          for (final feed in HomeFeed.values)
            Tab(value: feed, child: DemoTabLabel(feed.label)),
        ],
      ),
    );
    if (mobile) return tabs;

    // The control keeps the width of its labels; the menu is what gives
    // way.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        tabs,
        const Flexible(child: _SortMenu()),
      ],
    );
  }
}

/// "Sort by Top ⌄": a text button that opens the two orders.
class _SortMenu extends StatelessWidget {
  const _SortMenu();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = HomeFeedScope.of(context);
    final style = theme.textTheme.small.copyWith(
      color: scheme.mutedForeground,
    );

    return DropdownMenu(
      items: [
        MenuRadioGroup<FeedSort>(
          value: model.sort,
          onChanged: (sort) => model.sort = sort,
          children: [
            for (final sort in FeedSort.values)
              MenuRadioItem(value: sort, child: Text(sort.label)),
          ],
        ),
        const MenuDivider(),
        // What pulling the feed down does, for a mouse, which cannot pull.
        MenuItem(
          leading: const PhosphorIcon(PhosphorIconsRegular.arrowClockwise),
          onPressed: () => HomeFeedRefresh.show(context),
          child: const Text('Refresh feed'),
        ),
      ],
      builder: (context, controller, _) => Pressable(
        onPressed: controller.toggle,
        builder: (context, states) => FocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: theme.radii.sm,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  'Sort by',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: style,
                ),
              ),
              const Gap.xs(),
              Flexible(
                child: Text(
                  model.sort.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: style.copyWith(color: scheme.foreground),
                ),
              ),
              const Gap.xs(),
              PhosphorIcon(
                PhosphorIconsRegular.caretDown,
                size: theme.iconBeside(style),
                color: scheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
