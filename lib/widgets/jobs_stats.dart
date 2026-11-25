import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/data/applications_data.dart';
import 'package:finesse_demo/widgets/jobs_board_controller.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The four summary tiles: one row while each tile has room for its label,
/// two rows of two below that.
///
/// The first two count the "Saved" and "Applied" columns of the board, so
/// they move with everything that moves a card: saving or applying to a
/// listing, a drag, "Add from job alerts", "Archive all".
class JobsStats extends StatelessWidget {
  const JobsStats({required this.applications, super.key});

  final ApplicationsController applications;

  /// Under this width four tiles in a row truncate their labels.
  static const _singleRowMinWidth = 960.0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: applications,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    Widget tile(JobStat stat, [int? value]) => Expanded(
      child: StatTile(
        icon: PhosphorIcon(stat.icon),
        value: Text('${value ?? stat.value}'),
        label: Text(stat.label),
      ),
    );

    final tiles = [
      tile(
        JobsData.savedJobs,
        applications.at(ApplicationStage.saved).length,
      ),
      tile(
        JobsData.applicationsSent,
        applications.at(ApplicationStage.applied).length,
      ),
      tile(JobsData.interviews),
      tile(JobsData.profileViews),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _singleRowMinWidth) {
          return FinesseRow(gap: GapSize.md, children: tiles);
        }
        return FinesseColumn(
          gap: GapSize.md,
          mainAxisSize: MainAxisSize.min,
          children: [
            FinesseRow(gap: GapSize.md, children: tiles.sublist(0, 2)),
            FinesseRow(gap: GapSize.md, children: tiles.sublist(2)),
          ],
        );
      },
    );
  }
}
