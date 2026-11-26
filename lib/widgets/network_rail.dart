import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/network_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/network_controller.dart';

/// "Manage my network": one row per list — connections, following, groups,
/// events, pages — with its count, under a row that leads back to the
/// invitations and suggestions the screen opens on.
///
/// On a desktop the selected row is highlighted and [onSelected] swaps the
/// main column; on a phone nothing is selected and a row opens its list as
/// a page.
class NetworkManageCard extends StatelessWidget {
  const NetworkManageCard({
    required this.controller,
    required this.onSelected,
    this.showSelection = true,
    this.showGrow = true,
    super.key,
  });

  final NetworkController controller;
  final ValueChanged<NetworkSection> onSelected;

  /// Whether the controller's section is highlighted.
  final bool showSelection;

  /// Whether the "Grow" row is listed. A phone has a tab for it instead.
  final bool showGrow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inset = theme.gap(GapSize.sm);

    Widget row(NetworkSection section) {
      final selected = showSelection && controller.section == section;
      final count = controller.countOf(section);
      return Semantics(
        selected: selected,
        child: Button(
          variant: selected ? ButtonVariant.secondary : ButtonVariant.ghost,
          style: ButtonTheme(
            pressScale: 1,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: theme.gap(GapSize.sm)),
            gap: theme.gap(GapSize.sm),
            mainAxisAlignment: MainAxisAlignment.start,
            foregroundColor: selected ? scheme.tint : scheme.foregroundSubtle,
          ),
          leading: PhosphorIcon(section.icon),
          trailing: section == NetworkSection.grow
              ? IndicatorBadge(
                  count: count,
                  ringWidth: 0,
                  semanticLabel: '$count invitations waiting',
                )
              : Text(
                  '$count',
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.tint : scheme.mutedForeground,
                  ),
                ),
          onPressed: () => onSelected(section),
          child: Expanded(
            child: Text(
              section == NetworkSection.grow
                  ? 'Grow your network'
                  : section.label,
              // A button centres its label; this one is a list row.
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    return Card(
      style: CardTheme(padding: EdgeInsets.zero),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.cardInset,
              theme.cardInset,
              theme.cardInset,
              theme.gap(GapSize.sm),
            ),
            child: Semantics(
              header: true,
              child: Text(
                'Manage my network',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    theme.cardTheme.titleStyle ??
                    theme.textTheme.large.copyWith(color: scheme.foreground),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(inset, 0, inset, inset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showGrow) row(NetworkSection.grow),
                for (final section in NetworkSection.managed) row(section),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The right rail's "Upcoming events": the next three, each with a
/// calendar leaf and an "Attend" pill.
class NetworkEventsCard extends StatelessWidget {
  const NetworkEventsCard({
    required this.controller,
    required this.onSeeAll,
    super.key,
  });

  final NetworkController controller;
  final VoidCallback onSeeAll;

  /// How many events the rail lists; "See all" has the rest.
  static const _shown = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return HomeSectionCard(
      title: 'Upcoming events',
      trailing: HomeTextLink(
        'See all',
        onPressed: onSeeAll,
        style: theme.textTheme.small.copyWith(color: scheme.tint),
      ),
      child: UnaColumn(
        gap: GapSize.lg,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final event in NetworkData.events.take(_shown))
            UnaRow(
              gap: GapSize.md,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DemoDateTile(month: event.month, day: event.day),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.foreground,
                        ),
                      ),
                      Text(
                        '${event.place} · ${event.time}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.caption,
                      ),
                      const Gap.sm(),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: DemoPillButton(
                          label: 'Attend',
                          icon: PhosphorIconsRegular.star,
                          done: controller.isAttending(event),
                          doneLabel: 'Going',
                          doneIcon: PhosphorIconsFill.star,
                          onPressed: () => controller.toggleAttending(event),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The right rail's "Groups you may like".
class NetworkSuggestedGroupsCard extends StatelessWidget {
  const NetworkSuggestedGroupsCard({
    required this.controller,
    required this.onSeeAll,
    super.key,
  });

  final NetworkController controller;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return HomeSectionCard(
      title: 'Groups you may like',
      trailing: HomeTextLink(
        'See all',
        onPressed: onSeeAll,
        style: theme.textTheme.small.copyWith(color: scheme.tint),
      ),
      child: UnaColumn(
        gap: GapSize.md,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in NetworkData.suggestedGroups)
            Row(
              children: [
                DemoMark(
                  asset: group.logo,
                  icon: group.icon,
                  label: group.name,
                  size: theme.avatarSm,
                ),
                const Gap.sm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.foreground,
                        ),
                      ),
                      Text(
                        group.members,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.caption,
                      ),
                    ],
                  ),
                ),
                const Gap.sm(),
                DemoPillButton(
                  label: 'Join',
                  icon: PhosphorIconsRegular.plus,
                  done: controller.hasJoined(group),
                  doneLabel: 'Joined',
                  doneIcon: PhosphorIconsRegular.check,
                  onPressed: () => controller.toggleJoined(group),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
