import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/profile_data.dart';
import 'package:una_demo/widgets/demo_actions.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/person_avatar.dart';
import 'package:una_demo/widgets/profile_common.dart';
import 'package:una_demo/widgets/verified_badge.dart';

// The designs draw the profile with About selected. These are the other
// tabs' contents, built from the same people, photographs and wording.

/// One post of the Posts tab, with a like button that toggles.
class ProfilePostCard extends StatefulWidget {
  const ProfilePostCard(this.post, {super.key});

  final ProfilePost post;

  @override
  State<ProfilePostCard> createState() => _ProfilePostCardState();
}

class _ProfilePostCardState extends State<ProfilePostCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final post = widget.post;
    const person = ProfileData.person;
    final reactions = post.reactions + (_liked ? 1 : 0);

    return Card(
      style: CardTheme(
        rowMainAxisSize: MainAxisSize.max,
        columnCrossAxisAlignment: CrossAxisAlignment.stretch,
      ),
      child: UnaColumn(
        gap: GapSize.md,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            padding: EdgeInsets.zero,
            leading: const PersonAvatar(person),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Gap.xs(),
                if (person.verified) const VerifiedBadge(),
              ],
            ),
            subtitle: Text('${ProfileData.currentRole} · ${post.time}'),
          ),
          Text(
            post.text,
            style: theme.textTheme.p.copyWith(color: scheme.foregroundSubtle),
          ),
          if (post.image case final image?)
            ClipRRect(
              borderRadius: theme.radii.lg,
              // 16:9, but no taller than 340 in a wide column.
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 340),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    semanticLabel: post.imageLabel,
                  ),
                ),
              ),
            ),
          UnaRow(
            gap: GapSize.xs,
            children: [
              Button.ghost(
                size: ButtonSize.sm,
                style: ButtonTheme(
                  foregroundColor: _liked ? scheme.tint : null,
                  hoverForegroundColor: _liked ? scheme.tint : null,
                ),
                leading: PhosphorIcon(
                  _liked ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
                ),
                onPressed: () => setState(() => _liked = !_liked),
                child: Text('$reactions'),
              ),
              Button.ghost(
                size: ButtonSize.sm,
                leading: const PhosphorIcon(PhosphorIconsRegular.chatCircle),
                onPressed: () => showCommentDialog(context, person),
                child: Text('${post.comments}'),
              ),
              const Spacer(),
              Button.ghost(
                size: ButtonSize.sm,
                leading: const PhosphorIcon(PhosphorIconsRegular.export),
                onPressed: () => showSendDialog(context, what: 'this post'),
                child: const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Activity tab: what the profile's owner did on other people's posts.
class ProfileActivityCard extends StatelessWidget {
  const ProfileActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = theme.textTheme.p.copyWith(fontWeight: FontWeight.w500);
    return ProfileSection(
      title: 'Activity',
      child: UnaColumn(
        gap: GapSize.lg,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in ProfileData.activity)
            ListTile(
              padding: EdgeInsets.zero,
              crossAxisAlignment: CrossAxisAlignment.start,
              leading: IconTile(icon: PhosphorIcon(item.icon)),
              titleStyle: title,
              titleMaxLines: 2,
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${item.verb} '),
                    TextSpan(
                      text: item.person.name,
                      style: title.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(text: '’s post'),
                  ],
                ),
              ),
              subtitle: Text(item.detail),
              subtitleMaxLines: 2,
              trailing: Text(item.time, style: theme.textTheme.muted),
            ),
        ],
      ),
    );
  }
}

/// The Media tab: the photographs from the profile's posts, as a grid.
class ProfileMediaCard extends StatelessWidget {
  const ProfileMediaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = theme.gap(GapSize.sm);
    final radius = theme.radii.lg;
    return ProfileSection(
      title: 'Media',
      child: LayoutBuilder(
        builder: (context, constraints) {
          const columns = 3;
          final side = ((constraints.maxWidth - gap * (columns - 1)) / columns)
              .floorToDouble();
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in ProfileData.media)
                ClipRRect(
                  borderRadius: radius,
                  child: Image.asset(
                    item.image,
                    width: side,
                    height: side,
                    fit: BoxFit.cover,
                    semanticLabel: item.label,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
