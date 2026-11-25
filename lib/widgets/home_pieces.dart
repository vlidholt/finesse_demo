import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// Small pieces several home-feed cards share.

/// The designs' `--coral`: the unseen-story ring and the "love" reaction.
/// It has no theme token.
Color coralOf(ThemeData theme) => theme.brightness == Brightness.dark
    ? const Color(0xFFD24B38)
    : const Color(0xFFC8432F);

/// A line of text that acts as a link: it underlines on hover and takes a
/// focus ring, but has no box of its own.
class HomeTextLink extends StatelessWidget {
  const HomeTextLink(
    this.text, {
    required this.style,
    required this.onPressed,
    this.maxLines = 1,
    super.key,
  });

  final String text;
  final TextStyle style;
  final VoidCallback onPressed;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Pressable(
      onPressed: onPressed,
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: theme.radii.sm,
        child: Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(
            decoration: states.contains(WidgetState.hovered)
                ? TextDecoration.underline
                : null,
            decorationColor: style.color,
          ),
        ),
      ),
    );
  }
}

/// A side-rail card with a heading row: "Your groups", "Add to your
/// network", "Trending in design".
///
/// The heading is the card's own `title`, in the card's title style. The
/// link, button or icon that ends the row rides in the same slot rather
/// than in `Card.action`, which pins its widget to the top of the header:
/// the designs centre it on the heading, whichever of the two is taller.
class HomeSectionCard extends StatelessWidget {
  const HomeSectionCard({
    required this.title,
    required this.child,
    this.trailing,
    super.key,
  });

  final String title;

  /// The link, button or icon at the end of the heading row.
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      style: CardTheme(sectionGap: Theme.of(context).gap(GapSize.md)),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      action: trailing,
      child: child,
    );
  }
}
