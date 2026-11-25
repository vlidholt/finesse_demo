import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/widgets/jobs_filters_dialog.dart';
import 'package:finesse_demo/widgets/jobs_state.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The search box at the top of the Jobs screen.
///
/// On a desktop it is a card: the two fields and the Search button in a row,
/// a full-bleed divider, then the filter chips. On a phone it is a small
/// glass panel with the two fields stacked and no chips.
class JobsSearchCard extends StatelessWidget {
  const JobsSearchCard({
    required this.state,
    required this.titleController,
    required this.locationController,
    super.key,
  });

  final JobsState state;
  final TextEditingController titleController;
  final TextEditingController locationController;

  void _search() => state.search(titleController.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = theme.layoutTheme;
    final mobile = theme.formFactor == FormFactor.mobile;

    final title = _SearchInput(
      controller: titleController,
      label: 'Job title',
      placeholder: JobsData.titlePlaceholder,
      icon: PhosphorIconsRegular.magnifyingGlass,
      tall: !mobile,
      onSubmitted: _search,
    );
    final location = _SearchInput(
      controller: locationController,
      label: 'Location',
      placeholder: JobsData.locationPlaceholder,
      icon: PhosphorIconsRegular.mapPin,
      tall: !mobile,
      onSubmitted: _search,
    );

    if (mobile) {
      return Glass(
        // In the page's flow, on the flat page: nothing to blur.
        frosted: false,
        borderRadius: theme.radii.xl2,
        // Tighter than a card: the panel is little more than a frame
        // around the two fields.
        padding: EdgeInsets.all(theme.gap(GapSize.sm)),
        shadows: theme.cardTheme.shadows ?? const [],
        child: FinesseColumn(
          gap: GapSize.sm,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [title, location],
        ),
      );
    }

    final inset = layout.gap(GapSize.lg);
    return Card(
      style: CardTheme(
        padding: EdgeInsets.zero,
        borderRadius: theme.radii.xl3,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(inset),
            child: Row(
              spacing: theme.gap(GapSize.sm),
              children: [
                Expanded(flex: 7, child: title),
                Expanded(flex: 5, child: location),
                Button(
                  size: ButtonSize.lg,
                  style: ButtonTheme(
                    // As tall as the fields beside it, and a step rounder.
                    decoration: theme.buttonDecoration(radius: theme.radii.lg),
                  ),
                  leading: const PhosphorIcon(
                    PhosphorIconsRegular.magnifyingGlass,
                  ),
                  onPressed: _search,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
          const Divider(margin: EdgeInsets.zero),
          Padding(
            padding: EdgeInsets.fromLTRB(
              inset,
              theme.gap(GapSize.md),
              inset,
              inset,
            ),
            child: JobsFilterChips(state: state),
          ),
        ],
      ),
    );
  }
}

/// One of the two search fields: a solid card-coloured box rather than the
/// theme's muted field fill, because it already sits on a tinted surface.
class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.label,
    required this.placeholder,
    required this.icon,
    required this.tall,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String placeholder;
  final IconData icon;
  final bool tall;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // The desktop's hero fields are as tall as the large button beside
    // them; a phone keeps the theme's field height.
    final tallHeight = theme.buttonSizesTheme.lg?.height;
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSubmitted(),
        constraints: tall && tallHeight != null
            ? BoxConstraints(minHeight: tallHeight)
            : null,
        decoration: FinesseDecoration(color: colors.card),
        placeholder: Text(
          placeholder,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: PhosphorIcon(
          icon,
          size: theme.glyph,
          color: colors.mutedForeground,
        ),
      ),
    );
  }
}

/// The filter chips of the Jobs search, a `ChipGroup` of the filters with
/// the "All filters" chip, which opens every one of them as a switch, as
/// its action.
///
/// Under the desktop search fields they wrap, with "All filters" at the
/// end of the first row ([JobsFilterChips.new]). On a phone they are one
/// row that scrolls sideways under the search panel, with "All filters"
/// held at the start and the chips running out to the screen's edge
/// ([JobsFilterChips.bar]): give it the page's margin as [margin], and no
/// padding of its own around it.
class JobsFilterChips extends StatelessWidget {
  const JobsFilterChips({required this.state, super.key})
    : scrolls = false,
      margin = EdgeInsets.zero;

  /// The phone's scrolling filter bar.
  const JobsFilterChips.bar({
    required this.state,
    required this.margin,
    super.key,
  }) : scrolls = true;

  final JobsState state;

  /// Whether the chips are one row that scrolls, rather than wrapping.
  final bool scrolls;

  /// The page margin the bar's ends line up with: the "All filters" chip
  /// stands inside the start margin, and the chips scroll to the end of the
  /// screen through the end one.
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final start = rtl ? margin.right : margin.left;
    final end = rtl ? margin.left : margin.right;
    final allFilters = Chip(
      label: Text(scrolls ? 'Filters' : 'All filters'),
      leading: const PhosphorIcon(PhosphorIconsRegular.slidersHorizontal),
      semanticLabel: 'All filters',
      onPressed: () => showJobFiltersDialog(context, state),
    );
    final group = ChipGroup<String>.multiple(
      semanticLabel: 'Job filters',
      wrap: !scrolls,
      values: state.filters,
      onValuesChanged: state.setFilters,
      padding: scrolls ? EdgeInsetsDirectional.only(end: end) : EdgeInsets.zero,
      // Held at the start of the phone's bar while the chips scroll past
      // it; at the end of the first row when they wrap, however many rows
      // that is.
      leading: scrolls ? allFilters : null,
      trailing: scrolls ? null : allFilters,
      items: [
        for (final filter in JobsData.filters)
          ChipGroupItem(
            value: filter.label,
            label: Text(filter.label),
            leading: filter.icon == null ? null : PhosphorIcon(filter.icon),
          ),
      ],
    );
    if (!scrolls) return group;
    return Padding(
      padding: EdgeInsetsDirectional.only(start: start),
      child: group,
    );
  }
}
