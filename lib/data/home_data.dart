import 'package:finesse_demo/assets.dart';
import 'package:finesse_demo/data.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The three lists the home feed's segmented control switches between.
enum HomeFeed {
  forYou('For you'),
  following('Following'),
  trending('Trending');

  const HomeFeed(this.label);

  final String label;
}

/// The orders the "Sort by" menu offers.
enum FeedSort {
  top('Top'),
  recent('Recent');

  const FeedSort(this.label);

  final String label;
}

/// A reaction shown in the overlapping summary under a post.
///
/// The designs colour these with literals rather than theme variables, so
/// the discs look the same in light and dark.
enum Reaction {
  like(PhosphorIconsFill.thumbsUp, Color(0xFF176B83), Color(0xFFFFFFFF)),
  love(PhosphorIconsFill.heart, Color(0xFFC8432F), Color(0xFFFFFFFF)),
  insight(PhosphorIconsFill.lightbulb, Color(0xFFEAF4F6), Color(0xFF176B83)),
  applause(
    PhosphorIconsFill.handsClapping,
    Color(0xFF193C4A),
    Color(0xFFFFFFFF),
  );

  const Reaction(this.icon, this.background, this.foreground);

  final IconData icon;
  final Color background;
  final Color foreground;
}

/// A card in the stories row.
@immutable
class Story {
  const Story({required this.person, required this.image});

  final Person person;

  /// The photograph behind the card.
  final String image;
}

/// A photograph attached to a post.
@immutable
class FeedImage {
  const FeedImage(this.asset, this.alt);

  final String asset;

  /// The design's `alt` text.
  final String alt;
}

/// The article a post links to.
@immutable
class FeedLink {
  const FeedLink({
    required this.image,
    required this.source,
    required this.title,
  });

  final String image;

  /// "orbital.design · 8 min read"; shown in capitals.
  final String source;
  final String title;
}

/// The event a post announces, shown on glass over the post's photograph.
@immutable
class FeedEvent {
  const FeedEvent({
    required this.image,
    required this.month,
    required this.day,
    required this.title,
    required this.detail,
  });

  final FeedImage image;
  final String month;
  final String day;
  final String title;
  final String detail;
}

/// A comment under a post, or a reply to one.
@immutable
class FeedComment {
  const FeedComment({
    required this.id,
    required this.author,
    required this.text,
    required this.age,
    required this.likes,
    this.replies = const [],
    this.hiddenReplies = const [],
  });

  final String id;
  final Person author;
  final String text;

  /// "1h", "48m".
  final String age;
  final int likes;

  /// The replies shown from the start.
  final List<FeedComment> replies;

  /// The replies behind "View 6 more replies".
  final List<FeedComment> hiddenReplies;
}

/// A post in the feed.
@immutable
class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.age,
    required this.hoursAgo,
    required this.body,
    required this.compactBody,
    required this.reactions,
    required this.reactedBy,
    required this.otherReactions,
    required this.comments,
    this.reposts = 0,
    this.images = const [],
    this.link,
    this.event,
    this.followable = false,
    this.liked = false,
    this.thread = const [],
  });

  final String id;
  final Person author;

  /// "2h", "1d".
  final String age;

  /// [age] as a number, for the "Recent" order.
  final int hoursAgo;

  /// The text of the post in the desktop feed.
  final String body;

  /// The shorter text the phone design shows.
  final String compactBody;

  final List<FeedImage> images;
  final FeedLink? link;
  final FeedEvent? event;

  /// The kinds of reaction, most common first.
  final List<Reaction> reactions;

  /// The connection named in "Sara Lindqvist and 214 others".
  final Person reactedBy;

  /// The "214" in that line, as designed — before the signed-in user's own
  /// like is added or taken away.
  final int otherReactions;

  final int comments;
  final int reposts;

  /// Whether the header offers "Follow": the author is not followed yet.
  final bool followable;

  /// Whether the signed-in user has liked the post in the designs.
  final bool liked;

  /// The comments shown under the post in the desktop feed.
  final List<FeedComment> thread;

  /// Every reaction counted, with [liked] as designed.
  int get reactionCount => otherReactions + 1;
}

