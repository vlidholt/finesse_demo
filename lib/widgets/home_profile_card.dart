import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/data/network_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/network_links.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/saved_items_sheet.dart';
import 'package:una_demo/widgets/verified_badge.dart';

/// The left rail's summary of the signed-in user: cover photo, portrait,
/// name and headline, two figures and three shortcuts.
class HomeProfileCard extends StatelessWidget {
  const HomeProfileCard({super.key});

  /// The cover photograph's height: the card's own picture, not a step of
  /// any scale.
  static const _coverHeight = 76.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const me = People.me;
    final inset = theme.cardInset;
    final avatarSize = theme.avatarXl;
    void openProfile() => context.goTo(DemoDestination.profile);

    return Card(
      style: CardTheme(padding: EdgeInsets.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Image.asset(
                HomeData.cover,
                height: _coverHeight,
                width: double.infinity,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
              Padding(
                // The portrait rises half its height over the cover.
                padding: EdgeInsets.fromLTRB(
                  inset,
                  _coverHeight - avatarSize / 2,
                  inset,
                  inset,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Pressable(
                      onPressed: openProfile,
                      semanticLabel: 'Your profile',
                      builder: (context, states) => FocusRing(
                        visible: states.contains(WidgetState.focused),
                        borderRadius: theme.radii.full,
                        child: PersonAvatar(
                          me,
                          size: avatarSize,
                          ringColor: scheme.card,
                          ringWidth: 3,
                        ),
                      ),
                    ),
                    const Gap.md(),
                    Row(
                      children: [
                        Flexible(
                          child: HomeTextLink(
                            me.name,
                            onPressed: openProfile,
                            style: theme.textTheme.h4.copyWith(
                              color: scheme.foreground,
                            ),
                          ),
                        ),
                        if (me.verified) ...[
                          const Gap.xs(),
                          const VerifiedBadge(),
                        ],
                      ],
                    ),
                    Text(
                      me.headline,
                      // The stronger of the two secondary inks.
                      style: theme.textTheme.muted.copyWith(
                        color: scheme.foregroundSubtle,
                      ),
                    ),
                    if (me.location case final location?) ...[
                      const Gap.sm(),
                      Row(
                        children: [
                          PhosphorIcon(
                            PhosphorIconsRegular.mapPin,
                            size: theme.iconBeside(theme.textTheme.muted),
                            color: scheme.mutedForeground,
                          ),
                          const Gap.xs(),
                          Flexible(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Flush rules: the blocks on either side carry the space, whatever
          // margin the style gives a divider.
          const Divider(margin: EdgeInsets.zero),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: inset,
              vertical: theme.gap(GapSize.md),
            ),
            child: UnaColumn(
              gap: GapSize.sm,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final stat in HomeData.profileStats)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        stat.value,
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.tint,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Divider(margin: EdgeInsets.zero),
          Padding(
            padding: EdgeInsets.all(theme.gap(GapSize.sm)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final shortcut in HomeData.shortcuts)
                  Button.ghost(
                    style: ButtonTheme(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.gap(GapSize.sm),
                      ),
                      gap: theme.gap(GapSize.sm),
                      mainAxisAlignment: MainAxisAlignment.start,
                      foregroundColor: scheme.foregroundSubtle,
                    ),
                    leading: PhosphorIcon(shortcut.icon),
                    onPressed: () => switch (shortcut.label) {
                      'Groups' => openNetworkSection(
                        context,
                        NetworkSection.groups,
                      ),
                      'Events' => openNetworkSection(
                        context,
                        NetworkSection.events,
                      ),
                      _ => showSavedItems(context),
                    },
                    child: Text(shortcut.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
