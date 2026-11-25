import 'package:finesse_demo/data/messages_data.dart';
import 'package:finesse_demo/widgets/messages_common.dart';
import 'package:finesse_demo/widgets/person_avatar.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The measurements of a thread that the designs change between the desktop
/// pane and the full-screen conversation.
@immutable
class ThreadMetrics {
  const ThreadMetrics({
    required this.padding,
    required this.gap,
    required this.maxBubbleWidth,
    required this.imageSize,
    required this.attachmentWidth,
    required this.alignToEnd,
  });

  /// The conversation pane of the desktop card: the theme's widest gap at
  /// the sides and the card's padding under the header.
  factory ThreadMetrics.pane(ThemeData theme) {
    final side = theme.gap(GapSize.xl);
    return ThreadMetrics(
      padding: EdgeInsets.fromLTRB(side, messagesPaneInset(theme), side, 0),
      // Between the theme's `sm` and `md` gaps.
      gap: 10,
      maxBubbleWidth: 420,
      imageSize: const Size(280, 190),
      attachmentWidth: 320,
      alignToEnd: false,
    );
  }

  /// The conversation as a page of its own: tighter all round.
  factory ThreadMetrics.page(ThemeData theme) {
    final inset = theme.gap(GapSize.md);
    return ThreadMetrics(
      padding: EdgeInsets.fromLTRB(inset, inset, inset, 0),
      gap: theme.gap(GapSize.sm),
      maxBubbleWidth: 268,
      imageSize: const Size(260, 170),
      attachmentWidth: 300,
      alignToEnd: true,
    );
  }

  /// The inset of the messages, without the room kept for the composer.
  final EdgeInsets padding;

  /// The space between two messages.
  final double gap;

  /// The widest a line of message text runs. An incoming row — avatar, gap
  /// and bubble — is capped at this; an outgoing bubble is this plus its own
  /// padding, as the designs' CSS has it.
  final double maxBubbleWidth;

  /// The size of a picture message.
  final Size imageSize;

  /// The width of an attachment card.
  final double attachmentWidth;

  /// Whether a thread shorter than the viewport sits against the composer
  /// rather than under the header.
  final bool alignToEnd;
}

/// The messages of one conversation: the day divider, bubbles, attachments
/// and pictures, the read receipt and whoever is typing.
///
/// It is a `ChatList`: anchored to its newest message, which a new one
/// pushes up as it arrives; following a reply that is still being written;
/// and holding still, with a button back to the end, once the reader has
/// scrolled away.
class MessagesThread extends StatelessWidget {
  const MessagesThread({
    required this.conversation,
    required this.messages,
    required this.metrics,
    this.controller,
    this.insets = EdgeInsets.zero,
    super.key,
  });

  final Conversation conversation;

  /// The thread, oldest first; every message has its `id`.
  final List<ChatMessage> messages;

  final ThreadMetrics metrics;

  /// Scrolls the thread back to its end, and says whether it is there.
  final ChatListController? controller;

  /// Space to keep clear around the messages on top of the metrics' own
  /// padding: the header and the composer the thread scrolls under.
  final EdgeInsets insets;

  @override
  Widget build(BuildContext context) {
    return ChatList<ChatMessage>(
      messages: messages,
      idOf: (message) => message.id,
      controller: controller,
      alignment: metrics.alignToEnd
          ? ChatListAlignment.bottom
          : ChatListAlignment.top,
      padding: metrics.padding + insets,
      // The designs set every message the same distance from the last; a
      // run only decides who carries the portrait.
      spacing: metrics.gap,
      groupSpacing: metrics.gap,
      directionOf: (message) => message.outgoing
          ? ChatBubbleDirection.outgoing
          : ChatBubbleDirection.incoming,
      // A reply being written is a run of its own: the designs show the
      // portrait beside the dots and beside the message above them.
      sameGroup: (a, b) =>
          !a.outgoing &&
          !b.outgoing &&
          !a.pending &&
          !b.pending &&
          a.sender == b.sender,
      separatorBuilder: (context, previous, message) =>
          previous == null ? _DayDivider(conversation.day) : null,
      itemBuilder: (context, item) => _MessageItem(
        conversation: conversation,
        message: item.message,
        metrics: metrics,
        showAvatar: item.isLastInGroup,
      ),
    );
  }
}

