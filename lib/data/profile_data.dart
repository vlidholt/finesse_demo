import 'package:finesse_demo/assets.dart';
import 'package:finesse_demo/data.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The sections under the profile header.
///
/// A desktop shows all five; the phone design leaves out [activity].
enum ProfileTab {
  posts('Posts'),
  about('About'),
  experience('Experience'),
  activity('Activity'),
  media('Media');

  const ProfileTab(this.label);

  final String label;

  /// The tabs of the phone design, in order.
  static const mobile = [posts, about, experience, media];
}

/// One icon + text item of the header's meta row.
@immutable
class ProfileMeta {
  const ProfileMeta(this.icon, this.text, {this.link = false});

  final IconData icon;
  final String text;

  /// Whether the item is the profile's website, shown in the accent colour.
  final bool link;
}

/// One of the header's status tiles: "Open to work", "Available for talks".
@immutable
class ProfileStatus {
  const ProfileStatus({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    this.shortBody,
    this.positive = false,
  });

  final IconData icon;
  final String title;
  final String body;

  /// The phone design's shorter wording, where it has one.
  final String? shortBody;

  /// The link under the body.
  final String action;

  /// Whether the tile takes the success colours rather than the neutral fill.
  final bool positive;
}

/// One box of the Analytics card.
@immutable
class ProfileStat {
  const ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
  });

  final IconData icon;
  final String value;
  final String label;

  /// The change against last month: "12%".
  final String trend;
}

/// One card of the Featured row.
@immutable
class FeaturedItem {
  const FeaturedItem({
    required this.kind,
    required this.title,
    required this.meta,
    required this.image,
    required this.imageLabel,
  });

  /// The label over the image: "Talk", "Case study", "Article".
  final String kind;
  final String title;
  final String meta;

  /// One of the `DemoAssets.photo*`.
  final String image;
  final String imageLabel;
}

/// One position of the Experience timeline.
@immutable
class ExperienceEntry {
  const ExperienceEntry({
    required this.company,
    required this.role,
    required this.employment,
    required this.dates,
    required this.location,
    this.description,
  });

  final Company company;
  final String role;

  /// The line under the role: "Halcyon · Full-time · Hybrid".
  final String employment;
  final String dates;
  final String location;

  /// What the role involved. The phone design leaves it out.
  final String? description;
}

/// One school of the Education card.
@immutable
class EducationEntry {
  const EducationEntry({
    required this.school,
    required this.degree,
    required this.years,
  });

  final Company school;
  final String degree;
  final String years;
}

/// What the button beside a suggested person offers.
enum SuggestionAction {
  follow('Follow', 'Following'),
  message('Message', 'Message'),
  connect('Connect', 'Pending');

  const SuggestionAction(this.label, this.doneLabel);

  final String label;

  /// The label once the button has been pressed.
  final String doneLabel;
}

/// One row of "People also viewed".
@immutable
class ProfileSuggestion {
  const ProfileSuggestion(this.person, this.action);

  final Person person;
  final SuggestionAction action;
}

/// One of the profile owner's posts, for the Posts tab.
///
/// The designs only show the About tab; these are written from what the rest
/// of the profile says (the featured items, the experience entries).
@immutable
class ProfilePost {
  const ProfilePost({
    required this.time,
    required this.text,
    required this.reactions,
    required this.comments,
    this.image,
    this.imageLabel,
  });

  final String time;
  final String text;
  final int reactions;
  final int comments;

  /// One of the `DemoAssets.photo*`, when the post has a picture.
  final String? image;
  final String? imageLabel;
}

/// One line of the Activity tab.
@immutable
class ProfileActivity {
  const ProfileActivity({
    required this.icon,
    required this.verb,
    required this.person,
    required this.detail,
    required this.time,
  });

  final IconData icon;

  /// "Commented on", "Reacted to": what [People.me] did.
  final String verb;

  /// Whose post it was.
  final Person person;

  /// The comment, or the post's opening words.
  final String detail;
  final String time;
}

/// One picture of the Media tab.
@immutable
class ProfileMedia {
  const ProfileMedia(this.image, this.label);

  final String image;
  final String label;
}

/// Everything the Profile screen shows, copied from the Demo designs.
abstract final class ProfileData {
  static const person = People.me;

  static const coverLabel = 'Mountain lake cover photo';

  /// The desktop headline; the phone uses `person.headline`, which stops
  /// after the second sentence.
  static const headline =
      'Product designer at Halcyon. Building calmer tools for busy teams. '
      'Previously Birchline and Lumen Labs.';

