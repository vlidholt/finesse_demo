import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// The right rail's "Add to your network" card.
class HomeSuggestionsCard extends StatefulWidget {
  const HomeSuggestionsCard({this.onDismissed, super.key});

  /// Called when the card's close button is pressed.
  final VoidCallback? onDismissed;

  @override
  State<HomeSuggestionsCard> createState() => _HomeSuggestionsCardState();
}

class _HomeSuggestionsCardState extends State<HomeSuggestionsCard> {
  /// The names of the people an invitation has been sent to.
  final _invited = <String>{};

  void _toggle(String name) {
    setState(() {
      if (!_invited.remove(name)) _invited.add(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HomeSectionCard(
      title: 'Add to your network',
      trailing: IconButton.ghost(
        size: ButtonSize.sm,
        icon: const PhosphorIcon(PhosphorIconsRegular.x),
        semanticLabel: 'Dismiss',
        onPressed: widget.onDismissed,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          UnaColumn(
            // 16 between people; this card is desktop-only, where the
            // theme's `lg` gap is that.
            gap: GapSize.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final suggestion in HomeData.suggestions)
                _SuggestionRow(
                  suggestion,
                  invited: _invited.contains(suggestion.person.name),
                  onPressed: () => _toggle(suggestion.person.name),
                ),
            ],
          ),
          const Gap.lg(),
          Button.secondary(
            style: ButtonTheme(
              width: double.infinity,
              gap: theme.gap(GapSize.xs),
              textStyle: theme.textTheme.small,
            ),
            trailing: const PhosphorIcon(PhosphorIconsRegular.caretRight),
            onPressed: () => context.goTo(DemoDestination.network),
            child: const Flexible(
              child: Text(
                'Show all suggestions',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionRow extends StatelessWidget {
  const _SuggestionRow(
    this.suggestion, {
    required this.invited,
    required this.onPressed,
  });

  final Suggestion suggestion;
  final bool invited;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final person = suggestion.person;
    return UnaRow(
      gap: GapSize.md,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(person),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                person.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.p.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.foreground,
                ),
              ),
              Text(
                person.headline,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.muted,
              ),
              const Gap.xs(),
              // Scales down rather than overflowing if the column is ever
              // narrower than the stack of portraits.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: AvatarGroup(
                        size: theme.avatarXs,
                        overlap: theme.avatarXs / 3,
                        children: [
                          for (final avatar in suggestion.mutuals)
                            Image.asset(
                              avatar,
                              width: theme.avatarXs,
                              height: theme.avatarXs,
                              fit: BoxFit.cover,
                            ),
                        ],
                      ),
                    ),
                    const Gap.xs(),
                    Text(
                      '${suggestion.mutualCount} mutual',
                      maxLines: 1,
                      softWrap: false,
                      style: theme.textTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Button.outline(
          size: ButtonSize.sm,
          style: ButtonTheme(
            decoration: theme.buttonDecoration(radius: theme.radii.full),
            textStyle: theme.textTheme.small,
          ),
          leading: PhosphorIcon(
            invited
                ? PhosphorIconsRegular.clock
                : PhosphorIconsRegular.userPlus,
          ),
          onPressed: onPressed,
          child: Text(invited ? 'Pending' : 'Connect'),
        ),
      ],
    );
  }
}
