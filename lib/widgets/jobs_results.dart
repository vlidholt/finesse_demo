import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/widgets/jobs_job_card.dart';
import 'package:finesse_demo/widgets/jobs_state.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The results column: a count and sort line, then the job cards.
///
/// A phone swaps the count line for "Top picks for you" and lists only the
/// design's three picks.
class JobsResults extends StatelessWidget {
  const JobsResults({required this.state, required this.onOpen, super.key});

  final JobsState state;

  /// Called when a card is tapped, after it has been selected.
  final ValueChanged<Job> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mobile = theme.formFactor == FormFactor.mobile;
    final jobs = mobile
        ? [
            for (final job in state.jobs)
              if (job.topPick) job,
          ]
        : state.jobs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      // Cards sit 12 apart on a desktop and 10 on a phone; the header keeps
      // 12 on both.
      children: [
        if (mobile) const _TopPicksHeader() else _ResultsHeader(state: state),
        const Gap.md(),
        for (final (index, job) in jobs.indexed) ...[
          if (index > 0)
            if (mobile) const Gap.sm() else const Gap.md(),
          JobCard(
            key: ValueKey(job.id),
            job: job,
            selected: job == state.selected,
            saved: state.isSaved(job),
            onPressed: () {
              state.select(job);
              onOpen(job);
            },
            onSavePressed: () => state.toggleSaved(job),
          ),
        ],
      ],
    );
  }
}

/// "248 results for product designer" and the sort menu.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.state});

  final JobsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.gap(GapSize.xs),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: theme.gap(GapSize.md),
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                text: '${JobsData.resultCount} results',
                children: [
                  TextSpan(
                    text: ' for ${state.query.toLowerCase()}',
                    // A copy of the theme's style, so the lighter weight gets
                    // the font's regular face.
                    style: theme.textTheme.h4.copyWith(
                      fontWeight: FontWeight.w400,
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
              style: theme.textTheme.h4,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _SortMenu(state: state),
        ],
      ),
    );
  }
}

/// The "Most relevant" text button and its menu.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.state});

  final JobsState state;

  static const _anchor = AnchorAuto(
    offset: Offset(0, 4),
    targetAnchor: AlignmentDirectional.bottomEnd,
    followerAnchor: AlignmentDirectional.bottomStart,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DropdownMenu(
      anchor: _anchor,
      items: [
        for (final sort in JobSort.values)
          MenuItem(
            trailing: sort == state.sort
                ? const PhosphorIcon(PhosphorIconsRegular.check)
                : null,
            onPressed: () => state.setSort(sort),
            child: Text(sort.label),
          ),
      ],
      builder: (context, controller, _) => Pressable(
        onPressed: controller.toggle,
        semanticLabel: 'Sort: ${state.sort.label}',
        builder: (context, states) {
          final color = states.contains(WidgetState.hovered)
              ? colors.foreground
              : colors.mutedForeground;
          return FocusRing(
            visible: states.contains(WidgetState.focused),
            borderRadius: theme.radii.sm,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: theme.gap(GapSize.xs),
              children: [
                Text(
                  state.sort.label,
                  style: theme.textTheme.small.copyWith(
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                PhosphorIcon(
                  PhosphorIconsRegular.caretDown,
                  size: theme.iconBeside(theme.textTheme.small),
                  color: color,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The phone's list heading.
class _TopPicksHeader extends StatelessWidget {
  const _TopPicksHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // The design drops the heading 4 below the section gap.
      padding: EdgeInsets.only(top: theme.gap(GapSize.xs)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        spacing: theme.gap(GapSize.md),
        children: [
          Expanded(
            child: Text(
              'Top picks for you',
              style: theme.textTheme.h4,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('Based on your profile', style: theme.textTheme.muted),
        ],
      ),
    );
  }
}
