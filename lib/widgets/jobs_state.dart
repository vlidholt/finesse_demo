import 'package:flutter/foundation.dart';
import 'package:una_demo/data/jobs_data.dart';

/// What the "Find jobs" side remembers: the selected listing, the
/// switched-on filters, and what has been saved, followed and applied to.
///
/// It is a [ChangeNotifier] in the `DemoSession` rather than `setState`
/// in the screen because the detail pane is also shown on a pushed route,
/// which has to see — and change — the same saved and followed sets as the
/// list underneath it, and because a saved or applied-to listing is a card
/// on the board (`ApplicationsController`), which the summary tiles and
/// the "Saved items" sheet count.
class JobsState extends ChangeNotifier {
  Job _selected = JobsData.jobs.first;
  JobSort _sort = JobSort.relevant;
  String _query = JobsData.titleQuery;
  bool _alerts = false;

  final Set<String> _filters = {...JobsData.initialFilters};
  final Set<String> _saved = {};
  final Set<String> _applied = {};
  final Set<String> _followed = {};

  /// The listing the detail pane shows.
  Job get selected => _selected;

  JobSort get sort => _sort;

  /// The title the results were last searched for.
  String get query => _query;

  /// Whether job alerts are switched on.
  bool get alerts => _alerts;

  /// The results in the current order.
  List<Job> get jobs => switch (_sort) {
    JobSort.relevant => JobsData.jobs,
    JobSort.recent => [
      ...JobsData.jobs,
    ]..sort((a, b) => a.postedHoursAgo.compareTo(b.postedHoursAgo)),
    JobSort.salary => [
      ...JobsData.jobs,
    ]..sort((a, b) => b.salaryCeiling.compareTo(a.salaryCeiling)),
  };

  /// The labels of the switched-on filters.
  Set<String> get filters => Set.unmodifiable(_filters);

  /// Switches on exactly the filters labelled [labels]: what a tap in the
  /// filter chips reports.
  void setFilters(Set<String> labels) {
    if (setEquals(labels, _filters)) return;
    _filters
      ..clear()
      ..addAll(labels);
    notifyListeners();
  }

  bool isFilterOn(JobFilter filter) => _filters.contains(filter.label);
  bool isSaved(Job job) => _saved.contains(job.id);
  bool hasApplied(Job job) => _applied.contains(job.id);
  bool isFollowing(Job job) => _followed.contains(job.company.name);

  void select(Job job) {
    if (_selected == job) return;
    _selected = job;
    notifyListeners();
  }

  void setSort(JobSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  /// Records [title] as the searched-for query; a blank one is ignored.
  void search(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed == _query) return;
    _query = trimmed;
    notifyListeners();
  }

  void toggleAlerts() {
    _alerts = !_alerts;
    notifyListeners();
  }

  void toggleFilter(JobFilter filter) => _toggle(_filters, filter.label);
  void toggleSaved(Job job) => _toggle(_saved, job.id);
  void toggleFollowing(Job job) => _toggle(_followed, job.company.name);

  void apply(Job job) {
    if (_applied.add(job.id)) notifyListeners();
  }

  void _toggle(Set<String> set, String value) {
    if (!set.remove(value)) set.add(value);
    notifyListeners();
  }
}
