import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/assets.dart';
import 'package:una_demo/data.dart';

/// The lists the Network screen can show in its main column.
///
/// [grow] is the screen as it opens — invitations and suggestions. The rest
/// are what the "Manage my network" rows lead to.
enum NetworkSection {
  grow('Grow', PhosphorIconsRegular.userPlus),
  connections('Connections', PhosphorIconsRegular.users),
  following('Following', PhosphorIconsRegular.userCheck),
  groups('Groups', PhosphorIconsRegular.usersThree),
  events('Events', PhosphorIconsRegular.calendarBlank),
  pages('Pages', PhosphorIconsRegular.buildings);

  const NetworkSection(this.label, this.icon);

  final String label;
  final IconData icon;

  /// The rows of the "Manage my network" card: everything but [grow].
  static const managed = [connections, following, groups, events, pages];
}

/// Someone who has asked to connect.
@immutable
class Invitation {
  const Invitation({
    required this.person,
    required this.mutualCount,
    required this.age,
    this.mutuals = const [],
    this.note,
  });

  final Person person;

  /// The people both sides know; the first few are shown as a stack.
  final List<Person> mutuals;
  final int mutualCount;

  /// "2d ago".
  final String age;

  /// The message sent with the invitation, when there is one.
  final String? note;
}

/// Someone the "People you may know" grid suggests.
@immutable
class NetworkSuggestion {
  const NetworkSuggestion({
    required this.person,
    required this.reason,
    required this.reasonIcon,
    this.mutuals = const [],
    this.mutualCount = 0,
  });

  final Person person;

  /// Why they are suggested: "Works at Halcyon". Kept short — it has one
  /// line of a card a phone shows two across.
  final String reason;
  final IconData reasonIcon;
  final List<Person> mutuals;
  final int mutualCount;
}

/// A connection, as the Connections list shows it.
@immutable
class Connection {
  const Connection(this.person, this.since, {required this.monthsAgo});

  final Person person;

  /// "Connected in March 2024".
  final String since;

  /// How long ago, for the "Recently added" order.
  final int monthsAgo;
}

/// Someone the user follows without being connected.
@immutable
class Following {
  const Following(this.person, this.followers);

  final Person person;

  /// "12.4k followers".
  final String followers;
}

/// A company page the user follows, or could.
@immutable
class NetworkPage {
  const NetworkPage(
    this.company, {
    required this.tagline,
    required this.followers,
    this.following = true,
  });

  final Company company;
  final String tagline;
  final String followers;

  /// Whether the user follows the page as the screen opens.
  final bool following;
}

/// An upcoming event.
@immutable
class NetworkEvent {
  const NetworkEvent({
    required this.id,
    required this.month,
    required this.day,
    required this.title,
    required this.place,
    required this.time,
    required this.attendees,
    this.attending = false,
    this.going = const [],
  });

  final String id;

  /// "NOV".
  final String month;

  /// "28".
  final String day;
  final String title;

  /// "Copenhagen" or "Online".
  final String place;

  /// "Sat · 09:00".
  final String time;

  /// How many people are going, before the user's own answer.
  final int attendees;

  /// Whether the user is going as the screen opens.
  final bool attending;

  /// Connections who are going.
  final List<Person> going;
}

/// A group, with what the Groups list needs beyond the shared [Group].
@immutable
class NetworkGroup {
  const NetworkGroup({
    required this.name,
    required this.members,
    required this.about,
    this.logo,
    this.icon,
    this.joined = false,
    this.newPosts = 0,
  }) : assert(logo != null || icon != null, 'A group needs a mark.');

  /// One of the user's own groups.
  NetworkGroup.joined(Group group, {required this.about})
    : name = group.name,
      members = group.members,
      logo = group.logo,
      icon = null,
      joined = true,
      newPosts = group.newPosts;

  final String name;

  /// "18,402 members".
  final String members;

  /// One line about the group.
  final String about;

  /// The mark's asset, when the group has one.
  final String? logo;

  /// The glyph shown on a tile when it has none.
  final IconData? icon;

  /// Whether the user is a member as the screen opens.
  final bool joined;
  final int newPosts;
}

/// The Network screen's content.
///
/// The designs stop short of this screen, so everything here is written to
/// agree with what the four designed screens already say: who works where,
/// who Noor knows, which groups she is in, and that Config Nordics is this
/// weekend.
abstract final class NetworkData {
  static const title = 'Network';

  /// The connection count behind the profile's "500+".
  static const connectionCount = 512;
  static const followingCount = 86;

  static const invitations = [
    Invitation(
      person: People.irina,
      mutuals: [People.omar, People.sara],
      mutualCount: 9,
      age: '3h ago',
      note:
          'We overlapped at Birchline for a few months. I still use your '
          'onboarding checklist. Would love to stay in touch.',
    ),
    Invitation(
      person: People.mateo,
      mutuals: [People.rafael, People.freya],
      mutualCount: 6,
      age: '1d ago',
    ),
    Invitation(
      person: People.jonas,
      mutuals: [People.claire],
      mutualCount: 2,
      age: '4d ago',
      note:
          'Hi Noor, I am hiring a design lead for our research tools team '
          'and your Config Nordics talk came up twice this week.',
    ),
  ];

