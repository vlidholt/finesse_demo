import 'package:finesse_demo/data/search_data.dart';
import 'package:flutter/foundation.dart';

/// The searches the user has run since the app started, newest first.
///
/// Part of the `DemoSession`, so the desktop's app-bar field and the
/// phone's search page list the same ones. Nothing is persisted.
class SearchHistory extends ChangeNotifier {
  SearchHistory() : _recents = [...SearchData.recents];

  /// How many recent searches are kept.
  static const limit = 6;

  final List<String> _recents;

  List<String> get recents => List.unmodifiable(_recents);

  /// Records [query] as the newest search; a blank one is ignored, and one
  /// that is already listed moves to the top.
  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    if (_recents.isNotEmpty && _recents.first == trimmed) return;
    _recents
      ..removeWhere((entry) => entry.toLowerCase() == trimmed.toLowerCase())
      ..insert(0, trimmed);
    if (_recents.length > limit) _recents.removeRange(limit, _recents.length);
    notifyListeners();
  }

  void remove(String query) {
    if (_recents.remove(query)) notifyListeners();
  }

  void clear() {
    if (_recents.isEmpty) return;
    _recents.clear();
    notifyListeners();
  }
}
