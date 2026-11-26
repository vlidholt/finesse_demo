import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/jobs_state.dart';

/// Opens "All filters": every filter of the Jobs search as a switch. They
/// are the chips' own state, so a switch flipped here selects its chip.
Future<void> showJobFiltersDialog(BuildContext context, JobsState state) {
  return showDialog<void>(
    context: context,
    builder: (context) => ListenableBuilder(
      listenable: state,
      builder: (context, _) => Dialog(
        title: const Text('All filters'),
        description: const Text('Narrow the results to roles that fit.'),
        style: DialogTheme(constraints: const BoxConstraints(maxWidth: 440)),
        scrollable: true,
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Show results'),
          ),
        ],
        child: UnaColumn(
          gap: GapSize.md,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final filter in JobsData.filters)
              // One semantic node a row: the visible label names the
              // switch, and is read once.
              MergeSemantics(
                child: Row(
                  children: [
                    if (filter.icon case final icon?) ...[
                      PhosphorIcon(
                        icon,
                        size: Theme.of(context).glyph,
                        color: Theme.of(context).colorScheme.mutedForeground,
                      ),
                      const Gap.sm(),
                    ],
                    Expanded(child: Text(filter.label)),
                    Switch(
                      value: state.isFilterOn(filter),
                      onChanged: (_) => state.toggleFilter(filter),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
