import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/network_data.dart';
import 'package:finesse_demo/widgets/home_pieces.dart';
import 'package:finesse_demo/widgets/network_links.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The left rail's "Your groups" card.
class HomeGroupsCard extends StatelessWidget {
  const HomeGroupsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return HomeSectionCard(
      title: 'Your groups',
      trailing: HomeTextLink(
        'See all',
        onPressed: () => openNetworkSection(context, NetworkSection.groups),
        style: theme.textTheme.small.copyWith(color: scheme.tint),
      ),
      child: FinesseColumn(
        gap: GapSize.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final group in Groups.all)
            Pressable(
              onPressed: () =>
                  openNetworkSection(context, NetworkSection.groups),
              builder: (context, states) => FocusRing(
                visible: states.contains(WidgetState.focused),
                borderRadius: theme.radii.md,
                child: Row(
                  children: [
                    _GroupLogo(group),
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
                              decoration: states.contains(WidgetState.hovered)
                                  ? TextDecoration.underline
                                  : null,
                            ),
                          ),
                          Text(
                            '${group.newPosts} new posts',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.caption,
                          ),
                        ],
                      ),
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

/// A group's mark: a small square on the control radius, with a hairline drawn
/// inside its edge so a pale logo still has an outline on a pale card.
class _GroupLogo extends StatelessWidget {
  const _GroupLogo(this.group);

  final Group group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: theme.avatarSm,
      height: theme.avatarSm,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: theme.radii.md),
      foregroundDecoration: BoxDecoration(
        borderRadius: theme.radii.md,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Image.asset(
        group.logo,
        fit: BoxFit.cover,
        semanticLabel: '${group.name} logo',
      ),
    );
  }
}
