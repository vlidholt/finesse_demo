import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/verified_badge.dart';

/// Pieces the screens built after the designs share — Network,
/// Notifications, Search and Settings — so that the four of them use one
/// page title, one pill button and one way of saying "done".

/// A page's title, with a line under it and its actions at the end on a
/// desktop; the title alone on a phone. The Jobs page's header, for any
/// page.
class DemoPageHeader extends StatelessWidget {
  const DemoPageHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;

  /// The muted line under the title; left out on a phone.
  final String? subtitle;

  /// The buttons at the end of the row; left out on a phone.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = theme.layoutTheme;
    final heading = Semantics(
      header: true,
      child: Text(title, style: theme.textTheme.h1),
    );
    if (theme.formFactor == FormFactor.mobile) return heading;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: layout.gap(GapSize.xl),
      runSpacing: layout.gap(GapSize.md),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            if (subtitle case final subtitle?) ...[
              const Gap.xs(),
              Text(
                subtitle,
                style: theme.textTheme.p.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ],
        ),
        if (actions.isNotEmpty)
          UnaRow(
            gap: GapSize.sm,
            mainAxisSize: MainAxisSize.min,
            children: actions,
          ),
      ],
    );
  }
}

/// A heading on the page itself, over a list or a grid: "People you may
/// know", "Today". The Jobs list's "Top picks for you" line.
class DemoSectionHeading extends StatelessWidget {
  const DemoSectionHeading(this.title, {this.trailing, super.key});

  final String title;

  /// A link, a count or a menu at the end of the line.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.gap(GapSize.xs),
      ),
      // A wrap, so a long heading at a large text size pushes what ends
      // the line under itself instead of being cut short by it.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: theme.gap(GapSize.md),
        runSpacing: theme.gap(GapSize.xs),
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.h4,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// The label of a tab in a strip that fills a phone's width: "Mentions",
/// "My applications".
///
/// A tab's own text gives way with an ellipsis when its tab is too narrow.
/// In a strip of three or four across a phone that happens at the default
/// text size, and "Mentio…" beside "Jobs" reads as a fault; here the label
/// shrinks to fit instead, so the whole word stays. Where the strip hugs
/// its tabs, as on a desktop, it is the plain label.
class DemoTabLabel extends StatelessWidget {
  const DemoTabLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, maxLines: 1, softWrap: false),
    );
  }
}

/// A person's name with the verified seal after it.
class PersonName extends StatelessWidget {
  const PersonName(this.person, {this.style, this.onPressed, super.key});

  final Person person;

  /// Defaults to the 15-point semibold name of a post's author.
  final TextStyle? style;

  /// Makes the name a link.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effective =
        style ??
        theme.textTheme.large.copyWith(color: theme.colorScheme.foreground);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: onPressed == null
              ? Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: effective,
                )
              : HomeTextLink(
                  person.name,
                  onPressed: onPressed!,
                  style: effective,
                ),
        ),
        if (person.verified) ...[
          const Gap.xs(),
          const VerifiedBadge(),
        ],
      ],
    );
  }
}

/// A stack of portraits and a count: "14 mutual".
class MutualsLine extends StatelessWidget {
  const MutualsLine({
    required this.people,
    required this.label,
    this.size,
    this.alignment = MainAxisAlignment.start,
    super.key,
  });

  /// The portraits, first on top; three at most are shown.
  final List<Person> people;

  /// "14 mutual", "9 mutual connections".
  final String label;

  /// A portrait's diameter. Defaults to half the theme's avatar.
  final double? size;

  final MainAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = this.size ?? theme.avatarXs;
    // Initials are unreadable at this size: only portraits are stacked.
    final faces = [
      for (final person in people)
        if (person.avatar.isNotEmpty) person,
    ];
    return Row(
      mainAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (faces.isNotEmpty) ...[
          // Decorative: the label beside it says what it shows.
          ExcludeSemantics(
            child: AvatarGroup(
              size: size,
              overlap: size / 3,
              children: [
                for (final person in faces.take(3))
                  PersonAvatar(person, size: size),
              ],
            ),
          ),
          const Gap.xs(),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.caption,
          ),
        ),
      ],
    );
  }
}

