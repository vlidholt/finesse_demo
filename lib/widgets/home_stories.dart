import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/widgets/compose_dialog.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// The stories row: "Add story", then one card per story.
///
/// On a desktop the five cards share the feed column's width; on a phone
/// they are fixed 92x140 cards in a row that scrolls sideways, edge to edge.
class HomeStories extends StatelessWidget {
  const HomeStories({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = theme.formFactor == FormFactor.mobile;
    final metrics = mobile ? _StoryMetrics.mobile : _StoryMetrics.desktop;
    final cards = <Widget>[
      _AddStoryCard(metrics: metrics),
      for (final story in HomeData.stories)
        _StoryCard(story: story, metrics: metrics, shortName: mobile),
    ];

    if (!mobile) {
      return Row(
        spacing: metrics.gap,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, card) in cards.indexed)
            Expanded(
              child: SizedBox(
                height: index == 0 ? metrics.addHeight : metrics.height,
                child: card,
              ),
            ),
        ],
      );
    }

    final margin = (theme.layoutTheme.pagePadding ?? const EdgeInsets.all(16))
        .resolve(Directionality.of(context));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Room for the cards' shadow, which the scroll view would clip.
      clipBehavior: Clip.none,
      padding: EdgeInsets.only(left: margin.left, right: margin.right),
      child: Row(
        spacing: metrics.gap,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, card) in cards.indexed)
            SizedBox(
              width: metrics.width! + (index == 0 ? 2 : 0),
              height: index == 0 ? metrics.addHeight : metrics.height,
              child: card,
            ),
        ],
      ),
    );
  }
}

/// The two sizes of a story card. Every number here is the design's; none
/// of them sits on the theme's scales.
class _StoryMetrics {
  const _StoryMetrics({
    required this.width,
    required this.height,
    required this.gap,
    required this.photoHeight,
    required this.addButtonSize,
    required this.addIconSize,
    required this.addFontSize,
    required this.addLabelInset,
    required this.avatarSize,
    required this.inset,
    required this.labelInset,
    required this.labelPadding,
    required this.fontSize,
    required this.lineHeight,
  });

  // The story rail is a picture component: a card's proportions, the
  // portrait and the label's type are fitted to the photograph and are its
  // own, on neither the gap nor the type scale. Only its corners and its
  // colours come from the theme.
  static const desktop = _StoryMetrics(
    width: null,
    height: 190,
    gap: 10,
    // 62% of the card.
    photoHeight: 190 * .62,
    addButtonSize: 36,
    addIconSize: 20,
    addFontSize: 13,
    addLabelInset: 12,
    avatarSize: 32,
    inset: 10,
    labelInset: 8,
    labelPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    fontSize: 12,
    lineHeight: 16,
  );

  static const mobile = _StoryMetrics(
    width: 92,
    height: 140,
    gap: 8,
    photoHeight: 86,
    addButtonSize: 30,
    addIconSize: 18,
    addFontSize: 11,
    addLabelInset: 10,
    avatarSize: 26,
    inset: 8,
    labelInset: 6,
    labelPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    fontSize: 11,
    lineHeight: 14,
  );

  /// Null where the cards flex.
  final double? width;
  final double height;
  final double gap;

  /// The height of the portrait at the top of the "Add story" card.
  final double photoHeight;
  final double addButtonSize;
  final double addIconSize;

  /// "Add story" is a point larger than the story labels on a desktop.
  final double addFontSize;

  /// The space under the "Add story" label.
  final double addLabelInset;
  final double avatarSize;

  /// The portrait's distance from the card's top start corner.
  final double inset;

  /// The name label's distance from the card's edges.
  final double labelInset;
  final EdgeInsets labelPadding;
  final double fontSize;
  final double lineHeight;

  /// The "Add story" card's height. The designs size its content and draw
  /// the hairline outside that, so it stands a point proud of the
  /// photographs on every side.
  double get addHeight => height + 2;

  /// The card's corners, from the theme's scale: a step tighter on a phone,
  /// where the card is smaller.
  BorderRadius borderRadius(ThemeData theme) =>
      identical(this, mobile) ? theme.radii.lg : theme.radii.xl;

