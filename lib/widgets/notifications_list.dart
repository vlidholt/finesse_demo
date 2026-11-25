import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/network_data.dart';
import 'package:finesse_demo/data/notifications_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/session.dart';
import 'package:finesse_demo/widgets/home_pieces.dart';
import 'package:finesse_demo/widgets/network_links.dart';
import 'package:finesse_demo/widgets/notifications_controller.dart';
import 'package:finesse_demo/widgets/person_avatar.dart';
import 'package:finesse_demo/widgets/settings_controller.dart';
import 'package:finesse_demo/widgets/settings_links.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The notifications of the selected tab: a heading and a card of rows per
/// period — Today, This week, Earlier — or a note when the tab is empty.
class NotificationsList extends StatelessWidget {
  const NotificationsList({required this.controller, super.key});

  final NotificationsController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groups = controller.groups;
    final inset = theme.gap(GapSize.sm);

    if (groups.isEmpty) {
      final filter = controller.filter;
      return Card(
        child: Empty(
          icon: const PhosphorIcon(PhosphorIconsRegular.bellSimpleSlash),
          title: const Text('Nothing here'),
          description: Text(
            filter == NotificationFilter.all
                ? 'You have cleared every notification. New ones will '
                      'show up here.'
                : 'No notifications under ${filter.label} right now.',
          ),
          actions: [
            if (filter != NotificationFilter.all)
              Button.outline(
                onPressed: () => controller.filter = NotificationFilter.all,
                child: const Text('Show all notifications'),
              ),
          ],
        ),
      );
    }

