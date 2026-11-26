import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/messages_data.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// The designs' tight gap — a status dot and its label, two filter chips, a
/// name after its avatar's own gap — between the theme's `xs` and `sm`.
const messagesTightGap = 6.0;

/// How far a pane's content sits from the hairlines beside it. The card is
/// split edge to edge, so each pane applies the card's padding itself.
double messagesPaneInset(ThemeData theme) =>
    (theme.cardTheme.padding ?? const EdgeInsets.all(24)).horizontal / 2;

/// The portrait beside the last message of a run, and the gutter the other
/// messages of the run keep free for it. Smaller than any step of the
/// theme's avatar scale: it has to sit beside a single line of text.
const messagesThreadAvatar = 28.0;

/// The typing bubble's padding: rounder than a text bubble's, so the dots
/// sit in a pill. The designs keep it on a phone too.
const messagesTypingPadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 14,
);

/// The text styles of the Messages screen, each a theme style with at most
/// its weight or its colour changed.
extension MessagesTextStyles on ThemeData {
  /// The theme's fine print: timestamps, receipts, the day divider, a
  /// shared file's size.
  TextStyle get messagesCaption => textTheme.caption;

  /// The body style, semibold: a name in the conversation list, an
  /// attachment's file name.
  TextStyle get messagesName => textTheme.p.copyWith(
    fontWeight: FontWeight.w600,
    color: colorScheme.foreground,
  );

  /// The label style in the foreground colour: section titles and file
  /// names in the details pane, an unread row's preview.
  TextStyle get messagesLabel => textTheme.small.copyWith(
    fontWeight: FontWeight.w500,
    color: colorScheme.foreground,
  );

  /// The designs' `--coral`, which the colour scheme has no token for: the
  /// "active now" dot beside a name.
  Color get messagesCoral => brightness == Brightness.dark
      ? const Color(0xFFD24B38)
      : const Color(0xFFC8432F);
}

/// A group's mark: a rounded square with a hairline.
class GroupLogo extends StatelessWidget {
  const GroupLogo(this.group, {this.size = 48, super.key});

  final Group group;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // The designs round a logo in proportion to its size — 14 at 48, 9 at
    // 32 — rather than on the radius scale.
    final radius = BorderRadius.circular((size * .29).roundToDouble());
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: theme.colorScheme.muted,
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Image.asset(
        group.logo,
        fit: BoxFit.cover,
        semanticLabel: '${group.name} logo',
      ),
    );
  }
}

/// The picture that stands for a [Conversation]: the person's portrait with
/// a presence dot, or the group's logo.
class ConversationAvatar extends StatelessWidget {
  const ConversationAvatar(
    this.conversation, {
    this.size,
    this.showOnline = true,
    this.surfaceColor,
    super.key,
  });

  final Conversation conversation;

  /// The picture's side. Defaults to the theme's avatar.
  final double? size;

  /// Whether someone who is active gets the presence dot.
  final bool showOnline;

  /// The colour of the surface behind the avatar, when it is not a card: the
  /// presence dot is ringed in it.
  final Color? surfaceColor;

  @override
  Widget build(BuildContext context) {
    final size = this.size ?? Theme.of(context).avatarMd;
    if (conversation.assistant) return AssistantMark(size: size);
    final group = conversation.group;
    if (group != null) return GroupLogo(group, size: size);
    return PersonAvatar(
      conversation.person!,
      size: size,
      showOnline: showOnline && conversation.online,
      onlineRingColor: surfaceColor,
    );
  }
}

/// The assistant's picture: a spark on the theme's tint, where a person has
/// a portrait.
class AssistantMark extends StatelessWidget {
  const AssistantMark({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          shape: const CircleBorder(),
          color: colors.tint,
        ),
        child: PhosphorIcon(
          PhosphorIconsFill.sparkle,
          size: (size * .5).roundToDouble(),
          color: colors.tintForeground,
        ),
      ),
    );
  }
}
