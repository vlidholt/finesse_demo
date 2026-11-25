import 'dart:async';

import 'package:finesse_demo/app_state.dart';
import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/profile_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/widgets/person_avatar.dart';
import 'package:finesse_demo/widgets/settings_controller.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';

/// The cards of one page of Settings.
///
/// Each page is a column of cards; each card a heading, a line about it and
/// its controls — the package's own `TextField`, `TagField`, `Select`,
/// `DatePicker`, `TimePicker`, `NumberField`, `Switch`, `Checkbox`, `Slider`
/// and `SegmentedControl`, with nothing restyled. A group that is nothing
/// but switches, checkboxes or one radio choice is a `ListSection` of
/// `SwitchListTile`s, `CheckboxListTile`s or `RadioListTile`s instead: the
/// grouped list of a settings page, where the whole row takes the tap.
///
/// On a phone a `Select` opens its options in a sheet from the bottom edge
/// and the date and time pickers their wheels; on a desktop all three are
/// popovers under their buttons.
class SettingsSectionView extends StatelessWidget {
  const SettingsSectionView({
    required this.section,
    required this.settings,
    super.key,
  });

  final SettingsSection section;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return FinesseColumn(
      gap: GapSize.lg,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (section) {
        SettingsSection.account => [
          _ProfileCard(settings: settings),
          _SecurityCard(settings: settings),
        ],
        SettingsSection.privacy => [
          _VisibilityCard(settings: settings),
          _ActivityCard(settings: settings),
          _PersonalisationCard(settings: settings),
          _MessagesCard(settings: settings),
        ],
        SettingsSection.notifications => [
          _PauseCard(settings: settings),
          _QuietHoursCard(settings: settings),
          _TopicsCard(settings: settings),
          _JobMatchCard(settings: settings),
        ],
        SettingsSection.appearance => [
          const _ThemeCard(),
          _DisplayCard(settings: settings),
        ],
      },
    );
  }
}

/// A card of Settings: a heading, a muted line under it, then [child].
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      style: CardTheme(
        rowMainAxisSize: MainAxisSize.max,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      title: Semantics(header: true, child: Text(title)),
      description: Text(description),
      child: child,
    );
  }
}

/// A preference on one line: what it is, a sentence about it, and its
/// control at the end.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    required this.trailing,
    this.detail,
    this.leading,
    this.trailingIsLabelled = false,
    this.stacked = false,
  });

  final String title;
  final String? detail;
  final Widget? leading;
  final Widget trailing;

  /// Whether [trailing] goes under the text, across the row's width,
  /// instead of at its end: a control too wide to share a phone's line.
  final bool stacked;

  /// Whether [trailing] carries [title] as its own semantic label — a group
  /// of tabs named "Mode". The visible title is then left out of the
  /// semantics, or a screen reader would say it twice.
  final bool trailingIsLabelled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final row = _buildRow(theme, scheme);
    if (!stacked) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [row, const Gap.md(), trailing],
    );
  }

  Widget _buildRow(ThemeData theme, ColorScheme scheme) {
    return Row(
      children: [
        if (leading case final leading?) ...[leading, const Gap.md()],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                excluding: trailingIsLabelled,
                child: Text(
                  title,
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.foreground,
                  ),
                ),
              ),
              if (detail case final detail?)
                Text(
                  detail,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted,
                ),
            ],
          ),
        ),
        if (!stacked) ...[const Gap.lg(), trailing],
      ],
    );
  }
}

/// A switch with its label and sentence: a [_SettingRow] ending in a
/// `Switch`, read to assistive technology as one control.
///
/// The row is merged into one semantic node — the title and the sentence
/// become the switch's label — rather than the switch being given the
/// title as a label of its own, which left the visible title in the tree
/// to be read a second time.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: _SettingRow(
        title: title,
        detail: detail,
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

