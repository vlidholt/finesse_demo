import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/settings_controller.dart';
import 'package:una_demo/widgets/settings_sections.dart';

/// Demo's settings: a full-screen route the avatar menu's "Settings"
/// opens (`openSettings`), with four pages — Account, Privacy,
/// Notifications and Appearance.
///
/// * **Wide** — the pages as rows in a card beside the selected page's
///   cards.
/// * **Narrow, and a phone** — the pages as a strip of chips over them.
///
/// Light or dark and the text size on the Appearance page are real and
/// drive the whole app. Everything else is a
/// mock preference held by the session's `SettingsController`, so the page
/// reads the same when it is opened again; nothing is persisted. It is
/// built from the package's form controls as they come.
///
/// The two arrangements put the selected page under different parents — a
/// row beside the rail, a column under the chips — so the page is held by
/// a `GlobalKey` and moves from one to the other with its state: a name
/// half typed into the profile form is still there, unsaved, after the
/// window is resized.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  /// Capped narrower than the app's pages: forms read badly across 1280.
  static const _maxWidth = 1040.0;
  static const _railWidth = 260.0;

  /// The content width from which the pages are a rail beside the cards.
  static const _railFrom = 760.0;

  static const _icons = {
    SettingsSection.account: PhosphorIconsRegular.userCircle,
    SettingsSection.privacy: PhosphorIconsRegular.lockSimple,
    SettingsSection.notifications: PhosphorIconsRegular.bell,
    SettingsSection.appearance: PhosphorIconsRegular.palette,
  };

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// Keeps the page's element — its text controllers, its focus — when the
  /// layout around it changes shape.
  final _pageKey = GlobalKey(debugLabel: 'Settings page');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = context.demo.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: PageContainer(
        scrollable: true,
        maxWidth: SettingsScreen._maxWidth,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => LayoutBuilder(
            builder: (context, constraints) {
              void select(SettingsSection section) =>
                  settings.update(() => settings.section = section);

              final page = KeyedSubtree(
                key: _pageKey,
                child: SettingsSectionView(
                  // A page's fields keep no state from another page's.
                  key: ValueKey(settings.section),
                  section: settings.section,
                  settings: settings,
                ),
              );

              if (constraints.maxWidth >= SettingsScreen._railFrom) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.gap(GapSize.xl),
                  children: [
                    SizedBox(
                      width: SettingsScreen._railWidth,
                      child: _SectionRail(
                        selected: settings.section,
                        onSelected: select,
                      ),
                    ),
                    Expanded(child: page),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: theme.gap(GapSize.md),
                children: [
                  // One page at a time, on a row that scrolls and fades at
                  // the edge it continues beyond.
                  ChipGroup<SettingsSection>(
                    semanticLabel: 'Settings pages',
                    wrap: false,
                    allowDeselection: false,
                    value: settings.section,
                    onChanged: (section) => select(section!),
                    items: [
                      for (final section in SettingsSection.values)
                        ChipGroupItem(
                          value: section,
                          leading: PhosphorIcon(
                            SettingsScreen._icons[section],
                          ),
                          label: Text(section.label),
                        ),
                    ],
                  ),
                  page,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The pages as rows in a card: the Network screen's "Manage my network".
class _SectionRail extends StatelessWidget {
  const _SectionRail({required this.selected, required this.onSelected});

  final SettingsSection selected;
  final ValueChanged<SettingsSection> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      style: CardTheme(padding: EdgeInsets.all(theme.gap(GapSize.sm))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in SettingsSection.values)
            Semantics(
              selected: section == selected,
              child: Button(
                style: ButtonTheme(
                  pressScale: 1,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.gap(GapSize.sm),
                  ),
                  gap: theme.gap(GapSize.sm),
                  mainAxisAlignment: MainAxisAlignment.start,
                  foregroundColor: section == selected
                      ? scheme.tint
                      : scheme.foregroundSubtle,
                ),
                variant: section == selected
                    ? ButtonVariant.secondary
                    : ButtonVariant.ghost,
                leading: PhosphorIcon(SettingsScreen._icons[section]),
                onPressed: () => onSelected(section),
                child: Expanded(
                  child: Text(
                    section.label,
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
