import 'dart:async';

import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/home_data.dart';
import 'package:flutter/widgets.dart';

/// The home feed's state: which list is showing, how it is sorted, which
/// posts have arrived since the app opened, what the signed-in user has
/// liked and whom they follow — and what they have done in a post's
/// comments, down to the comment they are writing.
///
/// It is the session's (`context.demo.feed`), because the composer is
/// opened from the shell's bars as well as from the feed, and what it
/// publishes has to be in the feed whichever screen was showing.
///
/// It is one model because the pieces depend on each other:
/// following an author from a post adds that author's posts to the
/// "Following" list, and a like has to survive its card moving when the list
/// is re-sorted. The comment state is here for a plainer reason: the
/// desktop and the phone feeds are different widgets, and a post card is
/// rebuilt from nothing when the form factor changes — the window is
/// resized past the breakpoint. Anything the user would
/// mind losing to that, a half-written comment above all, cannot live in a
/// card's own `State`. Nothing here is persisted.
class HomeFeedModel extends ChangeNotifier {
  HomeFeedModel()
    : _liked = {
        for (final post in HomeData.posts)
          if (post.liked) post.id,
      },
      _following = {
        for (final post in HomeData.posts)
          if (!post.followable) post.author.name,
      };

  final Set<String> _liked;
  final Set<String> _following;

  /// The comments and replies the user has liked, and the comments whose
  /// hidden replies are showing.
  final Set<String> _likedComments = {};
  final Set<String> _expandedComments = {};

  /// What is typed in each post's comment field, by post id.
  final Map<String, TextEditingController> _drafts = {};

  HomeFeed _feed = HomeFeed.forYou;
  FeedSort _sort = FeedSort.top;

  /// The list the segmented control has selected.
  HomeFeed get feed => _feed;
  set feed(HomeFeed value) {
    if (_feed == value) return;
    _feed = value;
    notifyListeners();
  }

