import 'package:finesse_demo/app_state.dart';
import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/widgets/person_avatar.dart';
import 'package:finesse_demo/widgets/saved_items_sheet.dart';
import 'package:finesse_demo/widgets/settings_links.dart';
import 'package:finesse_demo/widgets/verified_badge.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The signed-in user's menu: their profile, saved items, settings and the
/// light/dark switch.
///
/// The desktop app bar opens it from the avatar pill. On a phone there is no
/// pill, so the Profile screen opens the same menu from its "More options"
/// button:
///
/// ```dart
/// UserMenu(
///   showProfile: false,
///   builder: (context, controller, _) => IconButton.ghost(
///     icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
///     semanticLabel: 'More options',
///     onPressed: controller.toggle,
///   ),
/// )
/// ```
class UserMenu extends StatelessWidget {
  const UserMenu({
    required this.builder,
    this.showProfile = true,
    this.anchor = endAligned,
    super.key,
  });

  /// Builds the trigger; call `controller.toggle` from its `onPressed`.
  final DropdownMenuTriggerBuilder builder;

  /// Whether the menu offers "View profile". Turn it off on the profile
  /// itself.
  final bool showProfile;

  /// Where the menu opens. Defaults to below the trigger, aligned to its end
  /// edge, since the trigger usually sits at the end of a bar.
  final AnchorBase anchor;

  /// Below the trigger and aligned to its end edge, flipping above it near
  /// the bottom of the screen.
  static const endAligned = AnchorAuto(
    offset: Offset(0, 4),
    targetAnchor: AlignmentDirectional.bottomEnd,
    followerAnchor: AlignmentDirectional.bottomStart,
    fallback: AnchorAuto(
      offset: Offset(0, 4),
      targetAnchor: AlignmentDirectional.bottomStart,
      followerAnchor: AlignmentDirectional.bottomEnd,
      fallback: AnchorAuto(
        offset: Offset(0, -4),
        targetAnchor: AlignmentDirectional.topEnd,
        followerAnchor: AlignmentDirectional.topStart,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const divider = Divider(
      margin: EdgeInsets.symmetric(vertical: 4),
    );

    return DropdownMenu(
      anchor: anchor,
      constraints: const BoxConstraints(minWidth: 248, maxWidth: 288),
      // Built when the menu opens, so the labels describe the state the app
      // is in at that moment. `context` is the UserMenu's own: the menu's
      // overlay is still below the app's providers, but this keeps the
      // callbacks valid after the menu has closed.
      itemsBuilder: (_) {
        final dark =
            themeModeProvider.of(context).untrackedValue == ThemeMode.dark;
        return [
          const _Identity(),
          divider,
          if (showProfile)
            MenuItem(
              leading: const PhosphorIcon(PhosphorIconsRegular.user),
              onPressed: () => context.goTo(DemoDestination.profile),
              child: const Text('View profile'),
            ),
          MenuItem(
            leading: const PhosphorIcon(PhosphorIconsRegular.bookmarkSimple),
            onPressed: () => showSavedItems(context),
            child: const Text('Saved items'),
          ),
          MenuItem(
            leading: const PhosphorIcon(PhosphorIconsRegular.gearSix),
            onPressed: () => openSettings(context),
            child: const Text('Settings'),
          ),
          MenuItem(
            leading: PhosphorIcon(
              dark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
            ),
            onPressed: () => toggleThemeMode(context),
            child: Text(dark ? 'Light mode' : 'Dark mode'),
          ),
        ];
      },
      builder: builder,
    );
  }
}

/// The menu's heading: who is signed in.
class _Identity extends StatelessWidget {
  const _Identity();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const me = People.me;
    // A menu row is inset twice — the gutter that stops its highlight short
    // of the menu's edge, then the style's item padding — and the heading
    // takes both, so the portrait lines up with the rows' icons.
    final step = theme.spacing.step / 4;
    return Padding(
      padding: (theme.contextMenuTheme.itemPadding ?? EdgeInsets.zero).add(
        EdgeInsets.symmetric(
          horizontal: theme.style.itemPaddingX * step,
          vertical: theme.style.itemPaddingY * step,
        ),
      ),
      child: FinesseRow(
        gap: GapSize.md,
        children: [
          const PersonAvatar(me),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FinesseRow(
                  gap: GapSize.xs,
                  children: [
                    Flexible(
                      child: Text(
                        me.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                    ),
                    if (me.verified) const VerifiedBadge(),
                  ],
                ),
                Text(
                  me.headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
