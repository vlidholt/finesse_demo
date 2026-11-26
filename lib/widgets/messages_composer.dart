import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';

/// The bar a message is written in: add and photo buttons, the field, and
/// the round send button, on a glass surface that floats over the thread.
///
/// Enter and the send button both call [onSend] with the field's text; the
/// field is cleared, and keeps the focus, when [onSend] returns true.
///
/// While a reply is being streamed the send button is a stop button: give
/// [onStop] and it calls that instead. Enter still sends.
class MessagesComposer extends StatefulWidget {
  const MessagesComposer({
    required this.onSend,
    required this.borderRadius,
    this.onStop,
    this.placeholder = 'Write a message…',
    super.key,
  });

  /// Called with what was typed. Returns whether it was sent.
  final bool Function(String text) onSend;

  /// Stops the reply that is arriving. Null while none is.
  final VoidCallback? onStop;

  /// What the empty field says.
  final String placeholder;

  /// The corners of the glass bar.
  final BorderRadius borderRadius;

  /// The bar's height: the send button, the padding around it and the
  /// hairline. The thread reserves this much, and a margin, under its last
  /// message.
  static double heightOf(BuildContext context) =>
      _sendSize + 2 * Theme.of(context).gap(GapSize.sm) + 2;

  // The designs keep the composer's controls the same size on a desktop and
  // on a phone — 40-point buttons and field, a 44-point send button — so
  // these do not follow the theme's control heights.
  static const _controlSize = 40.0;
  static const _sendSize = 44.0;

  @override
  State<MessagesComposer> createState() => _MessagesComposerState();
}

class _MessagesComposerState extends State<MessagesComposer> {
  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    if (widget.onSend(_text.text)) _text.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onStop = widget.onStop;
    // What is typed is set like the message it will become.
    final messageStyle = theme.chatBubbleTheme.textStyle ?? theme.textTheme.p;

    Widget tool(IconData icon, String label) => IconButton.ghost(
      style: ButtonTheme(
        width: MessagesComposer._controlSize,
        height: MessagesComposer._controlSize,
        iconSize: theme.glyphLg,
      ),
      icon: PhosphorIcon(icon),
      semanticLabel: label,
      onPressed: () => showNothingToAttach(context),
    );

    return Glass(
      borderRadius: widget.borderRadius,
      padding: EdgeInsets.all(theme.gap(GapSize.sm)),
      shadows: theme.cardTheme.shadows ?? const [],
      child: Row(
        spacing: theme.gap(GapSize.xs),
        children: [
          tool(PhosphorIconsRegular.plusCircle, 'Add'),
          tool(PhosphorIconsRegular.image, 'Add photo'),
          Expanded(
            child: Semantics(
              label: 'Message',
              child: TextField(
                controller: _text,
                focusNode: _focus,
                style: messageStyle.copyWith(color: colors.foreground),
                placeholderStyle: messageStyle.copyWith(
                  color: colors.mutedForeground,
                ),
                placeholder: Text(
                  widget.placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                // Not `onSubmitted`: the default editing-complete handler
                // drops the focus first, and a chat keeps the keyboard up.
                onEditingComplete: _send,
                constraints: const BoxConstraints(
                  minHeight: MessagesComposer._controlSize,
                ),
                // A borderless pill in the field's own fill. The design
                // shows no focus outline here; the caret is the indication.
                decoration: UnaDecoration(
                  border: UnaBorder.all(
                    width: 0,
                    color: const Color(0x00000000),
                    borderRadius: theme.radii.full,
                  ),
                  disableSecondaryBorder: true,
                ),
                trailing: PhosphorIcon(
                  PhosphorIconsRegular.smiley,
                  size: theme.glyphLg,
                  color: colors.mutedForeground,
                ),
              ),
            ),
          ),
          IconButton(
            style: ButtonTheme(
              width: MessagesComposer._sendSize,
              height: MessagesComposer._sendSize,
              iconSize: theme.glyphLg,
              // The design's `--accent`: the tint, not the primary button's
              // fill, which stays dark teal in the dark theme.
              backgroundColor: colors.tint,
              hoverBackgroundColor: colors.tint.withValues(alpha: .9),
              foregroundColor: colors.tintForeground,
              hoverForegroundColor: colors.tintForeground,
            ),
            // The plane gives way to a square while a reply can be stopped.
            icon: ContentSwitch(
              value: onStop != null,
              direction: 0,
              child: PhosphorIcon(
                onStop != null
                    ? PhosphorIconsFill.stop
                    : PhosphorIconsRegular.paperPlaneTilt,
              ),
            ),
            semanticLabel: onStop != null ? 'Stop' : 'Send',
            onPressed: onStop ?? _send,
          ),
        ],
      ),
    );
  }
}