  /// The order the "Sort by" menu has selected.
  FeedSort get sort => _sort;
  set sort(FeedSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  /// The posts of [feed], in [sort] order.
  ///
  /// * For you — every post, in the designed order.
  /// * Following — posts by the people the user follows.
  /// * Trending — every post, the most reacted-to first.
  ///
  /// "Recent" overrides either order with newest first.
  List<FeedPost> get posts {
    final posts = [
      // The newest first: what the user has posted, what a refresh brought.
      for (final post in [..._arrived, ...HomeData.posts])
        if (_feed != HomeFeed.following ||
            post.author == People.me ||
            isFollowing(post.author))
          post,
    ];
    if (_sort == FeedSort.recent) {
      posts.sort((a, b) => a.hoursAgo.compareTo(b.hoursAgo));
    } else if (_feed == HomeFeed.trending) {
      posts.sort((a, b) => reactionCount(b).compareTo(reactionCount(a)));
    }
    return posts;
  }

  /// The posts that have come in since the app opened, newest first: the
  /// user's own, and the ones a refresh found.
  final List<FeedPost> _arrived = [];
  int _fresh = 0;
  int _published = 0;
  Timer? _refreshTimer;
  Completer<int>? _refreshing;

  /// How long the pretend server takes to answer a refresh.
  static const refreshDelay = Duration(milliseconds: 900);

  /// Whether a [refresh] is under way.
  bool get isRefreshing => _refreshing != null;

  /// Asks for new posts, as pulling the feed down does. Completes — after
  /// [refreshDelay], there being no server — with how many arrived: one a
  /// time while there are any, then none.
  ///
  /// A second call while one is under way joins it.
  Future<int> refresh() {
    if (_refreshing case final running?) return running.future;
    final completer = _refreshing = Completer<int>();
    _refreshTimer = Timer(refreshDelay, () {
      _refreshing = null;
      _refreshTimer = null;
      var arrived = 0;
      if (_fresh < HomeData.freshPosts.length) {
        final post = HomeData.freshPosts[_fresh++];
        _arrived.insert(0, post);
        _following.add(post.author.name);
        arrived = 1;
      }
      notifyListeners();
      completer.complete(arrived);
    });
    return completer.future;
  }

  /// What is typed in the composer. Kept here so that a draft is still
  /// there when the composer is opened again.
  final composeDraft = TextEditingController();

  /// Publishes [text] as a post of the signed-in user's, at the top of the
  /// feed, and returns it.
  FeedPost publish(String text) {
    final post = FeedPost(
      id: 'me-${++_published}',
      author: People.me,
      age: 'now',
      hoursAgo: 0,
      body: text,
      compactBody: text,
      reactions: const [],
      reactedBy: People.me,
      // Nobody yet: with the author's own like it would be one.
      otherReactions: -1,
      comments: 0,
    );
    _arrived.insert(0, post);
    notifyListeners();
    return post;
  }

  /// Takes [post] out of the feed again: the "Undo" of [publish], and
  /// "Delete post".
  void unpublish(FeedPost post) {
    final index = _arrived.indexOf(post);
    if (index < 0) return;
    _arrived.removeAt(index);
    _removedFrom[post.id] = index;
    notifyListeners();
  }

  /// Where each post [unpublish] removed was, for [restore].
  final Map<String, int> _removedFrom = {};

  /// Puts a post [unpublish] removed back where it was: the "Undo" of
  /// "Delete post".
  void restore(FeedPost post) {
    final index = _removedFrom.remove(post.id);
    if (index == null || _arrived.contains(post)) return;
    _arrived.insert(index.clamp(0, _arrived.length), post);
    notifyListeners();
  }

  bool isLiked(FeedPost post) => _liked.contains(post.id);

  void toggleLike(FeedPost post) {
    if (!_liked.remove(post.id)) _liked.add(post.id);
    notifyListeners();
  }

  /// How many people other than the one the summary names have reacted:
  /// the "214" of "Sara Lindqvist and 214 others", following the user's own
  /// like.
  int otherReactions(FeedPost post) =>
      post.otherReactions + (isLiked(post) ? 1 : 0) - (post.liked ? 1 : 0);

  /// Every reaction on [post], the number beside the phone's like button.
  int reactionCount(FeedPost post) => otherReactions(post) + 1;

  bool isFollowing(Person person) => _following.contains(person.name);

  void toggleFollow(Person person) {
    if (!_following.remove(person.name)) _following.add(person.name);
    notifyListeners();
  }

  bool isCommentLiked(FeedComment comment) =>
      _likedComments.contains(comment.id);

  void toggleCommentLike(FeedComment comment) {
    if (!_likedComments.remove(comment.id)) _likedComments.add(comment.id);
    notifyListeners();
  }

  /// Whether [comment]'s hidden replies are showing.
  bool areRepliesShown(FeedComment comment) =>
      _expandedComments.contains(comment.id);

  void toggleReplies(FeedComment comment) {
    if (!_expandedComments.remove(comment.id)) {
      _expandedComments.add(comment.id);
    }
    notifyListeners();
  }

  /// The controller of [post]'s comment field: the same one for as long as
  /// the feed lives, so a draft outlasts the card it was typed in.
  TextEditingController draftFor(FeedPost post) =>
      _drafts.putIfAbsent(post.id, TextEditingController.new);

  @override
  void dispose() {
    _refreshTimer?.cancel();
    // Whoever is waiting for the refresh is told that nothing came.
    _refreshing?.complete(0);
    _refreshing = null;
    composeDraft.dispose();
    for (final draft in _drafts.values) {
      draft.dispose();
    }
    super.dispose();
  }
}

/// Provides the [HomeFeedModel] to the home screen's widgets and rebuilds
/// those that read it when it changes.
class HomeFeedScope extends InheritedNotifier<HomeFeedModel> {
  const HomeFeedScope({
    required HomeFeedModel model,
    required super.child,
    super.key,
  }) : super(notifier: model);

  static HomeFeedModel of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HomeFeedScope>();
    assert(scope != null, 'No HomeFeedScope above this widget.');
    return scope!.notifier!;
  }
}