    // One row open at a time: uncovering a second closes the first.
    return SwipeActionsScope(
      child: FinesseColumn(
        gap: GapSize.lg,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (period, notifications) in groups)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DemoSectionHeading(
                  period.label,
                  trailing: switch (notifications
                      .where(controller.isUnread)
                      .length) {
                    0 => null,
                    final unread => Text(
                      '$unread new',
                      style: theme.textTheme.muted,
                    ),
                  },
                ),
                const Gap.md(),
                Card(
                  style: CardTheme(padding: EdgeInsets.all(inset)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    // The Messages list's 2 between rows.
                    spacing: 2,
                    children: [
                      for (final notification in notifications)
                        _NotificationRow(
                          notification,
                          key: ValueKey(notification.id),
                          controller: controller,
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// One notification: who or what it is from, the sentence, what was
/// written, a button where one makes sense, its age and its menu.
///
/// The row has its menu's actions behind it too (`SwipeActions`): a finger
/// swipes from the start edge to mark it read or unread and from the end
/// edge to remove it or to see fewer like it, and a secondary click opens
/// them as a context menu.
class _NotificationRow extends StatelessWidget {
  const _NotificationRow(
    this.notification, {
    required this.controller,
    super.key,
  });

  final DemoNotification notification;
  final NotificationsController controller;

  /// Follows the row to wherever it is about.
  void _open(BuildContext context) {
    controller.markRead(notification);
    if (notification.kind == NotificationKind.event) {
      openNetworkSection(context, NetworkSection.events);
    } else if (notification.target == DemoDestination.network) {
      openNetworkSection(context, NetworkSection.grow);
    } else {
      context.goTo(notification.target);
    }
  }

  void _act(BuildContext context, NotificationAction action) {
    final person = notification.people.firstOrNull;
    switch (action) {
      case NotificationAction.reply:
      case NotificationAction.viewJob:
      case NotificationAction.message:
        _open(context);
      case NotificationAction.accept:
        final invitation = NotificationsData.invitationOf(notification);
        if (invitation != null) context.demo.network.accept(invitation);
        controller.answer(notification);
        showDemoToast(
          context,
          'You and ${person?.firstName} are now connected',
        );
      case NotificationAction.wish:
        controller.answer(notification);
        showDemoToast(
          context,
          'Birthday wishes sent to ${person?.firstName}',
        );
      case NotificationAction.congratulate:
        controller.answer(notification);
        showDemoToast(
          context,
          'Congratulations sent to ${person?.firstName}',
        );
    }
  }

  void _remove(
    BuildContext context,
    String message, {
    ToastVariant variant = ToastVariant.neutral,
  }) {
    final unread = controller.isUnread(notification);
    controller.remove(notification);
    showDemoToast(
      context,
      message,
      variant: variant,
      actionLabel: 'Undo',
      onAction: () => controller.restore(notification, unread: unread),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = controller.isUnread(notification);
    final action = notification.action;
    // An invitation accepted on the Network screen is answered here too.
    final answered =
        controller.isAnswered(notification) ||
        (action == NotificationAction.accept &&
            notification.people.isNotEmpty &&
            context.demo.network.isConnected(notification.people.first));

    // Clipped to the row's own rounded shape, so the actions come out from
    // behind it with its corners. A clip in paint: no layer.
    return ClipRRect(
      borderRadius: Theme.of(context).radii.lg,
      child: SwipeActions(
        // The row has a menu of its own, behind "More options", and a
        // secondary click opens that one (see [_RowMenuHost]): a menu
        // inside the child of another menu's region takes the outer one
        // for its parent, and then opens only every other time.
        contextMenu: false,
        leading: [
          SwipeAction(
            icon: PhosphorIcon(
              unread
                  ? PhosphorIconsRegular.envelopeSimpleOpen
                  : PhosphorIconsRegular.envelopeSimple,
            ),
            label: unread ? 'Read' : 'Unread',
            onPressed: () {
              controller.toggleRead(notification);
              return false;
            },
          ),
        ],
        trailing: [
          SwipeAction(
            icon: const PhosphorIcon(PhosphorIconsRegular.trash),
            label: 'Remove',
            destructive: true,
            // The row leaves; `onRemoved` takes it out of the list.
            onPressed: () => true,
          ),
          SwipeAction(
            icon: const PhosphorIcon(PhosphorIconsRegular.bellSimpleSlash),
            label: 'Fewer',
            onPressed: () {
              _remove(context, 'You will see fewer notifications like this');
              return false;
            },
          ),
        ],
        onRemoved: () => _remove(
          context,
          'Notification removed',
          variant: ToastVariant.destructive,
        ),
        child: _RowMenuHost(
          child: _buildRow(context, unread: unread, answered: answered),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required bool unread,
    required bool answered,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final layout = theme.layoutTheme;
    final action = notification.action;
    // The accent, thinned: a dozen unread rows are a tint, not a block.
    final wash = Color.alphaBlend(
      scheme.accent.withValues(
        alpha: theme.brightness == Brightness.dark ? .4 : .6,
      ),
      scheme.card,
    );

    final body = theme.textTheme.p.copyWith(
      color: unread ? scheme.foreground : scheme.foregroundSubtle,
    );

    return Pressable(
      onPressed: () => _open(context),
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed);
        return FocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: theme.radii.lg,
          // The fill fades as every control's does: on the theme's motion
          // (none under `Motion.none` or reduced motion), and as a
          // cross-fade, which an `AnimatedContainer`'s channel-by-channel
          // lerp between a fill and nothing is not.
          child: AnimatedFill(
            // Unread rows carry the accent wash a selected card does.
            color: unread
                ? wash
                : hovered
                ? scheme.muted
                : null,
            borderRadius: theme.radii.lg,
            child: Padding(
              padding: EdgeInsets.all(layout.gap(GapSize.md)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Mark(notification, surface: unread ? wash : null),
                  const Gap.md(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(children: _spans(notification.text, body)),
                          style: body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (notification.excerpt case final excerpt?) ...[
                          Text(
                            excerpt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.muted,
                          ),
                        ],
                        if (notification.quote case final quote?) ...[
                          const Gap.sm(),
                          _Quote(quote, onCard: !unread),
                        ],
                        if (action != null) ...[
                          const Gap.sm(),
                          DemoPillButton(
                            label: action.label,
                            icon: action.icon,
                            done: answered && action.done != null,
                            doneLabel: action.done,
                            doneIcon: PhosphorIconsRegular.check,
                            primary: action == NotificationAction.accept,
                            onPressed: answered && action.done != null
                                ? null
                                : () => _act(context, action),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Gap.sm(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (unread) ...[
                            Semantics(
                              label: 'Unread',
                              child: Container(
                                width: layout.gap(GapSize.sm),
                                height: layout.gap(GapSize.sm),
                                decoration: BoxDecoration(
                                  color: scheme.tint,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const Gap.xs(),
                          ],
                          Text(
                            notification.age,
                            // Semibold in the tint while unread.
                            style: theme.textTheme.caption.copyWith(
                              fontWeight: unread ? FontWeight.w600 : null,
                              color: unread ? scheme.tint : null,
                            ),
                          ),
                        ],
                      ),
                      _RowMenu(
                        unread: unread,
                        onToggleRead: () => controller.toggleRead(notification),
                        onMute: () => _remove(
                          context,
                          'You will see fewer notifications like this',
                        ),
                        onRemove: () => _remove(
                          context,
                          'Notification removed',
                          variant: ToastVariant.destructive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Splits `*bold* text` into spans; the bold ones are semibold in the
  /// foreground colour.
  static List<TextSpan> _spans(String text, TextStyle base) {
    final strong = base.copyWith(fontWeight: FontWeight.w600);
    final parts = text.split('*');
    return [
      for (final (index, part) in parts.indexed)
        if (part.isNotEmpty)
          TextSpan(text: part, style: index.isOdd ? strong : null),
    ];
  }
}

/// What leads a row: a portrait, a logo or a glyph, with the kind's mark
/// pinned to its corner when it is a picture.
class _Mark extends StatelessWidget {
  const _Mark(this.notification, {this.surface});

  final DemoNotification notification;

  /// The colour behind the row, when it is not a card: the mark's ring.
  final Color? surface;

  // The mark is a picture with a badge pinned to its corner: the badge is
  // half the picture and its glyph a little over half the badge, whatever
  // size the theme's avatar is.
  static const _badgeScale = .5;
  static const _badgeGlyphScale = .55;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final kind = notification.kind;
    final size = theme.avatarMd;
    final badgeSize = size * _badgeScale;

    final Widget picture;
    if (notification.people.firstOrNull case final Person person?) {
      picture = PersonAvatar(person, size: size);
    } else if (notification.company case final company?) {
      picture = DemoMark(
        asset: company.logo,
        label: company.name,
        size: size,
      );
    } else if (notification.group case final group?) {
      picture = DemoMark(asset: group.logo, label: group.name, size: size);
    } else {
      // No one to show: the kind's glyph is the picture.
      return IconTile(
        icon: PhosphorIcon(kind.icon),
        size: size,
        iconSize: size / 2,
        borderRadius: theme.radii.full,
        backgroundColor: surface == null ? null : scheme.card,
      );
    }

    final (Color fill, Color ink) = switch (kind) {
      NotificationKind.reaction => (coralOf(theme), const Color(0xFFFFFFFF)),
      NotificationKind.celebration => (
        scheme.warning,
        const Color(0xFFFFFFFF),
      ),
      NotificationKind.job || NotificationKind.application => (
        scheme.success,
        const Color(0xFFFFFFFF),
      ),
      _ => (scheme.primary, scheme.primaryForeground),
    };

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          picture,
          PositionedDirectional(
            end: -3,
            bottom: -3,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: surface ?? scheme.card,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: PhosphorIcon(
                kind.icon,
                size: badgeSize * _badgeGlyphScale,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What someone wrote, set apart from the sentence about it.
class _Quote extends StatelessWidget {
  const _Quote(this.text, {required this.onCard});

  final String text;

  /// Whether the row behind is the card itself rather than the unread wash.
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: theme.gap(GapSize.md),
        vertical: theme.gap(GapSize.sm),
      ),
      decoration: BoxDecoration(
        // A comment's bubble on the card; the card's own colour on the
        // wash, where the bubble's grey would disappear.
        color: onCard ? scheme.muted : scheme.card,
        borderRadius: theme.radii.lg,
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.muted.copyWith(
          color: scheme.foregroundSubtle,
        ),
      ),
    );
  }
}

/// The "More options" button of a row.
class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.unread,
    required this.onToggleRead,
    required this.onMute,
    required this.onRemove,
  });

  final bool unread;
  final VoidCallback onToggleRead;
  final VoidCallback onMute;
  final VoidCallback onRemove;

  static const _anchor = AnchorAuto(
    offset: Offset(0, 4),
    targetAnchor: AlignmentDirectional.bottomEnd,
    followerAnchor: AlignmentDirectional.bottomStart,
    fallback: AnchorAuto(
      offset: Offset(0, -4),
      targetAnchor: AlignmentDirectional.topEnd,
      followerAnchor: AlignmentDirectional.topStart,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DropdownMenu(
      anchor: _anchor,
      itemsBuilder: (_) => [
        MenuItem(
          leading: PhosphorIcon(
            unread
                ? PhosphorIconsRegular.envelopeSimpleOpen
                : PhosphorIconsRegular.envelopeSimple,
          ),
          onPressed: onToggleRead,
          child: Text(unread ? 'Mark as read' : 'Mark as unread'),
        ),
        MenuItem(
          leading: const PhosphorIcon(PhosphorIconsRegular.bellSimpleSlash),
          onPressed: onMute,
          child: const Text('Show fewer like this'),
        ),
        MenuItem(
          leading: const PhosphorIcon(PhosphorIconsRegular.gearSix),
          onPressed: () => openSettings(context, SettingsSection.notifications),
          child: const Text('Notification settings'),
        ),
        const MenuDivider(),
        MenuItem(
          destructive: true,
          leading: const PhosphorIcon(PhosphorIconsRegular.trash),
          onPressed: onRemove,
          child: const Text('Remove'),
        ),
      ],
      builder: (context, menu, _) {
        // A secondary click on the row opens this menu too.
        _RowMenuHost.of(context)?.openMenu = menu.open;
        return IconButton.ghost(
          size: ButtonSize.sm,
          icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
          semanticLabel: 'More options',
          onPressed: menu.toggle,
        );
      },
    );
  }
}

/// Makes a secondary click anywhere on a row open the row's own "More
/// options" menu: the context menu of a notification, for a mouse.
///
/// The menu is the one under the button, opened from there, so there is
/// one menu to keep right. Its trigger hands this host the way to open it.
class _RowMenuHost extends StatefulWidget {
  const _RowMenuHost({required this.child});

  final Widget child;

  static _RowMenuHostState? of(BuildContext context) =>
      context.findAncestorStateOfType<_RowMenuHostState>();

  @override
  State<_RowMenuHost> createState() => _RowMenuHostState();
}

class _RowMenuHostState extends State<_RowMenuHost> {
  /// Opens the row's menu; set by the menu's trigger when it is built.
  VoidCallback? openMenu;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapUp: (_) => openMenu?.call(),
      child: widget.child,
    );
  }
}
