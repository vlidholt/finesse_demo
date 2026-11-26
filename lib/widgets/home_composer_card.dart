import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/widgets/compose_dialog.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// The desktop feed's "Start a post" card: the signed-in user's portrait, a
/// pill that opens the composer, and four attachment shortcuts.
class HomeComposerCard extends StatelessWidget {
  const HomeComposerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void compose() => showComposeDialog(context);

    return Card(
      style: CardTheme(padding: EdgeInsets.all(theme.gap(GapSize.lg))),
      child: UnaColumn(
        gap: GapSize.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          UnaRow(
            gap: GapSize.md,
            children: [
              const PersonAvatar(People.me),
              Expanded(
                // A button dressed as a field: tapping it opens the
                // composer rather than taking text here.
                child: Button.outline(
                  size: ButtonSize.lg,
                  style: ButtonTheme(
                    width: double.infinity,
                    decoration: theme.buttonDecoration(
                      radius: theme.radii.full,
                    ),
                    backgroundColor: scheme.muted,
                    hoverBackgroundColor: scheme.secondary,
                    foregroundColor: scheme.mutedForeground,
                    hoverForegroundColor: scheme.mutedForeground,
                    mainAxisAlignment: MainAxisAlignment.start,
                    pressedOffset: Offset.zero,
                    // The size of the theme's `large`, at the weight of
                    // running text: a placeholder, not a label.
                    textStyle: theme.textTheme.large.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  mouseCursor: SystemMouseCursors.text,
                  onPressed: compose,
                  child: Flexible(
                    child: Text(
                      'Start a post, ${People.me.firstName}…',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final action in HomeData.composerActions)
                Flexible(
                  child: Button.ghost(
                    style: ButtonTheme(
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.gap(GapSize.md),
                      ),
                      foregroundColor: scheme.foregroundSubtle,
                    ),
                    leading: PhosphorIcon(action.icon),
                    onPressed: compose,
                    child: Flexible(
                      child: Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
