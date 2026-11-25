import 'dart:async';

import 'package:finesse_demo/data/messages_data.dart';
import 'package:finesse_demo/widgets/messages_common.dart';
import 'package:finesse_demo/widgets/messages_composer.dart';
import 'package:finesse_demo/widgets/messages_controller.dart';
import 'package:finesse_demo/widgets/messages_thread.dart';
import 'package:finesse_demo/widgets/demo_actions.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The middle pane of the desktop card: who the conversation is with, the
/// thread, and the composer floating over its end.
class MessagesConversationPane extends StatelessWidget {
  const MessagesConversationPane({
    required this.controller,
    this.onToggleDetails,
    super.key,
  });

  final MessagesController controller;

  /// Called by the header's info button; null hides the button, where the
  /// details pane cannot be shown.
  final VoidCallback? onToggleDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conversation = controller.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaneHeader(
          conversation: conversation,
          onToggleDetails: onToggleDetails,
        ),
        Expanded(
          child: MessagesConversationView(
            // A new thread starts at its newest message, with an empty
            // composer.
            key: ValueKey(conversation.id),
            controller: controller,
            conversation: conversation,
            metrics: ThreadMetrics.pane(theme),
            composerInset: EdgeInsets.all(theme.gap(GapSize.lg)),
            composerRadius: theme.radii.xl,
          ),
        ),
      ],
    );
  }
}

/// The pane's header: avatar, name, presence and headline, and the call,
/// video and details buttons.
class _PaneHeader extends StatelessWidget {
  const _PaneHeader({required this.conversation, this.onToggleDetails});

  final Conversation conversation;
  final VoidCallback? onToggleDetails;

  // Taller than the theme's app bar, for the two lines beside the avatar.
  static const _height = 72.0;

  // The "active now" dot beside the headline.
  static const _presenceDot = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget action(IconData icon, String label, VoidCallback onPressed) =>
        IconButton.ghost(
          size: ButtonSize.lg,
          icon: PhosphorIcon(icon),
          semanticLabel: label,
          onPressed: onPressed,
        );

