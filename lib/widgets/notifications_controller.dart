import 'package:flutter/foundation.dart';
import 'package:una_demo/data/notifications_data.dart';

/// The state of the Notifications screen: the selected tab, and what has
/// been read, removed or answered since the app started.
///
/// It is part of the `DemoSession`, above the shell, because the shell's
/// bell shows [unreadCount]. Nothing is persisted.
class NotificationsController extends ChangeNotifier {
  NotificationsController({this.notifications = NotificationsData.all})
    : _unread = {
        for (final notification in notifications)
          if (notification.unread) notification.id,
      };

  /// Every notification, newest first.
  final List<DemoNotification> notifications;

  final Set<String> _unread;
  final _removed = <String>{};
  final _answered = <String>{};
  NotificationFilter _filter = NotificationFilter.all;

  NotificationFilter get filter => _filter;
  set filter(NotificationFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  /// How many notifications are unread: the number on the bell.
  int get unreadCount => _unread.length;

  /// How many unread notifications [filter] lists.
  int unreadIn(NotificationFilter filter) => notifications
      .where((n) => _unread.contains(n.id) && _matches(n, filter))
      .length;

  bool isUnread(DemoNotification notification) =>
      _unread.contains(notification.id);

  /// Whether the row's button has been pressed.
  bool isAnswered(DemoNotification notification) =>
      _answered.contains(notification.id);

  /// The notifications of the selected tab, under their headings; a period
  /// with nothing in it is left out.
  List<(NotificationPeriod, List<DemoNotification>)> get groups => [
    for (final period in NotificationPeriod.values)
      if ([
            for (final notification in notifications)
              if (notification.period == period &&
                  !_removed.contains(notification.id) &&
                  _matches(notification, _filter))
                notification,
          ]
          case final list when list.isNotEmpty)
        (period, list),
  ];

  bool _matches(DemoNotification notification, NotificationFilter filter) =>
      !_removed.contains(notification.id) &&
      (filter == NotificationFilter.all || notification.kind.filter == filter);

  void markRead(DemoNotification notification) {
    if (_unread.remove(notification.id)) notifyListeners();
  }

  void toggleRead(DemoNotification notification) {
    if (!_unread.remove(notification.id)) _unread.add(notification.id);
    notifyListeners();
  }

  void markAllRead() {
    if (_unread.isEmpty) return;
    _unread.clear();
    notifyListeners();
  }

  /// Marks the row's button as pressed, and the row as read.
  void answer(DemoNotification notification) {
    final changed = _answered.add(notification.id);
    if (_unread.remove(notification.id) || changed) notifyListeners();
  }

  void remove(DemoNotification notification) {
    if (!_removed.add(notification.id)) return;
    _unread.remove(notification.id);
    notifyListeners();
  }

  /// Puts a removed notification back: the toast's "Undo".
  void restore(DemoNotification notification, {required bool unread}) {
    if (!_removed.remove(notification.id)) return;
    if (unread) _unread.add(notification.id);
    notifyListeners();
  }
}
