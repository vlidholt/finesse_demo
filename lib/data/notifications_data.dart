import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/data/network_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The tabs above the notification list.
enum NotificationFilter {
  all('All'),
  mentions('Mentions'),
  jobs('Jobs'),
  posts('My posts');

  const NotificationFilter(this.label);

  final String label;
}

/// The headings the list is grouped under.
enum NotificationPeriod {
  today('Today'),
  week('This week'),
  earlier('Earlier');

  const NotificationPeriod(this.label);

  final String label;
}

/// What a notification is about. It picks the small mark on the row's
/// portrait and the filter the row is listed under.
enum NotificationKind {
  reaction(PhosphorIconsFill.heart, NotificationFilter.posts),
  comment(PhosphorIconsFill.chatCircle, NotificationFilter.posts),
  repost(PhosphorIconsBold.repeat, NotificationFilter.posts),
  mention(PhosphorIconsBold.at, NotificationFilter.mentions),
  invitation(PhosphorIconsFill.userPlus),
  connection(PhosphorIconsFill.handshake),
  job(PhosphorIconsFill.briefcase, NotificationFilter.jobs),
  application(PhosphorIconsFill.paperPlaneTilt, NotificationFilter.jobs),
  views(PhosphorIconsRegular.eye),
  milestone(PhosphorIconsRegular.trendUp),
  group(PhosphorIconsFill.usersThree),
  event(PhosphorIconsRegular.calendarCheck),
  celebration(PhosphorIconsFill.confetti);

  const NotificationKind(this.icon, [this.filter]);

  final IconData icon;

  /// The tab, besides "All", that lists this kind.
  final NotificationFilter? filter;
}

/// The button a row may carry.
enum NotificationAction {
  reply('Reply', PhosphorIconsRegular.arrowBendUpLeft),
  accept('Accept', PhosphorIconsRegular.check, done: 'Connected'),
  viewJob('View job', PhosphorIconsRegular.briefcase),
  message('Message', PhosphorIconsRegular.paperPlaneTilt),
  wish('Say happy birthday', PhosphorIconsRegular.cake, done: 'Sent'),
  congratulate(
    'Congratulate',
    PhosphorIconsRegular.handsClapping,
    done: 'Congratulated',
  );

  const NotificationAction(this.label, this.icon, {this.done});

  final String label;
  final IconData icon;

  /// What the button reads once pressed, when pressing it does not leave
  /// the screen.
  final String? done;
}

/// One notification.
@immutable
class DemoNotification {
  const DemoNotification({
    required this.id,
    required this.kind,
    required this.period,
    required this.age,
    required this.text,
    required this.target,
    this.people = const [],
    this.company,
    this.group,
    this.quote,
    this.excerpt,
    this.action,
    this.unread = false,
  });

  final String id;
  final NotificationKind kind;
  final NotificationPeriod period;

  /// "12m", "Mon", "Nov 14".
  final String age;

  /// The sentence, with the parts the designs would set in semibold wrapped
  /// in asterisks: `*Omar Rahimi* commented on your post`.
  final String text;

  /// The people behind it; the first one's portrait leads the row.
  final List<Person> people;

  /// The company whose mark leads the row, for a job.
  final Company? company;

  /// The group whose mark leads the row.
  final Group? group;

  /// What someone wrote: a comment, a mention.
  final String? quote;

  /// The start of the post the notification is about.
  final String? excerpt;

  final NotificationAction? action;

  /// Whether it is unread as the app starts.
  final bool unread;

  /// Where tapping the row leads.
  final DemoDestination target;
}

/// The Notifications screen's content: eighteen notifications, the newest
/// twelve unread — the "12" the designs put on the bell.
abstract final class NotificationsData {
  static const title = 'Notifications';