/// Someone the "Add to your network" card suggests.
@immutable
class Suggestion {
  const Suggestion({
    required this.person,
    required this.mutuals,
    required this.mutualCount,
  });

  final Person person;

  /// The portraits in the overlapping stack; asset paths.
  final List<String> mutuals;
  final int mutualCount;
}

/// A row of the "Trending in design" card.
@immutable
class Trend {
  const Trend(this.title, this.posts);

  final String title;

  /// "4,812 posts".
  final String posts;
}

/// A row of the profile card's figures.
@immutable
class ProfileStat {
  const ProfileStat(this.label, this.value);

  final String label;
  final String value;
}

/// A link in the profile card's shortcut list or the composer's action row.
@immutable
class HomeShortcut {
  const HomeShortcut(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The home feed's content, copied from the Demo designs.
abstract final class HomeData {
  /// The banner at the top of the profile card.
  static const cover = DemoAssets.photoCoverMountainLake;

  static const profileStats = [
    ProfileStat('Profile viewers', '128'),
    ProfileStat('Post impressions', '2,431'),
  ];

  static const shortcuts = [
    HomeShortcut('Saved items', PhosphorIconsRegular.bookmarkSimple),
    HomeShortcut('Groups', PhosphorIconsRegular.usersThree),
    HomeShortcut('Events', PhosphorIconsRegular.calendarBlank),
  ];

  static const composerActions = [
    HomeShortcut('Photo', PhosphorIconsRegular.image),
    HomeShortcut('Video', PhosphorIconsRegular.videoCamera),
    HomeShortcut('Event', PhosphorIconsRegular.calendarBlank),
    HomeShortcut('Write article', PhosphorIconsRegular.article),
  ];

  static const stories = [
    Story(person: People.julian, image: DemoAssets.storyConferenceAudience),
    Story(person: People.sara, image: DemoAssets.storyMountainMeadow),
    Story(person: People.omar, image: DemoAssets.photoWhiteboardUserFlow),
    Story(person: People.freya, image: DemoAssets.storyOfficeLounge),
  ];

  static const posts = [onboardingWorkshop, calmWriteUp, configNordics];

  /// What a refresh of the feed brings in, one post a pull, in this order.
  /// They are not in the designs: they are written for the demo, so that
  /// pulling the feed down has something to show for it.
  static const freshPosts = [tokenNaming, portfolioReviews, researchReadout];

  static const tokenNaming = FeedPost(
    id: 'token-naming',
    author: People.freya,
    age: 'now',
    hoursAgo: 0,
    body:
        'Renamed forty colour tokens this morning and nothing broke. The '
        'trick was naming them for what they are for, not what they look '
        'like: “surface”, “ink”, “tint”. A dark theme stopped being a '
        'second design system the same day.',
    compactBody:
        'Renamed forty colour tokens this morning and nothing broke. Name '
        'them for what they are for, not what they look like.',
    reactions: [Reaction.like, Reaction.insight],
    reactedBy: People.omar,
    otherReactions: 12,
    comments: 3,
  );

  static const portfolioReviews = FeedPost(
    id: 'portfolio-reviews',
    author: People.mei,
    age: 'now',
    hoursAgo: 0,
    body:
        'I have four slots for portfolio reviews next week, for anyone in '
        'their first two years of design. Thirty minutes, honest notes, no '
        'slides needed. Reply here or send me a message.',
    compactBody:
        'Four slots for portfolio reviews next week, for anyone in their '
        'first two years of design. Reply here or send me a message.',
    reactions: [Reaction.love, Reaction.applause],
    reactedBy: People.sara,
    otherReactions: 31,
    comments: 9,
    reposts: 4,
  );

  static const researchReadout = FeedPost(
    id: 'research-readout',
    author: People.aisha,
    age: 'now',
    hoursAgo: 0,
    body:
        'Read-out from eight sessions with screen-reader users: the single '
        'biggest fix was not a component. It was putting the page’s one '
        'heading first, so the page says what it is before it says '
        'anything else.',
    compactBody:
        'Eight sessions with screen-reader users, one big fix: put the '
        'page’s heading first, so it says what it is before anything else.',
    reactions: [Reaction.insight, Reaction.like, Reaction.applause],
    reactedBy: People.julian,
    otherReactions: 47,
    comments: 11,
    reposts: 6,
  );

  static const onboardingWorkshop = FeedPost(
    id: 'onboarding-workshop',
    author: People.omar,
    age: '2h',
    hoursAgo: 2,
    body:
        'We ran a two-day workshop to rebuild onboarding from scratch. The '
        'biggest unlock wasn’t a new flow. It was cutting six setup screens '
        'down to two, and letting people skip setup entirely.\n'
        '\n'
        'Three things I’d do again:\n'
        '1. Map every question to the decision it informs\n'
        '2. Prototype in the room, test the same afternoon\n'
        '3. Invite support, not just product',
    compactBody:
        'We ran a two-day workshop to rebuild onboarding from scratch. The '
        'biggest unlock was cutting six setup screens down to two, and '
        'letting people skip setup entirely.',
    images: [
      FeedImage(
        DemoAssets.photoWorkshopTeam,
        'Team at a whiteboard during the onboarding workshop',
      ),
      FeedImage(
        DemoAssets.photoWhiteboardFlowSketches,
        'Flow sketches on a whiteboard',
      ),
    ],
    reactions: [Reaction.like, Reaction.love, Reaction.insight],
    reactedBy: People.sara,
    otherReactions: 214,
    comments: 38,
    reposts: 12,
    followable: true,
    liked: true,
    thread: [
      FeedComment(
        id: 'freya-activation',
        author: People.freya,
        text:
            'Cutting setup entirely is so underrated. Did activation hold up '
            'after launch?',
        age: '1h',
        likes: 24,
        replies: [
          FeedComment(
            id: 'omar-activation',
            author: People.omar,
            text:
                'It went up, from 61% to 78% in the first two weeks. Support '
                'tickets about setup dropped by half.',
            age: '48m',
            likes: 9,
          ),
        ],
        // The designs only count these ("View 6 more replies"); the text is
        // written for the demo so the link has something to reveal.
        hiddenReplies: [
          FeedComment(
            id: 'sara-cohorts',
            author: People.sara,
            text:
                'We saw the same in our interviews: nobody missed the '
                'screens that went away.',
            age: '41m',
            likes: 6,
          ),
          FeedComment(
            id: 'mateo-skip',
            author: People.mateo,
            text: 'How did you decide which two screens to keep?',
            age: '37m',
            likes: 3,
          ),
          FeedComment(
            id: 'omar-keep',
            author: People.omar,
            text:
                'The two that change what you see on day one. Everything '
                'else moved into settings.',
            age: '33m',
            likes: 5,
          ),
          FeedComment(
            id: 'elena-support',
            author: People.elena,
            text: 'Inviting support is the part most teams skip. Great call.',
            age: '29m',
            likes: 4,
          ),
          FeedComment(
            id: 'irina-copy',
            author: People.irina,
            text: 'Would love to see the before and after copy.',
            age: '22m',
            likes: 2,
          ),
          FeedComment(
            id: 'mei-borrow',
            author: People.mei,
            text: 'Borrowing the same-afternoon testing idea for next sprint.',
            age: '15m',
            likes: 1,
          ),
        ],
      ),
    ],
  );

  static const calmWriteUp = FeedPost(
    id: 'calm-write-up',
    author: People.aisha,
    age: '5h',
    hoursAgo: 5,
    body:
        'New write-up from our research team. Fewer announcements, clearer '
        'landmarks and no surprise motion made the biggest difference. Full '
        'notes and the interview guide are free to reuse.',
    compactBody:
        'New write-up from our research team. Fewer announcements, clearer '
        'landmarks and no surprise motion made the biggest difference.',
    link: FeedLink(
      image: DemoAssets.photoAlpineLake,
      source: 'orbital.design · 8 min read',
      title:
          'Designing for calm: notes from 40 interviews with screen reader '
          'users',
    ),
    reactions: [Reaction.love, Reaction.insight, Reaction.applause],
    reactedBy: People.rafael,
    otherReactions: 1028,
    comments: 96,
    reposts: 140,
  );

  static const configNordics = FeedPost(
    id: 'config-nordics',
    author: People.julian,
    age: '1d',
    hoursAgo: 24,
    body:
        'Speaking at Config Nordics next week on design systems that scale '
        'past 200 engineers. Come say hi after the talk. I’ll be at the '
        'community lounge both days.',
    compactBody:
        'Speaking at Config Nordics next week on design systems that scale '
        'past 200 engineers. Come say hi after the talk.',
    event: FeedEvent(
      image: FeedImage(
        DemoAssets.photoConferenceStage,
        'Speaker on a conference stage',
      ),
      month: 'NOV',
      day: '28',
      title: 'Config Nordics 2026',
      detail: 'Copenhagen · 1,240 attending',
    ),
    reactions: [Reaction.like, Reaction.applause],
    reactedBy: People.mei,
    otherReactions: 482,
    comments: 41,
    followable: true,
  );

  static const suggestions = [
    Suggestion(
      person: People.elena,
      mutuals: [
        DemoAssets.avatarSaraLindqvist,
        DemoAssets.avatarOmarRahimi,
        DemoAssets.avatarRafaelCruz,
      ],
      mutualCount: 14,
    ),
    Suggestion(
      person: People.rafael,
      mutuals: [
        DemoAssets.avatarConnectionA,
        DemoAssets.avatarFreyaHolm,
      ],
      mutualCount: 10,
    ),
    Suggestion(
      person: People.mei,
      mutuals: [
        DemoAssets.avatarIrinaVolkova,
        DemoAssets.avatarJulianReyes,
        DemoAssets.avatarSaraLindqvist,
      ],
      mutualCount: 14,
    ),
  ];

  static const trends = [
    Trend('#DesignSystems', '4,812 posts'),
    Trend('Config Nordics 2026', '2,190 posts'),
    Trend('AI in user research', '1,604 posts'),
    Trend('Accessibility audits', '988 posts'),
    Trend('Remote design teams', '720 posts'),
  ];

  static const footerLinks = [
    'About',
    'Accessibility',
    'Privacy',
    'Terms',
    'Help center',
    'Advertising',
  ];

  static const copyright = 'Demo © 2026';

  /// Every image the home feed shows, for a caller that wants them decoded
  /// before the first frame (a screenshot test).
  static List<String> get images => [
    cover,
    People.me.avatar,
    for (final group in Groups.all) group.logo,
    for (final story in stories) ...[story.image, story.person.avatar],
    for (final post in posts) ...[
      post.author.avatar,
      for (final image in post.images) image.asset,
      ?post.link?.image,
      ?post.event?.image.asset,
      for (final comment in post.thread) ...[
        comment.author.avatar,
        for (final reply in comment.replies) reply.author.avatar,
        for (final reply in comment.hiddenReplies) reply.author.avatar,
      ],
    ],
    for (final suggestion in suggestions) ...[
      suggestion.person.avatar,
      ...suggestion.mutuals,
    ],
  ];
}

/// "1,028" for 1028: the designs group thousands with a comma.
String formatCount(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
