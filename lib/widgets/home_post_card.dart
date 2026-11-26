import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/demo_previews.dart';
import 'package:una_demo/widgets/home_feed_scope.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/home_post_comments.dart';
import 'package:una_demo/widgets/home_post_media.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/verified_badge.dart';

/// A post in the home feed.
///
/// The desktop card is the full post: header with "Follow", text, media, the
/// reaction summary, four labelled actions and the comment thread. The
/// phone's card is the compact one from the mobile design: shorter text, one
/// photograph, and an icon-only action row that carries the counts.
class HomePostCard extends StatefulWidget {
  const HomePostCard(this.post, {super.key});

  final FeedPost post;

  @override
  State<HomePostCard> createState() => _HomePostCardState();
}

class _HomePostCardState extends State<HomePostCard> {
  final _commentFocus = FocusNode(debugLabel: 'Add a comment');

  @override
  void dispose() {
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final compact = theme.formFactor == FormFactor.mobile;
    final body = Text(
      compact ? post.compactBody : post.body,
      style: theme.textTheme.p.copyWith(
        color: theme.colorScheme.foreground,
      ),
    );

    if (compact) {
      final padding = (theme.cardTheme.padding ?? const EdgeInsets.all(16))
          .resolve(
            Directionality.of(context),
          );
      return Card(
        style: CardTheme(
          padding: padding.copyWith(
            bottom: padding.bottom - theme.gap(GapSize.xs),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _PostHeader(post, compact: true),
            const Gap.md(),
            body,
            if (HomePostMedia.has(post)) ...[
              const Gap.md(),
              HomePostMedia(post, compact: true),
            ],
            const Gap.md(),
            _ReactionSummary(post, compact: true),
            const Gap.xs(),
            _CompactActions(post),
          ],
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _PostHeader(post, compact: false),
          const Gap.md(),
          body,
          if (HomePostMedia.has(post)) ...[
            const Gap.md(),
            HomePostMedia(post, compact: false),
          ],
          Padding(
            padding: EdgeInsets.only(
              top: theme.gap(GapSize.md),
              bottom: theme.gap(GapSize.sm),
            ),
            child: _ReactionSummary(post, compact: false),
          ),
          const Divider(margin: EdgeInsets.zero),
          const Gap.xs(),
          _Actions(
            post,
            onComment: post.thread.isEmpty
                ? () => showCommentDialog(context, post.author)
                : _commentFocus.requestFocus,
          ),
          if (post.thread.isNotEmpty) ...[
            const Gap.md(),
            HomePostComments(post, fieldFocusNode: _commentFocus),
          ],
        ],
      ),
    );
  }
}

/// Portrait, name, age and headline, then "Follow" and the overflow menu.
class _PostHeader extends StatelessWidget {
  const _PostHeader(this.post, {required this.compact});

  final FeedPost post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = HomeFeedScope.of(context);
    final author = post.author;
    final following = model.isFollowing(author);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(author),
        const Gap.md(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    // With a mouse, resting on the name says who it is.
                    child: PersonHoverCard(
                      author,
                      child: HomeTextLink(
                        author.name,
                        onPressed: () => showPersonPreview(context, author),
                        style: theme.textTheme.large.copyWith(
                          color: scheme.foreground,
                        ),
                      ),
                    ),
                  ),
                  if (author.verified) ...[
                    const Gap.xs(),
                    const VerifiedBadge(),
                  ],
                  const Gap.xs(),
                  Text('· ${post.age}', style: theme.textTheme.muted),
                ],
              ),
              Text(
                author.headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.muted,
              ),
            ],
          ),
        ),
        // The phone's card has no room for "Follow"; it lives in the menu.
        if (!compact && post.followable) ...[
          const Gap.xs(),
          _FollowChip(
            following: following,
            onPressed: () => model.toggleFollow(author),
          ),
        ],
        const Gap.xs(),
        _PostMenu(post),
      ],
    );
  }
}

/// "+ Follow", an outlined pill; "✓ Following" once pressed.
class _FollowChip extends StatelessWidget {
  const _FollowChip({required this.following, required this.onPressed});

  final bool following;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      selected: following,
      onSelected: (_) => onPressed(),
      // Outlined in the strong border on the bare card.
      backgroundColor: const Color(0x00000000),
      borderColor: scheme.borderStrong,
      foregroundColor: scheme.foreground,
      leading: PhosphorIcon(
        following ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
      ),
      label: Text(following ? 'Following' : 'Follow'),
    );
  }
}

