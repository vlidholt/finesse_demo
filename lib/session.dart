import 'package:disco/disco.dart';
import 'package:flutter/widgets.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/widgets/home_feed_scope.dart';
import 'package:una_demo/widgets/jobs_board_controller.dart';
import 'package:una_demo/widgets/jobs_state.dart';
import 'package:una_demo/widgets/messages_assistant.dart';
import 'package:una_demo/widgets/messages_controller.dart';
import 'package:una_demo/widgets/network_controller.dart';
import 'package:una_demo/widgets/notifications_controller.dart';
import 'package:una_demo/widgets/search_history.dart';
import 'package:una_demo/widgets/settings_controller.dart';

/// The state Demo's screens share for as long as the app runs: what has
/// been read, answered, requested, searched for and switched on.
///
/// A screen's own state stays in the screen. These are here instead
/// because more than one place shows them:
///
/// * [feed] — the composer is opened from the shell's bars on any screen,
///   and what it publishes is a post in the home feed.
/// * [notifications] — the shell's bell counts the unread ones.
/// * [messages] — the shell's Messages badge counts the conversations with
///   something unread, and a reply goes on arriving after the user has left
///   the Messages screen for another.
/// * [network] — an invitation can be accepted from a notification, and a
///   request to connect sent from a search result or a profile preview.
/// * [search] — the app-bar field and the search page list the same recent
///   searches.
/// * [settings] — the page is a pushed route, and has to read the same when
///   it is opened again.
/// * [jobs] and [applications] — the Jobs screen's two sides, its summary
///   tiles and the "Saved items" sheet all count the same saved jobs. A
///   listing saved or applied to in [jobs] is a card on the board that
///   [applications] holds.
///
/// Nothing is persisted.
class DemoSession {
  /// [replies] is how the other side of every conversation answers. A test
  /// passes its own, to decide what arrives and when.
  DemoSession({MessagesReplies replies = const MessagesReplies()})
    : messages = MessagesController(replies: replies) {
    jobs.addListener(_trackListings);
  }

  final feed = HomeFeedModel();
  final notifications = NotificationsController();
  final MessagesController messages;
  final network = NetworkController();
  final search = SearchHistory();
  final settings = SettingsController();
  final jobs = JobsState();
  final applications = ApplicationsController();

  /// What the navigation's badges count: it announces a change in either
  /// number, and nothing else the two controllers do.
  late final Listenable badges = Listenable.merge([
    notifications,
    messages.unreadCount,
  ]);

  /// [jobs] announces everything about the Jobs screen — a selection, a
  /// filter, the sort — and every listing is reported each time; the board
  /// acts only on a listing whose saved or applied state has changed (see
  /// [ApplicationsController.track]).
  void _trackListings() {
    for (final job in JobsData.jobs) {
      applications.track(
        job,
        saved: jobs.isSaved(job),
        applied: jobs.hasApplied(job),
      );
    }
  }

  void dispose() {
    jobs
      ..removeListener(_trackListings)
      ..dispose();
    applications.dispose();
    feed.dispose();
    notifications.dispose();
    messages.dispose();
    network.dispose();
    search.dispose();
    settings.dispose();
  }
}

/// The [DemoSession], provided above the whole app beside
/// `demoDestinationProvider` so that full-screen routes reach it too.
///
/// ```dart
/// final network = context.demo.network;
/// ```
final demoSessionProvider = Provider<DemoSession>(
  (_) => DemoSession(),
  dispose: (session) => session.dispose(),
);

/// Shorthand for the session.
extension DemoSessionContext on BuildContext {
  /// The [DemoSession] above this context.
  DemoSession get demo => demoSessionProvider.of(this);
}