  /// The corners of the name label inside the card.
  BorderRadius labelRadius(ThemeData theme) =>
      identical(this, mobile) ? theme.radii.sm : theme.radii.md;
}

class _AddStoryCard extends StatelessWidget {
  const _AddStoryCard({required this.metrics});

  final _StoryMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sideInset = theme.gap(GapSize.sm);
    return Card(
      onTap: () => showComposeDialog(context),
      style: CardTheme(
        padding: EdgeInsets.zero,
        borderRadius: metrics.borderRadius(theme),
        height: metrics.addHeight,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      child: SizedBox(
        height: metrics.height,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: metrics.photoHeight,
              child: Image.asset(
                People.me.avatar,
                fit: BoxFit.cover,
                excludeFromSemantics: true,
              ),
            ),
            Positioned(
              top: metrics.photoHeight - metrics.addButtonSize / 2,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: metrics.addButtonSize,
                  height: metrics.addButtonSize,
                  decoration: ShapeDecoration(
                    color: scheme.tint,
                    shape: CircleBorder(
                      side: BorderSide(
                        color: scheme.card,
                        width: 3,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                  ),
                  child: PhosphorIcon(
                    PhosphorIconsRegular.plus,
                    size: metrics.addIconSize,
                    color: scheme.tintForeground,
                  ),
                ),
              ),
            ),
            Positioned(
              left: sideInset,
              right: sideInset,
              bottom: metrics.addLabelInset,
              child: Text(
                'Add story',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.small.copyWith(
                  fontSize: metrics.addFontSize,
                  height: metrics.lineHeight / metrics.addFontSize,
                  fontWeight: FontWeight.w600,
                  color: scheme.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scrim behind a story's name: denser than the designs' 32%, which sat
/// on a blur of the photograph.
const _labelScrim = Color(0x8009090B);

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.story,
    required this.metrics,
    required this.shortName,
  });

  final Story story;
  final _StoryMetrics metrics;

  /// Whether the label is the given name only, as on a phone.
  final bool shortName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = story.person;
    return Pressable(
      onPressed: () => showStoryViewer(context, story),
      semanticLabel: '${person.name}’s story',
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: metrics.borderRadius(theme),
        // The shadow sits outside the clip that rounds the photograph.
        child: DecoratedBox(
          decoration: ShadowDecoration.box(
            borderRadius: metrics.borderRadius(theme),
            shadows: theme.cardTheme.shadows ?? const [],
          ),
          child: ClipRRect(
            borderRadius: metrics.borderRadius(theme),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  story.image,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                PositionedDirectional(
                  top: metrics.inset,
                  start: metrics.inset,
                  child: _StoryAvatar(person: person, size: metrics.avatarSize),
                ),
                Positioned(
                  left: metrics.labelInset,
                  right: metrics.labelInset,
                  bottom: metrics.labelInset,
                  // A scrim on a photograph: these colours do not follow
                  // the theme. Not frosted: a backdrop filter per story
                  // would need a layer per card to keep the page out of
                  // its blur, and the rail is on screen whenever the feed
                  // is at rest.
                  child: Glass(
                    frosted: false,
                    color: _labelScrim,
                    border: Border.all(color: const Color(0x2EFFFFFF)),
                    borderRadius: metrics.labelRadius(theme),
                    padding: metrics.labelPadding,
                    child: Text(
                      shortName ? person.firstName : person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        fontSize: metrics.fontSize,
                        height: metrics.lineHeight / metrics.fontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A story's author: the portrait in a card-coloured ring on a coral disc.
///
/// The ring covers the disc to its edge, which leaves the coral as the
/// faintest fringe — the "unseen" mark. `PersonAvatar.storyRing` draws a
/// stronger version in the alert colour; the designs use coral here.
class _StoryAvatar extends StatelessWidget {
  const _StoryAvatar({required this.person, required this.size});

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: const CircleBorder(),
        color: coralOf(theme),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: PersonAvatar(
          person,
          size: size,
          ringColor: theme.colorScheme.card,
        ),
      ),
    );
  }
}
