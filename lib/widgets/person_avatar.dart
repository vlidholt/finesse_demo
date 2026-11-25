import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// A [Person]'s portrait.
///
/// ```dart
/// PersonAvatar(People.omar, showOnline: true)
/// PersonAvatar(People.omar, size: Theme.of(context).avatarSm)
/// ```
///
/// Three optional decorations, as the designs use them:
///
/// * [showOnline] pins the presence dot to the bottom end, sized a quarter
///   of the avatar (10 on a 40 avatar, 12 on a 48 one).
/// * [ringColor] draws a ring flush around the portrait without changing
///   the widget's size — the card-coloured ring that separates an avatar
///   from a cover photo, or the tint ring on the selected "Me" tab.
/// * [storyRing] is the unseen-story treatment on the home feed's story
///   rail; it adds 2 logical pixels on every side.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(
    this.person, {
    this.size,
    this.showOnline = false,
    this.storyRing = false,
    this.ringColor,
    this.ringWidth = 2,
    this.onlineRingColor,
    super.key,
  });

  final Person person;

  /// The portrait's diameter. Defaults to the theme's avatar size; the
  /// steps around it are `theme.avatarXs`, `avatarSm`, `avatarLg` and
  /// `avatarXl`.
  final double? size;

  /// Whether to show the presence dot. Pass `person.online` to show it only
  /// for someone who is active.
  final bool showOnline;

  /// Whether to wrap the portrait in the story ring.
  final bool storyRing;

  /// The colour of a ring painted just outside the portrait; null for none.
  final Color? ringColor;

  /// The width of that ring.
  final double ringWidth;

  /// The colour of the gap around the presence dot. Defaults to the theme's
  /// card colour; pass the surface the avatar sits on when it is not a card.
  final Color? onlineRingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = this.size ?? theme.avatarMd;

    Widget avatar = Avatar(
      person.avatar,
      size: Size.square(size),
      fit: BoxFit.cover,
      fallback: Text(
        person.initials,
        // The portrait's own type: initials fitted to the disc.
        style: theme.textTheme.small.copyWith(
          fontSize: size * .36,
          height: 1,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );

    final ring = ringColor;
    if (ring != null) {
      avatar = _ringed(avatar, ring, ringWidth);
    }

    if (storyRing) {
      // The designs put a card-coloured ring over a disc in the alert
      // colour, which leaves the alert colour as a hairline around it.
      avatar = DecoratedBox(
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          color: theme.colorScheme.destructive,
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: _ringed(avatar, theme.colorScheme.card, 1.5),
        ),
      );
    }

    if (showOnline) {
      avatar = IndicatorBadge(
        alignment: AlignmentDirectional.bottomEnd,
        overhang: 0,
        size: (size / 4).roundToDouble(),
        ringColor: onlineRingColor,
        semanticLabel: 'Active now',
        child: avatar,
      );
    }

    return Semantics(
      image: true,
      label: person.name,
      child: avatar,
    );
  }

  static Widget _ringed(Widget child, Color color, double width) {
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: ShapeDecoration(
        shape: CircleBorder(
          side: BorderSide(
            color: color,
            width: width,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
      child: child,
    );
  }
}
