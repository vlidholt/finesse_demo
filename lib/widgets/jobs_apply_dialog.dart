import 'dart:async';

import 'package:finesse_demo/data/jobs_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/session.dart';
import 'package:finesse_demo/widgets/jobs_board_view.dart';
import 'package:finesse_demo/widgets/jobs_state.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// Opens "Easy Apply" for [job]: three short steps — contact details, a
/// résumé, a last look — in a `Stepper`, and "Submit application".
///
/// Submitting applies through [state], which puts the listing under
/// "Applied" on the "My applications" board, and says so in a toast whose
/// "View" opens the board — from a page pushed over the shell too, which
/// it closes on the way.
///
/// The steps run across the top on a desktop and down the dialog on a
/// phone, as the stepper does by itself.
Future<void> showEasyApply(
  BuildContext context, {
  required Job job,
  required JobsState state,
}) {
  final email = context.demo.settings.email;
  final viewApplications = applicationsOpener(context);
  return showDialog<void>(
    context: context,
    builder: (_) => _EasyApplyDialog(
      job: job,
      state: state,
      email: email,
      onViewApplications: viewApplications,
    ),
  );
}

/// What opens the "My applications" board from wherever [context] is,
/// closing the pages pushed over the shell first.
///
/// It is worked out now and holds no context: it is called later, from a
/// toast, by when the page it was made on may have been closed. Null where
/// the app's providers are not above [context] (a test of one piece).
VoidCallback? applicationsOpener(BuildContext context) {
  final view = jobsViewProvider.maybeOf(context);
  final destination = demoDestinationProvider.maybeOf(context);
  if (view == null || destination == null) return null;
  final navigator = Navigator.of(context);
  return () {
    if (navigator.mounted) navigator.popUntil((route) => route.isFirst);
    view.value = JobsView.applications;
    destination.value = DemoDestination.jobs;
  };
}

/// The steps, in order.
enum _ApplyStep { contact, resume, review }

class _EasyApplyDialog extends StatefulWidget {
  const _EasyApplyDialog({
    required this.job,
    required this.state,
    required this.email,
    required this.onViewApplications,
  });

  final Job job;
  final JobsState state;
  final String email;
  final VoidCallback? onViewApplications;

  @override
  State<_EasyApplyDialog> createState() => _EasyApplyDialogState();
}

class _EasyApplyDialogState extends State<_EasyApplyDialog> {
  /// How long the pretend server takes to accept an application.
  static const _delay = Duration(milliseconds: 700);

  // A dialog is a route of its own, which no resize of the page underneath
  // rebuilds: what is typed here is safe in this state.
  late final _email = TextEditingController(text: widget.email);
  final _phone = TextEditingController(text: JobsData.applicantPhone);

