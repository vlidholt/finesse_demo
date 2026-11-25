import 'package:finesse_demo/data/messages_data.dart';
import 'package:finesse_demo/widgets/messages_common.dart';
import 'package:finesse_demo/widgets/messages_controller.dart';
import 'package:finesse_demo/widgets/messages_new_dialog.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The first pane of Messages: the title, search, the filter chips and one
/// row per conversation.
///
/// In the desktop card it fills the pane and scrolls its own rows. On a
/// phone it is the whole Messages destination and the page scrolls it, so
/// [scrollable] is false and the rows are laid out in full.
class MessagesConversationList extends StatelessWidget {
  const MessagesConversationList({
    required this.controller,
    required this.onOpen,
    required this.headerPadding,
    this.scrollable = true,
    this.showSelection = true,
    this.surfaceColor,
    super.key,
  });

  final MessagesController controller;

  /// Called with the conversation whose row was tapped.
  final ValueChanged<Conversation> onOpen;

  /// The inset of the title, the search field and the chips.
  final EdgeInsetsGeometry headerPadding;

  /// Whether the rows scroll inside the pane.
  final bool scrollable;

  /// Whether the open conversation's row is highlighted. Off where the
  /// conversation is not on screen beside the list.
  final bool showSelection;

  /// The colour behind the list, when it is not a card.
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowInset = theme.layoutTheme.gap(GapSize.sm);
    final conversations = controller.visible;

    Widget row(Conversation conversation) => _ConversationRow(
      key: ValueKey(conversation.id),
      controller: controller,
      conversation: conversation,
      child: _ConversationTile(
        conversation: conversation,
        preview: controller.previewOf(conversation),
        time: controller.timeOf(conversation),
        unread: controller.unreadOf(conversation),
        muted: controller.isMuted(conversation),
        selected: showSelection && conversation.id == controller.selected.id,
        surfaceColor: surfaceColor,
        onTap: () => onOpen(conversation),
      ),
    );

    final header = Padding(
      padding: headerPadding,
      child: _ListHeader(controller: controller, onOpen: onOpen),
    );

    if (conversations.isEmpty) {
      const empty = Empty(
        icon: PhosphorIcon(PhosphorIconsRegular.chatCircleDots),
        title: Text('No conversations'),
        description: Text('Nothing matches this filter.'),
      );
      return Column(
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (scrollable)
            const Expanded(child: SingleChildScrollView(child: empty))
          else
            empty,
        ],
      );
    }

    // The designs leave 2 between rows, which is under the gap scale.
    const rowGap = 2.0;
    final rowsPadding = EdgeInsets.fromLTRB(rowInset, 0, rowInset, rowInset);

    // One row open at a time: uncovering a second closes the first.
    return SwipeActionsScope(
      child: Column(
        mainAxisSize: scrollable ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (scrollable)
            Expanded(
              child: ListView.separated(
                padding: rowsPadding,
                itemCount: conversations.length,
                separatorBuilder: (_, _) => const SizedBox(height: rowGap),
                itemBuilder: (context, index) => row(conversations[index]),
              ),
            )
          else
            Padding(
              padding: rowsPadding,
              child: Column(
                spacing: rowGap,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (final c in conversations) row(c)],
              ),
            ),
        ],
      ),
    );
  }
}

/// A conversation's row with its actions behind it.
///
/// With a finger the row is swiped: from the start edge to mark it read or
/// unread, from the end edge to delete it or mute it, and a swipe all the
/// way across does the first of those. With a mouse the same three are the
/// row's context menu (a secondary click, or the menu key). The state they
/// change is the session's controller, so the navigation's badge follows.
class _ConversationRow extends StatelessWidget {
  const _ConversationRow({
    required this.controller,
    required this.conversation,
    required this.child,
    super.key,
  });