/// A labelled form field: the label over the control.
///
/// The control carries the label in its semantics, so the visible text is
/// left out of them: one node per field, not a label and then a field of
/// the same name.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.foreground,
            ),
          ),
        ),
        const Gap.xs(),
        Semantics(label: label, child: child),
      ],
    );
  }
}

/// Lays [children] out two across where there is room, and in one column
/// where there is not.
///
/// One `Wrap` either way, with the children's width worked out from the
/// room: every field stays the same child of the same parent when the
/// number of columns changes, so the one being typed in keeps its focus
/// through a resize.
class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  /// The least a field is wide before the grid drops to one column.
  static const _minFieldWidth = 240.0;

  @override
  Widget build(BuildContext context) {
    final gap = Theme.of(context).layoutTheme.gap(GapSize.lg);
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth;
        final two = room >= _minFieldWidth * 2 + gap;
        // Rounded down, so that two of them and the gap never come to a
        // hair more than the room and wrap.
        final width = two ? ((room - gap) / 2).floorToDouble() : room;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// How a `Select` of Settings shows its options: in a sheet from the bottom
/// edge on a phone, where a list under a field near the keyboard has no
/// room, and in a popover under its button on a desktop.
PickerPresentation _selectPresentation(BuildContext context) =>
    Theme.of(context).formFactor == FormFactor.mobile
    ? PickerPresentation.sheet
    : PickerPresentation.popover;

/// The heading over a `ListSection` of Settings, in the theme's overline.
Widget _sectionHeader(BuildContext context, String text) =>
    Text(Theme.of(context).style.overline.applyCase(text));

/// The rule between two rows of a settings card.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) => Divider(
    margin: EdgeInsets.symmetric(
      vertical: Theme.of(context).gap(GapSize.md),
    ),
  );
}

// Account.

