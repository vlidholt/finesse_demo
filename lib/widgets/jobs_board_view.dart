import 'package:disco/disco.dart';
import 'package:finesse_demo/data/applications_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// The two sides of the Jobs destination.
enum JobsView {
  /// The designed screen: search, summary tiles, results and a listing.
  find(ApplicationsData.findTab),

  /// The board of the user's own applications.
  applications(ApplicationsData.boardTab);

  const JobsView(this.label);

  final String label;
}

/// Which side of Jobs is showing.
///
/// Provided above the whole app beside `demoDestinationProvider`, so any
/// screen can open the board:
///
/// ```dart
/// context.openApplications();
/// ```
final jobsViewProvider = Provider((_) => Signal(JobsView.find));

/// Shortcuts to the Jobs destination's two sides.
extension JobsNavigation on BuildContext {
  /// Switches the Demo shell to Jobs, showing the "My applications"
  /// board.
  void openApplications() {
    jobsViewProvider.of(this).value = JobsView.applications;
    goTo(DemoDestination.jobs);
  }
}

/// The switch at the top of Jobs: "Find jobs" / "My applications".
///
/// On a desktop it hugs its two labels; on a phone it fills the width, and
/// a label that does not fit its half — a wide font, a large text size —
/// shrinks to it (`DemoTabLabel`).
class JobsViewSwitch extends StatelessWidget {
  const JobsViewSwitch({
    required this.view,
    required this.onChanged,
    super.key,
  });

  final JobsView view;
  final ValueChanged<JobsView> onChanged;

  @override
  Widget build(BuildContext context) {
    final mobile = Theme.of(context).formFactor == FormFactor.mobile;
    return Semantics(
      label: 'Jobs view',
      container: true,
      child: Tabs<JobsView>(
        value: view,
        expandTabs: mobile,
        onChanged: onChanged,
        tabs: [
          for (final view in JobsView.values)
            Tab(value: view, child: DemoTabLabel(view.label)),
        ],
      ),
    );
  }
}
