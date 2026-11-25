import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/widgets/person_avatar.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The fact tiles under a job's actions: two columns, or one when a tile
/// would be too narrow for its value.
class JobFactGrid extends StatelessWidget {
  const JobFactGrid({required this.facts, super.key});

  final List<JobFact> facts;

  /// Under this width a half-width tile truncates "4 designers, 12 engineers".
  static const _twoColumnMinWidth = 530.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = Theme.of(context).gap(GapSize.sm);
        final tiles = [for (final fact in facts) _FactTile(fact)];
        if (constraints.maxWidth < _twoColumnMinWidth) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: tiles,
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          spacing: gap,
          children: [
            for (var i = 0; i < tiles.length; i += 2)
              Row(
                spacing: gap,
                children: [
                  Expanded(child: tiles[i]),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? tiles[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile(this.fact);

  final JobFact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final layout = theme.layoutTheme;
    return Container(
      padding: EdgeInsets.all(layout.gap(GapSize.md)),
      decoration: BoxDecoration(
        color: colors.muted,
        border: Border.all(color: colors.border),
        borderRadius: theme.radii.lg,
      ),
      child: Row(
        spacing: layout.gap(GapSize.md),
        children: [
          IconTile(icon: PhosphorIcon(fact.icon)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fact.label,
                  style: theme.textTheme.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  fact.value,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Strong match for your profile" panel: the score, a progress bar and
/// the role's skills, the ones missing from the profile dashed.
class JobMatchPanel extends StatelessWidget {
  const JobMatchPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    return Container(
      padding: EdgeInsets.all(theme.gap(GapSize.lg)),
      decoration: BoxDecoration(
        color: colors.successMuted,
        border: Border.all(color: colors.border),
        borderRadius: theme.radii.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: theme.gap(GapSize.md),
            children: [
              Expanded(
                child: Row(
                  spacing: theme.gap(GapSize.sm),
                  children: [
                    PhosphorIcon(
                      PhosphorIconsFill.sealCheck,
                      size: theme.glyphLg,
                      color: colors.success,
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            JobsData.matchTitle,
                            style: text.large,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            JobsData.matchSummary,
                            style: text.muted,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                JobsData.matchScoreLabel,
                style: text.h3.copyWith(color: colors.success),
              ),
            ],
          ),
          const Gap.md(),
          const ProgressBar(
            value: JobsData.matchScore,
            // A hair slimmer than the theme's bar.
            height: 6,
            semanticLabel: 'Skills match',
            semanticValue: JobsData.matchScoreLabel,
          ),
          const Gap.md(),
          Wrap(
            spacing: theme.gap(GapSize.xs),
            runSpacing: theme.gap(GapSize.xs),
            children: [
              for (final skill in JobsData.skills) _SkillChip(skill),
            ],
          ),
        ],
      ),
    );
  }
}

/// A skill tag, a size under the theme's filter chip.
class _SkillChip extends StatelessWidget {
  const _SkillChip(this.skill);

  final JobSkill skill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final matched = skill.matched;
    return Chip(
      variant: matched ? ChipVariant.outline : ChipVariant.dashed,
      backgroundColor: matched ? colors.card : null,
      foregroundColor: matched ? null : colors.mutedForeground,
      semanticLabel: matched
          ? skill.name
          : '${skill.name}, not on your profile',
      leading: PhosphorIcon(
        matched ? PhosphorIconsRegular.check : PhosphorIconsRegular.x,
        color: matched ? colors.tint : colors.mutedForeground,
      ),
      label: Text(skill.name),
    );
  }
}

/// "Meet the hiring team": the job poster and a Message button.
class JobHiringTeam extends StatelessWidget {
  const JobHiringTeam({required this.onMessage, super.key});

  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    const person = JobsData.hiringManager;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(JobsData.hiringTeamTitle, style: text.h4),
        const Gap.md(),
        Row(
          spacing: theme.gap(GapSize.md),
          children: [
            const PersonAvatar(person),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: person.name,
                      children: [
                        TextSpan(
                          text: ' · ${JobsData.hiringManagerDegree}',
                          // A copy of the theme's style, so the lighter weight
                          // gets the font's regular face.
                          style: text.large.copyWith(
                            fontWeight: FontWeight.w400,
                            color: colors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                    style: text.large,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    JobsData.hiringManagerRole,
                    style: text.muted,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Button.outline(
              leading: const PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt),
              onPressed: onMessage,
              child: const Text('Message'),
            ),
          ],
        ),
      ],
    );
  }
}

/// "About the role" and the "What you'll do" checklist.
class JobDescription extends StatelessWidget {
  const JobDescription({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final prose = text.p.copyWith(color: colors.foregroundSubtle);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          JobsData.aboutRoleTitle,
          style: text.h4,
        ),
        const Gap.sm(),
        Text(JobsData.aboutRole, style: prose),
        const Gap.lg(),
        Text(JobsData.responsibilitiesTitle, style: text.h4),
        const Gap.sm(),
        for (final (index, item) in JobsData.responsibilities.indexed) ...[
          if (index > 0) const Gap.sm(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.gap(GapSize.sm),
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.checkCircle,
                size: theme.glyphLg,
                color: colors.tint,
              ),
              Expanded(
                child: Text(item, style: prose),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// "About Kestrel Health": the company's size, offices and site.
class JobCompanyFacts extends StatelessWidget {
  const JobCompanyFacts({required this.companyName, super.key});

  final String companyName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('About $companyName', style: text.h4),
        const Gap.md(),
        Wrap(
          spacing: theme.gap(GapSize.lg),
          runSpacing: theme.gap(GapSize.sm),
          children: [
            for (final (icon, label) in JobsData.companyFacts)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: theme.gap(GapSize.xs),
                children: [
                  PhosphorIcon(
                    icon,
                    size: theme.iconBeside(text.muted),
                    color: colors.mutedForeground,
                  ),
                  Flexible(
                    child: Text(
                      label,
                      style: text.muted,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
