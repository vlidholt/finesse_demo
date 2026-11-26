import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_feed_scope.dart';

/// Opens the post composer: what the "Create post" action of the bottom bar
/// and of the rail, and the home feed's "Start a post" box, lead to.
///
/// "Post" publishes what was written as a post of the user's own at the top
/// of the home feed (`HomeFeedModel.publish`) and says so in a toast that
/// can take it back. What is typed is the session's, so a composer closed
/// by accident opens again on the same words.
///
/// The designs stop at the entry points, so the composer is a plain dialog.
Future<void> showComposeDialog(BuildContext context) {
  final feed = context.demo.feed;
  return showDialog<void>(
    context: context,
    builder: (_) => _ComposeDialog(feed: feed, opener: context),
  );
}

class _ComposeDialog extends StatefulWidget {
  const _ComposeDialog({required this.feed, required this.opener});

  final HomeFeedModel feed;

  /// The context the composer was opened from: a screen, or the shell.
  final BuildContext opener;

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  /// How long the pretend server takes to accept a post.
  static const _delay = Duration(milliseconds: 700);

  Timer? _publishing;

  @override
  void dispose() {
    _publishing?.cancel();
    super.dispose();
  }

  void _post() {
    final draft = widget.feed.composeDraft;
    final text = draft.text.trim();
    if (text.isEmpty || _publishing != null) return;
    setState(() {
      _publishing = Timer(_delay, () {
        final feed = widget.feed;
        final post = feed.publish(text);
        draft.clear();
        showDemoToast(
          context,
          'Post published',
          description: 'It is at the top of your feed.',
          variant: ToastVariant.success,
          actionLabel: 'Undo',
          onAction: () {
            feed.unpublish(post);
            // Back in the composer, for another go.
            draft.text = text;
          },
        );
        Navigator.of(context).pop();
        // The post is in the home feed, whichever screen it was written
        // from.
        final opener = widget.opener;
        if (opener.mounted) opener.goTo(DemoDestination.home);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.feed.composeDraft;
    final posting = _publishing != null;
    return Dialog(
      title: const Text('Create post'),
      description: const Text('Share an update with your network.'),
      actions: [
        Button.outline(
          enabled: !posting,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        // Nothing to post until something is written.
        ListenableBuilder(
          listenable: draft,
          builder: (context, _) => Button(
            enabled: draft.text.trim().isNotEmpty,
            loading: posting,
            onPressed: _post,
            child: const Text('Post'),
          ),
        ),
      ],
      child: Textarea(
        controller: draft,
        autofocus: true,
        readOnly: posting,
        placeholder: Text('Start a post, ${People.me.firstName}…'),
      ),
    );
  }
}
