import 'package:finesse_demo/data/profile_data.dart';
import 'package:finesse_demo/widgets/profile_common.dart';
import 'package:finesse_demo/widgets/demo_actions.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The "Analytics" card: three numbers only the profile's owner sees.
class ProfileAnalyticsCard extends StatelessWidget {
  const ProfileAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.mutedForeground;
    return ProfileSection(
      title: 'Analytics',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.eye,
            size: theme.iconBeside(theme.textTheme.muted),
            color: muted,
          ),
          const Gap.xs(),
          Text('Private to you', style: theme.textTheme.muted),
        ],
      ),
      child: IntrinsicHeight(
        child: FinesseRow(
          gap: GapSize.md,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final stat in ProfileData.stats)
              Expanded(child: _StatBox(stat)),
          ],
        ),
      ),
    );
  }
}

/// One number of the Analytics card: the icon and the trend above, the
/// value and what it counts below.
class _StatBox extends StatelessWidget {
  const _StatBox(this.stat);

  final ProfileStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.all(theme.gap(GapSize.md)),
      decoration: BoxDecoration(
        color: scheme.muted,
        borderRadius: theme.radii.lg,
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PhosphorIcon(
                stat.icon,
                size: theme.glyphLg,
                color: scheme.mutedForeground,
              ),
              const Spacer(),
              PhosphorIcon(
                PhosphorIconsRegular.trendUp,
                size: theme.iconBeside(theme.textTheme.caption),
                color: scheme.tint,
              ),
              const Gap.xs(),
              Text(
                stat.trend,
                semanticsLabel: 'Up ${stat.trend}',
                style: theme.textTheme.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.tint,
                ),
              ),
            ],
          ),
          const Gap.sm(),
          Text(
            stat.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.h3.copyWith(color: scheme.foreground),
          ),
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.muted,
          ),
        ],
      ),
    );
  }
}

/// The About text of a profile.
class ProfileAboutText extends StatelessWidget {
  const ProfileAboutText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.p.copyWith(
        color: theme.colorScheme.foregroundSubtle,
      ),
    );
  }
}

/// A wrapping run of skills as soft chips.
class ProfileSkills extends StatelessWidget {
  const ProfileSkills(this.skills, {super.key});

  final List<String> skills;

  @override
  Widget build(BuildContext context) {
    final gap = Theme.of(context).layoutTheme.gap(GapSize.sm);
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final skill in skills)
          Chip(label: Text(skill), variant: ChipVariant.soft),
      ],
    );
  }
}

/// The "About" card: the summary and the top skills.
class ProfileAboutCard extends StatelessWidget {
  const ProfileAboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ProfileSection(
      title: 'About',
      trailing: const ProfileHeaderAction(
        icon: PhosphorIconsRegular.pencilSimple,
        label: 'Edit about',
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ProfileAboutText(ProfileData.about),
          const Gap.lg(),
          Text(
            'Top skills',
            style: theme.textTheme.small.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.foreground,
            ),
          ),
          const Gap.sm(),
          const ProfileSkills(ProfileData.skills),
        ],
      ),
    );
  }
}

/// The "Featured" card: a talk, a case study and an article.
class ProfileFeaturedCard extends StatelessWidget {
  const ProfileFeaturedCard({this.onSeeAll, super.key});

  /// Called by "See all": the screen switches to its Media tab.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      title: 'Featured',
      trailing: ProfileTextLink('See all', onPressed: onSeeAll),
      child: IntrinsicHeight(
        child: FinesseRow(
          gap: GapSize.md,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in ProfileData.featured)
              Expanded(child: _FeaturedTile(item)),
          ],
        ),
      ),
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile(this.item);

  final FeaturedItem item;

  /// The scrim behind a label on a photograph: denser than the designs'
  /// 36%, which sat on a blur of the photograph.
  static const _scrim = Color(0x8A09090B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final layout = theme.layoutTheme;
    final radius = theme.radii.lg;

    return Pressable(
      onPressed: () => showArticlePreview(
        context,
        image: item.image,
        source: item.meta,
        title: item.title,
        summary: switch (item.kind) {
          'Talk' =>
            'Twenty minutes on designing for focus: why defaults matter '
                'more than settings, and what the planning suite removed '
                'to get there. Recorded on the main stage at Config '
                'Nordics.',
          'Case study' =>
            'One whiteboard, five people and a rule that nothing ships '
                'unless a new customer can finish it without reading a '
                'single tooltip. How six setup screens became two.',
          _ =>
            'Forty conversations with small-business owners, and the '
                'pattern is hard to miss: nobody asked for more features. '
                'They asked for fewer decisions.',
        },
      ),
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: states.contains(WidgetState.hovered)
                ? scheme.secondary
                : scheme.muted,
            borderRadius: radius,
            border: Border.all(color: scheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Image.asset(
                    item.image,
                    height: 130,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    semanticLabel: item.imageLabel,
                  ),
                  PositionedDirectional(
                    top: layout.gap(GapSize.sm),
                    start: layout.gap(GapSize.sm),
                    child: Glass(
                      frosted: false,
                      color: _scrim,
                      border: const Border.fromBorderSide(BorderSide.none),
                      borderRadius: theme.radii.full,
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.gap(GapSize.sm),
                        vertical: layout.gap(GapSize.xs),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          item.kind,
                          style: theme.textTheme.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(layout.gap(GapSize.md)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.p.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.foreground,
                      ),
                    ),
                    const Gap.xs(),
                    Text(
                      item.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
