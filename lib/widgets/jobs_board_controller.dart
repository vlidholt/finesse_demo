import 'package:flutter/foundation.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/applications_data.dart';
import 'package:una_demo/data/jobs_data.dart';

/// How a column of the board can be ordered from its menu.
enum ApplicationSort { updated, company }

/// The applications on the board, by stage.
///
/// The `Board` only reports what the user did; this is where a move is
/// carried out. It is a [ChangeNotifier] in the `DemoSession`, so the
/// board keeps its state while the screen shows "Find jobs", a listing
/// saved or applied to over there turns up here, and the summary tiles and
/// the "Saved items" sheet count the same columns.
class ApplicationsController extends ChangeNotifier {
  final Map<ApplicationStage, List<JobApplication>> _stages = {
    for (final stage in ApplicationStage.values)
      stage: [...?ApplicationsData.initial[stage]],
  };

  final List<JobApplication> _suggestions = [...ApplicationsData.suggestions];

  /// The applications at [stage], first on top.
  List<JobApplication> at(ApplicationStage stage) => _stages[stage]!;

  /// Whether "Add from job alerts" has anything left to add.
  bool get hasSuggestions => _suggestions.isNotEmpty;

  ApplicationStage? stageOf(String id) {
    for (final MapEntry(key: stage, value: list) in _stages.entries) {
      if (list.any((application) => application.id == id)) return stage;
    }
    return null;
  }

  /// Carries out a move the board asked for. A card that changes stage
  /// takes that stage's status line.
  void move(BoardMove<JobApplication> move) {
    final from = move.fromColumn as ApplicationStage;
    final to = move.toColumn as ApplicationStage;
    final application = _stages[from]!.removeAt(move.fromIndex);
    _stages[to]!.insert(
      move.toIndex.clamp(0, _stages[to]!.length),
      from == to ? application : application.movedTo(to),
    );
    notifyListeners();
  }

  /// Puts the next role from the user's job alerts on top of "Saved".
  void addSuggestion() {
    if (_suggestions.isEmpty) return;
    _stages[ApplicationStage.saved]!.insert(0, _suggestions.removeAt(0));
    notifyListeners();
  }

  void sort(ApplicationStage stage, ApplicationSort order) {
    _stages[stage]!.sort(
      (a, b) => switch (order) {
        ApplicationSort.updated => a.updatedHoursAgo.compareTo(
          b.updatedHoursAgo,
        ),
        ApplicationSort.company => a.company.name.compareTo(b.company.name),
      },
    );
    notifyListeners();
  }

  /// Moves every application at [stage] to the archive, and returns what
  /// [restore] needs to take it back.
  ApplicationsSnapshot archiveAll(ApplicationStage stage) {
    final snapshot = _snapshot();
    if (stage == ApplicationStage.archived) return snapshot;
    final list = _stages[stage]!;
    _stages[ApplicationStage.archived]!.insertAll(0, [
      for (final application in list)
        application.movedTo(ApplicationStage.archived),
    ]);
    list.clear();
    notifyListeners();
    return snapshot;
  }

  /// Empties the archive, and returns what [restore] needs to take it back.
  ApplicationsSnapshot clearArchive() {
    final snapshot = _snapshot();
    if (_stages[ApplicationStage.archived]!.isEmpty) return snapshot;
    _stages[ApplicationStage.archived]!.clear();
    notifyListeners();
    return snapshot;
  }

  /// Puts every column back as it was when [snapshot] was taken: the
  /// "Undo" of [archiveAll] and [clearArchive].
  void restore(ApplicationsSnapshot snapshot) {
    for (final MapEntry(key: stage, value: list) in snapshot._stages.entries) {
      _stages[stage]!
        ..clear()
        ..addAll(list);
    }
    notifyListeners();
  }

  ApplicationsSnapshot _snapshot() => ApplicationsSnapshot._({
    for (final MapEntry(key: stage, value: list) in _stages.entries)
      stage: List.unmodifiable(list),
  });

  /// What [track] was last told about each listing: (saved, applied).
  final Map<String, (bool, bool)> _tracked = {};

  /// Tells the board what the "Find jobs" side now says about [job].
  ///
  /// The board acts on what *changed* since the last call for the same
  /// listing, and on nothing else: newly applied to, the card goes under
  /// "Applied"; newly saved, under "Saved"; no longer saved, it leaves
  /// "Saved". A call that repeats what the board already knew does
  /// nothing, so the caller can report every listing whenever anything
  /// about the screen changes without undoing what the user has done to
  /// the board since — a card dragged back to "Saved", or cleared from the
  /// archive, stays where the user put it.
  void track(Job job, {required bool saved, required bool applied}) {
    final (wasSaved, wasApplied) = _tracked[job.id] ?? (false, false);
    if (saved == wasSaved && applied == wasApplied) return;
    _tracked[job.id] = (saved, applied);

    final stage = stageOf(job.id);
    if (applied && !wasApplied) {
      // Applying moves the card along from "Saved"; further along, or in
      // the archive, the user has already said where it belongs.
      if (stage == null || stage == ApplicationStage.saved) {
        _stages[ApplicationStage.saved]!.removeWhere((a) => a.id == job.id);
        _stages[ApplicationStage.applied]!.insert(
          0,
          ApplicationsData.fromJob(job, applied: true),
        );
        notifyListeners();
      }
    } else if (saved && !wasSaved) {
      if (stage == null) {
        _stages[applied ? ApplicationStage.applied : ApplicationStage.saved]!
            .insert(0, ApplicationsData.fromJob(job, applied: applied));
        notifyListeners();
      }
    } else if (!saved && wasSaved) {
      // An application the user moved back to "Saved" is not a bookmark.
      if (stage == ApplicationStage.saved && !applied) {
        _stages[ApplicationStage.saved]!.removeWhere((a) => a.id == job.id);
        notifyListeners();
      }
    }
  }
}

/// The board as it was a moment ago, for an "Undo".
@immutable
class ApplicationsSnapshot {
  const ApplicationsSnapshot._(this._stages);

  final Map<ApplicationStage, List<JobApplication>> _stages;
}
