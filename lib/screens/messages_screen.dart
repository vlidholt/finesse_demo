import 'dart:math' as math;

import 'package:finesse_demo/data/messages_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/session.dart';
import 'package:finesse_demo/widgets/messages_controller.dart';
import 'package:finesse_demo/widgets/messages_conversation.dart';
import 'package:finesse_demo/widgets/messages_conversation_list.dart';
import 'package:finesse_demo/widgets/messages_details_pane.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The Messages destination of the Demo shell.
///
/// On a desktop it is one tall card split by hairlines into three panes: the
/// conversation list, the open conversation, and the details of whoever it
/// is with — a `ListDetailLayout` whose detail is the conversation and the
/// details side by side. The card sheds panes as the window narrows — the
/// details first, then the conversation, which the list then pushes as a
/// full-screen page.
///
/// On a phone the destination is the list alone, on the page itself, and a
/// row opens the conversation as a page with its own header and composer.
///
/// The conversations are the session's (`context.demo.messages`): the
/// shell's Messages badge counts the unread ones, and a reply keeps coming
/// while another screen is showing. What this screen adds is knowing when a
/// thread is actually on screen, which is what makes a reply read on
/// arrival (`MessagesController.threadVisible`).
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  /// The widths of the outer panes; the conversation takes what is left.
  static const listWidth = 360.0;
  static const detailsWidth = 340.0;

  /// The card's width under which the details pane is dropped, and the one
  /// under which the conversation is.
  static const detailsBreakpoint = 1100.0;
  static const conversationBreakpoint = 760.0;

  /// The least the card is tall, in a window too short for it; the page
  /// scrolls instead.
  static const minHeight = 520.0;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final MessagesController _controller = context.demo.messages;

  // Whether the conversation pane is beside the list, whether this screen
  // is the destination showing, and how many conversation pages are open
  // over it.
  bool _paneShown = false;
  bool _onStage = false;
  int _pages = 0;

  /// Tells the controller whether the open conversation can be seen.
  void _reportThread() {
    _controller.threadVisible = _pages > 0 || (_paneShown && _onStage);
  }

  @override
  void dispose() {
    // The session outlives the screen; nothing of it is showing any more.
    _controller.threadVisible = false;
    super.dispose();
  }

  void _openAsPage(Conversation conversation) {
    _controller.select(conversation);
    _pages++;
    _reportThread();
    context
        .pushFullScreen<void>(
          (context) => MessagesConversationPage(
            controller: _controller,
            conversationId: conversation.id,
          ),
        )
        .whenComplete(() {
          _pages--;
          if (mounted) _reportThread();
        });
  }

  @override
  Widget build(BuildContext context) {
    // The shell keeps a visited screen alive, and stops its tickers while
    // another destination shows: that is how this one knows it is not the
    // one being looked at.
    _onStage = TickerMode.valuesOf(context).enabled;
    _reportThread();
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => FormFactorBuilder(
        mobile: _buildList,
        desktop: _buildCard,
      ),
    );
  }

  /// A phone: the list is the page.
  Widget _buildList(BuildContext context) {
    _paneShown = false;
    _reportThread();
    final theme = Theme.of(context);
    final layout = theme.layoutTheme;
    final margins = (layout.pagePadding ?? const EdgeInsets.all(16)).resolve(
      Directionality.of(context),
    );
    return PageContainer(
      scrollable: true,
      // The list brings its own insets: the header's are the page margins,
      // the rows' are tighter, as in the card.
      padding: EdgeInsets.zero,
      child: MessagesConversationList(
        controller: _controller,
        onOpen: _openAsPage,
        scrollable: false,
        showSelection: false,
        surfaceColor: theme.colorScheme.background,
        headerPadding: margins.copyWith(bottom: theme.gap(GapSize.md)),
      ),
    );
  }

  /// A desktop: the card, as tall as the window allows.
  Widget _buildCard(BuildContext context) {
    final theme = Theme.of(context);
    final layout = theme.layoutTheme;
    final margins = (layout.pagePadding ?? const EdgeInsets.all(24)).resolve(
      Directionality.of(context),
    );
    final bars = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, viewport) {
        final available = viewport.hasBoundedHeight
            ? viewport.maxHeight - bars.vertical - margins.vertical
            : MessagesScreen.minHeight;
        return PageContainer(
          // Only scrolls in a window shorter than the card's least height.
          scrollable: true,
          child: SizedBox(
            height: math.max(available, MessagesScreen.minHeight),
            child: LayoutBuilder(
              builder: (context, card) => _buildPanes(context, card.maxWidth),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPanes(BuildContext context, double width) {
    final theme = Theme.of(context);
    final showConversation = width >= MessagesScreen.conversationBreakpoint;
    final canShowDetails = width >= MessagesScreen.detailsBreakpoint;
    _paneShown = showConversation;
    _reportThread();

    final list = MessagesConversationList(
      controller: _controller,
      onOpen: showConversation ? _controller.select : _openAsPage,
      showSelection: showConversation,
      headerPadding: EdgeInsets.fromLTRB(
        theme.gap(GapSize.lg),
        theme.gap(GapSize.lg),
        theme.gap(GapSize.lg),
        theme.gap(GapSize.md),
      ),
    );

    return Card(
      style: CardTheme(
        padding: EdgeInsets.zero,
        borderRadius: theme.radii.xl2,
      ),
      child: SizedBox.expand(
        child: !showConversation
            ? list
            // The list and what is chosen in it, side by side with a
            // hairline between. On a phone the package's layout would push
            // the detail inside itself, under the shell's bars; a
            // conversation there needs the whole screen, so the phone's
            // list pushes its own page instead (see [_openAsPage]).
            : ListDetailLayout(
                listWidth: MessagesScreen.listWidth,
                list: list,
                detail: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: MessagesConversationPane(
                        controller: _controller,
                        onToggleDetails: canShowDetails
                            ? _controller.toggleDetails
                            : null,
                      ),
                    ),
                    if (canShowDetails && _controller.detailsVisible) ...[
                      const Divider.vertical(),
                      SizedBox(
                        width: MessagesScreen.detailsWidth,
                        child: MessagesDetailsPane(controller: _controller),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
