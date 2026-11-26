import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/assets.dart';
import 'package:una_demo/data/profile_data.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/profile_common.dart';
import 'package:una_demo/widgets/settings_controller.dart';
import 'package:una_demo/widgets/settings_links.dart';
import 'package:una_demo/widgets/user_menu.dart';
import 'package:una_demo/widgets/verified_badge.dart';

/// The bar of the profile on a phone: a `SliverAppBar.large` whose expanded
/// area is the cover photo, running up under the status bar, with the
/// person's name set large on it and the headline under the name.
///
/// As the page scrolls the name slides under the toolbar and comes back
/// small in it, and the bar takes its surface: the profile's own header
/// becomes the screen's app bar. The shell shows no app bar of its own over
/// the profile on a phone.
///
/// The three buttons name no variant, so the bar picks it: over its
/// photograph an outline disc, which reads on the picture while the bar is
/// expanded and on the bar's surface once it has collapsed; on Liquid
/// Glass plain icons on the bar's capsules, as on every other screen's
/// bar.
class ProfileMobileBar extends StatelessWidget {
  const ProfileMobileBar({
    required this.onBack,
    required this.onSearch,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onSearch;

  /// The height of the cover under the toolbar: the profile's own picture
  /// size, on no scale.
  static const coverHeight = 132.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const person = ProfileData.person;
    // The buttons sit 12 from the edges, inside the page's 16 margin.
    final inset = theme.gap(GapSize.md);
    IconButton button({
      required Widget icon,
      required String semanticLabel,
      required VoidCallback onPressed,
    }) => IconButton(
      icon: icon,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
    );

    // The bar follows the scroll in paint, so every frame of its collapse
    // paints it again. Its buttons do not change with it: each is a layer
    // of its own, and a frame moves them instead of painting them.
    return SliverAppBar.large(
      padding: EdgeInsets.symmetric(horizontal: inset),
      actionsGap: theme.gap(GapSize.sm),
      // The profile is a destination, not a pushed page: its back button
      // is its own, and goes Home.
      leading: RepaintBoundary(
        child: button(
          icon: PhosphorIcon(
            Directionality.of(context) == TextDirection.rtl
                ? PhosphorIconsRegular.arrowRight
                : PhosphorIconsRegular.arrowLeft,
          ),
          semanticLabel: 'Back',
          onPressed: onBack,
        ),
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: person.name),
            if (person.verified)
              const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: _TitleSeal(),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(person.headline),
      expandedHeight: coverHeight,
      background: const Image(
        image: AssetImage(DemoAssets.photoCoverMountainLake),
        fit: BoxFit.cover,
        semanticLabel: ProfileData.coverLabel,
      ),
      actions: [
        RepaintBoundary(
          child: button(
            icon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
            semanticLabel: 'Search',
            onPressed: onSearch,
          ),
        ),
        // On a phone this is the way to saved items, settings and the
        // light/dark switch.
        RepaintBoundary(
          child: UserMenu(
            showProfile: false,
            builder: (context, controller, _) => button(
              icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
              semanticLabel: 'More options',
              onPressed: controller.toggle,
            ),
          ),
        ),
      ],
    );
  }
}

/// The verified seal after the name in the bar's title, sized to whichever
/// of the two titles — large or small — it is drawn in.
class _TitleSeal extends StatelessWidget {
  const _TitleSeal();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: Theme.of(context).gap(GapSize.xs),
      ),
      child: VerifiedBadge(style: DefaultTextStyle.of(context).style),
    );
  }
}

/// Who the person is, under the [ProfileMobileBar]: the portrait beside the
/// numbers, then the actions and the "Open to work" tile.
class ProfileMobileHeader extends StatelessWidget {
  const ProfileMobileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final margin = (theme.layoutTheme.pagePadding ?? const EdgeInsets.all(16))
        .resolve(Directionality.of(context));
    return Padding(
      padding: EdgeInsets.fromLTRB(
        margin.left,
        theme.gap(GapSize.sm),
        margin.right,
        0,
      ),
      child: const _Identity(),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const person = ProfileData.person;
    // The diameter of the mutual connections' faces.
    final mutualSize = theme.avatarXs;
    // A copy of the line's own theme style, so the heavier weight gets the
    // font's semibold face.
    final strong = theme.textTheme.muted.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.foreground,
    );
    // The designs space the meta line's parts with the `xs` gap rather than
    // with word spaces.
    const gap = WidgetSpan(child: Gap.xs());

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PersonAvatar(
              person,
              size: theme.avatarXl,
              // The portrait sits on the page here, not on a card.
              ringColor: scheme.background,
            ),
            const Gap.md(),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.gap(GapSize.xs),
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: ProfileData.followers, style: strong),
                        gap,
                        const TextSpan(text: ' followers ·'),
                        gap,
                        TextSpan(text: ProfileData.connections, style: strong),
                        gap,
                        const TextSpan(text: ' connections'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted,
                  ),
                  Row(
                    children: [
                      PhosphorIcon(
                        PhosphorIconsRegular.mapPin,
                        size: theme.iconBeside(theme.textTheme.muted),
                        color: scheme.mutedForeground,
                      ),
                      const Gap.xs(),
                      Expanded(
                        child: Text(
                          ProfileData.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ExcludeSemantics(
                        child: AvatarGroup(
                          size: mutualSize,
                          // The same 6 as the desktop's 24-point faces.
                          overlap: theme.gap(GapSize.xs),
                          children: [
                            for (final person in ProfileData.mutuals.take(3))
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
                        child: Text(
                          ProfileData.mutualCount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.caption,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap.md(),
        const _Actions(),
        const Gap.md(),
        const ProfileStatusTile(ProfileData.openToWork, compact: true),
      ],
    );
  }
}

/// "Open to", "Edit profile" and the share button, sharing the width.
class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UnaRow(
      gap: GapSize.sm,
      children: [
        Expanded(
          child: Button(
            leading: const PhosphorIcon(PhosphorIconsRegular.plusCircle),
            onPressed: () => openSettings(context, SettingsSection.privacy),
            child: const _ButtonLabel('Open to'),
          ),
        ),
        Expanded(
          child: Button.outline(
            onPressed: () => openSettings(context, SettingsSection.account),
            child: const _ButtonLabel('Edit profile'),
          ),
        ),
        IconButton.secondary(
          icon: const PhosphorIcon(PhosphorIconsRegular.export),
          style: ButtonTheme(
            // Squared to the text buttons' radius, as on the desktop.
            decoration: theme.buttonDecoration(radius: theme.radius),
          ),
          semanticLabel: 'Share profile',
          onPressed: () => copyLink(
            context,
            ProfileData.publicUrl,
            title: 'Profile link copied',
          ),
        ),
      ],
    );
  }
}

/// The label of a button that shares a row: it gives way, with an ellipsis,
/// rather than overflowing when the row is narrow or the text is large.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // A button lays its label out in a row at its natural width; `Flexible`
    // lets that row shrink it.
    return Flexible(
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
