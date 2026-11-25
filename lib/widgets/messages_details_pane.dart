import 'package:finesse_demo/data/messages_data.dart';
import 'package:finesse_demo/data/network_data.dart';
import 'package:finesse_demo/widgets/messages_common.dart';
import 'package:finesse_demo/widgets/messages_controller.dart';
import 'package:finesse_demo/widgets/network_links.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse_demo/widgets/demo_previews.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

// One notch under the theme's `md` gap, where the designs tighten it: between
// a row's tile and its text, and between the avatar stack and its title.
const _tightGap = 10.0;

/// The portrait the pane is about: larger than any step of the theme's
/// avatar scale.
const _portraitSize = 88.0;

/// The last pane of the desktop card: who the conversation is with, the
/// people both sides know, and what has been shared.
class MessagesDetailsPane extends StatelessWidget {
  const MessagesDetailsPane({required this.controller, super.key});

  final MessagesController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final layout = theme.layoutTheme;
    final conversation = controller.selected;
    final muted = controller.isMuted(conversation);
    final location = conversation.person?.location;
    final mutedText = theme.textTheme.muted;
    final inset = messagesPaneInset(theme);

    Widget section(String title, Widget child, {double? titleGap}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.messagesLabel.copyWith(fontWeight: FontWeight.w600),
        ),
        Gap.raw(titleGap ?? layout.gap(GapSize.md)),
        child,
      ],
    );

    return SingleChildScrollView(
      // The card's padding at the sides and a little more above and below;
      // the sections are as far apart as a card's.
      padding: EdgeInsets.symmetric(
        horizontal: inset,
        vertical: layout.gap(GapSize.xl),
      ),
      child: Column(
        spacing: theme.cardTheme.sectionGap ?? inset,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              ConversationAvatar(
                conversation,
                size: _portraitSize,
                showOnline: false,
              ),
              const Gap.md(),
              Text(
                conversation.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.h4.copyWith(color: colors.foreground),
              ),
              const Gap.xs(),
              Text(
                conversation.headline,
                textAlign: TextAlign.center,
                style: mutedText,
              ),
              if (location != null) ...[
                const Gap.xs(),
                Text(location, textAlign: TextAlign.center, style: mutedText),
              ],
              const Gap.lg(),
              FinesseRow(
                gap: GapSize.sm,
                children: [
                  Expanded(
                    child: conversation.assistant
                        // It has no profile to look at; a fresh start is
                        // the useful thing to offer.
                        ? Button.outline(
                            onPressed: () => controller.clear(conversation),
                            child: const Text('Clear chat'),
                          )
                        : Button.outline(
                            onPressed: () => switch (conversation.person) {
                              final person? => showPersonPreview(
                                context,
                                person,
                              ),
                              null => openNetworkSection(
                                context,
                                NetworkSection.groups,
                              ),
                            },
                            child: Text(
                              conversation.isGroup
                                  ? 'View group'
                                  : 'View profile',
                            ),
                          ),
                  ),
                  IconButton.secondary(
                    style: ButtonTheme(
                      // A rounded square beside the button rather than the
                      // theme's round icon button.
                      decoration: theme.buttonDecoration(radius: theme.radius),
                      iconSize: theme.glyph,
                    ),
                    icon: PhosphorIcon(
                      muted
                          ? PhosphorIconsRegular.bellSlash
                          : PhosphorIconsRegular.bell,
                    ),
                    semanticLabel: muted
                        ? 'Unmute notifications'
                        : 'Mute notifications',
                    onPressed: () => controller.toggleMuted(conversation),
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          if (conversation.mutuals.isNotEmpty)
            section(
              conversation.isGroup ? 'Members' : 'Mutual connections',
              titleGap: _tightGap,
              FinesseRow(
                gap: GapSize.sm,
                children: [
                  AvatarGroup(
                    size: theme.avatarXs + theme.gap(GapSize.xs) * 1.5,
                    overlap: theme.gap(GapSize.xs) * 1.5,
                    children: [
                      for (final avatar in conversation.mutuals)
                        Avatar(avatar, fit: BoxFit.cover),
                    ],
                  ),
                  if (conversation.mutualsLabel case final label?)
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mutedText,
                      ),
                    ),
                ],
              ),
            ),
          if (conversation.sharedFiles.isNotEmpty)
            section(
              'Shared files',
              FinesseColumn(
                gap: GapSize.md,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final file in conversation.sharedFiles)
                    _SharedFileRow(file),
                ],
              ),
            ),
          if (conversation.sharedGroups.isNotEmpty)
            section(
              'Shared groups',
              FinesseColumn(
                gap: GapSize.md,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final group in conversation.sharedGroups)
                    ListTile(
                      padding: EdgeInsets.zero,
                      gap: _tightGap,
                      leading: GroupLogo(group, size: theme.avatarSm),
                      title: Text(group.name),
                      titleStyle: theme.messagesLabel,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A shared file: its type on a soft tile, its name, its size and age.
class _SharedFileRow extends StatelessWidget {
  const _SharedFileRow(this.file);

  final SharedFile file;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      padding: EdgeInsets.zero,
      gap: _tightGap,
      leading: IconTile(
        size: theme.avatarSm + theme.gap(GapSize.xs),
        iconSize: theme.glyphLg,
        borderRadius: theme.radius,
        icon: PhosphorIcon(file.icon),
      ),
      title: Text(file.name),
      titleStyle: theme.messagesLabel,
      subtitle: Text(file.listCaption),
      subtitleStyle: theme.messagesCaption,
    );
  }
}
