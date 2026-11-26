import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/data/network_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/demo_previews.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/network_controller.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// One of the lists behind "Manage my network": connections, following,
/// groups, events or pages, as a card of rows.
///
/// A desktop shows it in the Network screen's main column; a phone shows it
/// as a page of its own ([NetworkSectionPage]).
class NetworkSectionView extends StatelessWidget {
  const NetworkSectionView({
    required this.section,
    required this.controller,
    this.showTitle = true,
    super.key,
  });

  final NetworkSection section;
  final NetworkController controller;

  /// Whether the card carries the list's name. Off where an app bar above
  /// it already does.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final count = formatCount(controller.countOf(section));

    final (String summary, List<Widget> rows) = switch (section) {
      NetworkSection.connections => (
        '$count connections',
        [
          for (final entry in controller.connections)
            _PersonRow(
              entry.person,
              key: ValueKey(entry.person.name),
              detail: entry.since,
              trailing: Button.outline(
                size: ButtonSize.sm,
                style: ButtonTheme(
                  decoration: theme.buttonDecoration(radius: theme.radii.full),
                  textStyle: theme.textTheme.small,
                ),
                leading: const PhosphorIcon(
                  PhosphorIconsRegular.paperPlaneTilt,
                ),
                onPressed: () => context.leaveTo(DemoDestination.messages),
                child: const Text('Message'),
              ),
            ),
        ],
      ),
      NetworkSection.following => (
        'You follow $count people',
        [
          for (final entry in NetworkData.following)
            _PersonRow(
              entry.person,
              detail: entry.followers,
              trailing: DemoPillButton.follow(
                following: controller.isFollowing(entry.person),
                onPressed: () => controller.toggleFollowing(entry.person),
              ),
            ),
        ],
      ),
      NetworkSection.groups => (
        'You are in $count groups',
        [
          for (final group in NetworkData.groups)
            _MarkRow(
              mark: DemoMark(
                asset: group.logo,
                icon: group.icon,
                label: group.name,
              ),
              title: group.name,
              subtitle: group.about,
              detail: group.newPosts > 0 && controller.hasJoined(group)
                  ? '${group.members} · ${group.newPosts} new posts'
                  : group.members,
              trailing: DemoPillButton(
                label: 'Join',
                icon: PhosphorIconsRegular.plus,
                done: controller.hasJoined(group),
                doneLabel: 'Joined',
                doneIcon: PhosphorIconsRegular.check,
                onPressed: () => controller.toggleJoined(group),
              ),
            ),
        ],
      ),
      NetworkSection.events => (
        controller.eventCount == 1
            ? 'You are going to 1 event'
            : 'You are going to $count events',
        [
          for (final event in NetworkData.events)
            _MarkRow(
              mark: DemoDateTile(
                month: event.month,
                day: event.day,
              ),
              title: event.title,
              subtitle: '${event.place} · ${event.time}',
              detailWidget: MutualsLine(
                people: event.going,
                label: '${formatCount(controller.attendeesOf(event))} going',
              ),
              trailing: DemoPillButton(
                label: 'Attend',
                icon: PhosphorIconsRegular.star,
                done: controller.isAttending(event),
                doneLabel: 'Going',
                doneIcon: PhosphorIconsFill.star,
                onPressed: () => controller.toggleAttending(event),
              ),
            ),
        ],
      ),
      NetworkSection.pages => (
        'You follow $count pages',
        [
          for (final page in NetworkData.pages)
            _MarkRow(
              mark: DemoMark(
                asset: page.company.logo,
                label: page.company.name,
              ),
              title: page.company.name,
              subtitle: page.tagline,
              detail: page.followers,
              onPressed: () => showCompanyPreview(context, page.company),
              trailing: DemoPillButton.follow(
                following: controller.isFollowingPage(page.company),
                onPressed: () => controller.togglePage(page.company),
              ),
            ),
        ],
      ),
      NetworkSection.grow => ('', const <Widget>[]),
    };

