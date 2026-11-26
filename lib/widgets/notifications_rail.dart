import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/settings_controller.dart';
import 'package:una_demo/widgets/settings_links.dart';

/// The left rail's "Manage notifications": the three switches people reach
/// for most, and a link to the rest.
///
/// They are the Settings page's own preferences, so a switch flipped here
/// is flipped there.
class NotificationsManageCard extends StatelessWidget {
  const NotificationsManageCard({required this.settings, super.key});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Merged into one semantic node: the label and the sentence name the
    // switch. Labelling the switch itself would leave the visible label to
    // be read a second time.
    Widget toggle({
      required String label,
      required String detail,
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.foreground,
                  ),
                ),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.caption,
                ),
              ],
            ),
          ),
          const Gap.md(),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );

    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => HomeSectionCard(
        title: 'Manage notifications',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UnaColumn(
              gap: GapSize.lg,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                toggle(
                  label: 'Pause all',
                  detail: 'Mute everything for now',
                  value: settings.pauseAll,
                  onChanged: (value) =>
                      settings.update(() => settings.pauseAll = value),
                ),
                toggle(
                  label: 'Mentions',
                  detail: 'Push when someone tags you',
                  value: settings.push.contains(NotificationTopic.mentions),
                  onChanged: (_) => settings.toggle(
                    settings.push,
                    NotificationTopic.mentions,
                  ),
                ),
                toggle(
                  label: 'Job matches',
                  detail: 'Email for roles that fit your profile',
                  value: settings.emailed.contains(NotificationTopic.jobs),
                  onChanged: (_) => settings.toggle(
                    settings.emailed,
                    NotificationTopic.jobs,
                  ),
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
              onPressed: () =>
                  openSettings(context, SettingsSection.notifications),
              child: const Flexible(
                child: Text(
                  'All notification settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The right rail's "Your week": three figures the notifications keep
/// referring to, with a link to the profile's analytics.
class NotificationsWeekCard extends StatelessWidget {
  const NotificationsWeekCard({super.key});

  static const _stats = [
    (PhosphorIconsRegular.eye, '128', 'Profile viewers', '+12%'),
    (PhosphorIconsRegular.chartLineUp, '2,431', 'Post impressions', '+38%'),
    (PhosphorIconsRegular.magnifyingGlass, '312', 'Search appearances', '+6%'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return HomeSectionCard(
      title: 'Your week',
      trailing: HomeTextLink(
        'Analytics',
        onPressed: () => context.goTo(DemoDestination.profile),
        style: theme.textTheme.small.copyWith(color: scheme.tint),
      ),
      child: UnaColumn(
        gap: GapSize.md,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (icon, value, label, change) in _stats)
            Row(
              children: [
                IconTile(
                  icon: PhosphorIcon(icon),
                  size: theme.avatarSm,
                  iconSize: theme.avatarSm / 2,
                ),
                const Gap.sm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.foreground,
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.caption,
                      ),
                    ],
                  ),
                ),
                PhosphorIcon(
                  PhosphorIconsRegular.trendUp,
                  size: theme.iconBeside(theme.textTheme.caption),
                  color: scheme.tint,
                ),
                const Gap.xs(),
                Text(
                  change,
                  style: theme.textTheme.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.tint,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