  var _step = _ApplyStep.contact;
  var _resume = JobsData.resumes.first;
  late var _follow = !widget.state.isFollowing(widget.job);
  Timer? _submitting;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onChanged);
    _phone.addListener(_onChanged);
  }

  @override
  void dispose() {
    _submitting?.cancel();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _contactDone =>
      _email.text.trim().contains('@') && _phone.text.trim().isNotEmpty;

  /// Whether the user may go on from [step].
  bool _canLeave(_ApplyStep step) => switch (step) {
    _ApplyStep.contact => _contactDone,
    _ApplyStep.resume || _ApplyStep.review => true,
  };

  void _goTo(int index) {
    final target = _ApplyStep.values[index];
    // Back to any step; forward only past steps that are complete.
    for (final step in _ApplyStep.values.take(index)) {
      if (!_canLeave(step)) return;
    }
    setState(() => _step = target);
  }

  void _submit() {
    if (_submitting != null) return;
    setState(() {
      _submitting = Timer(_delay, () {
        final job = widget.job;
        final state = widget.state;
        state.apply(job);
        if (_follow && !state.isFollowing(job)) state.toggleFollowing(job);
        showDemoToast(
          context,
          'Application sent',
          description: '${job.company.name} usually replies within a week.',
          variant: ToastVariant.success,
          actionLabel: widget.onViewApplications == null ? null : 'View',
          onAction: widget.onViewApplications,
        );
        Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final submitting = _submitting != null;
    final index = _step.index;
    final last = _step == _ApplyStep.review;

    return Dialog(
      title: Text('Apply to ${job.company.name}'),
      description: Text(job.title),
      style: DialogTheme(constraints: const BoxConstraints(maxWidth: 560)),
      scrollable: true,
      actions: [
        if (index == 0)
          Button.outline(
            enabled: !submitting,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          )
        else
          Button.outline(
            enabled: !submitting,
            onPressed: () => _goTo(index - 1),
            child: const Text('Back'),
          ),
        if (last)
          Button(
            loading: submitting,
            leading: const PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt),
            onPressed: _submit,
            child: const Text('Submit application'),
          )
        else
          Button(
            enabled: _canLeave(_step),
            onPressed: () => _goTo(index + 1),
            child: const Text('Next'),
          ),
      ],
      child: IgnorePointer(
        ignoring: submitting,
        child: Padding(
          // Clear of the description, as a section of the dialog.
          padding: EdgeInsets.only(top: Theme.of(context).gap(GapSize.sm)),
          child: Stepper(
            currentStep: index,
            onStepTapped: submitting ? null : _goTo,
            steps: [
              Step(
                title: const Text('Contact'),
                subtitle: index > 0 ? Text(_email.text.trim()) : null,
                state: index > 0 && !_contactDone
                    ? StepState.error
                    : StepState.auto,
                content: _ContactStep(email: _email, phone: _phone),
              ),
              Step(
                title: const Text('Résumé'),
                subtitle: index > 1 ? Text(_resume.$1) : null,
                content: _ResumeStep(
                  value: _resume,
                  onChanged: (resume) => setState(() => _resume = resume),
                ),
              ),
              Step(
                title: const Text('Review'),
                content: _ReviewStep(
                  job: job,
                  email: _email.text.trim(),
                  phone: _phone.text.trim(),
                  resume: _resume,
                  follow: _follow,
                  alreadyFollowing: widget.state.isFollowing(job),
                  onFollowChanged: (value) => setState(() => _follow = value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A label over a field, read as the field's name.
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

class _ContactStep extends StatelessWidget {
  const _ContactStep({required this.email, required this.phone});

  final TextEditingController email;
  final TextEditingController phone;

  @override
  Widget build(BuildContext context) {
    return FinesseColumn(
      gap: GapSize.md,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'Email',
          child: TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            clearable: true,
          ),
        ),
        _Field(
          label: 'Phone',
          child: TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            clearable: true,
          ),
        ),
      ],
    );
  }
}

class _ResumeStep extends StatelessWidget {
  const _ResumeStep({required this.value, required this.onChanged});

  final (String, String) value;
  final ValueChanged<(String, String)> onChanged;

  @override
  Widget build(BuildContext context) {
    return FinesseRadioGroup<(String, String)>(
      value: value,
      onChanged: onChanged,
      child: ListSection(
        footer: const Text('The hiring team sees the file you choose.'),
        children: [
          for (final resume in JobsData.resumes)
            RadioListTile<(String, String)>(
              value: resume,
              secondary: const IconTile(
                icon: PhosphorIcon(PhosphorIconsRegular.filePdf),
              ),
              title: Text(resume.$1),
              subtitle: Text(resume.$2),
            ),
        ],
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.job,
    required this.email,
    required this.phone,
    required this.resume,
    required this.follow,
    required this.alreadyFollowing,
    required this.onFollowChanged,
  });

  final Job job;
  final String email;
  final String phone;
  final (String, String) resume;
  final bool follow;
  final bool alreadyFollowing;
  final ValueChanged<bool> onFollowChanged;

  @override
  Widget build(BuildContext context) {
    return FinesseColumn(
      gap: GapSize.md,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListSection(
          children: [
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.envelopeSimple),
              title: Text(email),
            ),
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.phone),
              title: Text(phone),
            ),
            ListTile(
              leading: const PhosphorIcon(PhosphorIconsRegular.filePdf),
              title: Text(resume.$1),
            ),
          ],
        ),
        if (!alreadyFollowing)
          ListSection(
            children: [
              SwitchListTile(
                title: Text('Follow ${job.company.name}'),
                subtitle: const Text('See their posts and new roles first'),
                value: follow,
                onChanged: onFollowChanged,
              ),
            ],
          ),
      ],
    );
  }
}