  static const meta = [
    ProfileMeta(PhosphorIconsRegular.mapPin, 'Copenhagen, Denmark'),
    ProfileMeta(PhosphorIconsRegular.link, 'noorhaddad.design', link: true),
    ProfileMeta(PhosphorIconsRegular.briefcase, 'Halcyon'),
    ProfileMeta(
      PhosphorIconsRegular.graduationCap,
      'Nordhavn School of Design',
    ),
  ];

  /// The phone's meta line names only the city.
  static const city = 'Copenhagen';

  static const followers = '1,284';
  static const connections = '500+';
  static const mutualSummary = 'Omar, Sara and 18 others you know';
  static const mutualCount = '+18 mutual';

  /// The faces of the mutual-connections stack. The phone shows the first
  /// three.
  static const mutuals = [
    People.omar,
    People.sara,
    People.julian,
    People.freya,
  ];

  static const openToWork = ProfileStatus(
    icon: PhosphorIconsRegular.briefcase,
    title: 'Open to work',
    body: 'Design lead and principal designer roles · Remote or Copenhagen',
    shortBody: 'Design lead roles · Remote or Copenhagen',
    action: 'Show details',
    positive: true,
  );

  static const availableForTalks = ProfileStatus(
    icon: PhosphorIconsRegular.microphoneStage,
    title: 'Available for talks',
    body: 'Design systems, research ops and accessible product design',
    action: 'Get in touch',
  );

  static const stats = [
    ProfileStat(
      icon: PhosphorIconsRegular.users,
      value: '1,128',
      label: 'Profile viewers this month',
      trend: '12%',
    ),
    ProfileStat(
      icon: PhosphorIconsRegular.chartLineUp,
      value: '24,310',
      label: 'Post impressions',
      trend: '38%',
    ),
    ProfileStat(
      icon: PhosphorIconsRegular.magnifyingGlass,
      value: '312',
      label: 'Search appearances',
      trend: '6%',
    ),
  ];

  static const about =
      'I design tools for people who are short on time. For the past eight '
      'years I’ve worked on planning, billing and onboarding products, '
      'usually as the first or second designer on the team. I care about '
      'plain language, keyboard-first workflows and interfaces that stay out '
      'of the way.';

  /// The phone design's shorter About text.
  static const aboutShort =
      'I design tools for people who are short on time. Eight years on '
      'planning, billing and onboarding products, usually as one of the '
      'first designers on the team.';

  static const skills = [
    'Design systems',
    'Interaction design',
    'User research',
    'Prototyping',
    'Accessibility',
    'Figma',
    'Workshop facilitation',
  ];

  /// How many of [skills] the phone design shows.
  static const mobileSkillCount = 5;

  static const featured = [
    FeaturedItem(
      kind: 'Talk',
      title: 'Calm by default: designing for focus',
      meta: 'Config Nordics · 2.4k views',
      image: DemoAssets.photoConferenceStage,
      imageLabel: 'A speaker on a conference stage',
    ),
    FeaturedItem(
      kind: 'Case study',
      title: 'Rebuilding onboarding in two days',
      meta: 'Post · 812 reactions',
      image: DemoAssets.photoWorkshopTeam,
      imageLabel: 'A team at a whiteboard during a workshop',
    ),
    FeaturedItem(
      kind: 'Article',
      title: 'What we learned from 40 interviews',
      meta: 'Article · 6 min read',
      image: DemoAssets.photoAlpineLake,
      imageLabel: 'A lake under alpine peaks',
    ),
  ];

  static const experience = [
    ExperienceEntry(
      company: Companies.halcyon,
      role: 'Senior product designer',
      employment: 'Halcyon · Full-time · Hybrid',
      dates: 'Jan 2023 – Present · 3 yrs',
      location: 'Copenhagen, Denmark',
      description:
          'Lead designer for the planning suite. Rebuilt the shared '
          'component library and cut design-to-ship time for new features '
          'by about a third.',
    ),
    ExperienceEntry(
      company: Companies.birchline,
      role: 'Product designer',
      employment: 'Birchline · Full-time',
      dates: 'Mar 2020 – Dec 2022 · 2 yrs 10 mos',
      location: 'Stockholm, Sweden',
      description:
          'Owned onboarding and billing. Ran weekly research sessions with '
          'small-business owners.',
    ),
    ExperienceEntry(
      company: Companies.lumenLabs,
      role: 'UX designer',
      employment: 'Lumen Labs · Full-time',
      dates: 'Aug 2017 – Feb 2020 · 2 yrs 7 mos',
      location: 'Amman, Jordan',
    ),
  ];