class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.settings});

  final SettingsController settings;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  late final _name = TextEditingController(text: widget.settings.name);
  late final _headline = TextEditingController(
    text: widget.settings.headline,
  );
  late final _email = TextEditingController(text: widget.settings.email);
  late String _language = widget.settings.language;
  late List<String> _skills = widget.settings.skills;
  late DateTime? _birthday = widget.settings.birthday;

  /// Runs while "Save changes" is on its way to the pretend server.
  Timer? _saving;

  /// How long that takes.
  static const _saveDelay = Duration(milliseconds: 600);

  SettingsController get _settings => widget.settings;

  bool get _dirty =>
      _name.text != _settings.name ||
      _headline.text != _settings.headline ||
      _email.text != _settings.email ||
      _language != _settings.language ||
      _birthday != _settings.birthday ||
      !listEquals(_skills, _settings.skills);

  @override
  void initState() {
    super.initState();
    for (final controller in [_name, _headline, _email]) {
      controller.addListener(_onEdited);
    }
  }

  @override
  void dispose() {
    // A save that is on its way still lands: leaving the page does not
    // take back what was sent.
    if (_saving?.isActive ?? false) {
      _saving!.cancel();
      // After this frame: the tree is locked while it is being taken
      // down, and the settings have listeners in it.
      final apply = _changes();
      scheduleMicrotask(() => _settings.update(apply));
    }
    _name.dispose();
    _headline.dispose();
    _email.dispose();
    super.dispose();
  }

  void _onEdited() => setState(() {});

  /// What the card's fields say, as a change to the settings: read now,
  /// so that it can be applied after the fields are gone.
  VoidCallback _changes() {
    final settings = _settings;
    final (name, headline, email) = (_name.text, _headline.text, _email.text);
    final (language, skills, birthday) = (_language, _skills, _birthday);
    return () {
      settings
        ..name = name
        ..headline = headline
        ..email = email
        ..language = language
        ..skills = skills
        ..birthday = birthday;
    };
  }

  /// Writes the card's fields to the settings.
  void _apply() => _settings.update(_changes());

  void _save() {
    if (_saving != null) return;
    setState(() {
      _saving = Timer(_saveDelay, () {
        _apply();
        setState(() => _saving = null);
        showDemoToast(
          context,
          'Your changes are saved',
          variant: ToastVariant.success,
        );
      });
    });
  }

  void _discard() {
    _name.text = _settings.name;
    _headline.text = _settings.headline;
    _email.text = _settings.email;
    setState(() {
      _language = _settings.language;
      _skills = _settings.skills;
      _birthday = _settings.birthday;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SettingsCard(
      title: 'Profile',
      description: 'How you appear across Demo.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingRow(
            leading: PersonAvatar(People.me, size: theme.avatarLg),
            title: _settings.name,
            detail: ProfileData.currentRole,
            trailing: Button.outline(
              size: ButtonSize.sm,
              onPressed: () => context.leaveTo(DemoDestination.profile),
              child: const Text('View profile'),
            ),
          ),
          const _RowDivider(),
          _FieldGrid(
            children: [
              _Field(
                label: 'Name',
                child: TextField(controller: _name),
              ),
              _Field(
                label: 'Email',
                child: TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              _Field(
                label: 'Headline',
                child: TextField(controller: _headline),
              ),
              _Field(
                label: 'Language',
                child: Select<String>(
                  // Rebuilt when "Discard" puts the saved language back.
                  key: ValueKey(_language),
                  initialValue: _language,
                  minWidth: double.infinity,
                  presentation: _selectPresentation(context),
                  title: const Text('Language'),
                  options: [
                    for (final language in SettingsController.languages)
                      SelectOption(value: language, child: Text(language)),
                  ],
                  selectedOptionBuilder: (context, value) => Text(value),
                  onChanged: (value) {
                    if (value != null) setState(() => _language = value);
                  },
                ),
              ),
              _Field(
                label: 'Birthday',
                // A calendar under the button on a desktop; wheels in a
                // sheet on a phone, where a year long past is three flicks
                // away instead of four hundred taps.
                child: DatePicker(
                  value: _birthday,
                  expands: true,
                  mode: theme.formFactor == FormFactor.mobile
                      ? DatePickerMode.wheel
                      : DatePickerMode.calendar,
                  captionLayout: CalendarCaptionLayout.dropdown,
                  min: DateTime(1920),
                  max: DateTime(2012, 12, 31),
                  title: const Text('Birthday'),
                  placeholder: const Text('Add your birthday'),
                  onChanged: (value) => setState(() => _birthday = value),
                ),
              ),
            ],
          ),
          Gap.raw(theme.gap(GapSize.lg)),
          _Field(
            label: 'Skills',
            child: TagField<String>(
              values: _skills,
              maxTags: 12,
              placeholder: const Text('Add a skill'),
              labelBuilder: (context, skill) => Text(skill),
              parse: (text) => text.trim().isEmpty ? null : text.trim(),
              // The skills other people list, less the ones already here.
              optionsBuilder: (value) {
                final typed = value.text.trim().toLowerCase();
                if (typed.isEmpty) return const [];
                return [
                  for (final skill in SettingsController.skillSuggestions)
                    if (skill.toLowerCase().contains(typed) &&
                        !_skills.contains(skill))
                      skill,
                ];
              },
              onChanged: (value) => setState(() => _skills = value),
            ),
          ),
          const Gap.xl(),
          // A wrap: in a narrow card at a large text size the two buttons
          // stack rather than overflow.
          Wrap(
            alignment: WrapAlignment.end,
            spacing: theme.gap(GapSize.sm),
            runSpacing: theme.gap(GapSize.sm),
            children: [
              Button.outline(
                enabled: _dirty && _saving == null,
                onPressed: _discard,
                child: const Text('Discard'),
              ),
              Button(
                enabled: _dirty,
                // Spins while the changes are on their way.
                loading: _saving != null,
                onPressed: _save,
                child: const Text('Save changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecurityCard extends StatelessWidget {
  const _SecurityCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Sign-in and security',
      description: 'Keep your account yours.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SwitchRow(
            title: 'Two-step verification',
            detail: 'Ask for a code from your phone when you sign in',
            value: settings.twoStep,
            onChanged: (value) =>
                settings.update(() => settings.twoStep = value),
          ),
          const _RowDivider(),
          _SettingRow(
            title: 'Password',
            detail: 'Last changed in August',
            trailing: Button.outline(
              size: ButtonSize.sm,
              onPressed: () => showDemoToast(
                context,
                'Check your inbox',
                description:
                    'We sent a link to ${settings.email} to set a new '
                    'password.',
              ),
              child: const Text('Change'),
            ),
          ),
          const _RowDivider(),
          const _SettingRow(
            leading: IconTile(icon: PhosphorIcon(PhosphorIconsRegular.laptop)),
            title: 'MacBook Pro · Copenhagen',
            detail: 'This device · Active now',
            trailing: Badge.secondary(child: Text('Current')),
          ),
          const Gap.md(),
          _SettingRow(
            leading: const IconTile(
              icon: PhosphorIcon(PhosphorIconsRegular.deviceMobile),
            ),
            title: 'iPhone · Copenhagen',
            detail: 'Demo for iOS · Active 2 hours ago',
            trailing: Button.ghost(
              size: ButtonSize.sm,
              onPressed: () => showDemoToast(
                context,
                'Signed out of iPhone',
                description: 'That device will need your password again.',
              ),
              child: const Text('Sign out'),
            ),
          ),
        ],
      ),
    );
  }
}

// Privacy.

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    // One choice of three: a grouped list of radio rows, each of which
    // takes the tap anywhere along it.
    return FinesseRadioGroup<ProfileVisibility>(
      value: settings.visibility,
      onChanged: (value) => settings.update(() => settings.visibility = value),
      child: ListSection(
        header: _sectionHeader(context, 'Profile visibility'),
        footer: const Text('Who can open your profile and find it in search.'),
        children: [
          for (final option in ProfileVisibility.values)
            RadioListTile<ProfileVisibility>(
              value: option,
              title: Text(option.label),
              subtitle: Text(option.detail),
            ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    // Nothing but switches: a grouped list, its heading over the card and
    // its explanation under it. Each row is one control — the whole row
    // takes the tap.
    return ListSection(
      header: _sectionHeader(context, 'Activity'),
      footer: const Text('What other people can tell about what you do here.'),
      children: [
        SwitchListTile(
          title: const Text('Show when you are active'),
          subtitle: const Text('The dot on your portrait in Messages'),
          value: settings.showOnline,
          onChanged: (value) =>
              settings.update(() => settings.showOnline = value),
        ),
        SwitchListTile(
          title: const Text('Read receipts'),
          subtitle: const Text(
            'Let people see when you have read their message',
          ),
          value: settings.readReceipts,
          onChanged: (value) =>
              settings.update(() => settings.readReceipts = value),
        ),
        SwitchListTile(
          title: const Text('Share profile views'),
          subtitle: const Text(
            'Show your name when you look at someone’s profile',
          ),
          value: settings.shareProfileViews,
          onChanged: (value) =>
              settings.update(() => settings.shareProfileViews = value),
        ),
        SwitchListTile(
          title: const Text('Open to work, recruiters only'),
          subtitle: const Text('Hide the status from people at Halcyon'),
          value: settings.openToRecruitersOnly,
          onChanged: (value) =>
              settings.update(() => settings.openToRecruitersOnly = value),
        ),
      ],
    );
  }
}

class _PersonalisationCard extends StatelessWidget {
  const _PersonalisationCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    // Any number of them: a grouped list of checkbox rows.
    return ListSection(
      header: _sectionHeader(context, 'Personalisation'),
      footer: const Text('What Demo may use what it knows about you for.'),
      children: [
        for (final use in Personalisation.values)
          CheckboxListTile(
            title: Text(use.label),
            subtitle: Text(use.detail),
            value: settings.personalisation.contains(use),
            onChanged: (checked) => settings.update(() {
              if (checked ?? false) {
                settings.personalisation.add(use);
              } else {
                settings.personalisation.remove(use);
              }
            }),
          ),
      ],
    );
  }
}

class _MessagesCard extends StatelessWidget {
  const _MessagesCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'Messages',
      description: 'Everyone else lands in your message requests.',
      child: _FieldGrid(
        children: [
          _Field(
            label: 'Who can message you',
            child: Select<MessagePolicy>(
              initialValue: settings.messages,
              minWidth: double.infinity,
              presentation: _selectPresentation(context),
              title: const Text('Who can message you'),
              options: [
                for (final policy in MessagePolicy.values)
                  SelectOption(value: policy, child: Text(policy.label)),
              ],
              selectedOptionBuilder: (context, value) => Text(
                value.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onChanged: (value) {
                if (value != null) {
                  settings.update(() => settings.messages = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Notifications.

class _PauseCard extends StatelessWidget {
  const _PauseCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return ListSection(
      children: [
        SwitchListTile(
          secondary: IconTile(
            icon: PhosphorIcon(
              settings.pauseAll
                  ? PhosphorIconsRegular.bellSimpleSlash
                  : PhosphorIconsRegular.bellSimpleRinging,
            ),
          ),
          title: const Text('Pause all notifications'),
          subtitle: Text(
            settings.pauseAll
                ? 'Paused. Nothing new will reach you until you switch this '
                      'off.'
                : 'Take a break without changing what you are told about.',
          ),
          subtitleMaxLines: 3,
          value: settings.pauseAll,
          onChanged: (value) =>
              settings.update(() => settings.pauseAll = value),
        ),
      ],
    );
  }
}

/// Quiet hours: a switch, and while it is on the two times between which
/// nothing is pushed.
class _QuietHoursCard extends StatelessWidget {
  const _QuietHoursCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = settings.quietHours && !settings.pauseAll;

    // A wheel in a sheet on a phone, a field in a popover on a desktop:
    // the picker chooses by the theme's form factor.
    Widget time(
      String label,
      TimeOfDay value,
      ValueChanged<TimeOfDay> onChanged,
    ) => _Field(
      label: label,
      child: TimePicker(
        value: value,
        expands: true,
        enabled: enabled,
        minuteInterval: 5,
        title: Text(label),
        onChanged: (time) {
          if (time != null) settings.update(() => onChanged(time));
        },
      ),
    );

    return _SettingsCard(
      title: 'Quiet hours',
      description: 'Nothing is pushed to your devices between these times.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SwitchRow(
            title: 'Keep quiet at night',
            detail: 'Email still arrives; it waits for the morning anyway',
            value: settings.quietHours,
            onChanged: (value) =>
                settings.update(() => settings.quietHours = value),
          ),
          Gap.raw(theme.gap(GapSize.lg)),
          _FieldGrid(
            children: [
              time(
                'From',
                settings.quietFrom,
                (value) => settings.quietFrom = value,
              ),
              time(
                'Until',
                settings.quietUntil,
                (value) => settings.quietUntil = value,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopicsCard extends StatelessWidget {
  const _TopicsCard({required this.settings});

  final SettingsController settings;

  /// The width of a channel's column: a checkbox under a short heading.
  static const _columnWidth = 52.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final width = _columnWidth * scale;
    final heading = theme.textTheme.caption.copyWith(
      fontWeight: FontWeight.w600,
    );

    Widget box(
      Set<NotificationTopic> channel,
      String name,
      NotificationTopic t,
    ) {
      return SizedBox(
        width: width,
        child: Center(
          child: Semantics(
            label: '${t.label}, $name',
            child: Checkbox(
              value: channel.contains(t),
              enabled: !settings.pauseAll,
              onChanged: (_) => settings.toggle(channel, t),
            ),
          ),
        ),
      );
    }

    return _SettingsCard(
      title: 'What you are told about',
      description: 'Choose a channel for each kind of activity.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Activity', style: heading)),
              for (final name in const ['Push', 'Email'])
                SizedBox(
                  width: width,
                  child: Text(
                    name,
                    textAlign: TextAlign.center,
                    style: heading,
                  ),
                ),
            ],
          ),
          for (final topic in NotificationTopic.values) ...[
            const _RowDivider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        topic.label,
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.foreground,
                        ),
                      ),
                      Text(topic.detail, style: theme.textTheme.muted),
                    ],
                  ),
                ),
                box(settings.push, 'push', topic),
                box(settings.emailed, 'email', topic),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _JobMatchCard extends StatelessWidget {
  const _JobMatchCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final percent = (settings.jobMatch * 100).round();
    return _SettingsCard(
      title: 'Job matches and email',
      description: 'Fewer, better emails.',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Only tell me about roles that match at least',
                  style: theme.textTheme.p.copyWith(
                    fontWeight: FontWeight.w500,
                    color: scheme.foreground,
                  ),
                ),
              ),
              const Gap.md(),
              Text(
                '$percent%',
                style: theme.textTheme.large.copyWith(color: scheme.tint),
              ),
            ],
          ),
          const Gap.md(),
          Semantics(
            label: 'Least match for a job notification',
            child: Slider(
              initialValue: settings.jobMatch * 100,
              min: 50,
              max: 100,
              divisions: 10,
              showDivisionMarks: false,
              // The figure rides above the thumb while it is dragged.
              valueIndicator: SliderValueIndicator.whileDragging,
              valueLabel: (value) => '${value.round()}%',
              onChanged: (value) =>
                  settings.update(() => settings.jobMatch = value / 100),
            ),
          ),
          const Gap.xs(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('50%, more roles', style: theme.textTheme.caption),
              Text('100%, exact fits', style: theme.textTheme.caption),
            ],
          ),
          const _RowDivider(),
          _FieldGrid(
            children: [
              _Field(
                label: 'Summary email',
                child: Select<DigestFrequency>(
                  initialValue: settings.digest,
                  minWidth: double.infinity,
                  presentation: _selectPresentation(context),
                  title: const Text('Summary email'),
                  options: [
                    for (final option in DigestFrequency.values)
                      SelectOption(value: option, child: Text(option.label)),
                  ],
                  selectedOptionBuilder: (context, value) => Text(
                    value.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      settings.update(() => settings.digest = value);
                    }
                  },
                ),
              ),
              _Field(
                label: 'Job emails a week, at most',
                // A small whole number: minus, the figure, plus.
                child: NumberField.stepper(
                  value: settings.jobEmailsPerWeek,
                  min: 0,
                  max: 14,
                  semanticLabel: 'Job emails a week, at most',
                  onChanged: (value) => settings.update(
                    () => settings.jobEmailsPerWeek = (value ?? 0).round(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Appearance.

/// Light or dark, and the text size: the two settings on this page that are
/// real. They write to the app's own state, so the whole app follows.
class _ThemeCard extends StatefulWidget {
  const _ThemeCard();

  /// The range of the text-size slider.
  static const _minScale = .85;
  static const _maxScale = 1.3;

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SignalBuilder(
      builder: (context, _) {
        final mode = themeModeProvider.of(context);
        final textScale = textScaleProvider.of(context);
        final scale = textScale.value;
        // The slider is controlled: the text scale is the app's, which
        // something else may change while this card is showing. The thumb
        // follows the setting as far as this slider's range goes, and a
        // drag here writes the value it rounds to.
        final thumb = scale.clamp(_ThemeCard._minScale, _ThemeCard._maxScale);
        final mobile = theme.formFactor == FormFactor.mobile;

        return _SettingsCard(
          title: 'Theme',
          description: 'These two change the whole app, right away.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingRow(
                title: 'Mode',
                detail: 'Light for the day, dark for the evening',
                trailingIsLabelled: true,
                // On a phone the three segments take a line of their own.
                stacked: mobile,
                trailing: Semantics(
                  label: 'Mode',
                  container: true,
                  // One of three, all in view: a segmented control.
                  child: SegmentedControl<ThemeMode>(
                    expand: mobile,
                    value: mode.value,
                    onChanged: (value) => mode.value = value,
                    segments: const [
                      Segment(
                        value: ThemeMode.system,
                        icon: PhosphorIcon(PhosphorIconsRegular.circleHalf),
                        label: Text('Auto'),
                        tooltip: 'Follow the device',
                      ),
                      Segment(
                        value: ThemeMode.light,
                        icon: PhosphorIcon(PhosphorIconsRegular.sun),
                        label: Text('Light'),
                      ),
                      Segment(
                        value: ThemeMode.dark,
                        icon: PhosphorIcon(PhosphorIconsRegular.moon),
                        label: Text('Dark'),
                      ),
                    ],
                  ),
                ),
              ),
              const _RowDivider(),
              Row(
                children: [
                  Expanded(
                    // The slider below is labelled with the same words.
                    child: ExcludeSemantics(
                      child: Text(
                        'Text size',
                        style: theme.textTheme.p.copyWith(
                          fontWeight: FontWeight.w500,
                          color: scheme.foreground,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${(scale * 100).round()}%',
                    style: theme.textTheme.large.copyWith(color: scheme.tint),
                  ),
                ],
              ),
              const Gap.md(),
              Row(
                children: [
                  PhosphorIcon(
                    PhosphorIconsRegular.textAa,
                    // A small letter and a large one: the slider's two ends.
                    size: theme.iconBeside(theme.textTheme.caption),
                    color: scheme.mutedForeground,
                  ),
                  const Gap.md(),
                  Expanded(
                    child: Semantics(
                      label: 'Text size',
                      child: Slider(
                        value: thumb,
                        min: _ThemeCard._minScale,
                        max: _ThemeCard._maxScale,
                        divisions: 9,
                        showDivisionMarks: false,
                        valueIndicator: SliderValueIndicator.whileDragging,
                        valueLabel: (value) => '${(value * 100).round()}%',
                        onChanged: (value) {
                          // Rounded, so that 100% is exactly the default.
                          textScale.value = (value * 20).round() / 20;
                        },
                      ),
                    ),
                  ),
                  const Gap.md(),
                  PhosphorIcon(
                    PhosphorIconsRegular.textAa,
                    size: theme.iconBeside(theme.textTheme.h3),
                    color: scheme.mutedForeground,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DisplayCard extends StatelessWidget {
  const _DisplayCard({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return FinesseColumn(
      gap: GapSize.lg,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListSection(
          header: _sectionHeader(context, 'Feed and motion'),
          footer: const Text('How the home feed behaves.'),
          children: [
            SwitchListTile(
              title: const Text('Reduce motion'),
              subtitle: const Text('Fade where things would slide or scale'),
              value: settings.reduceMotion,
              onChanged: (value) =>
                  settings.update(() => settings.reduceMotion = value),
            ),
            SwitchListTile(
              title: const Text('Compact feed'),
              subtitle: const Text('Shorter posts, smaller pictures'),
              value: settings.compactFeed,
              onChanged: (value) =>
                  settings.update(() => settings.compactFeed = value),
            ),
          ],
        ),
        _SettingsCard(
          title: 'Video',
          description: 'Moving pictures cost data and attention.',
          child: _FieldGrid(
            children: [
              _Field(
                label: 'Play videos automatically',
                child: Select<Autoplay>(
                  initialValue: settings.autoplay,
                  minWidth: double.infinity,
                  presentation: _selectPresentation(context),
                  title: const Text('Play videos automatically'),
                  options: [
                    for (final option in Autoplay.values)
                      SelectOption(value: option, child: Text(option.label)),
                  ],
                  selectedOptionBuilder: (context, value) => Text(value.label),
                  onChanged: (value) {
                    if (value != null) {
                      settings.update(() => settings.autoplay = value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
