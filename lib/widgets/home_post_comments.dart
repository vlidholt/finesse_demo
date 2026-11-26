import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_feed_scope.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// The thread under a desktop post: comments with their replies, the
/// "View more replies" link and the field for a new comment.
///
/// What the user does here — the comment being written, the likes, the
/// replies opened — is kept in the `HomeFeedModel`, not in this widget: the
/// card is built anew when the layout changes form factor, and none of it
/// may be lost to a window resize.
class HomePostComments extends StatefulWidget {
  const HomePostComments(this.post, {this.fieldFocusNode, super.key});

  final FeedPost post;

  /// The comment field's focus node, so the post's "Comment" action can
  /// move focus to it.
  final FocusNode? fieldFocusNode;

  @override
  State<HomePostComments> createState() => _HomePostCommentsState();
}

class _HomePostCommentsState extends State<HomePostComments> {
  /// The field's focus node when the post did not hand one in.
  final _ownFocus = FocusNode();

  FocusNode get _fieldFocus => widget.fieldFocusNode ?? _ownFocus;

  /// What is typed in the comment field.
  TextEditingController get _draft =>
      HomeFeedScope.of(context).draftFor(widget.post);

  @override
  void dispose() {
    _ownFocus.dispose();
    super.dispose();
  }

  /// Puts [text] at the end of the draft and the cursor after it.
  void _append(String text) {
    final draft = _draft;
    final next = '${draft.text}$text';
    draft.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _fieldFocus.requestFocus();
  }

  void _post() {
    final draft = _draft;
    final text = draft.text.trim();
    if (text.isEmpty) return;
    draft.clear();
    showDemoToast(context, 'Comment posted', description: text);
  }

  Widget _comment(FeedComment comment) {
    final model = HomeFeedScope.of(context);
    return _Comment(
      comment,
      liked: model.isCommentLiked(comment),
      onLike: () => model.toggleCommentLike(comment),
      // Start the comment with who it answers.
      onReply: () => _append('@${comment.author.name} '),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = HomeFeedScope.of(context);
    // The portrait beside a comment and beside the comment field.
    final avatarSize = theme.avatarSm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: theme.gap(GapSize.md),
      children: [
        for (final comment in widget.post.thread) ...[
          _comment(comment),
          for (final reply in [
            ...comment.replies,
            if (model.areRepliesShown(comment)) ...comment.hiddenReplies,
          ])
            _Reply(
              // The rule is centred under the comment's portrait.
              ruleCentre: avatarSize / 2,
              child: _comment(reply),
            ),
          if (comment.hiddenReplies.isNotEmpty)
            Padding(
              // Under the comment's text column: its portrait and gap.
              padding: EdgeInsetsDirectional.only(
                start: avatarSize + theme.gap(GapSize.sm),
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: HomeTextLink(
                  model.areRepliesShown(comment)
                      ? 'Hide replies'
                      : 'View ${comment.hiddenReplies.length} more replies',
                  onPressed: () => model.toggleReplies(comment),
                  style: theme.textTheme.small.copyWith(
                    color: scheme.mutedForeground,
                  ),
                ),
              ),
            ),
        ],
        Row(
          children: [
            PersonAvatar(People.me, size: avatarSize),
            const Gap.sm(),
            Expanded(
              child: Semantics(
                label: 'Add a comment',
                child: TextField(
                  controller: _draft,
                  focusNode: _fieldFocus,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _post(),
                  placeholder: const Text('Add a comment…'),
                  // The reshaping a pill button takes suits a field too.
                  decoration: theme.buttonDecoration(radius: theme.radii.full),
                  // The round trailing buttons sit closer to the pill's end
                  // than a field's usual inset.
                  padding: EdgeInsetsDirectional.only(
                    start: theme.gap(GapSize.lg),
                    end: theme.gap(GapSize.xs),
                  ),
                  gap: theme.gap(GapSize.xs),
                  trailing: UnaRow(
                    gap: GapSize.xs,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.ghost(
                        size: ButtonSize.sm,
                        icon: const PhosphorIcon(PhosphorIconsRegular.smiley),
                        semanticLabel: 'Add emoji',
                        onPressed: () => _append('👏'),
                      ),
                      IconButton.ghost(
                        size: ButtonSize.sm,
                        icon: const PhosphorIcon(PhosphorIconsRegular.image),
                        semanticLabel: 'Add photo',
                        onPressed: () => showNothingToAttach(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A reply: indented under its comment, with a rule down its start edge.
class _Reply extends StatelessWidget {
  const _Reply({required this.ruleCentre, required this.child});

  /// How far in from the start edge the rule's centre line runs.
  final double ruleCentre;
  final Widget child;

  /// The thread's rule: a drawn line, not a gap of any scale.
  static const _ruleWidth = 2.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        PositionedDirectional(
          start: ruleCentre - _ruleWidth / 2,
          top: 0,
          bottom: 0,
          width: _ruleWidth,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.borderStrong,
              borderRadius: const BorderRadius.all(
                Radius.circular(_ruleWidth),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: ruleCentre + _ruleWidth / 2 + theme.gap(GapSize.sm),
          ),
          child: child,
        ),
      ],
    );
  }
}

/// One comment: portrait, a bubble with the author and the text, and the
/// age / like / reply line under it.
class _Comment extends StatelessWidget {
  const _Comment(
    this.comment, {
    required this.liked,
    required this.onLike,
    required this.onReply,
  });

  final FeedComment comment;
  final bool liked;
  final VoidCallback onLike;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final author = comment.author;
    final meta = theme.style.caption
        .apply(theme.textTheme.small)
        .copyWith(color: scheme.mutedForeground);
    final likes = comment.likes + (liked ? 1 : 0);
    // The bubble's three round corners; the fourth is the tail.
    final corner = theme.radii.xl.topLeft;
    final tail = Radius.circular(
      theme.chatBubbleTheme.tailRadius ?? theme.radii.sm.topLeft.x,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(author, size: theme.avatarSm),
        const Gap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // The package's ChatBubble is a message: capped at part of
              // the width, with its tail at the bottom. A comment fills the
              // column and points up at its author, so only the bubble's
              // colour is shared.
              Container(
                padding:
                    theme.chatBubbleTheme.padding ??
                    EdgeInsets.symmetric(
                      horizontal: theme.gap(GapSize.md),
                      vertical: theme.gap(GapSize.sm),
                    ),
                decoration: BoxDecoration(
                  color: theme.chatBubbleTheme.incomingColor ?? scheme.accent,
                  borderRadius: BorderRadiusDirectional.only(
                    topStart: tail,
                    topEnd: corner,
                    bottomStart: corner,
                    bottomEnd: corner,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: author.name,
                        children: [
                          TextSpan(
                            text: ' · ${author.headline}',
                            // A copy of the theme's style, so the lighter
                            // weight gets the font's regular face.
                            style: theme.textTheme.small.copyWith(
                              fontWeight: FontWeight.w400,
                              color: scheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.foreground,
                      ),
                    ),
                    Text(
                      comment.text,
                      style: theme.textTheme.p.copyWith(
                        color: scheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: theme.gap(GapSize.xs),
                  top: theme.gap(GapSize.xs),
                  right: theme.gap(GapSize.xs),
                ),
                child: Row(
                  spacing: theme.gap(GapSize.md),
                  children: [
                    Text(comment.age, style: meta),
                    HomeTextLink(
                      '${liked ? 'Liked' : 'Like'} · $likes',
                      onPressed: onLike,
                      style: liked ? meta.copyWith(color: scheme.tint) : meta,
                    ),
                    HomeTextLink('Reply', onPressed: onReply, style: meta),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
