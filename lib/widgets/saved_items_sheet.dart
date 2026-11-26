import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/applications_data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/data/profile_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/demo_metrics.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_pieces.dart';
import 'package:una_demo/widgets/person_avatar.dart';

/// Opens "Saved items": the posts, articles and jobs the user has
/// bookmarked, in a sheet — from the end edge on a desktop, from the bottom
/// on a phone.
///
/// What the home feed's "Saved items" shortcut and the avatar menu lead to.
/// A row closes the sheet and goes to where the item lives. The jobs are
/// the "Saved" column of the "My applications" board, newest on top.
Future<void> showSavedItems(BuildContext context) async {
  final mobile = Theme.of(context).formFactor == FormFactor.mobile;
  final destination = await showSheet<DemoDestination>(
    context: context,
    side: mobile ? SheetSide.bottom : SheetSide.right,
    builder: (context) => const _SavedItemsSheet(),
  );
  if (destination != null && context.mounted) context.leaveTo(destination);
}

class _SavedItemsSheet extends StatelessWidget {
  const _SavedItemsSheet();

  /// How many of the saved jobs are listed; the link under them leads to
  /// the rest.
  static const _jobsShown = 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mobile = theme.formFactor == FormFactor.mobile;
    const post = HomeData.calmWriteUp;
    const talk = HomeData.configNordics;
    final article = ProfileData.featured.last;
    // The board's "Saved" column: what the Jobs screen's tile counts, and
    // where a listing saved on "Find jobs" turns up.
    final savedJobs = context.demo.applications.at(ApplicationStage.saved);

    Widget row({
      required Widget leading,
      required String title,
      required String detail,
      required String saved,
      required DemoDestination destination,
    }) => ListTile(
      onTap: () => Navigator.of(context).pop(destination),
      crossAxisAlignment: CrossAxisAlignment.start,
      leading: leading,
      titleStyle: theme.textTheme.p.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.foreground,
      ),
      titleMaxLines: 2,
      title: Text(title),
      subtitle: Text(detail),
      trailing: Text(saved, style: theme.textTheme.caption),
    );

    Widget heading(String text) => Padding(
      padding: EdgeInsets.fromLTRB(
        theme.gap(GapSize.md),
        theme.gap(GapSize.lg),
        theme.gap(GapSize.md),
        theme.gap(GapSize.xs),
      ),
      child: Semantics(
        header: true,
        child: Text(
          text,
          style: theme.textTheme.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );

    return Sheet(
      title: const Text('Saved items'),
      description: const Text('Only you can see what you save.'),
      style: SheetTheme(
        constraints: mobile ? null : const BoxConstraints(maxWidth: 420),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          heading('Jobs · ${savedJobs.length}'),
          for (final application in savedJobs.take(_jobsShown))
            row(
              leading: DemoMark(
                asset: application.company.logo,
                label: application.company.name,
              ),
              title: application.title,
              detail: '${application.company.name} · ${application.location}',
              saved: application.updated,
              destination: DemoDestination.jobs,
            ),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.gap(GapSize.md),
              vertical: theme.gap(GapSize.xs),
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: HomeTextLink(
                switch (savedJobs.length) {
                  0 => 'Find jobs to save',
                  1 => 'See your saved job',
                  final count => 'See all $count saved jobs',
                },
                onPressed: () =>
                    Navigator.of(context).pop(DemoDestination.jobs),
                style: theme.textTheme.small.copyWith(color: scheme.tint),
              ),
            ),
          ),
          heading('Posts and articles · 3'),
          row(
            leading: PersonAvatar(post.author),
            title: post.link?.title ?? post.compactBody,
            detail: '${post.author.name} · ${post.age}',
            saved: 'Today',
            destination: DemoDestination.home,
          ),
          row(
            leading: PersonAvatar(talk.author),
            title: talk.event?.title ?? talk.compactBody,
            detail: '${talk.author.name} · ${talk.age}',
            saved: 'Mon',
            destination: DemoDestination.home,
          ),
          row(
            leading: IconTile(
              icon: const PhosphorIcon(PhosphorIconsRegular.article),
              size: theme.avatarMd,
              iconSize: theme.avatarMd / 2,
            ),
            title: article.title,
            detail: 'By you · ${article.meta}',
            saved: 'Nov 12',
            destination: DemoDestination.profile,
          ),
        ],
      ),
    );
  }
}