/// The small pill beside a person, a page or a group: outlined until it is
/// pressed, filled once it is — "Connect" and "Pending", "Follow" and
/// "Following", "Join" and "Joined".
class DemoPillButton extends StatelessWidget {
  const DemoPillButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.done = false,
    this.doneLabel,
    this.doneIcon,
    this.primary = false,
    this.expand = false,
    super.key,
  });

  /// "Connect": an invitation, sent or still to send.
  const DemoPillButton.connect({
    required bool pending,
    required this.onPressed,
    this.expand = false,
    super.key,
  }) : label = 'Connect',
       icon = PhosphorIconsRegular.userPlus,
       done = pending,
       doneLabel = 'Pending',
       doneIcon = PhosphorIconsRegular.clock,
       primary = false;

  /// "Follow": a person or a page.
  const DemoPillButton.follow({
    required bool following,
    required this.onPressed,
    this.expand = false,
    super.key,
  }) : label = 'Follow',
       icon = PhosphorIconsRegular.plus,
       done = following,
       doneLabel = 'Following',
       doneIcon = PhosphorIconsRegular.check,
       primary = false;

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  /// Whether the button has been pressed.
  final bool done;
  final String? doneLabel;
  final IconData? doneIcon;

  /// Whether the button is the row's main action, filled in the primary
  /// colour: "Accept".
  final bool primary;

  /// Whether the button fills the width it is given.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Button(
      style: ButtonTheme(
        pressScale: 1,
        width: expand ? double.infinity : null,
        // A pill, where the style's text buttons are rounded rectangles.
        decoration: theme.buttonDecoration(radius: theme.radii.full),
        textStyle: theme.textTheme.small,
      ),
      variant: done
          ? ButtonVariant.secondary
          : primary
          ? ButtonVariant.primary
          : ButtonVariant.outline,
      size: ButtonSize.sm,
      leading: PhosphorIcon(done ? doneIcon ?? icon : icon),
      onPressed: onPressed,
      // Flexible, so a long label in a narrow column — a phone at a large
      // text size — is cut short rather than pushed out of the pill.
      child: Flexible(
        child: Text(
          done ? doneLabel ?? label : label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// A company's, school's or group's mark on a rounded square with a
/// hairline — or, for something that has no logo, a glyph on an accent
/// tile of the same size.
class DemoMark extends StatelessWidget {
  const DemoMark({
    required this.label,
    this.asset,
    this.icon,
    this.size,
    super.key,
  }) : assert(asset != null || icon != null, 'A mark needs a logo or a glyph.');

  /// One of the `DemoAssets.logo*`.
  final String? asset;

  /// The glyph shown when there is no [asset].
  final IconData? icon;

  /// Whose mark it is: "Halcyon".
  final String label;

  /// The mark's side. Defaults to the theme's avatar.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = this.size ?? theme.avatarMd;
    // The designs round a small mark on the control radius and a larger
    // one a step further.
    final radius = size < theme.avatarMd ? theme.radius : theme.radii.lg;
    final logo = asset;
    if (logo == null) {
      return IconTile(
        icon: PhosphorIcon(icon, semanticLabel: label),
        size: size,
        iconSize: size / 2,
        borderRadius: radius,
      );
    }
    return Container(
      width: size,
      height: size,
      // The designs outline a logo inside its own box, so a pale one keeps
      // its shape on a pale card.
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          logo,
          fit: BoxFit.cover,
          semanticLabel: '$label logo',
        ),
      ),
    );
  }
}

/// A calendar leaf: the month in small capitals over the day.
///
/// On a card it takes the theme's accent pair; the home feed's event card
/// passes literal colours for the one that sits on glass over a photograph.
class DemoDateTile extends StatelessWidget {
  const DemoDateTile({
    required this.month,
    required this.day,
    this.size,
    this.color,
    this.monthColor,
    this.dayColor,
    super.key,
  });

  /// "NOV".
  final String month;

  /// "28".
  final String day;

  /// The tile's side. Defaults to the theme's avatar.
  final double? size;

  /// The tile's fill, the month's ink and the day's: the theme's accent
  /// pair and its foreground unless the tile sits on a photograph.
  final Color? color;
  final Color? monthColor;
  final Color? dayColor;

  // The tile's own type: two lines fitted to the square, as a fraction of
  // its side (10 and 18 points in a 44-point tile). Not on the type scale.
  static const _monthSize = .23;
  static const _monthTracking = .06;
  static const _daySize = .41;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final size = this.size ?? theme.avatarMd;
    final base = theme.textTheme.small.copyWith(fontWeight: FontWeight.w700);
    // The glyphs are fitted to the tile, so a larger text size does not
    // push them out of it.
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      width: size * scale,
      height: size * scale,
      decoration: BoxDecoration(
        color: color ?? scheme.accent,
        borderRadius: theme.radii.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: base.copyWith(
              fontSize: size * _monthSize,
              height: 1,
              letterSpacing: size * _monthSize * _monthTracking,
              color: monthColor ?? scheme.tint,
            ),
          ),
          Text(
            day,
            style: base.copyWith(
              fontSize: size * _daySize,
              height: 1.1,
              color: dayColor ?? scheme.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Says that something happened, in a toast: "Invitation sent to Elena".
///
/// With an [actionLabel] the toast carries a button — usually "Undo" —
/// that calls [onAction] and closes it.
///
/// The [variant] says what kind of news it is: [ToastVariant.success] for
/// something the user asked for that is now done and kept (saved, sent,
/// published), [ToastVariant.destructive] for something taken away
/// (deleted, withdrawn, declined), and the neutral default for the rest.
void showDemoToast(
  BuildContext context,
  String title, {
  String? description,
  String? actionLabel,
  VoidCallback? onAction,
  ToastVariant variant = ToastVariant.neutral,
}) {
  // Not every host has a toaster (a widget test that pumps one piece).
  final toaster = Toaster.maybeOf(context);
  if (toaster == null) return;
  final id = UniqueKey();
  toaster.show(
    Toast(
      id: id,
      variant: variant,
      title: Text(title),
      description: description == null ? null : Text(description),
      action: actionLabel == null
          ? null
          : Button.outline(
              size: ButtonSize.sm,
              onPressed: () {
                onAction?.call();
                toaster.dismiss(id);
              },
              child: Text(actionLabel),
            ),
    ),
  );
}
