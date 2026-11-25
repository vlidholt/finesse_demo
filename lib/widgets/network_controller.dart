import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/network_data.dart';
import 'package:flutter/foundation.dart';

/// The orders the Connections list offers.
enum ConnectionSort {
  recent('Recently added'),
  name('First name');

  const ConnectionSort(this.label);

  final String label;
}

/// What the user has done on the Network screen since the app started:
/// invitations answered, requests sent, events and groups joined, pages
/// followed.
///
/// It is part of the `DemoSession` rather than the screen's own state so
/// that a request sent from somewhere else — a search result, a profile
/// preview — shows as pending here too. Nothing is persisted.
class NetworkController extends ChangeNotifier {
  NetworkController()
    : _attending = {
        for (final event in NetworkData.events)
          if (event.attending) event.id,
      },
      _joined = {
        for (final group in NetworkData.groups)
          if (group.joined) group.name,
      },
      _pages = {
        for (final page in NetworkData.pages)
          if (page.following) page.company.name,
      },
      _following = {
        for (final entry in NetworkData.following) entry.person.name,
      };

  NetworkSection _section = NetworkSection.grow;
  ConnectionSort _sort = ConnectionSort.recent;

  final _accepted = <String>[];
  final _ignored = <String>{};
  final _requested = <String>{};
  final _dismissed = <String>{};
  final Set<String> _attending;
  final Set<String> _joined;
  final Set<String> _pages;
  final Set<String> _following;

  /// The list the desktop's main column shows.
  NetworkSection get section => _section;
  set section(NetworkSection value) {
    if (_section == value) return;
    _section = value;
    notifyListeners();
  }

  ConnectionSort get sort => _sort;
  set sort(ConnectionSort value) {
    if (_sort == value) return;
    _sort = value;
    notifyListeners();
  }

  // Invitations.

  /// The invitations still waiting for an answer.
  List<Invitation> get pending => [
    for (final invitation in NetworkData.invitations)
      if (!_accepted.contains(invitation.person.name) &&
          !_ignored.contains(invitation.person.name))
        invitation,
  ];

  /// Accepts [invitation] — also one that was ignored before: the
  /// notification about it still offers "Accept".
  void accept(Invitation invitation) {
    final name = invitation.person.name;
    if (_accepted.contains(name)) return;
    _accepted.add(name);
    _ignored.remove(name);
    notifyListeners();
  }

  void ignore(Invitation invitation) {
    if (_ignored.add(invitation.person.name)) notifyListeners();
  }

  /// The "Undo" of the toast that follows [accept]: the invitation is
  /// waiting for an answer again.
  void undoAccept(Invitation invitation) {
    if (_accepted.remove(invitation.person.name)) notifyListeners();
  }

  /// The "Undo" of the toast that follows [ignore].
  ///
  /// Each undo takes back its own answer and nothing else: the toast stays
  /// up for a few seconds, and the invitation may have been accepted from
  /// its notification in the meantime. Undoing the *ignore* must not undo
  /// that.
  void undoIgnore(Invitation invitation) {
    if (_ignored.remove(invitation.person.name)) notifyListeners();
  }

  // Connections.

  /// Whether [person] is a connection — from the start, or by an invitation
  /// accepted since.
  bool isConnected(Person person) =>
      _accepted.contains(person.name) ||
      NetworkData.connections.any((entry) => entry.person == person);

  /// The Connections list: accepted invitations first when sorted by
  /// recency, then the connections the screen opens with.
  List<Connection> get connections {
    final list = [
      for (final name in _accepted.reversed)
        Connection(
          NetworkData.invitations
              .firstWhere((invitation) => invitation.person.name == name)
              .person,
          'Connected just now',
          monthsAgo: 0,
        ),
      ...NetworkData.connections,
    ];
    if (_sort == ConnectionSort.name) {
      list.sort((a, b) => a.person.name.compareTo(b.person.name));
    }
    return list;
  }

  int get connectionCount => NetworkData.connectionCount + _accepted.length;

  // Suggestions.

  /// The people the grid still suggests.
  List<NetworkSuggestion> get suggestions => [
    for (final suggestion in NetworkData.suggestions)
      if (!_dismissed.contains(suggestion.person.name)) suggestion,
  ];

  /// Whether a request to connect with [person] is waiting for an answer.
  bool isRequested(Person person) => _requested.contains(person.name);

  void toggleRequest(Person person) => _toggle(_requested, person.name);

  void dismiss(NetworkSuggestion suggestion) {
    if (_dismissed.add(suggestion.person.name)) notifyListeners();
  }

  // Following, pages, groups and events.

  bool isFollowing(Person person) => _following.contains(person.name);

  void toggleFollowing(Person person) => _toggle(_following, person.name);

  int get followingCount =>
      NetworkData.followingCount -
      NetworkData.following.length +
      _following.length;

  bool isFollowingPage(Company company) => _pages.contains(company.name);

  void togglePage(Company company) => _toggle(_pages, company.name);

  int get pageCount => _pages.length;

  bool hasJoined(NetworkGroup group) => _joined.contains(group.name);

  void toggleJoined(NetworkGroup group) => _toggle(_joined, group.name);

  int get groupCount => _joined.length;

  bool isAttending(NetworkEvent event) => _attending.contains(event.id);

  void toggleAttending(NetworkEvent event) => _toggle(_attending, event.id);

  int get eventCount => _attending.length;

  /// Everyone going to [event], the user included.
  int attendeesOf(NetworkEvent event) =>
      event.attendees +
      (isAttending(event) ? 1 : 0) -
      (event.attending ? 1 : 0);

  /// The figure beside a "Manage my network" row.
  int countOf(NetworkSection section) => switch (section) {
    NetworkSection.grow => pending.length,
    NetworkSection.connections => connectionCount,
    NetworkSection.following => followingCount,
    NetworkSection.groups => groupCount,
    NetworkSection.events => eventCount,
    NetworkSection.pages => pageCount,
  };

  void _toggle(Set<String> set, String value) {
    if (!set.remove(value)) set.add(value);
    notifyListeners();
  }
}
