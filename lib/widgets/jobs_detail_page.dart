import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/jobs_detail.dart';
import 'package:una_demo/widgets/jobs_state.dart';

/// A job's detail as a page of its own: what a phone — or a window too
/// narrow for the two-pane layout — pushes when a job card is tapped.
///
/// ```dart
/// context.pushFullScreen<void>(
///   (context) => JobDetailPage(job: job, state: state, onMessage: ...),
/// );
/// ```
///
/// The app bar carries the back button, the company's name and the save and
/// share actions. On a phone "Easy Apply" and "Save" move into a glass bar
/// pinned to the bottom, so the call to action stays on screen while the
/// description scrolls.
class JobDetailPage extends StatelessWidget {
  const JobDetailPage({
    required this.job,
    required this.state,
    required this.onMessage,
    super.key,
  });

  final Job job;

  /// The Jobs screen's state: saving or following here shows in the list
  /// underneath.
  final JobsState state;

  final VoidCallback onMessage;

  /// The width the single column of detail stops growing at.
  static const _maxWidth = 720.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mobile = theme.formFactor == FormFactor.mobile;

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final saved = state.isSaved(job);
        return Scaffold(
          // The detail sits straight on the card colour: its tiles and
          // panels are washes that need a card under them.
          backgroundColor: colors.card,
          appBar: AppBar(
            title: Text(job.company.name),
            actionsGap: 0,
            actions: [
              IconButton(
                icon: PhosphorIcon(
                  saved
                      ? PhosphorIconsFill.bookmarkSimple
                      : PhosphorIconsRegular.bookmarkSimple,
                ),
                style: ButtonTheme(
                  foregroundColor: saved ? colors.tint : null,
                ),
                semanticLabel: saved ? 'Remove from saved jobs' : 'Save job',
                onPressed: () => state.toggleSaved(job),
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsRegular.export),
                semanticLabel: 'Share job',
                onPressed: () => copyLink(context, 'demo.app/jobs/${job.id}'),
              ),
            ],
          ),
          bottomNavigationBar: mobile
              ? _ApplyBar(job: job, state: state)
              : null,
          body: PageContainer(
            scrollable: true,
            maxWidth: _maxWidth,
            child: JobDetail(
              job: job,
              state: state,
              onMessage: onMessage,
              showHeaderActions: false,
              showActions: !mobile,
            ),
          ),
        );
      },
    );
  }
}

/// The bar at the bottom of the phone's detail page: the apply and save
/// buttons on the package's docked [Toolbar], inside the page margins. The
/// `Scaffold` measures it, so the page scrolls clear of it.
class _ApplyBar extends StatelessWidget {
  const _ApplyBar({required this.job, required this.state});

  final Job job;
  final JobsState state;

  @override
  Widget build(BuildContext context) {
    // The package's docked bar: glass on iOS and macOS, the style's bottom
    // bar elsewhere, clear of the home indicator. Docked, not floating:
    // the apply button takes the width the bar gives it.
    final theme = Theme.of(context);
    final side = (theme.layoutTheme.pagePadding ?? EdgeInsets.zero)
        .resolve(Directionality.of(context))
        .left;
    return Toolbar(
      floating: false,
      padding: EdgeInsets.fromLTRB(
        side,
        theme.layoutTheme.gap(GapSize.sm),
        side,
        theme.layoutTheme.gap(GapSize.sm),
      ),
      children: [
        Expanded(
          child: JobActions(job: job, state: state, expand: true),
        ),
      ],
    );
  }
}
