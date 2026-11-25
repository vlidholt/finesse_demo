import 'package:finesse_demo/data/profile_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/widgets/settings_controller.dart';
import 'package:finesse_demo/widgets/settings_links.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// A card of the profile: a heading row, then content.
///
/// ```dart
/// ProfileSection(
///   title: 'About',
///   trailing: IconButton.ghost(...),
///   child: Text(about),
/// )
/// ```
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    required this.title,
    required this.child,
    this.trailing,
    this.padding,
    super.key,
  });

  final String title;

  /// The widget at the end of the heading row: an edit button, a link.
  final Widget? trailing;

  final Widget child;

  /// Padding inside the card, in place of the theme's.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
    return Card(
      style: CardTheme(
        padding: padding,
        sectionGap: Theme.of(context).gap(GapSize.md),
        rowMainAxisSize: MainAxisSize.max,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      title: heading,
      action: trailing,
      child: child,
    );
  }
}

/// The small borderless button in a card's heading row: edit, add.
class ProfileHeaderAction extends StatelessWidget {
  const ProfileHeaderAction({
    required this.icon,
    required this.label,
    this.onPressed,
    super.key,
  });

  final IconData icon;

  /// What the button does, for assistive technology.
  final String label;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.ghost(
      size: ButtonSize.sm,
      style: ButtonTheme(
        // The designs draw a text button's 18-point glyph in the small icon
        // button, not the icon button's own 20.
        iconSize: Theme.of(context).buttonSizesTheme.regular?.iconSize,
      ),
      icon: PhosphorIcon(icon),
      semanticLabel: label,
      // Editing lives in one place: the Account page of Settings.
      onPressed:
          onPressed ?? () => openSettings(context, SettingsSection.account),
    );
  }
}

/// A company, school or group mark: a rounded square with a hairline.
class ProfileLogo extends StatelessWidget {
  const ProfileLogo(
    this.asset, {
    required this.label,
    this.size,
    this.radius,
    super.key,
  });

  /// One of the `DemoAssets.logo*`.
  final String asset;

  /// The image's description: "Halcyon logo".
  final String label;

  /// The mark's side. Defaults to the theme's avatar.
  final double? size;

  /// The corner radius. Defaults to the theme's `lg` step.
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = this.size ?? theme.avatarMd;
    final effectiveRadius = radius ?? theme.radii.lg;
    return Container(
      width: size,
      height: size,
      // The designs outline the mark inside its own box.
      foregroundDecoration: BoxDecoration(
        borderRadius: effectiveRadius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Image.asset(asset, fit: BoxFit.cover, semanticLabel: label),
      ),
    );
  }
}

/// A status tile of the header: an icon, a title, a line of detail and,
/// optionally, a link.
class ProfileStatusTile extends StatelessWidget {
  const ProfileStatusTile(
    this.status, {
    this.compact = false,
    this.onAction,
    super.key,
  });

  final ProfileStatus status;

  /// The phone's form: the shorter wording, tighter padding and no link.
  final bool compact;

  /// Called when the link is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = status.positive ? scheme.success : scheme.foreground;
    final layout = theme.layoutTheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: layout.gap(GapSize.lg),
        vertical: layout.gap(GapSize.md),
      ),
      decoration: BoxDecoration(
        color: status.positive ? scheme.successMuted : scheme.muted,
        borderRadius: theme.radii.lg,
        border: Border.all(color: scheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: layout.gap(GapSize.md),
        children: [
          PhosphorIcon(
            status.icon,
            size: theme.glyphLg,
            color: status.positive ? scheme.success : scheme.foregroundSubtle,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.foreground,
                  ),
                ),
                Text(
                  compact ? status.shortBody ?? status.body : status.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(
                    color: scheme.foregroundSubtle,
                  ),
                ),
                if (!compact)
                  ProfileTextLink(
                    status.action,
                    color: accent,
                    // The status is a privacy preference; the talks are
                    // arranged in Messages.
                    onPressed:
                        onAction ??
                        () => status.positive
                            ? openSettings(context, SettingsSection.privacy)
                            : context.goTo(DemoDestination.messages),
                    style: theme.textTheme.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A line of text that is a link: "See all", "Show details".
class ProfileTextLink extends StatelessWidget {
  const ProfileTextLink(
    this.text, {
    required this.onPressed,
    this.color,
    this.style,
    super.key,
  });

  final String text;
  final VoidCallback? onPressed;

  /// Defaults to the theme's accent foreground.
  final Color? color;

  /// Defaults to the theme's small text style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = style ?? theme.textTheme.small;
    return Pressable(
      onPressed: onPressed,
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: theme.radii.sm,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: effectiveStyle.copyWith(
            color: color ?? theme.colorScheme.tint,
            decoration: states.contains(WidgetState.hovered)
                ? TextDecoration.underline
                : TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// A frosted button that sits on the cover photograph.
///
/// With a [label] it is the desktop's "Edit cover": a light glass rectangle.
/// Without one it is the phone's round header button on a dark scrim. Both
/// are drawn in literal white, because they sit on a photograph and do not
/// follow the theme's colours; their sizes are the theme's button sizes.
class ProfileCoverButton extends StatelessWidget {
  const ProfileCoverButton({
    required this.icon,
    required this.onPressed,
    this.label,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final String? label;

  /// The description of an icon-only button.
  final String? semanticLabel;

  final VoidCallback? onPressed;

  static const _white = Color(0xFFFFFFFF);
  static const _hairline = Color(0x4DFFFFFF);

  /// `rgba(255,255,255,.22)`, and a step heavier under the pointer.
  static const _lightFill = Color(0x38FFFFFF);
  static const _lightFillHover = Color(0x52FFFFFF);

  /// `rgba(9,9,11,.24)`, and a step heavier under the pointer.
  static const _darkFill = Color(0x3D09090B);
  static const _darkFillHover = Color(0x5C09090B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sizes = theme.buttonSizesTheme;
    final text = label;
    final round = text == null;
    final size = round ? sizes.icon! : sizes.regular!;
    final radius = round ? theme.radii.full : theme.radius;

    return Pressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        return FocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: radius,
          child: Glass(
            color: round
                ? (hovered ? _darkFillHover : _darkFill)
                : (hovered ? _lightFillHover : _lightFill),
            border: Border.all(color: _hairline),
            borderRadius: radius,
            width: round ? size.height : null,
            height: size.height,
            padding: round ? null : size.padding,
            alignment: round ? Alignment.center : null,
            child: round
                ? PhosphorIcon(icon, size: size.iconSize, color: _white)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: theme.gap(GapSize.sm),
                    children: [
                      PhosphorIcon(icon, size: size.iconSize, color: _white),
                      Text(
                        text,
                        style: theme.textTheme.small.copyWith(
                          height: 1,
                          color: _white,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// An icon + text pair of a meta line: muted, or a link in the accent ink.
class ProfileMetaItem extends StatelessWidget {
  const ProfileMetaItem(this.meta, {super.key});

  final ProfileMeta meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = meta.link
        ? theme.textTheme.small.copyWith(color: theme.colorScheme.tint)
        : theme.textTheme.muted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PhosphorIcon(
          meta.icon,
          size: theme.iconBeside(style),
          color: style.color,
        ),
        const Gap.xs(),
        Flexible(
          child: Text(
            meta.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}
