import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/widgets/jobs_apply_dialog.dart';
import 'package:finesse_demo/widgets/jobs_company_logo.dart';
import 'package:finesse_demo/widgets/jobs_detail_sections.dart';
import 'package:finesse_demo/widgets/jobs_state.dart';
import 'package:finesse_demo/widgets/demo_actions.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// Everything the designs say about one job, top to bottom: the company
/// header, the title, the actions, the fact tiles, the match panel, the
/// hiring team, the description and the company.
///
/// It is only the content. The desktop screen puts it in a card beside the
/// results; a phone pushes it as a page (`JobDetailPage`), which moves the
/// share action into its app bar and "Easy Apply" into a bar at the bottom —
/// hence [showHeaderActions] and [showActions].
class JobDetail extends StatelessWidget {
  const JobDetail({
    required this.job,
    required this.state,
    required this.onMessage,
    this.showHeaderActions = true,
    this.showActions = true,
    super.key,
  });

  final Job job;
  final JobsState state;

  /// Called by the hiring manager's Message button.
  final VoidCallback onMessage;

  /// Whether the company header carries the share and overflow buttons.
  final bool showHeaderActions;

  /// Whether "Easy Apply" and "Save" sit under the title.
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const section = Gap.xl();
    final rule = Divider(
      margin: EdgeInsets.symmetric(vertical: theme.gap(GapSize.xl)),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CompanyHeader(
          job: job,
          following: state.isFollowing(job),
          onFollowPressed: () => state.toggleFollowing(job),
          showActions: showHeaderActions,
        ),
        const Gap.lg(),
        Text(
          job.title,
          // The pane's own heading: a step under the page's title.
          style: theme.textTheme.h3,
        ),
        const Gap.xs(),
        Text(
          job.detailMeta,
          style: theme.textTheme.muted,
        ),
        if (showActions) ...[
          const Gap.lg(),
          JobActions(job: job, state: state),
        ],
        section,
        JobFactGrid(facts: JobsData.factsFor(job)),
        const Gap.md(),
        const JobMatchPanel(),
        section,
        JobHiringTeam(onMessage: onMessage),
        rule,
        const JobDescription(),
        rule,
        JobCompanyFacts(companyName: job.company.name),
      ],
    );
  }
}

/// The logo, the company's name and tagline, and Follow / share / more.
class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({
    required this.job,
    required this.following,
    required this.onFollowPressed,
    required this.showActions,
  });

  final Job job;
  final bool following;
  final VoidCallback onFollowPressed;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Row(
      // Between every part of the row, as between a job card's logo and its
      // text.
      spacing: theme.gap(GapSize.md),
      children: [
        JobsCompanyLogo(
          job.company,
          size: theme.avatarLg,
          radius: theme.radii.xl,
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.company.name,
                style: text.large,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                JobsData.companyTagline,
                style: text.muted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Button.outline(
          leading: PhosphorIcon(
            following ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
          ),
          onPressed: onFollowPressed,
          child: Text(following ? 'Following' : 'Follow'),
        ),
        if (showActions) ...[
          IconButton.secondary(
            icon: const PhosphorIcon(PhosphorIconsRegular.export),
            semanticLabel: 'Share job',
            onPressed: () => copyLink(context, 'demo.app/jobs/${job.id}'),
          ),
          IconButton.secondary(
            icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
            semanticLabel: 'More options',
            onPressed: () => showSendDialog(context, what: 'this job'),
          ),
        ],
      ],
    );
  }
}

/// "Easy Apply" and "Save".
///
/// Under the title on a desktop; in the bottom bar of the phone's detail
/// page, where [expand] lets "Easy Apply" take the spare width.
class JobActions extends StatelessWidget {
  const JobActions({
    required this.job,
    required this.state,
    this.expand = false,
    super.key,
  });

  final Job job;
  final JobsState state;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final applied = state.hasApplied(job);
    final saved = state.isSaved(job);

    final apply = Button(
      size: ButtonSize.lg,
      style: ButtonTheme(
        // The one call to action in the tint rather than the primary colour.
        backgroundColor: colors.tint,
        hoverBackgroundColor: colors.tint.withValues(alpha: .8),
        foregroundColor: colors.tintForeground,
        hoverForegroundColor: colors.tintForeground,
      ),
      leading: PhosphorIcon(
        applied ? PhosphorIconsRegular.check : PhosphorIconsRegular.lightning,
      ),
      // Once applied, the button leads to the application on the board.
      onPressed: applied
          ? applicationsOpener(context)
          : () => showEasyApply(context, job: job, state: state),
      // In the phone's bar the label gives way to a large text size.
      expands: expand,
      child: Text(
        applied ? 'View application' : 'Easy Apply',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return FinesseRow(
      gap: GapSize.sm,
      children: [
        if (expand) Expanded(child: apply) else apply,
        Button.outline(
          size: ButtonSize.lg,
          style: ButtonTheme(
            // The large height with the regular button's side padding.
            padding: theme.buttonSizesTheme.regular?.padding,
          ),
          leading: PhosphorIcon(
            saved
                ? PhosphorIconsFill.bookmarkSimple
                : PhosphorIconsRegular.bookmarkSimple,
            color: saved ? colors.tint : null,
          ),
          onPressed: () => state.toggleSaved(job),
          child: Text(saved ? 'Saved' : 'Save'),
        ),
      ],
    );
  }
}
