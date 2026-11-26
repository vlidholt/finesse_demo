import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/jobs_company_logo.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// A listing in the results list: a tappable [Card], selected while it is
/// the one the detail pane shows. The bookmark inside it is a button of its
/// own.
class JobCard extends StatelessWidget {
  const JobCard({
    required this.job,
    required this.selected,
    required this.saved,
    required this.onPressed,
    required this.onSavePressed,
    super.key,
  });

  final Job job;
  final bool selected;
  final bool saved;
  final VoidCallback onPressed;
  final VoidCallback onSavePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final caption = text.caption;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.gap(GapSize.md),
      children: [
        JobsCompanyLogo(job.company),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UnaRow(
                crossAxisAlignment: CrossAxisAlignment.start,
                gap: GapSize.sm,
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: text.large,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _SaveButton(saved: saved, onPressed: onSavePressed),
                ],
              ),
              Text(
                job.company.name,
                style: text.small.copyWith(color: colors.foregroundSubtle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                job.location,
                style: text.muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap.sm(),
              Wrap(
                spacing: theme.gap(GapSize.xs),
                runSpacing: theme.gap(GapSize.xs),
                children: [
                  JobTag(job.salary),
                  if (job.easyApply) const JobTag.easyApply(),
                ],
              ),
              const Gap.sm(),
              Row(
                spacing: theme.gap(GapSize.xs),
                children: [
                  // Decorative: the label beside it says what it shows.
                  ExcludeSemantics(
                    child: AvatarGroup(
                      size: theme.avatarXs,
                      overlap: theme.avatarXs / 3,
                      children: [
                        for (final person in job.connections)
                          PersonAvatar(person, size: theme.avatarXs),
                      ],
                    ),
                  ),
                  Flexible(
                    child: Text(
                      job.connectionsLabel,
                      style: caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Gap.sm(),
              Text(
                job.postedLabel,
                style: caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    return Card(
      onTap: onPressed,
      selected: selected,
      // No `semanticLabel`: it would stand in for everything inside the
      // card, the bookmark button included. The card reads its own text.
      style: CardTheme(borderRadius: theme.radii.xl),
      child: content,
    );
  }
}

/// The bookmark at the top end of a job card.
///
/// The design hangs the 36px button 6px into the card's padding, so the
/// icon lines up with the title's cap height and the card's inner edge.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onPressed});

  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton.ghost(
      size: ButtonSize.sm,
      icon: PhosphorIcon(
        saved
            ? PhosphorIconsFill.bookmarkSimple
            : PhosphorIconsRegular.bookmarkSimple,
      ),
      style: ButtonTheme(
        foregroundColor: saved ? colors.tint : colors.foreground,
      ),
      semanticLabel: saved ? 'Remove from saved jobs' : 'Save job',
      onPressed: onPressed,
    );
  }
}

/// A small tag on a job card: the salary band, which is the theme's grey
/// secondary badge, or the green "Easy apply" marker.
class JobTag extends StatelessWidget {
  const JobTag(this.label, {super.key}) : _easyApply = false;

  const JobTag.easyApply({super.key}) : label = 'Easy apply', _easyApply = true;

  final String label;
  final bool _easyApply;

  @override
  Widget build(BuildContext context) {
    if (!_easyApply) return Badge.secondary(child: Text(label));

    final colors = Theme.of(context).colorScheme;
    return Badge.secondary(
      // No badge variant is green: the success pair goes on by hand.
      backgroundColor: colors.successMuted,
      foregroundColor: colors.success,
      child: UnaRow(
        gap: GapSize.xs,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PhosphorIcon(PhosphorIconsRegular.lightning),
          Text(label),
        ],
      ),
    );
  }
}