  static const suggestions = [
    NetworkSuggestion(
      person: People.elena,
      reason: 'Viewed your profile',
      reasonIcon: PhosphorIconsRegular.eye,
      mutuals: [People.sara, People.omar, People.julian],
      mutualCount: 14,
    ),
    NetworkSuggestion(
      person: People.ingrid,
      reason: 'Works at Halcyon',
      reasonIcon: PhosphorIconsRegular.briefcase,
      mutuals: [People.emil, People.freya],
      mutualCount: 31,
    ),
    NetworkSuggestion(
      person: People.rafael,
      reason: 'Knows Freya Holm',
      reasonIcon: PhosphorIconsRegular.users,
      mutuals: [People.leo, People.freya],
      mutualCount: 10,
    ),
    NetworkSuggestion(
      person: People.mei,
      reason: 'Nordhavn alumna',
      reasonIcon: PhosphorIconsRegular.graduationCap,
      mutuals: [People.irina, People.julian, People.sara],
      mutualCount: 14,
    ),
    NetworkSuggestion(
      person: People.julian,
      reason: 'Config speaker',
      reasonIcon: PhosphorIconsRegular.microphoneStage,
      mutuals: [People.elena, People.aisha],
      mutualCount: 22,
    ),
    NetworkSuggestion(
      person: People.hanna,
      reason: 'In a group with you',
      reasonIcon: PhosphorIconsRegular.usersThree,
      mutuals: [People.aisha, People.sara],
      mutualCount: 8,
    ),
    NetworkSuggestion(
      person: People.leo,
      reason: 'Works with Aisha',
      reasonIcon: PhosphorIconsRegular.briefcase,
      mutuals: [People.aisha],
      mutualCount: 5,
    ),
    NetworkSuggestion(
      person: People.priya,
      reason: 'Design Systems Guild',
      reasonIcon: PhosphorIconsRegular.usersThree,
      mutuals: [People.freya, People.omar],
      mutualCount: 12,
    ),
  ];

  static const connections = [
    Connection(People.emil, 'Connected in October 2026', monthsAgo: 1),
    Connection(People.aisha, 'Connected in June 2026', monthsAgo: 5),
    Connection(People.tobias, 'Connected in January 2026', monthsAgo: 10),
    Connection(People.freya, 'Connected in September 2025', monthsAgo: 14),
    Connection(People.claire, 'Connected in May 2025', monthsAgo: 18),
    Connection(People.sara, 'Connected in March 2021', monthsAgo: 68),
    Connection(People.omar, 'Connected in April 2020', monthsAgo: 79),
  ];

  static const following = [
    Following(People.julian, '18.2k followers'),
    Following(People.aisha, '9,410 followers'),
    Following(People.priya, '6,075 followers'),
    Following(People.ingrid, '4,318 followers'),
  ];

  static const pages = [
    NetworkPage(
      Companies.halcyon,
      tagline: 'Planning software · 340 employees',
      followers: '12,804 followers',
    ),
    NetworkPage(
      Companies.birchline,
      tagline: 'Billing for small businesses · 610 employees',
      followers: '21,377 followers',
    ),
    NetworkPage(
      Companies.orbital,
      tagline: 'Design tooling · 95 employees',
      followers: '48,112 followers',
    ),
    NetworkPage(
      Companies.nordhavnSchoolOfDesign,
      tagline: 'Higher education · Copenhagen',
      followers: '7,560 followers',
    ),
    NetworkPage(
      Companies.kestrelHealth,
      tagline: 'Health tech · 1,200 employees',
      followers: '33,940 followers',
      following: false,
    ),
    NetworkPage(
      Companies.quill,
      tagline: 'Writing tools · 60 employees',
      followers: '15,226 followers',
      following: false,
    ),
    NetworkPage(
      Companies.tidewater,
      tagline: 'Logistics software · 420 employees',
      followers: '5,918 followers',
      following: false,
    ),
  ];

  static const events = [
    NetworkEvent(
      id: 'config-nordics',
      month: 'NOV',
      day: '28',
      title: 'Config Nordics 2026',
      place: 'Copenhagen',
      time: 'Sat – Sun · 09:00',
      attendees: 1240,
      attending: true,
      going: [People.julian, People.omar, People.freya],
    ),
    NetworkEvent(
      id: 'tokens-v3',
      month: 'DEC',
      day: '3',
      title: 'Tokens v3: a walkthrough with the maintainers',
      place: 'Online',
      time: 'Thu · 17:00',
      attendees: 386,
      going: [People.freya, People.priya],
    ),
    NetworkEvent(
      id: 'audit-office-hours',
      month: 'DEC',
      day: '10',
      title: 'Accessibility audit office hours',
      place: 'Online',
      time: 'Thu · 12:30',
      attendees: 142,
      going: [People.aisha],
    ),
    NetworkEvent(
      id: 'winter-social',
      month: 'DEC',
      day: '12',
      title: 'Copenhagen Product Circle winter social',
      place: 'Halcyon, Nørrebro',
      time: 'Sat · 18:30',
      attendees: 74,
      going: [People.emil, People.tobias],
    ),
  ];

  static final groups = [
    NetworkGroup.joined(
      Groups.designSystemsGuild,
      about: 'Tokens, components and the people who maintain them.',
    ),
    NetworkGroup.joined(
      Groups.copenhagenProductCircle,
      about: 'Monthly meetups for product people in Copenhagen.',
    ),
    NetworkGroup.joined(
      Groups.accessibilityCollective,
      about: 'Audits, patterns and answers from practitioners.',
    ),
    ...suggestedGroups,
  ];

  static const suggestedGroups = [
    NetworkGroup(
      name: 'Research Ops Nordics',
      members: '3,208 members',
      about: 'Panels, consent and repositories for research teams.',
      icon: PhosphorIconsRegular.flask,
    ),
    NetworkGroup(
      name: 'Nordhavn Alumni',
      members: '5,641 members',
      about: 'Graduates of the Nordhavn School of Design.',
      logo: DemoAssets.logoNordhavnSchoolOfDesign,
    ),
    NetworkGroup(
      name: 'Calm Software Club',
      members: '1,972 members',
      about: 'Fewer notifications, fewer decisions, better defaults.',
      icon: PhosphorIconsRegular.leaf,
    ),
  ];
}
