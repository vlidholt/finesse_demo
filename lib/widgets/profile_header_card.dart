import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/assets.dart';
import 'package:una_demo/data/profile_data.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/profile_common.dart';
import 'package:una_demo/widgets/saved_items_sheet.dart';
import 'package:una_demo/widgets/settings_controller.dart';
import 'package:una_demo/widgets/settings_links.dart';
import 'package:una_demo/widgets/verified_badge.dart';

/// The desktop profile's first card: the cover photo, who the person is, the
/// status tiles and the tab bar that switches the sections below it.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    required this.tab,
    required this.onTabSelected,
    super.key,
  });

  final ProfileTab tab;
  final ValueChanged<ProfileTab> onTabSelected;

  /// The cover's height, and the portrait that straddles its bottom edge:
  /// the profile's own picture sizes, on no scale.
  static const _coverHeight = 260.0;
  static const _avatarSize = 152.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = theme.layoutTheme;

    return Card(
      style: CardTheme(
        padding: EdgeInsets.zero,
        borderRadius: theme.radii.xl3,
        rowMainAxisSize: MainAxisSize.max,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _coverHeight,
                child: Image(
                  image: AssetImage(DemoAssets.photoCoverMountainLake),
                  fit: BoxFit.cover,
                  semanticLabel: ProfileData.coverLabel,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  layout.gap(GapSize.xl),
                  _coverHeight - _avatarSize / 2,
                  layout.gap(GapSize.xl),
                  layout.gap(GapSize.xl),
                ),
                child: const _Identity(),
              ),
              PositionedDirectional(
                top: layout.gap(GapSize.lg),
                end: layout.gap(GapSize.lg),
                child: ProfileCoverButton(
                  icon: PhosphorIconsRegular.camera,
                  label: 'Edit cover',
                  onPressed: () =>
                      openSettings(context, SettingsSection.account),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.gap(GapSize.lg)),
            child: TabBar<ProfileTab>(
              value: tab,
              onChanged: onTabSelected,
              tabs: [
                for (final tab in ProfileTab.values)
                  Tab(value: tab, child: Text(tab.label)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Everything between the cover and the tab bar.
class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final layout = theme.layoutTheme;
    const person = ProfileData.person;
    // A copy of the line's own theme style, so the heavier weight gets the
    // font's semibold face.
    final strong = theme.textTheme.p.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.foreground,
    );
    // The diameter of the mutual connections' faces.
    final mutualSize = theme.avatarXs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PersonAvatar(
              person,
              size: ProfileHeaderCard._avatarSize,
              ringColor: scheme.card,
              ringWidth: 5,
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(bottom: layout.gap(GapSize.sm)),
              child: UnaRow(
                gap: GapSize.sm,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Button.outline(
                    leading: const PhosphorIcon(PhosphorIconsRegular.export),
                    onPressed: () => copyLink(
                      context,
                      ProfileData.publicUrl,
                      title: 'Profile link copied',
                    ),
                    child: const Text('Share profile'),
                  ),
                  IconButton.secondary(
                    icon: const PhosphorIcon(PhosphorIconsRegular.pencilSimple),
                    style: ButtonTheme(
                      iconSize: theme.buttonSizesTheme.regular?.iconSize,
                      // A square that takes the text button's radius to sit
                      // beside one, where the style's icon buttons are round.
                      decoration: theme.buttonDecoration(radius: theme.radius),
                    ),
                    semanticLabel: 'Edit profile',
                    onPressed: () =>
                        openSettings(context, SettingsSection.account),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap.md(),
        Row(
          children: [
            Flexible(
              child: Semantics(
                header: true,
                child: Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.h1.copyWith(color: scheme.foreground),
                ),
              ),
            ),
            const Gap.sm(),
            if (person.verified) VerifiedBadge(style: theme.textTheme.h3),
            if (person.pronouns case final pronouns?) ...[
              const Gap.md(),
              Text(pronouns, style: theme.textTheme.muted),
            ],
          ],
        ),
        const Gap.xs(),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            ProfileData.headline,
            // The title style at the weight of running text.
            style: theme.textTheme.h4.copyWith(
              fontWeight: FontWeight.w400,
              color: scheme.foregroundSubtle,
            ),
          ),
        ),
        const Gap.md(),
        Wrap(
          spacing: layout.gap(GapSize.lg),
          runSpacing: theme.gap(GapSize.xs),
          children: [
            for (final meta in ProfileData.meta) ProfileMetaItem(meta),
          ],
        ),
        const Gap.md(),
        Row(
          children: [
            ExcludeSemantics(
              child: AvatarGroup(
                size: mutualSize,
                children: [
                  for (final person in ProfileData.mutuals)
                    Image.asset(
                      person.avatar,
                      width: mutualSize,
                      height: mutualSize,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
            ),
            const Gap.sm(),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: ProfileData.followers, style: strong),
                    const TextSpan(text: ' followers · '),
                    TextSpan(text: ProfileData.connections, style: strong),
                    const TextSpan(
                      text: ' connections · ${ProfileData.mutualSummary}',
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.p.copyWith(
                  color: scheme.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        const Gap.lg(),
        Wrap(
          spacing: layout.gap(GapSize.sm),
          runSpacing: layout.gap(GapSize.sm),
          children: [
            Button(
              leading: const PhosphorIcon(PhosphorIconsRegular.plusCircle),
              onPressed: () => openSettings(context, SettingsSection.privacy),
              child: const Text('Open to'),
            ),
            Button.outline(
              onPressed: () => openSettings(context, SettingsSection.account),
              child: const Text('Add section'),
            ),
            Button.outline(
              onPressed: () => showSavedItems(context),
              child: const Text('Resources'),
            ),
          ],
        ),
        const Gap.lg(),
        const _StatusTiles(),
      ],
    );
  }
}

/// "Open to work" and "Available for talks": side by side, or stacked when
/// the card is too narrow for two readable tiles.
class _StatusTiles extends StatelessWidget {
  const _StatusTiles();

  @override
  Widget build(BuildContext context) {
    final gap = Theme.of(context).layoutTheme.gap(GapSize.md);
    const tiles = [
      ProfileStatusTile(ProfileData.openToWork),
      ProfileStatusTile(ProfileData.availableForTalks),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: tiles,
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: [for (final tile in tiles) Expanded(child: tile)],
          ),
        );
      },
    );
  }
}