  /// The line under the name on the profile owner's posts.
  static const currentRole = 'Senior product designer at Halcyon';

  static const education = [
    EducationEntry(
      school: Companies.nordhavnSchoolOfDesign,
      degree: 'MA, Interaction Design',
      years: '2015 – 2017',
    ),
  ];

  static const language = 'English';
  static const publicUrl = 'demo.app/in/noorhaddad';

  static const suggestions = [
    ProfileSuggestion(People.sara, SuggestionAction.follow),
    ProfileSuggestion(People.omar, SuggestionAction.message),
    ProfileSuggestion(People.irina, SuggestionAction.connect),
    ProfileSuggestion(People.mateo, SuggestionAction.connect),
  ];

  static const groups = Groups.all;

  static const posts = [
    ProfilePost(
      time: '2d',
      text:
          'We rebuilt onboarding in two days. One whiteboard, five people '
          'and a rule that nothing ships unless a new customer can finish '
          'it without reading a single tooltip. The case study is in my '
          'featured section.',
      reactions: 812,
      comments: 64,
      image: DemoAssets.photoWorkshopTeam,
      imageLabel: 'A team at a whiteboard during a workshop',
    ),
    ProfilePost(
      time: '1w',
      text:
          'Forty interviews with small-business owners later, the pattern '
          'is hard to miss: nobody asked for more features. They asked for '
          'fewer decisions. Wrote up what we learned.',
      reactions: 236,
      comments: 31,
    ),
    ProfilePost(
      time: '3w',
      text:
          'Slides from “Calm by default: designing for focus” at Config '
          'Nordics are up. Thank you to everyone who stayed for the '
          'questions.',
      reactions: 418,
      comments: 27,
      image: DemoAssets.photoConferenceStage,
      imageLabel: 'A speaker on a conference stage',
    ),
  ];

  static const activity = [
    ProfileActivity(
      icon: PhosphorIconsRegular.chatCircle,
      verb: 'Commented on',
      person: People.omar,
      detail:
          '“The flow map is what made it click for the team. Keeping this '
          'one.”',
      time: '3h',
    ),
    ProfileActivity(
      icon: PhosphorIconsRegular.heart,
      verb: 'Reacted to',
      person: People.aisha,
      detail: 'A checklist for accessible onboarding flows',
      time: '1d',
    ),
    ProfileActivity(
      icon: PhosphorIconsRegular.repeat,
      verb: 'Reposted',
      person: People.julian,
      detail: 'Notes from the main stage at Config Nordics',
      time: '4d',
    ),
    ProfileActivity(
      icon: PhosphorIconsRegular.chatCircle,
      verb: 'Commented on',
      person: People.sara,
      detail:
          '“Weekly sessions beat a quarterly study every time. Happy to '
          'share our script.”',
      time: '1w',
    ),
  ];

  static const media = [
    ProfileMedia(
      DemoAssets.photoConferenceStage,
      'A speaker on a conference stage',
    ),
    ProfileMedia(
      DemoAssets.photoWorkshopTeam,
      'A team at a whiteboard during a workshop',
    ),
    ProfileMedia(DemoAssets.photoAlpineLake, 'A lake under alpine peaks'),
    ProfileMedia(
      DemoAssets.photoWhiteboardUserFlow,
      'A whiteboard with a mapped user flow',
    ),
    ProfileMedia(
      DemoAssets.photoWhiteboardFlowSketches,
      'Flow sketches on a whiteboard',
    ),
    ProfileMedia(
      DemoAssets.storyConferenceAudience,
      'The audience at a conference',
    ),
    ProfileMedia(
      DemoAssets.storyMountainMeadow,
      'A meadow under a mountain',
    ),
    ProfileMedia(
      DemoAssets.storyOfficeLounge,
      'An office lounge with plants',
    ),
    ProfileMedia(DemoAssets.photoCoverMountainLake, coverLabel),
  ];

  /// Every image the screen can show, for precaching.
  static List<String> get images => [
    person.avatar,
    DemoAssets.photoCoverMountainLake,
    for (final mutual in mutuals) mutual.avatar,
    for (final item in featured) item.image,
    for (final entry in experience) entry.company.logo,
    for (final entry in education) entry.school.logo,
    for (final suggestion in suggestions) suggestion.person.avatar,
    for (final group in groups) group.logo,
    for (final item in activity) item.person.avatar,
    for (final item in media) item.image,
  ];
}
