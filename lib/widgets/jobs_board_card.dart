import 'package:finesse_demo/data/applications_data.dart';
import 'package:finesse_demo/widgets/jobs_company_logo.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// An application on the board: the company's mark, the role, where it is,
/// and one status line with when it last changed.
///
/// It is a plain [Card]; inside a `Board` a card takes the board's tighter
/// padding and radius by itself.
class ApplicationCard extends StatelessWidget {
  const ApplicationCard(this.application, {super.key});

  final JobApplication application;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final text = theme.textTheme;
    final caption = text.caption;
    final toneColor = switch (application.tone) {
      ApplicationTone.quiet => colors.mutedForeground,
      ApplicationTone.active => colors.tint,
      ApplicationTone.good => colors.success,
      ApplicationTone.urgent => colors.warning,
    };

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.gap(GapSize.sm),
            children: [
              JobsCompanyLogo(
                application.company,
                size: theme.avatarSm,
                radius: theme.radii.md,
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      application.title,
                      style: text.p.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.foreground,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${application.company.name} · '
                      '${application.location}',
                      style: caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap.sm(),
          Row(
            spacing: theme.gap(GapSize.xs),
            children: [
              // Decorative: the text beside it says what it marks.
              ExcludeSemantics(
                child: PhosphorIcon(
                  application.statusIcon,
                  size: theme.iconBeside(caption),
                  color: toneColor,
                ),
              ),
              Expanded(
                child: Text(
                  application.status,
                  style: caption.copyWith(
                    color: toneColor,
                    fontWeight: application.tone == ApplicationTone.quiet
                        ? null
                        : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                application.updated,
                style: caption,
                semanticsLabel: 'Updated ${application.updated}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
