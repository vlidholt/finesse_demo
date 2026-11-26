import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/data/network_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_trending_card.dart';
import 'package:una_demo/widgets/network_controller.dart';
import 'package:una_demo/widgets/network_invitations_card.dart';
import 'package:una_demo/widgets/network_links.dart';
import 'package:una_demo/widgets/network_rail.dart';
import 'package:una_demo/widgets/network_section_view.dart';
import 'package:una_demo/widgets/network_suggestions.dart';
import 'package:una_demo/widgets/settings_links.dart';

/// The Network destination of the Demo shell: invitations, people you
/// may know, and the lists behind "Manage my network".
///
/// The designs name this destination but never drew it; it is built from
/// the designed screens' pieces and follows their rules.
///
/// * **Desktop** — the page title, then three columns like the home feed:
///   a left rail ("Manage my network"), the main column (invitations and
///   the suggestions grid — or the list a rail row selects) and a right
///   rail (upcoming events, groups you may like). The rails drop away as
///   the window narrows, the right one first; without the left one its
///   rows become a strip of chips over the main column.
/// * **Phone** — a segmented control: "Grow" (the suggestions, two across),
///   "Invitations" and "My network", whose rows open their lists as pages.
class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.demo.network;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => FormFactorBuilder(
        mobile: (context) => _MobileNetwork(controller: controller),
        desktop: (context) => _DesktopNetwork(controller: controller),
      ),
    );
  }
}

class _DesktopNetwork extends StatelessWidget {
  const _DesktopNetwork({required this.controller});

  final NetworkController controller;

  // The home feed's columns: rails of 260 and 320 that give up 20 and 40
  // before the main column, which wants 520, is squeezed.
  static const _leftWidth = 260.0;
  static const _leftMinWidth = 240.0;
  static const _rightWidth = 320.0;
  static const _rightMinWidth = 280.0;
  static const _mainWidth = 520.0;

  // The content widths from which each rail is shown, as on the home feed.
  static const _rightRailFrom = 1052.0;
  static const _leftRailFrom = 812.0;

  String get _subtitle {
    final pending = controller.pending.length;
    final connections = formatCount(controller.connectionCount);
    return switch (pending) {
      0 => 'No invitations waiting · $connections connections',
      1 => '1 invitation waiting · $connections connections',
      _ => '$pending invitations waiting · $connections connections',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = theme.layoutTheme;
    final gap = layout.gap(GapSize.xl);
    final section = controller.section;

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

          final main = UnaColumn(
            gap: GapSize.lg,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!showLeft) _SectionChips(controller: controller),
              if (section == NetworkSection.grow) ...[
                NetworkInvitationsCard(controller: controller),
                NetworkSuggestions(controller: controller),
              ] else
                NetworkSectionView(section: section, controller: controller),
            ],
          );

