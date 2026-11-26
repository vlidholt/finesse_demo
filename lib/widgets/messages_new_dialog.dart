import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/messages_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/messages_common.dart';
import 'package:una_demo/widgets/messages_controller.dart';

/// Opens "New message": a field for whom it is to, which completes from
/// the people and groups the user can write to, and a field for what to
/// say.
///
/// "Send" sends the message in that person's conversation — a deleted one
/// comes back — and calls [onOpen] with it, exactly as tapping their row in
/// the list would. With nothing written, the button only opens the
/// conversation.
Future<void> showNewMessageDialog(
  BuildContext context,
  MessagesController controller,
  ValueChanged<Conversation> onOpen,
) async {
  final result = await showDialog<_NewMessage>(
    context: context,
    builder: (context) => _NewMessageDialog(controller.conversations),
  );
  if (result == null) return;
  onOpen(result.to);
  controller.send(result.to, result.text);
}

/// What the dialog was closed with.
typedef _NewMessage = ({Conversation to, String text});

class _NewMessageDialog extends StatefulWidget {
  const _NewMessageDialog(this.conversations);

  final List<Conversation> conversations;

  @override
  State<_NewMessageDialog> createState() => _NewMessageDialogState();
}

class _NewMessageDialogState extends State<_NewMessageDialog> {
  final _to = TextEditingController();
  final _text = TextEditingController();
  final _textFocus = FocusNode(debugLabel: 'New message text');

  /// The conversation the "To" field names, once it names one.
  Conversation? _recipient;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _to.dispose();
    _text.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  /// Everyone the user can write to whose name has [query] in it. Requests
  /// are not conversations yet.
  Iterable<Conversation> _matching(String query) {
    final needle = query.trim().toLowerCase();
    return [
      for (final conversation in widget.conversations)
        if (!conversation.request &&
            conversation.name.toLowerCase().contains(needle))
          conversation,
    ];
  }

  /// The field's text is free: it names a recipient only while it is one
  /// conversation's whole name.
  void _onToChanged(String text) {
    final typed = text.trim().toLowerCase();
    Conversation? named;
    for (final conversation in widget.conversations) {
      if (!conversation.request && conversation.name.toLowerCase() == typed) {
        named = conversation;
      }
    }
    if (named != _recipient) setState(() => _recipient = named);
  }

  void _choose(Conversation conversation) {
    setState(() => _recipient = conversation);
    // On to what to say.
    _textFocus.requestFocus();
  }

  void _send() {
    final to = _recipient;
    if (to == null) return;
    Navigator.of(context).pop<_NewMessage>((to: to, text: _text.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final to = _recipient;
    final hasText = _text.text.trim().isNotEmpty;

    return Dialog(
      title: const Text('New message'),
      style: DialogTheme(constraints: const BoxConstraints(maxWidth: 440)),
      actions: [
        Button.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Button(
          enabled: to != null,
          leading: hasText
              ? const PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt)
              : null,
          onPressed: _send,
          child: Text(hasText ? 'Send' : 'Open conversation'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'To',
            child: Autocomplete<Conversation>(
              controller: _to,
              autofocus: true,
              // The people one can write to are few: show them at once,
              // and let Enter take the first that matches.
              openOnFocus: true,
              autoHighlight: true,
              clearable: true,
              placeholder: const Text('To: type a name'),
              leading: to == null
                  ? PhosphorIcon(
                      PhosphorIconsRegular.magnifyingGlass,
                      size: theme.glyph,
                      color: theme.colorScheme.mutedForeground,
                    )
                  : ConversationAvatar(
                      to,
                      size: theme.avatarXs,
                      showOnline: false,
                    ),
              optionsBuilder: (value) => _matching(value.text),
              displayStringForOption: (conversation) => conversation.name,
              optionBuilder: (context, conversation) => Row(
                children: [
                  ConversationAvatar(
                    conversation,
                    size: theme.avatarSm,
                    showOnline: false,
                  ),
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
                          style: theme.messagesName,
                        ),
                        Text(
                          conversation.headline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              emptyBuilder: (context) => Padding(
                padding: EdgeInsets.all(theme.gap(GapSize.md)),
                child: Text(
                  'No one in your conversations is called “${_to.text}”.',
                  style: theme.textTheme.muted,
                ),
              ),
              onChanged: _onToChanged,
              onSelected: _choose,
              textInputAction: TextInputAction.next,
            ),
          ),
          const Gap.md(),
          Semantics(
            label: 'Message',
            child: Textarea(
              controller: _text,
              focusNode: _textFocus,
              placeholder: Text(
                to == null
                    ? 'Write a message…'
                    : 'Write to ${to.name.split(' ').first}…',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
