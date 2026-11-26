import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/notifications_data.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_trending_card.dart';
import 'package:una_demo/widgets/notifications_controller.dart';
import 'package:una_demo/widgets/notifications_list.dart';
import 'package:una_demo/widgets/notifications_rail.dart';
import 'package:una_demo/widgets/settings_controller.dart';
import 'package:una_demo/widgets/settings_links.dart';

/// The Notifications destination of the Demo shell.
///
/// The designs name this destination but never drew it; it is built from
/// the designed screens' pieces and follows their rules.
///
/// * **Desktop** — the page title with "Mark all as read", then three
///   columns like the home feed: a left rail (the switches people reach
///   for most), the list — a segmented control over one card per period —
///   and a right rail (the week's figures, trending topics). The rails drop
///   away as the window narrows, the right one first.
/// * **Phone** — the title with its two actions as icon buttons, the
///   control at full width, and the same cards.
///
/// The unread rows are washed in the accent colour and carry a dot; the
/// shell's bell counts them. A row leads to what it is about, and its
/// button answers it in place where that makes sense.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // The home feed's columns.
  static const _leftWidth = 260.0;
  static const _leftMinWidth = 240.0;
  static const _rightWidth = 320.0;
  static const _rightMinWidth = 280.0;
  static const _mainWidth = 520.0;
  static const _rightRailFrom = 1052.0;
  static const _leftRailFrom = 812.0;

  @override
  Widget build(BuildContext context) {
    final session = context.demo;
    final controller = session.notifications;
    return ListenableBuilder(
      // The network too: an invitation accepted there is answered here.
      listenable: Listenable.merge([controller, session.network]),
      builder: (context, _) => FormFactorBuilder(
        mobile: (context) => _buildMobile(context, controller),
        desktop: (context) => _buildDesktop(context, controller),
      ),
    );
  }

  static String _subtitle(NotificationsController controller) =>
      switch (controller.unreadCount) {
        0 => 'You are all caught up.',
        1 => '1 unread notification.',
        final count => '$count unread notifications.',
      };

  Widget _buildDesktop(
    BuildContext context,
    NotificationsController controller,
  ) {
    final theme = Theme.of(context);
    final layout = theme.layoutTheme;
    final gap = layout.gap(GapSize.xl);

    return PageContainer(
      scrollable: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showRight = width >= _rightRailFrom;
          final showLeft = width >= _leftRailFrom;
          final full = _leftWidth + _rightWidth + _mainWidth + gap * 2;
          final least = _leftMinWidth + _rightMinWidth + _mainWidth + gap * 2;
          final squeeze = showRight
              ? ((full - width) / (full - least)).clamp(0.0, 1.0)
              : 0.0;

          return UnaColumn(
            gap: GapSize.lg,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DemoPageHeader(
                title: NotificationsData.title,
                subtitle: _subtitle(controller),
                actions: [
                  Button.outline(
                    leading: const PhosphorIcon(PhosphorIconsRegular.gearSix),
                    onPressed: () =>
                        openSettings(context, SettingsSection.notifications),
                    child: const Text('Settings'),
                  ),
                  Button(
                    enabled: controller.unreadCount > 0,
                    leading: const PhosphorIcon(PhosphorIconsRegular.checks),
                    onPressed: controller.markAllRead,
                    child: const Text('Mark all as read'),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.only(top: layout.gap(GapSize.xs)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: gap,
                  children: [
                    if (showLeft)
                      SizedBox(
                        width:
                            _leftWidth - (_leftWidth - _leftMinWidth) * squeeze,
                        child: NotificationsManageCard(
                          settings: context.demo.settings,
                        ),
                      ),
                    Expanded(
                      child: UnaColumn(
                        gap: GapSize.lg,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FilterTabs(controller: controller, expand: false),
                          NotificationsList(controller: controller),
                        ],
                      ),
                    ),
                    if (showRight)
                      SizedBox(
                        width:
                            _rightWidth -
                            (_rightWidth - _rightMinWidth) * squeeze,
                        child: const UnaColumn(
                          gap: GapSize.lg,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            NotificationsWeekCard(),
                            HomeTrendingCard(),
                            HomeFooterLinks(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    NotificationsController controller,
  ) {
    final layout = Theme.of(context).layoutTheme;
    return PageContainer(
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: layout.gap(GapSize.md),
        children: [
          Row(
            children: [
              const Expanded(
                child: DemoPageHeader(title: NotificationsData.title),
              ),
              IconButton.secondary(
                enabled: controller.unreadCount > 0,
                icon: const PhosphorIcon(PhosphorIconsRegular.checks),
                semanticLabel: 'Mark all as read',
                onPressed: controller.markAllRead,
              ),
              const Gap.xs(),
              IconButton.secondary(
                icon: const PhosphorIcon(PhosphorIconsRegular.gearSix),
                semanticLabel: 'Notification settings',
                onPressed: () =>
                    openSettings(context, SettingsSection.notifications),
              ),
            ],
          ),
          _FilterTabs(controller: controller, expand: true),
          NotificationsList(controller: controller),
        ],
      ),
    );
  }
}

/// The segmented control: All, Mentions, Jobs, My posts.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.controller, required this.expand});

  final NotificationsController controller;

  /// Whether the control fills the width, as on a phone.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filter notifications',
      container: true,
      child: Tabs<NotificationFilter>(
        value: controller.filter,
        expandTabs: expand,
        onChanged: (filter) => controller.filter = filter,
        tabs: [
          for (final filter in NotificationFilter.values)
            Tab(
              value: filter,
              // Four labels share a phone's width: each may shrink.
              child: DemoTabLabel(filter.label),
            ),
        ],
      ),
    );
  }
}