/// "Today", between two hairlines.
class _DayDivider extends StatelessWidget {
  const _DayDivider(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: theme.gap(GapSize.xs)),
      child: FinesseRow(
        gap: GapSize.md,
        children: [
          const Expanded(child: Divider()),
          Text(
            label,
            style: theme.messagesCaption.copyWith(
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

/// A message and what hangs under it: the delivery line, the room a
/// reaction pill needs.
class _MessageItem extends StatelessWidget {
  const _MessageItem({
    required this.conversation,
    required this.message,
    required this.metrics,
    required this.showAvatar,
  });

  final Conversation conversation;
  final ChatMessage message;
  final ThreadMetrics metrics;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final receipt = message.receipt;
    // The delivery line moves to the newest message when another is sent:
    // the one that loses it closes up instead of jumping.
    return SpringSize(
      clipBehavior: Clip.none,
      // A bubble below that is already growing smoothly is followed as it
      // is.
      rigidDistance: theme.gap(GapSize.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MessageRow(
            conversation: conversation,
            message: message,
            metrics: metrics,
            showAvatar: showAvatar,
          ),
          // The receipt hangs closer to its message than the next message
          // would; a reaction pill overhangs its bubble and needs more room.
          if (receipt != null) ...[
            SizedBox(height: metrics.gap - theme.gap(GapSize.xs)),
            _Receipt(receipt),
          ],
          if (message.reactions > 0) const SizedBox(height: _Reacted.margin),
        ],
      ),
    );
  }
}

/// One message on its side of the thread: an outgoing one against the end
/// edge, an incoming one after the avatar gutter.
class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.conversation,
    required this.message,
    required this.metrics,
    required this.showAvatar,
  });

  final Conversation conversation;
  final ChatMessage message;
  final ThreadMetrics metrics;

  /// Whether this is the last incoming message of a run, which carries the
  /// sender's portrait.
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = message.outgoing
        ? ChatBubbleDirection.outgoing
        : ChatBubbleDirection.incoming;
    final bubblePadding =
        (theme.chatBubbleTheme.padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10))
            .resolve(Directionality.of(context));
    final gutter = theme.gap(GapSize.sm);
    final sender = message.sender ?? conversation.person;
    final text = message.text;

    // Each kind of content caps its own width, the way the designs measure
    // it: the whole box for a card or a picture; for a bubble, the text of
    // an outgoing one and the row — avatar, gutter and bubble — of an
    // incoming one.
    final Widget content;
    if (message.file case final file?) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: metrics.attachmentWidth),
        child: _Attachment(file),
      );
    } else if (message.image case final image?) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: metrics.imageSize.width + 2 * _Picture.borderWidth,
        ),
        child: _Picture(image, size: metrics.imageSize),
      );
    } else {
      final Widget body;
      if (message.outgoing) {
        body = Text(text!);
      } else if (message.reactions > 0) {
        body = _Reacted(
          count: message.reactions,
          bubblePadding: bubblePadding,
          child: Text(text!),
        );
      } else {
        // A reply is three dots until it arrives, and then is revealed
        // rather than swapped in. The assistant's keeps arriving, with a
        // caret at its end; a message that was always there is plain text.
        body = StreamingText(
          text ?? '',
          streaming: message.pending || message.streaming,
          showCaret: conversation.assistant,
          placeholder: TypingIndicator(
            dotSize: _typingDot,
            semanticLabel: conversation.assistant
                ? 'The assistant is writing'
                : '${sender?.firstName ?? 'Someone'} is typing',
          ),
        );
      }
      content = ChatBubble(
        direction: direction,
        padding: message.pending ? messagesTypingPadding : null,
        maxWidth: message.outgoing
            ? metrics.maxBubbleWidth + bubblePadding.horizontal
            : metrics.maxBubbleWidth - messagesThreadAvatar - gutter,
        child: body,
      );
    }

    if (message.outgoing) {
      return Padding(
        // An outgoing message stays out of the avatar gutter.
        padding: const EdgeInsetsDirectional.only(start: messagesThreadAvatar),
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: content,
        ),
      );
    }

    final Widget avatar;
    if (!showAvatar) {
      avatar = const SizedBox(width: messagesThreadAvatar);
    } else if (conversation.assistant) {
      avatar = const AssistantMark(size: messagesThreadAvatar);
    } else if (sender != null) {
      // The bubble, or the indicator in it, says who is writing.
      avatar = ExcludeSemantics(
        child: PersonAvatar(sender, size: messagesThreadAvatar),
      );
    } else {
      avatar = const SizedBox(width: messagesThreadAvatar);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        avatar,
        SizedBox(width: gutter),
        Flexible(child: content),
      ],
    );
  }

  // A little larger than the indicator's own default, as the designs draw
  // the dots.
  static const _typingDot = 7.0;
}

