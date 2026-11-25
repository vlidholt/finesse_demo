import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The sizes Demo's screens derive from the theme.
///
/// A screen names what a thing *is* — a small portrait, a glyph beside a
/// line of text, the inset of a card — and these turn that into a number
/// from the theme being shown, so that another style, a denser spacing or a
/// larger type scale reaches the screens too. Nothing here is a size of its
/// own: change the theme's avatar size, card padding or gap scale and every
/// one of them follows.
///
/// ```dart
/// final theme = Theme.of(context);
/// PersonAvatar(person, size: theme.avatarSm);
/// PhosphorIcon(PhosphorIconsRegular.mapPin, size: theme.iconBeside(style));
/// ```
extension DemoMetrics on ThemeData {
  /// The theme's avatar: the portrait or logo that leads a post, a row of
  /// a list, a suggestion. 40 in the default style.
  double get avatarMd => avatarTheme.size?.shortestSide ?? 40;

  /// Half an avatar: the overlapping portraits of a "12 mutual" line.
  double get avatarXs => _even(avatarMd * .5);

  /// A small portrait or logo: a comment's author, the bar's account
  /// button, a compact row.
  double get avatarSm => _even(avatarMd * .8);

  /// A large portrait or logo: the one a pane or a settings row is about.
  double get avatarLg => _even(avatarMd * 1.4);

  /// The largest portrait short of a profile's own: a preview card, a
  /// person to connect with.
  double get avatarXl => _even(avatarMd * 1.8);

  /// The side of a glyph set inline with text in [style]: a pin before a
  /// place, a caret after a label. A little over the type size, as the
  /// designs draw them (14 beside 12-point text, 16 beside 14).
  double iconBeside(TextStyle style) =>
      ((style.fontSize ?? 14) * 1.15).roundToDouble();

  /// A glyph that stands on its own in a row: the size the theme's buttons
  /// draw theirs at.
  double get glyph => style.buttonIconSize;

  /// A glyph that leads a block of text or fills a tile: the size the
  /// theme's icon buttons draw theirs at.
  double get glyphLg => style.iconButtonIconSize;

  /// The padding of the theme's cards, for a surface that is laid out like
  /// one without being a `Card`.
  EdgeInsets get cardInsets =>
      (cardTheme.padding ?? EdgeInsets.all(gap(GapSize.lg))).resolve(
        TextDirection.ltr,
      );

  /// One side of [cardInsets].
  double get cardInset => cardInsets.left;

  /// The extent of [size] on the theme's gap scale.
  double gap(GapSize size) => layoutTheme.gap(size);

  static double _even(double value) => (value / 2).roundToDouble() * 2;
}