          return UnaColumn(
            gap: GapSize.lg,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DemoPageHeader(
                title: NetworkData.title,
                subtitle: _subtitle,
                actions: [
                  Button.outline(
                    leading: const PhosphorIcon(
                      PhosphorIconsRegular.slidersHorizontal,
                    ),
                    onPressed: () => openSettings(context),
                    child: const Text('Invitation settings'),
                  ),
                  Button(
                    leading: const PhosphorIcon(
                      PhosphorIconsRegular.envelopeSimple,
                    ),
                    onPressed: () => showInviteDialog(context),
                    child: const Text('Invite people'),
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
                        child: NetworkManageCard(
                          controller: controller,
                          onSelected: (value) => controller.section = value,
                        ),
                      ),
                    Expanded(child: main),
                    if (showRight)
                      SizedBox(
                        width:
                            _rightWidth -
                            (_rightWidth - _rightMinWidth) * squeeze,
                        child: UnaColumn(
                          gap: GapSize.lg,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Not beside the full list of the same things.
                            if (section != NetworkSection.events)
                              NetworkEventsCard(
                                controller: controller,
                                onSeeAll: () =>
                                    controller.section = NetworkSection.events,
                              ),
                            if (section != NetworkSection.groups)
                              NetworkSuggestedGroupsCard(
                                controller: controller,
                                onSeeAll: () =>
                                    controller.section = NetworkSection.groups,
                              ),
                            const HomeFooterLinks(),
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
}

/// The "Manage my network" rows as a strip of chips, for a window too
/// narrow for the left rail. The ones that do not fit scroll into view.
class _SectionChips extends StatelessWidget {
  const _SectionChips({required this.controller});

  final NetworkController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        spacing: theme.gap(GapSize.xs),
        children: [
          for (final section in NetworkSection.values)
            Chip(
              leading: PhosphorIcon(section.icon),
              label: Text(
                '${section.label} · '
                '${formatCount(controller.countOf(section))}',
              ),
              selected: controller.section == section,
              onSelected: (_) => controller.section = section,
            ),
        ],
      ),
    );
  }
}

/// The three tabs of the phone layout.
enum _MobileTab { grow, invitations, manage }

class _MobileNetwork extends StatefulWidget {
  const _MobileNetwork({required this.controller});

  final NetworkController controller;

  @override
  State<_MobileNetwork> createState() => _MobileNetworkState();
}

class _MobileNetworkState extends State<_MobileNetwork> {
  _MobileTab _tab = _MobileTab.grow;

  NetworkController get _controller => widget.controller;

  String _label(_MobileTab tab) => switch (tab) {
    _MobileTab.grow => 'Grow',
    _MobileTab.invitations =>
      _controller.pending.isEmpty
          ? 'Invitations'
          : 'Invitations · ${_controller.pending.length}',
    _MobileTab.manage => 'My network',
  };

  void _open(NetworkSection section) {
    context.pushFullScreen<void>(
      (context) =>
          NetworkSectionPage(section: section, controller: _controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PageContainer(
      scrollable: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        // The phone designs space their blocks 14 apart.
        spacing: theme.gap(GapSize.md),
        children: [
          Row(
            children: [
              const Expanded(child: DemoPageHeader(title: NetworkData.title)),
              IconButton.secondary(
                icon: const PhosphorIcon(PhosphorIconsRegular.envelopeSimple),
                semanticLabel: 'Invite people',
                onPressed: () => showInviteDialog(context),
              ),
            ],
          ),
          Semantics(
            label: 'Network',
            container: true,
            child: Tabs<_MobileTab>(
              value: _tab,
              expandTabs: true,
              onChanged: (tab) => setState(() => _tab = tab),
              tabs: [
                for (final tab in _MobileTab.values)
                  Tab(
                    value: tab,
                    child: DemoTabLabel(_label(tab)),
                  ),
              ],
            ),
          ),
          ...switch (_tab) {
            _MobileTab.grow => [
              if (_controller.pending.isNotEmpty)
                _InvitationsTeaser(
                  count: _controller.pending.length,
                  onPressed: () =>
                      setState(() => _tab = _MobileTab.invitations),
                ),
              NetworkSuggestions(controller: _controller),
            ],
            _MobileTab.invitations => [
              NetworkInvitationsCard(controller: _controller),
            ],
            _MobileTab.manage => [
              NetworkManageCard(
                controller: _controller,
                onSelected: _open,
                showSelection: false,
                showGrow: false,
              ),
              NetworkEventsCard(
                controller: _controller,
                onSeeAll: () => _open(NetworkSection.events),
              ),
              NetworkSuggestedGroupsCard(
                controller: _controller,
                onSeeAll: () => _open(NetworkSection.groups),
              ),
            ],
          },
        ],
      ),
    );
  }
}

/// The phone's nudge towards the Invitations tab: a tappable card.
class _InvitationsTeaser extends StatelessWidget {
  const _InvitationsTeaser({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      onTap: onPressed,
      style: CardTheme(
        borderRadius: theme.radii.xl,
        padding: EdgeInsets.all(theme.gap(GapSize.md)),
        rowMainAxisSize: MainAxisSize.max,
      ),
      child: Row(
        children: [
          const IconTile(icon: PhosphorIcon(PhosphorIconsRegular.userPlus)),
          const Gap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count == 1
                      ? '1 invitation waiting'
                      : '$count invitations waiting',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.large.copyWith(
                    color: scheme.foreground,
                  ),
                ),
                Text(
                  'See who wants to connect',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted,
                ),
              ],
            ),
          ),
          PhosphorIcon(
            PhosphorIconsRegular.caretRight,
            size: theme.glyph,
            color: scheme.mutedForeground,
          ),
        ],
      ),
    );
  }
}