  final MessagesController controller;
  final Conversation conversation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final unread = controller.unreadOf(conversation) > 0;
    final muted = controller.isMuted(conversation);
    final theme = Theme.of(context);
    // Clipped to the row's rounded shape, so the actions come out from
    // behind it with its corners. A clip in paint: no layer.
    return ClipRRect(
      borderRadius: theme.listTileTheme.borderRadius ?? theme.radius,
      child: SwipeActions(
        leading: [
          SwipeAction(
            icon: PhosphorIcon(
              unread
                  ? PhosphorIconsRegular.envelopeSimpleOpen
                  : PhosphorIconsRegular.envelopeSimple,
            ),
            label: unread ? 'Read' : 'Unread',
            onPressed: () {
              controller.toggleRead(conversation);
              return false;
            },
          ),
        ],
        trailing: [
          // The assistant is pinned: it can be muted, not deleted.
          if (!conversation.assistant)
            SwipeAction(
              icon: const PhosphorIcon(PhosphorIconsRegular.trash),
              label: 'Delete',
              destructive: true,
              // The row leaves, and `onRemoved` takes it out of the list.
              onPressed: () => true,
            ),
          SwipeAction(
            icon: PhosphorIcon(
              muted
                  ? PhosphorIconsRegular.bell
                  : PhosphorIconsRegular.bellSimpleSlash,
            ),
            label: muted ? 'Unmute' : 'Mute',
            onPressed: () {
              controller.toggleMuted(conversation);
              return false;
            },
          ),
        ],
        onRemoved: () {
          controller.delete(conversation);
          showDemoToast(
            context,
            'Conversation deleted',
            description: conversation.name,
            variant: ToastVariant.destructive,
            actionLabel: 'Undo',
            onAction: () => controller.restore(conversation),
          );
        },
        child: child,
      ),
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({required this.controller, required this.onOpen});

  final MessagesController controller;

  /// Opens the conversation "New message" chose.
  final ValueChanged<Conversation> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget action(IconData icon, String label, VoidCallback onPressed) =>
        IconButton.secondary(
          icon: PhosphorIcon(icon),
          semanticLabel: label,
          onPressed: onPressed,
        );

    return FinesseColumn(
      gap: GapSize.md,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Messages',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // The theme's section heading, a weight heavier: the
                // page's own title.
                style: theme.textTheme.h3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.foreground,
                ),
              ),
            ),
            // Steps through the chips below, for a hand on the keyboard.
            action(
              PhosphorIconsRegular.slidersHorizontal,
              'Filter',
              () => controller.filter =
                  MessageFilter.values[(controller.filter.index + 1) %
                      MessageFilter.values.length],
            ),
            const Gap.xs(),
            action(
              PhosphorIconsRegular.pencilSimple,
              'New message',
              () => showNewMessageDialog(context, controller, onOpen),
            ),
          ],
        ),
        SearchField(
          placeholder: const Text('Search messages'),
          controller: controller.search,
        ),
        // One filter at a time, on a row that does not wrap: the chips
        // that do not fit scroll into view, fading at the edge.
        ChipGroup<MessageFilter>(
          semanticLabel: 'Show conversations',
          wrap: false,
          allowDeselection: false,
          value: controller.filter,
          onChanged: (filter) => controller.filter = filter!,
          items: [
            for (final filter in MessageFilter.values)
              ChipGroupItem(
                value: filter,
                label: Text(
                  filter == MessageFilter.requests
                      ? '${filter.label} · ${controller.requestCount}'
                      : filter.label,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// One conversation: avatar, name and time on the first line, the last
/// message and the unread count on the second.
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.preview,
    required this.time,
    required this.unread,
    required this.muted,
    required this.selected,
    required this.onTap,
    this.surfaceColor,
  });

  final Conversation conversation;
  final String preview;
  final String time;
  final int unread;

  /// Whether the conversation's notifications are off: a struck-out bell
  /// before the time.
  final bool muted;
  final bool selected;
  final VoidCallback onTap;
  final Color? surfaceColor;

  // A row's picture: a step up from the theme's avatar, for the two lines
  // of text beside it.
  static const _avatarSize = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isUnread = unread > 0;

    return ListTile(
      selected: selected,
      onTap: onTap,
      leading: ConversationAvatar(
        conversation,
        size: _avatarSize,
        surfaceColor: surfaceColor,
      ),
      titleStyle: theme.messagesName,
      // The time shares the name's line and the count the preview's, so the
      // preview runs the full width under the time when nothing is unread.
      title: Row(
        children: [
          Expanded(child: Text(conversation.name)),
          const Gap.sm(),
          if (muted) ...[
            PhosphorIcon(
              PhosphorIconsRegular.bellSimpleSlash,
              size: theme.iconBeside(theme.messagesCaption),
              color: colors.mutedForeground,
              semanticLabel: 'Muted',
            ),
            const Gap.xs(),
          ],
          Text(
            time,
            style: theme.messagesCaption.copyWith(
              // As tall as the name it shares a line with.
              height:
                  (theme.messagesName.fontSize! * theme.messagesName.height!) /
                  theme.messagesCaption.fontSize!,
              fontWeight: isUnread ? FontWeight.w600 : null,
              color: isUnread ? colors.tint : null,
            ),
          ),
        ],
      ),
      subtitleStyle: isUnread ? theme.messagesLabel : null,
      subtitle: Row(
        children: [
          Expanded(child: Text(preview)),
          if (isUnread) ...[
            const Gap.sm(),
            IndicatorBadge(
              count: unread,
              size: theme.glyphLg,
              ringWidth: 0,
              semanticLabel: '$unread unread',
            ),
          ],
        ],
      ),
    );
  }
}
