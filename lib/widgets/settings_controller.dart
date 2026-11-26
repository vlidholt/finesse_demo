import 'package:flutter/foundation.dart';
import 'package:una/una.dart' show TimeOfDay;
import 'package:una_demo/data.dart';
import 'package:una_demo/data/profile_data.dart';

/// The pages of the Settings screen.
enum SettingsSection {
  account('Account'),
  privacy('Privacy'),
  notifications('Notifications'),
  appearance('Appearance');

  const SettingsSection(this.label);

  final String label;
}

/// Who can see the profile.
enum ProfileVisibility {
  public('Public', 'Anyone on or off Demo'),
  members('Demo members', 'Only people who are signed in'),
  connections('Connections', 'Only people you are connected to');

  const ProfileVisibility(this.label, this.detail);

  final String label;
  final String detail;
}

/// Who may start a conversation.
enum MessagePolicy {
  anyone('Anyone on Demo'),
  secondDegree('Connections and their connections'),
  connections('Connections only');

  const MessagePolicy(this.label);

  final String label;
}

/// How often the summary email is sent.
enum DigestFrequency {
  daily('Every morning'),
  weekly('Once a week, on Monday'),
  never('Never');

  const DigestFrequency(this.label);

  final String label;
}

/// When videos in the feed start by themselves.
enum Autoplay {
  always('Always'),
  wifi('On Wi-Fi only'),
  never('Never');

  const Autoplay(this.label);

  final String label;
}

/// What the user lets Demo use what it knows about them for.
enum Personalisation {
  jobs('Suggest jobs from my activity', 'Roles like the ones you look at'),
  people(
    'Suggest people from my network',
    'Colleagues, classmates and friends of connections',
  ),
  research(
    'Invite me to research',
    'A few short studies a year about Demo itself',
  );

  const Personalisation(this.label, this.detail);

  final String label;
  final String detail;
}

/// A kind of activity the user can be told about, on two channels.
enum NotificationTopic {
  reactions('Reactions and comments', 'On your posts and articles'),
  mentions('Mentions', 'When someone tags you'),
  invitations('Invitations', 'Requests to connect and to join groups'),
  jobs('Job matches', 'New roles that fit your profile'),
  messages('Messages', 'New conversations and replies'),
  events('Events', 'Reminders for events you are going to');

  const NotificationTopic(this.label, this.detail);

  final String label;
  final String detail;
}

/// What the Settings screen has been set to since the app started.
///
/// Light or dark and the text size are not here: those two are real, and
/// live in the app's own state (`themeModeProvider`, `textScaleProvider`).
/// Everything else is a mock preference, kept for the session so the page
/// reads the same when it is opened again. Nothing is persisted.
class SettingsController extends ChangeNotifier {
  SettingsSection section = SettingsSection.account;

  // Account.
  String name = People.me.name;
  String headline = ProfileData.currentRole;
  String email = 'noor@noorhaddad.design';
  String language = ProfileData.language;
  bool twoStep = true;

  /// The skills listed on the profile, in the user's order.
  List<String> skills = [
    for (final skill in ProfileData.skills.take(ProfileData.mobileSkillCount))
      skill,
  ];

  /// Shown to connections on the day, without the year.
  DateTime? birthday = DateTime(1992, 3, 14);

  // Privacy.
  ProfileVisibility visibility = ProfileVisibility.public;
  MessagePolicy messages = MessagePolicy.secondDegree;
  bool showOnline = true;
  bool readReceipts = true;
  bool shareProfileViews = false;
  bool openToRecruitersOnly = true;
  final personalisation = <Personalisation>{
    Personalisation.jobs,
    Personalisation.people,
  };

  // Notifications.
  final push = <NotificationTopic>{
    NotificationTopic.reactions,
    NotificationTopic.mentions,
    NotificationTopic.invitations,
    NotificationTopic.messages,
    NotificationTopic.events,
  };
  final emailed = <NotificationTopic>{
    NotificationTopic.invitations,
    NotificationTopic.jobs,
  };
  DigestFrequency digest = DigestFrequency.weekly;

  /// The least a role has to match the profile, from .5 to 1, before a job
  /// notification is sent.
  double jobMatch = .8;
  bool pauseAll = false;

  /// The most job emails in a week; 0 is none.
  int jobEmailsPerWeek = 3;

  /// Nothing is pushed between [quietFrom] and [quietUntil] while this is
  /// on.
  bool quietHours = true;
  TimeOfDay quietFrom = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay quietUntil = const TimeOfDay(hour: 7, minute: 0);

  // Appearance.
  bool reduceMotion = false;
  bool compactFeed = false;
  Autoplay autoplay = Autoplay.wifi;

  /// The languages the profile can be shown in.
  static const languages = [
    'English',
    'Dansk',
    'Svenska',
    'Norsk bokmål',
    'Deutsch',
    'Français',
  ];

  /// Skills the field suggests while one is typed.
  static const skillSuggestions = ProfileData.skills;

  /// Applies [change] to the fields above and notifies listeners.
  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  void toggle(Set<NotificationTopic> channel, NotificationTopic topic) {
    if (!channel.remove(topic)) channel.add(topic);
    notifyListeners();
  }
}
