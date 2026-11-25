import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/widgets/jobs_state.dart';
import 'package:finesse_demo/widgets/demo_actions.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The page title. A desktop adds the subtitle and the two page actions;
/// a phone shows the title alone.
class JobsHeader extends StatelessWidget {
  const JobsHeader({required this.state, super.key});

  final JobsState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final layout = theme.layoutTheme;
    final title = Text(JobsData.title, style: theme.textTheme.h1);
    if (theme.formFactor == FormFactor.mobile) return title;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: layout.gap(GapSize.xl),
      runSpacing: layout.gap(GapSize.md),
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            title,
            const Gap.xs(),
            Text(
              JobsData.subtitle,
              style: theme.textTheme.p.copyWith(
                color: colors.mutedForeground,
              ),
            ),
          ],
        ),
        FinesseRow(
          gap: GapSize.sm,
          mainAxisSize: MainAxisSize.min,
          children: [
            Button.outline(
              leading: PhosphorIcon(
                state.alerts
                    ? PhosphorIconsFill.bellRinging
                    : PhosphorIconsRegular.bell,
                color: state.alerts ? colors.tint : null,
              ),
              onPressed: state.toggleAlerts,
              child: const Text('Job alerts'),
            ),
            Button(
              leading: const PhosphorIcon(PhosphorIconsRegular.plus),
              onPressed: () async {
                final title = await showWriteDialog(
                  context,
                  title: 'Post a job',
                  description:
                      'Start with the role’s title. You can add the rest '
                      'before it goes live.',
                  placeholder: 'Senior product designer',
                  submit: 'Save draft',
                  multiline: false,
                );
                if (title != null && context.mounted) {
                  showDemoToast(
                    context,
                    'Draft saved',
                    description: '$title at Halcyon',
                    variant: ToastVariant.success,
                  );
                }
              },
              child: const Text('Post a job'),
            ),
          ],
        ),
      ],
    );
  }
}
