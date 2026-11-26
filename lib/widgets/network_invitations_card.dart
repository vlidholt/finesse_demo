import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/network_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/demo_previews.dart';
import 'package:una_demo/widgets/network_controller.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// The invitations waiting for an answer, each with "Ignore" and "Accept".
///
/// Answering one takes its row away, moves the count in the heading — and
/// everywhere else the controller's `pending` is shown — and offers "Undo"
/// in a toast. With nothing left the card says so rather than vanishing, so
/// the page does not jump.
class NetworkInvitationsCard extends StatelessWidget {
  const NetworkInvitationsCard({required this.controller, super.key});

  final NetworkController controller;

  void _accept(BuildContext context, Invitation invitation) {
    controller.accept(invitation);
    showDemoToast(
      context,
      'You and ${invitation.person.firstName} are now connected',
      actionLabel: 'Undo',
      onAction: () => controller.undoAccept(invitation),
    );
  }

  void _ignore(BuildContext context, Invitation invitation) {
    controller.ignore(invitation);
    showDemoToast(
      context,
      'Invitation from ${invitation.person.firstName} ignored',
      description: 'They will not be told.',
      actionLabel: 'Undo',
      onAction: () => controller.undoIgnore(invitation),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pending = controller.pending;

    return Card(
      style: CardTheme(
        sectionGap: theme.gap(GapSize.md),
        rowMainAxisSize: MainAxisSize.max,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      title: Row(
        children: [
          const Flexible(
            child: Text(
              'Invitations',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (pending.isNotEmpty) ...[
            const Gap.sm(),
            IndicatorBadge(
              count: pending.length,
              ringWidth: 0,
              semanticLabel: '${pending.length} waiting',
            ),
          ],
        ],
      ),
      child: pending.isEmpty
          ? Row(
              children: [
                IconTile(
                  icon: const PhosphorIcon(PhosphorIconsRegular.checkCircle),
                  backgroundColor: scheme.successMuted,
                  foregroundColor: scheme.success,
                ),
                const Gap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'You are all caught up',
                        style: theme.textTheme.large.copyWith(
                          color: scheme.foreground,
                        ),
                      ),
                      Text(
                        'New invitations to connect will show up here.',
                        style: theme.textTheme.muted,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, invitation) in pending.indexed) ...[
                  if (index > 0)
                    Divider(
                      margin: EdgeInsets.symmetric(
                        vertical: theme.gap(GapSize.md),
                      ),
                    ),
                  _InvitationRow(
                    invitation,
                    key: ValueKey(invitation.person.name),
                    onAccept: () => _accept(context, invitation),
                    onIgnore: () => _ignore(context, invitation),
                  ),
                ],
              ],
            ),
    );
  }
}

class _InvitationRow extends StatelessWidget {
  const _InvitationRow(
    this.invitation, {
    required this.onAccept,
    required this.onIgnore,
    super.key,
  });

  final Invitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onIgnore;

  /// Under this width the buttons move below the text.
  static const _stackBelow = 440.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final person = invitation.person;
    void open() => showPersonPreview(context, person);

    final buttons = UnaRow(
      gap: GapSize.sm,
      mainAxisSize: MainAxisSize.min,
      children: [
        DemoPillButton(
          label: 'Ignore',
          icon: PhosphorIconsRegular.x,
          onPressed: onIgnore,
        ),
        DemoPillButton(
          label: 'Accept',
          icon: PhosphorIconsRegular.check,
          primary: true,
          onPressed: onAccept,
        ),
      ],
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        PersonName(person, onPressed: open),
        Text(
          person.headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.muted,
        ),
        const Gap.xs(),
        MutualsLine(
          people: invitation.mutuals,
          label: '${invitation.mutualCount} mutual · ${invitation.age}',
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < _stackBelow;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UnaRow(
              gap: GapSize.md,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Pressable(
                  onPressed: open,
                  semanticLabel: 'Preview ${person.name}',
                  builder: (context, states) => FocusRing(
                    visible: states.contains(WidgetState.focused),
                    borderRadius: theme.radii.full,
                    child: PersonAvatar(person),
                  ),
                ),
                Expanded(child: text),
                if (!stacked) buttons,
              ],
            ),
            if (invitation.note case final note?)
              Padding(
                // Under the text, not under the portrait.
                padding: EdgeInsetsDirectional.only(
                  start: theme.avatarMd + theme.gap(GapSize.md),
                  top: theme.gap(GapSize.sm),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: theme.gap(GapSize.md),
                    vertical: theme.gap(GapSize.sm),
                  ),
                  decoration: BoxDecoration(
                    color: scheme.muted,
                    borderRadius: theme.radii.lg,
                  ),
                  child: Text(
                    note,
                    style: theme.textTheme.muted.copyWith(
                      color: scheme.foregroundSubtle,
                    ),
                  ),
                ),
              ),
            if (stacked)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: theme.avatarMd + theme.gap(GapSize.md),
                  top: theme.gap(GapSize.md),
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: buttons,
                ),
              ),
          ],
        );
      },
    );
  }
}
