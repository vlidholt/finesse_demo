import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/profile_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/profile_common.dart';

/// The "Experience" card: the positions as a timeline, newest first.
///
/// The phone design is the [compact] form: smaller logos, no descriptions
/// and no add/edit buttons.
class ProfileExperienceCard extends StatelessWidget {
  const ProfileExperienceCard({
    this.compact = false,
    this.showDescriptions,
    super.key,
  });

  final bool compact;

  /// Whether each position's description is shown. Defaults to not
  /// [compact].
  final bool? showDescriptions;

  @override
  Widget build(BuildContext context) {
    final descriptions = showDescriptions ?? !compact;
    return ProfileSection(
      title: 'Experience',
      trailing: compact
          ? null
          : const UnaRow(
              gap: GapSize.xs,
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileHeaderAction(
                  icon: PhosphorIconsRegular.plus,
                  label: 'Add experience',
                ),
                ProfileHeaderAction(
                  icon: PhosphorIconsRegular.pencilSimple,
                  label: 'Edit experience',
                ),
              ],
            ),
      child: Timeline(
        entries: [
          for (final entry in ProfileData.experience)
            TimelineEntry(
              marker: ProfileLogo(
                entry.company.logo,
                label: '${entry.company.name} logo',
              ),
              child: _Lines(
                title: entry.role,
                subtitle: entry.employment,
                details: [entry.dates, entry.location],
                description: descriptions ? entry.description : null,
              ),
            ),
        ],
      ),
    );
  }
}

/// The "Education" card.
class ProfileEducationCard extends StatelessWidget {
  const ProfileEducationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ProfileSection(
      title: 'Education',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.gap(GapSize.lg),
        children: [
          for (final entry in ProfileData.education)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Lined up with the Experience timeline above it.
              spacing: theme.timelineTheme.gap ?? theme.gap(GapSize.md),
              children: [
                ProfileLogo(
                  entry.school.logo,
                  label: '${entry.school.name} logo',
                ),
                Expanded(
                  child: _Lines(
                    title: entry.school.name,
                    subtitle: entry.degree,
                    details: [entry.years],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The text beside a logo: a title, a subtitle, muted details and an
/// optional paragraph.
class _Lines extends StatelessWidget {
  const _Lines({
    required this.title,
    required this.subtitle,
    required this.details,
    this.description,
  });

  final String title;
  final String subtitle;
  final List<String> details;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final body = theme.textTheme.p.copyWith(color: scheme.foregroundSubtle);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.large.copyWith(color: scheme.foreground),
        ),
        Text(subtitle, style: body),
        for (final detail in details)
          Text(detail, style: theme.textTheme.muted),
        if (description case final description?) ...[
          const Gap.sm(),
          Text(description, style: body),
        ],
      ],
    );
  }
}
