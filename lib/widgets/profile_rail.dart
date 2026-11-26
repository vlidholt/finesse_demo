import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/profile_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/profile_common.dart';

/// The title of a setting, a person or a group: body text, semibold.
TextStyle _rowTitleStyle(ThemeData theme) =>
    theme.textTheme.p.copyWith(fontWeight: FontWeight.w600);

/// "Profile language" and "Public profile and URL".
class ProfileSettingsCard extends StatelessWidget {
  const ProfileSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget setting(String title, String value, String editLabel) => ListTile(
      padding: EdgeInsets.zero,
      crossAxisAlignment: CrossAxisAlignment.start,
      titleStyle: _rowTitleStyle(theme),
      title: Text(title),
      subtitle: Text(value),
      trailing: ProfileHeaderAction(
        icon: PhosphorIconsRegular.pencilSimple,
        label: editLabel,
      ),
    );

    return Card(
      style: CardTheme(
        rowMainAxisSize: MainAxisSize.max,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.gap(GapSize.md),
        children: [
          setting('Profile language', ProfileData.language, 'Edit language'),
          const Divider(margin: EdgeInsets.zero),
          setting('Public profile and URL', ProfileData.publicUrl, 'Edit URL'),
        ],
      ),
    );
  }
}

/// "People also viewed": four people, each with a Follow, Message or
/// Connect button.
class ProfilePeopleCard extends StatelessWidget {
  const ProfilePeopleCard({
    required this.done,
    required this.onAction,
    super.key,
  });

  /// The people whose Follow or Connect button has been pressed.
  final Set<Person> done;

  /// Called with the row whose button was pressed.
  final ValueChanged<ProfileSuggestion> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ProfileSection(
      title: 'People also viewed',
      child: UnaColumn(
        gap: GapSize.lg,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final suggestion in ProfileData.suggestions)
            ListTile(
              padding: EdgeInsets.zero,
              crossAxisAlignment: CrossAxisAlignment.start,
              leading: PersonAvatar(
                suggestion.person,
              ),
              titleStyle: _rowTitleStyle(theme),
              title: Text(suggestion.person.name),
              subtitle: Text(suggestion.person.headline),
              subtitleMaxLines: 2,
              trailing: _ActionButton(
                suggestion.action,
                done: done.contains(suggestion.person),
                onPressed: () => onAction(suggestion),
              ),
            ),
        ],
      ),
    );
  }
}

/// The pill beside a suggested person.
class _ActionButton extends StatelessWidget {
  const _ActionButton(
    this.action, {
    required this.done,
    required this.onPressed,
  });

  final SuggestionAction action;
  final bool done;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = switch (action) {
      SuggestionAction.follow =>
        done ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
      SuggestionAction.message => PhosphorIconsRegular.paperPlaneTilt,
      SuggestionAction.connect =>
        done ? PhosphorIconsRegular.clock : PhosphorIconsRegular.userPlus,
    };
    return Button(
      style: ButtonTheme(
        pressScale: 1,
        // A pill, where the style's text buttons are rounded rectangles.
        decoration: theme.buttonDecoration(radius: theme.radii.full),
        textStyle: theme.textTheme.small,
      ),
      // Pressed, it fills in: "Following", "Pending".
      variant: done ? ButtonVariant.secondary : ButtonVariant.outline,
      size: ButtonSize.sm,
      leading: PhosphorIcon(icon),
      onPressed: onPressed,
      child: Text(done ? action.doneLabel : action.label),
    );
  }
}

/// "Your groups".
class ProfileGroupsCard extends StatelessWidget {
  const ProfileGroupsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ProfileSection(
      title: 'Your groups',
      child: UnaColumn(
        gap: GapSize.md,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in ProfileData.groups)
            ListTile(
              padding: EdgeInsets.zero,
              // A step under a `ListTile`'s own gap.
              gap: theme.gap(GapSize.sm),
              leading: ProfileLogo(
                group.logo,
                label: '${group.name} logo',
                size: theme.avatarSm,
                radius: theme.radius,
              ),
              titleStyle: _rowTitleStyle(theme),
              title: Text(group.name),
              subtitleStyle: theme.textTheme.caption,
              subtitle: Text(group.members),
            ),
        ],
      ),
    );
  }
}