    return Card(
      style: CardTheme(
        sectionGap: theme.gap(GapSize.md),
        rowMainAxisSize: MainAxisSize.max,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      title: showTitle
          ? Semantics(
              header: true,
              child: Text(
                section.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(
                    color: scheme.foregroundSubtle,
                  ),
                ),
              ),
              if (section == NetworkSection.connections)
                _SortMenu(controller: controller),
            ],
          ),
          for (final row in rows) ...[
            Divider(
              margin: EdgeInsets.symmetric(vertical: theme.gap(GapSize.md)),
            ),
            row,
          ],
        ],
      ),
    );
  }
}

/// A list of [NetworkSectionView] as a page: what a phone's "My network"
/// rows — and the home feed's "Groups" and "Events" shortcuts — open.
class NetworkSectionPage extends StatelessWidget {
  const NetworkSectionPage({
    required this.section,
    required this.controller,
    super.key,
  });

  final NetworkSection section;
  final NetworkController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(section.label),
      ),
      body: PageContainer(
        scrollable: true,
        // The readable width of a list, in a window wider than a phone's.
        maxWidth: 720,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => NetworkSectionView(
            section: section,
            controller: controller,
            showTitle: false,
          ),
        ),
      ),
    );
  }
}

/// "Recently added ⌄": the order of the Connections list.
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.controller});

  final NetworkController controller;

  static const _anchor = AnchorAuto(
    offset: Offset(0, 4),
    targetAnchor: AlignmentDirectional.bottomEnd,
    followerAnchor: AlignmentDirectional.bottomStart,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DropdownMenu(
      anchor: _anchor,
      items: [
        for (final sort in ConnectionSort.values)
          MenuItem(
            trailing: controller.sort == sort
                ? const PhosphorIcon(PhosphorIconsRegular.check)
                : null,
            onPressed: () => controller.sort = sort,
            child: Text(sort.label),
          ),
      ],
      builder: (context, menu, _) => Pressable(
        onPressed: menu.toggle,
        builder: (context, states) => FocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: theme.radii.sm,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.sort.label,
                style: theme.textTheme.small.copyWith(
                  color: scheme.foreground,
                ),
              ),
              const Gap.xs(),
              PhosphorIcon(
                PhosphorIconsRegular.caretDown,
                size: theme.iconBeside(theme.textTheme.small),
                color: scheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A person in a list: portrait, name, headline, a line of detail and a
/// button.
class _PersonRow extends StatelessWidget {
  const _PersonRow(
    this.person, {
    required this.detail,
    required this.trailing,
    super.key,
  });

  final Person person;
  final String detail;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    void open() => showPersonPreview(context, person);
    return UnaRow(
      gap: GapSize.md,
      children: [
        Pressable(
          onPressed: open,
          semanticLabel: 'Preview ${person.name}',
          builder: (context, states) => FocusRing(
            visible: states.contains(WidgetState.focused),
            borderRadius: theme.radii.full,
            child: PersonAvatar(person, showOnline: person.online),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonName(person, onPressed: open),
              Text(
                person.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.muted,
              ),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.caption,
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

/// A group, an event or a page in a list: a mark, a title, a line about it,
/// a line of detail and a button.
class _MarkRow extends StatelessWidget {
  const _MarkRow({
    required this.mark,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.detail,
    this.detailWidget,
    this.onPressed,
  });

  final Widget mark;
  final String title;
  final String subtitle;

  /// The fine print under the subtitle, as text or as a widget.
  final String? detail;
  final Widget? detailWidget;
  final Widget trailing;

  /// Makes the title a link.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.large.copyWith(
      color: theme.colorScheme.foreground,
    );
    return UnaRow(
      gap: GapSize.md,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        mark,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onPressed case final onPressed?)
                HomeTextLink(title, onPressed: onPressed, style: titleStyle)
              else
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.muted,
              ),
              if (detailWidget case final widget?) ...[
                const Gap.xs(),
                widget,
              ] else if (detail case final detail?)
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.caption,
                ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}