  static const all = <DemoNotification>[
    DemoNotification(
      id: 'reactions-onboarding',
      kind: NotificationKind.reaction,
      period: NotificationPeriod.today,
      age: '12m',
      people: [People.sara, People.freya, People.emil],
      text: '*Sara Lindqvist*, *Freya Holm* and 46 others reacted to your post',
      excerpt:
          'We rebuilt onboarding in two days. One whiteboard, five '
          'people and a rule that nothing ships unless…',
      target: DemoDestination.profile,
      unread: true,
    ),
    DemoNotification(
      id: 'comment-omar',
      kind: NotificationKind.comment,
      period: NotificationPeriod.today,
      age: '38m',
      people: [People.omar],
      text: '*Omar Rahimi* commented on your post',
      quote:
          'The flow map is what made it click for the team. Did you keep '
          'the first version anywhere?',
      action: NotificationAction.reply,
      target: DemoDestination.home,
      unread: true,
    ),
    DemoNotification(
      id: 'mention-aisha',
      kind: NotificationKind.mention,
      period: NotificationPeriod.today,
      age: '1h',
      people: [People.aisha],
      text: '*Aisha Rahman* mentioned you in a comment',
      quote:
          '@Noor Haddad ran the workshop this is based on. Her template is '
          'worth stealing.',
      action: NotificationAction.reply,
      target: DemoDestination.home,
      unread: true,
    ),
    DemoNotification(
      id: 'job-kestrel',
      kind: NotificationKind.job,
      period: NotificationPeriod.today,
      age: '2h',
      company: Companies.kestrelHealth,
      text:
          '*Senior product designer, Design systems* at Kestrel Health is a '
          'strong match. You have 8 of the 10 skills listed.',
      action: NotificationAction.viewJob,
      target: DemoDestination.jobs,
      unread: true,
    ),
    DemoNotification(
      id: 'invitation-irina',
      kind: NotificationKind.invitation,
      period: NotificationPeriod.today,
      age: '3h',
      people: [People.irina],
      text: '*Irina Volkova* invited you to connect',
      excerpt: 'UX writer at Birchline · 9 mutual connections',
      action: NotificationAction.accept,
      target: DemoDestination.network,
      unread: true,
    ),
    DemoNotification(
      id: 'views-week',
      kind: NotificationKind.views,
      period: NotificationPeriod.today,
      age: '5h',
      text:
          '*18 people* viewed your profile this week, six of them '
          'recruiters',
      target: DemoDestination.profile,
      unread: true,
    ),
    DemoNotification(
      id: 'connection-emil',
      kind: NotificationKind.connection,
      period: NotificationPeriod.week,
      age: 'Mon',
      people: [People.emil],
      text: '*Emil Sandberg* accepted your invitation',
      excerpt: 'Front-end engineer at Halcyon',
      action: NotificationAction.message,
      target: DemoDestination.messages,
      unread: true,
    ),
    DemoNotification(
      id: 'application-quill',
      kind: NotificationKind.application,
      period: NotificationPeriod.week,
      age: 'Mon',
      company: Companies.quill,
      text:
          'Your application for *Product designer, Editor* at Quill was '
          'viewed by the hiring team',
      action: NotificationAction.viewJob,
      target: DemoDestination.jobs,
      unread: true,
    ),
    DemoNotification(
      id: 'mention-julian',
      kind: NotificationKind.mention,
      period: NotificationPeriod.week,
      age: 'Sun',
      people: [People.julian],
      text: '*Julian Reyes* mentioned you in a post',
      quote:
          'Borrowing a slide from @Noor Haddad for the main stage on '
          'Saturday. Calm by default, indeed.',
      target: DemoDestination.home,
      unread: true,
    ),
    DemoNotification(
      id: 'repost-mei',
      kind: NotificationKind.repost,
      period: NotificationPeriod.week,
      age: 'Sun',
      people: [People.mei],
      text:
          '*Mei Tanaka* reposted your article *What we learned from 40 '
          'interviews*',
      target: DemoDestination.profile,
      unread: true,
    ),
    DemoNotification(
      id: 'group-tokens',
      kind: NotificationKind.group,
      period: NotificationPeriod.week,
      age: 'Sat',
      group: Groups.designSystemsGuild,
      text: '*Freya Holm* posted in Design Systems Guild',
      quote: 'Tokens v3 is live, release notes inside.',
      target: DemoDestination.messages,
      unread: true,
    ),
    DemoNotification(
      id: 'event-config',
      kind: NotificationKind.event,
      period: NotificationPeriod.week,
      age: 'Sat',
      text:
          '*Config Nordics 2026* starts on Saturday. Julian, Omar and '
          '1,238 others are going.',
      target: DemoDestination.network,
      unread: true,
    ),
    DemoNotification(
      id: 'birthday-claire',
      kind: NotificationKind.celebration,
      period: NotificationPeriod.week,
      age: 'Fri',
      people: [People.claire],
      text: 'It was *Claire Dubois*’s birthday on Friday',
      action: NotificationAction.wish,
      target: DemoDestination.messages,
    ),
    DemoNotification(
      id: 'reactions-interviews',
      kind: NotificationKind.reaction,
      period: NotificationPeriod.earlier,
      age: 'Nov 16',
      people: [People.rafael, People.elena],
      text:
          '*Rafael Cruz*, *Elena Petrova* and 234 others reacted to your '
          'post',
      excerpt:
          'Forty interviews with small-business owners later, the '
          'pattern is hard to miss…',
      target: DemoDestination.profile,
    ),
    DemoNotification(
      id: 'job-birchline',
      kind: NotificationKind.job,
      period: NotificationPeriod.earlier,
      age: 'Nov 14',
      company: Companies.birchline,
      text:
          '*Design lead, Onboarding* at Birchline is open. Three of your '
          'connections work there.',
      action: NotificationAction.viewJob,
      target: DemoDestination.jobs,
    ),
    DemoNotification(
      id: 'anniversary-omar',
      kind: NotificationKind.celebration,
      period: NotificationPeriod.earlier,
      age: 'Nov 12',
      people: [People.omar],
      text: '*Omar Rahimi* is celebrating six years at Birchline',
      action: NotificationAction.congratulate,
      target: DemoDestination.messages,
    ),
    DemoNotification(
      id: 'reply-sara',
      kind: NotificationKind.comment,
      period: NotificationPeriod.earlier,
      age: 'Nov 10',
      people: [People.sara],
      text: '*Sara Lindqvist* replied to your comment',
      quote:
          'Weekly sessions beat a quarterly study every time. Sharing our '
          'script tomorrow.',
      target: DemoDestination.home,
    ),
    DemoNotification(
      id: 'milestone-talk',
      kind: NotificationKind.milestone,
      period: NotificationPeriod.earlier,
      age: 'Nov 9',
      text:
          'Your talk *Calm by default: designing for focus* passed 2,400 '
          'views',
      target: DemoDestination.profile,
    ),
  ];

  /// The job a job notification is about, for the row's button.
  static Job? jobOf(DemoNotification notification) {
    final company = notification.company;
    if (company == null) return null;
    for (final job in JobsData.jobs) {
      if (job.company == company) return job;
    }
    return null;
  }

  /// The invitation an [NotificationAction.accept] row answers.
  static Invitation? invitationOf(DemoNotification notification) {
    if (notification.kind != NotificationKind.invitation) return null;
    for (final invitation in NetworkData.invitations) {
      if (invitation.person == notification.people.first) return invitation;
    }
    return null;
  }
}