/// One thing the "More options" button offers for a post.
typedef _PostAction = ({
  IconData icon,
  String label,
  VoidCallback onPressed,
  bool destructive,
});

/// The "More options" button: a menu under the button on a desktop, and on
/// a phone an action sheet that comes up from the bottom edge, where a
/// thumb reaches it.
class _PostMenu extends StatelessWidget {
  const _PostMenu(this.post);

  final FeedPost post;

  List<_PostAction> _actions(BuildContext context, HomeFeedModel model) {
    final author = post.author;
    final own = author == People.me;
    return [
      (
        icon: PhosphorIconsRegular.bookmarkSimple,
        label: 'Save post',
        destructive: false,
        onPressed: () => showDemoToast(
          context,
          'Post saved',
          description: 'Find it under Saved items in your menu.',
          variant: ToastVariant.success,
        ),
      ),
      (
        icon: PhosphorIconsRegular.link,
        label: 'Copy link',
        destructive: false,
        onPressed: () => copyLink(context, 'demo.app/posts/${post.id}'),
      ),
      if (post.followable)
        (
          icon: model.isFollowing(author)
              ? PhosphorIconsRegular.userMinus
              : PhosphorIconsRegular.userPlus,
          label:
              '${model.isFollowing(author) ? 'Unfollow' : 'Follow'} '
              '${author.firstName}',
          destructive: false,
          onPressed: () => model.toggleFollow(author),
        ),
      if (own)
        (
          icon: PhosphorIconsRegular.trash,
          label: 'Delete post',
          destructive: true,
          onPressed: () {
            model.unpublish(post);
            showDemoToast(
              context,
              'Post deleted',
              variant: ToastVariant.destructive,
              actionLabel: 'Undo',
              onAction: () => model.restore(post),
            );
          },
        )
      else
        (
          icon: PhosphorIconsRegular.eyeSlash,
          label: 'Not interested',
          destructive: false,
          onPressed: () => showDemoToast(
            context,
            'Thanks, noted',
            description: 'You will see fewer posts like this one.',
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final model = HomeFeedScope.of(context);
    final author = post.author;

    Widget button(VoidCallback onPressed) => IconButton.ghost(
      size: ButtonSize.sm,
      icon: const PhosphorIcon(PhosphorIconsRegular.dotsThree),
      semanticLabel: 'More options',
      onPressed: onPressed,
    );

    if (Theme.of(context).formFactor == FormFactor.mobile) {
      return button(
        () => showActionSheet<void>(
          context: context,
          title: Text('Post by ${author.name}'),
          actions: [
            for (final action in _actions(context, model))
              ActionSheetAction(
                icon: PhosphorIcon(action.icon),
                label: Text(action.label),
                destructive: action.destructive,
                onPressed: action.onPressed,
              ),
          ],
        ),
      );
    }

    return DropdownMenu(
      itemsBuilder: (_) => [
        for (final action in _actions(context, model))
          MenuItem(
            leading: PhosphorIcon(action.icon),
            destructive: action.destructive,
            onPressed: action.onPressed,
            child: Text(action.label),
          ),
      ],
      builder: (context, controller, _) => button(controller.toggle),
    );
  }
}

/// The overlapping reaction discs and "Sara Lindqvist and 214 others";
/// on a desktop, the comment and repost counts at the end of the row.
class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary(this.post, {required this.compact});

  final FeedPost post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = HomeFeedScope.of(context);
    final others = formatCount(model.otherReactions(post));
    final name = compact ? post.reactedBy.firstName : post.reactedBy.name;
    final size = theme.avatarXs;
    // A post of the user's own, a moment old: nobody has reacted yet.
    final none = post.reactions.isEmpty;
    final summary = !none
        ? '$name and $others others'
        : model.isLiked(post)
        ? 'You reacted'
        : 'Be the first to react';

    return Row(
      children: [
        if (!none) ...[
          ExcludeSemantics(
            child: AvatarGroup(
              size: size,
              overlap: size / 4,
              children: [
                for (final reaction in post.reactions)
                  SizedBox.square(
                    dimension: size,
                    child: ColoredBox(
                      color: reaction.background,
                      child: PhosphorIcon(
                        reaction.icon,
                        // The disc's own glyph, fitted to it.
                        size: size * .6,
                        color: reaction.foreground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Gap.sm(),
        ],
        Expanded(
          child: Text(
            summary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.muted,
          ),
        ),
        if (!compact) ...[
          const Gap.md(),
          Text(
            [
              '${formatCount(post.comments)} comments',
              if (post.reposts > 0) '${formatCount(post.reposts)} reposts',
            ].join(' · '),
            style: theme.textTheme.muted,
          ),
        ],
      ],
    );
  }
}

/// The desktop card's four labelled actions, sharing the width.
class _Actions extends StatelessWidget {
  const _Actions(this.post, {required this.onComment});

  final FeedPost post;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = HomeFeedScope.of(context);
    final liked = model.isLiked(post);

    Widget action({
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
      Color? color,
    }) {
      return Expanded(
        child: Button.ghost(
          style: ButtonTheme(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: theme.gap(GapSize.xs),
            ),
            foregroundColor: color ?? scheme.foregroundSubtle,
            hoverForegroundColor: color ?? scheme.foreground,
          ),
          leading: PhosphorIcon(icon),
          onPressed: onPressed,
          child: Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      );
    }

    return UnaRow(
      gap: GapSize.xs,
      children: [
        action(
          icon: liked ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
          label: 'Like',
          color: liked ? scheme.tint : null,
          onPressed: () => model.toggleLike(post),
        ),
        action(
          icon: PhosphorIconsRegular.chatCircle,
          label: 'Comment',
          onPressed: onComment,
        ),
        action(
          icon: PhosphorIconsRegular.repeat,
          label: 'Repost',
          onPressed: () => repostWithToast(context, post.author),
        ),
        action(
          icon: PhosphorIconsRegular.paperPlaneTilt,
          label: 'Send',
          onPressed: () => showSendDialog(context, what: 'this post'),
        ),
      ],
    );
  }
}

/// The phone card's action row: like, comment and repost with their
/// counts, then send.
class _CompactActions extends StatelessWidget {
  const _CompactActions(this.post);

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final model = HomeFeedScope.of(context);
    final liked = model.isLiked(post);
    final pill = theme.buttonDecoration(radius: theme.radii.full);

    Widget action({
      required IconData icon,
      required String label,
      required int count,
      required VoidCallback onPressed,
      Color? color,
    }) {
      return Semantics(
        label: label,
        child: Button.ghost(
          style: ButtonTheme(
            // Hugs its count, so four of them fit a phone with room to
            // spare.
            padding: EdgeInsets.symmetric(horizontal: theme.gap(GapSize.sm)),
            gap: theme.gap(GapSize.xs),
            iconSize: theme.buttonSizesTheme.icon?.iconSize,
            decoration: pill,
            textStyle: theme.textTheme.small,
            foregroundColor: color ?? scheme.foregroundSubtle,
            hoverForegroundColor: color ?? scheme.foreground,
          ),
          leading: PhosphorIcon(icon),
          onPressed: onPressed,
          child: Text(formatCount(count)),
        ),
      );
    }

    // The row's glyphs line up with the card's content, so the buttons
    // start their side padding outside it.
    return Transform.translate(
      offset: Offset(
        Directionality.of(context) == TextDirection.rtl
            ? theme.gap(GapSize.sm)
            : -theme.gap(GapSize.sm),
        0,
      ),
      // Scaled down rather than cut off where a theme's type and spacing
      // make the four wider than a narrow phone.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            action(
              icon: liked
                  ? PhosphorIconsFill.heart
                  : PhosphorIconsRegular.heart,
              label: 'Like',
              count: model.reactionCount(post),
              color: liked ? scheme.tint : null,
              onPressed: () => model.toggleLike(post),
            ),
            action(
              icon: PhosphorIconsRegular.chatCircle,
              label: 'Comment',
              count: post.comments,
              onPressed: () => showCommentDialog(context, post.author),
            ),
            if (post.reposts > 0)
              action(
                icon: PhosphorIconsRegular.repeat,
                label: 'Repost',
                count: post.reposts,
                onPressed: () => repostWithToast(context, post.author),
              )
            else
              IconButton.ghost(
                icon: const PhosphorIcon(PhosphorIconsRegular.repeat),
                style: ButtonTheme(
                  foregroundColor: scheme.foregroundSubtle,
                ),
                semanticLabel: 'Repost',
                onPressed: () => repostWithToast(context, post.author),
              ),
            IconButton.ghost(
              icon: const PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt),
              style: ButtonTheme(
                foregroundColor: scheme.foregroundSubtle,
              ),
              semanticLabel: 'Send',
              onPressed: () => showSendDialog(context, what: 'this post'),
            ),
          ],
        ),
      ),
    );
  }
}