    return Container(
      // 72 and the hairline under it, which a `Container` counts in.
      height: _height + 1,
      padding: EdgeInsets.symmetric(horizontal: messagesPaneInset(theme)),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          ConversationAvatar(conversation),
          const Gap.md(),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.large.copyWith(
                    color: colors.foreground,
                  ),
                ),
                Row(
                  children: [
                    if (conversation.online) ...[
                      Container(
                        width: _presenceDot,
                        height: _presenceDot,
                        decoration: ShapeDecoration(
                          shape: const CircleBorder(),
                          color: theme.messagesCoral,
                        ),
                      ),
                      const Gap.raw(messagesTightGap),
                    ],
                    Flexible(
                      child: Text(
                        conversation.online
                            ? 'Active now · ${conversation.headline}'
                            : conversation.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Gap.sm(),
          FinesseRow(
            gap: GapSize.xs,
            mainAxisSize: MainAxisSize.min,
            children: [
              action(
                PhosphorIconsRegular.phone,
                'Call',
                () => startCall(context, conversation.name),
              ),
              action(
                PhosphorIconsRegular.videoCamera,
                'Video call',
                () => startCall(context, conversation.name, video: true),
              ),
              if (onToggleDetails case final toggle?)
                action(
                  PhosphorIconsRegular.info,
                  'Conversation details',
                  toggle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A thread with the composer pinned over its end.
///
/// The messages scroll under the composer — and under whatever [MediaQuery]
/// says covers the top of the view, which on the full-screen page is its
/// glass app bar. The software keyboard pushes both the composer and the
/// end of the thread up.
class MessagesConversationView extends StatefulWidget {
  const MessagesConversationView({
    required this.controller,
    required this.conversation,
    required this.metrics,
    required this.composerInset,
    required this.composerRadius,
    super.key,
  });

  final MessagesController controller;
  final Conversation conversation;
  final ThreadMetrics metrics;

  /// How far the composer floats from the view's sides and bottom.
  final EdgeInsets composerInset;

  final BorderRadius composerRadius;

  @override
  State<MessagesConversationView> createState() =>
      _MessagesConversationViewState();
}

class _MessagesConversationViewState extends State<MessagesConversationView> {
  final _thread = ChatListController();

  // The air between the last message and the composer over it.
  static const _composerClearance = 18.0;

  @override
  void dispose() {
    _thread.dispose();
    super.dispose();
  }

  bool _send(String text) {
    if (!widget.controller.send(widget.conversation, text)) return false;
    // Whatever the reader was looking at, what they just said is at the
    // end.
    unawaited(_thread.scrollToEnd());
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final composerInset = widget.composerInset;
    final conversation = widget.conversation;

    // A scaffold inside whatever the view is in — the pane's card, the
    // page's own scaffold — for its footer: the composer rides above the
    // keyboard and the home indicator, and the thread is told how far it
    // reaches in, with nothing measured or added up here.
    return Scaffold(
      backgroundColor: const Color(0x00000000),
      footer: Builder(
        builder: (context) {
          // The safe area under a footer is the footer's to keep clear of.
          final safe = MediaQuery.paddingOf(context);
          return Padding(
            padding: EdgeInsets.fromLTRB(
              composerInset.left + safe.left,
              0,
              composerInset.right + safe.right,
              composerInset.bottom + safe.bottom,
            ),
            child: MessagesComposer(
              onSend: _send,
              // While the assistant is answering, the send button stops it.
              onStop: widget.controller.isStreaming(conversation)
                  ? () => widget.controller.stopStreaming(conversation)
                  : null,
              placeholder: conversation.assistant
                  ? 'Ask the assistant…'
                  : 'Write a message…',
              borderRadius: widget.composerRadius,
            ),
          );
        },
      ),
      body: Builder(
        builder: (context) {
          // The top is whatever covers the view — on the full-screen page,
          // its glass app bar; the bottom is the composer. The designs keep
          // 96 under the last message: the composer, its 16 from the
          // bottom, and a little air between the two.
          final covered = MediaQuery.paddingOf(context);
          return MessagesThread(
            conversation: conversation,
            messages: widget.controller.messagesOf(conversation),
            metrics: widget.metrics,
            controller: _thread,
            insets: EdgeInsets.only(
              top: covered.top,
              bottom: covered.bottom + _composerClearance,
            ),
          );
        },
      ),
    );
  }
}

/// A conversation as a page of its own: what a phone — or a window too
/// narrow for two panes — pushes when a row of the list is tapped.
///
/// It has its own glass app bar (back, avatar, name, presence, call and
/// video) and no bottom navigation; the composer sits in a glass bar at the
/// bottom.
class MessagesConversationPage extends StatelessWidget {
  const MessagesConversationPage({
    required this.controller,
    required this.conversationId,
    super.key,
  });

  final MessagesController controller;
  final String conversationId;

  // The designs' header is 68 tall — taller than the theme's phone app bar,
  // to fit the two lines beside a 40-point avatar. The hairline under it is
  // the `AppBar`'s own business.
  static const _barHeight = 68.0;

  // How far the composer floats from the sides of the page: between two
  // steps of the gap scale, as the designs have it.
  static const _composerSide = 10.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final conversation = controller.byId(conversationId);

    return Scaffold(
      appBar: AppBar(
        height: _barHeight,
        // 8 at the sides, so the 44-point buttons' glyphs — not their boxes
        // — line up with the page margin, and 4 between everything.
        padding: EdgeInsets.symmetric(horizontal: theme.gap(GapSize.sm)),
        gap: theme.gap(GapSize.sm),
        actionsGap: theme.gap(GapSize.xs),
        leading: FinesseRow(
          gap: GapSize.xs,
          mainAxisSize: MainAxisSize.min,
          children: [
            const BackButton(),
            ConversationAvatar(
              conversation,
              // The bar is the surface here, not a card.
              surfaceColor: colors.bar,
            ),
          ],
        ),
        title: Padding(
          // 10 between the avatar and the name: the bar's 4 and these 6.
          padding: const EdgeInsetsDirectional.only(start: messagesTightGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(conversation.name),
              Text(
                conversation.online ? 'Active now' : conversation.headline,
                style: theme.messagesCaption.copyWith(
                  color: conversation.online ? colors.tint : null,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton.ghost(
            icon: const PhosphorIcon(PhosphorIconsRegular.phone),
            semanticLabel: 'Call',
            onPressed: () => startCall(context, conversation.name),
          ),
          IconButton.ghost(
            icon: const PhosphorIcon(PhosphorIconsRegular.videoCamera),
            semanticLabel: 'Video call',
            onPressed: () => startCall(context, conversation.name, video: true),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => MessagesConversationView(
          controller: controller,
          conversation: conversation,
          metrics: ThreadMetrics.page(theme),
          // A little in from the sides and the page margin from the bottom,
          // in a bar as round as the phone's cards.
          composerInset: EdgeInsets.fromLTRB(
            _composerSide,
            0,
            _composerSide,
            theme.gap(GapSize.xl),
          ),
          composerRadius: theme.radii.xl4,
        ),
      ),
    );
  }
}