/// A message with the reaction pill hanging off its bottom end corner.
///
/// The pill is positioned from inside the bubble — a `ChatBubble` has no
/// slot for one and aligns itself, so its outline cannot be reached from
/// outside — and is pushed out past the bubble's padding.
class _Reacted extends StatelessWidget {
  const _Reacted({
    required this.count,
    required this.bubblePadding,
    required this.child,
  });

  final int count;
  final EdgeInsets bubblePadding;
  final Widget child;

  // The pill's geometry in the designs: how tall it is, its padding and how
  // far it hangs past the bubble's side, how far below the bubble's bottom,
  // and the room the thread adds under a message that carries one.
  static const _height = 22.0;
  static const _inset = 6.0;
  static const _drop = 12.0;
  static const margin = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          end: -(bubblePadding.right + _inset),
          bottom: -(bubblePadding.bottom + _drop),
          child: Semantics(
            label: '$count ${count == 1 ? 'reaction' : 'reactions'}',
            excludeSemantics: true,
            child: Container(
              height: _height,
              padding: const EdgeInsets.symmetric(horizontal: _inset),
              decoration: ShapeDecoration(
                color: colors.card,
                shape: StadiumBorder(side: BorderSide(color: colors.border)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  // The designs' coral, in both themes.
                  PhosphorIcon(
                    PhosphorIconsFill.heart,
                    size: theme.messagesCaption.fontSize,
                    color: const Color(0xFFC8432F),
                  ),
                  Text(
                    '$count',
                    style: theme.messagesCaption.copyWith(
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: colors.foregroundSubtle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A shared document: a file-type tile, the name, the size, and an arrow.
class _Attachment extends StatelessWidget {
  const _Attachment(this.file);

  final SharedFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = theme.radii.xl;
    return Glass(
      // On a bubble's flat fill, and one per attachment down the thread.
      frosted: false,
      level: GlassLevel.strong,
      borderRadius: radius,
      child: ListTile(
        onTap: () => showDemoToast(
          context,
          'Opening ${file.name}',
          description: file.attachmentCaption,
        ),
        padding: EdgeInsets.all(theme.gap(GapSize.md)),
        borderRadius: radius,
        leading: IconTile(
          size: theme.avatarMd,
          borderRadius: theme.radius,
          icon: PhosphorIcon(file.icon),
        ),
        title: Text(file.name),
        titleStyle: theme.messagesName,
        subtitle: Text(file.attachmentCaption),
        trailing: PhosphorIcon(
          PhosphorIconsRegular.arrowUpRight,
          size: theme.glyph,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}

/// A picture message.
class _Picture extends StatelessWidget {
  const _Picture(this.image, {required this.size});

  final MessageImage image;

  /// The size of the photograph; the hairline goes around it.
  final Size size;

  static const borderWidth = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(theme.chatBubbleTheme.radius ?? 18);
    final outer = Size(
      size.width + 2 * borderWidth,
      size.height + 2 * borderWidth,
    );
    return AspectRatio(
      aspectRatio: outer.aspectRatio,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: theme.colorScheme.muted,
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: theme.colorScheme.border,
            width: borderWidth,
          ),
        ),
        child: Image.asset(
          image.asset,
          fit: BoxFit.cover,
          semanticLabel: image.label,
        ),
      ),
    );
  }
}

/// "Seen 10:14", under the outgoing message it belongs to.
class _Receipt extends StatelessWidget {
  const _Receipt(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: FinesseRow(
        gap: GapSize.xs,
        mainAxisSize: MainAxisSize.min,
        children: [
          PhosphorIcon(
            PhosphorIconsRegular.check,
            size: theme.iconBeside(theme.messagesCaption),
            color: theme.colorScheme.tint,
          ),
          Text(
            label,
            style: theme.messagesCaption.copyWith(
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
