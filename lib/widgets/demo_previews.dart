import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/network_data.dart';
import 'package:finesse_demo/data/search_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/session.dart';
import 'package:finesse_demo/widgets/person_avatar.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse_demo/widgets/demo_metrics.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// Opens a short preview of [person]: who they are, how the user knows
/// them, and the two things to do about it — connect and message.
///
/// It is what a name or a portrait leads to anywhere in Demo. Only the
/// signed-in user has a full profile page, so for them it goes straight
/// there.
Future<void> showPersonPreview(BuildContext context, Person person) async {
  if (person == People.me) {
    context.leaveTo(DemoDestination.profile);
    return;
  }
  final destination = await showDialog<DemoDestination>(
    context: context,
    builder: (context) => _PersonPreview(person),
  );
  if (destination != null && context.mounted) context.leaveTo(destination);
}

/// Opens a short preview of [company]: what it is, how many roles it has
/// open, and a "Follow" button.
Future<void> showCompanyPreview(BuildContext context, Company company) async {
  final destination = await showDialog<DemoDestination>(
    context: context,
    builder: (context) => _CompanyPreview(company),
  );
  if (destination != null && context.mounted) context.leaveTo(destination);
}

/// Says who [person] is when the pointer rests on [child] — their name,
/// usually — on a desktop: a `HoverCard` with the portrait, the headline
/// and how the user knows them.
///
/// It is for looking, not for doing: the card has no buttons, and what a
/// click on the name leads to ([showPersonPreview]) offers the same and
/// more. On a phone, and for the signed-in user, it is [child] alone; a
/// finger has the tap.
class PersonHoverCard extends StatelessWidget {
  const PersonHoverCard(this.person, {required this.child, super.key});

  final Person person;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.formFactor == FormFactor.mobile || person == People.me) {
      return child;
    }
    return HoverCard(
      builder: (context) => _PersonCard(person),
      child: child,
    );
  }
}

/// What a [PersonHoverCard] shows.
class _PersonCard extends StatelessWidget {
  const _PersonCard(this.person);

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final network = context.demo.network;
    final mutuals = _mutualsOf(person);

    return ConstrainedBox(
      constraints: _hoverConstraints,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PersonAvatar(
                person,
                size: theme.avatarLg,
                showOnline: person.online,
                onlineRingColor: scheme.popover,
              ),
              const Gap.md(),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PersonName(person),
                    Text(
                      person.headline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.muted.copyWith(
                        color: scheme.foregroundSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap.md(),
          if (person.location case final location?) ...[
            Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsRegular.mapPin,
                  size: theme.iconBeside(theme.textTheme.muted),
                  color: scheme.mutedForeground,
                ),
                const Gap.xs(),
                Flexible(
                  child: Text(
                    location,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.muted,
                  ),
                ),
              ],
            ),
            const Gap.sm(),
          ],
          if (network.isConnected(person))
            Text('1st · In your network', style: theme.textTheme.caption)
          else if (mutuals != null)
            MutualsLine(
              people: mutuals.mutuals,
              label: '${mutuals.count} mutual connections',
            )
          else
            Text('2nd · Not connected yet', style: theme.textTheme.caption),
        ],
      ),
    );
  }
}

/// The width a hover card is capped at: a note beside a name.
const _hoverConstraints = BoxConstraints(minWidth: 240, maxWidth: 280);

/// How the user knows [person], from the Network screen's lists.
({List<Person> mutuals, int count})? _mutualsOf(Person person) {
  for (final entry in NetworkData.suggestions) {
    if (entry.person == person) {
      return (mutuals: entry.mutuals, count: entry.mutualCount);
    }
  }
  for (final entry in NetworkData.invitations) {
    if (entry.person == person) {
      return (mutuals: entry.mutuals, count: entry.mutualCount);
    }
  }
  return null;
}

/// The width the previews are capped at: a card, not a page.
const _previewConstraints = BoxConstraints(maxWidth: 400);

/// A preview's two buttons, as the dialog's `actions`: side by side while
/// both fit, one above the other when they do not.
///
/// The dialog lays its actions out in a row whose children keep their
/// natural width, and in a dialog this narrow two labelled buttons outgrow
/// it at a large text size, or in a wide typeface. Cutting a label short
/// would lose the one word that says what the button does, so the pair
/// wraps instead — the main action on top, as the dialog itself stacks its
/// actions on a narrow screen.
List<Widget> _previewActions(BuildContext context, List<Widget> buttons) {
  final gap =
      Theme.of(context).primaryDialogTheme.actionsGap ??
      Theme.of(context).gap(GapSize.sm);
  return [
    Flexible(
      child: Wrap(
        alignment: WrapAlignment.end,
        verticalDirection: VerticalDirection.up,
        spacing: gap,
        runSpacing: gap,
        children: buttons,
      ),
    ),
  ];
}

class _PersonPreview extends StatelessWidget {
  const _PersonPreview(this.person);

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final network = context.demo.network;

    return ListenableBuilder(
      listenable: network,
      builder: (context, _) {
        final connected = network.isConnected(person);
        final mutuals = _mutualsOf(person);
        return Dialog(
          style: DialogTheme(constraints: _previewConstraints),
          showCloseButton: true,
          semanticLabel: person.name,
          actions: _previewActions(context, [
            Button.outline(
              leading: const PhosphorIcon(PhosphorIconsRegular.paperPlaneTilt),
              onPressed: () =>
                  Navigator.of(context).pop(DemoDestination.messages),
              child: const Text('Message'),
            ),
            if (connected)
              Button.secondary(
                leading: const PhosphorIcon(PhosphorIconsRegular.check),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Connected'),
              )
            else
              Button(
                leading: PhosphorIcon(
                  network.isRequested(person)
                      ? PhosphorIconsRegular.clock
                      : PhosphorIconsRegular.userPlus,
                ),
                onPressed: () => network.toggleRequest(person),
                child: Text(
                  network.isRequested(person) ? 'Pending' : 'Connect',
                ),
              ),
          ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PersonAvatar(
                person,
                size: theme.avatarXl,
                showOnline: person.online,
                onlineRingColor: scheme.popover,
              ),
              const Gap.md(),
              PersonName(
                person,
                style: theme.textTheme.h3.copyWith(color: scheme.foreground),
              ),
              Text(
                person.headline,
                textAlign: TextAlign.center,
                style: theme.textTheme.muted.copyWith(
                  color: scheme.foregroundSubtle,
                ),
              ),
              if (person.location case final location?) ...[
                const Gap.sm(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.mapPin,
                      size: theme.iconBeside(theme.textTheme.muted),
                      color: scheme.mutedForeground,
                    ),
                    const Gap.xs(),
                    Flexible(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.muted,
                      ),
                    ),
                  ],
                ),
              ],
              const Gap.md(),
              if (connected)
                Text(
                  '1st · In your network',
                  style: theme.textTheme.caption,
                )
              else if (mutuals != null)
                MutualsLine(
                  people: mutuals.mutuals,
                  label: '${mutuals.count} mutual connections',
                )
              else
                Text('2nd · Not connected yet', style: theme.textTheme.caption),
            ],
          ),
        );
      },
    );
  }
}

class _CompanyPreview extends StatelessWidget {
  const _CompanyPreview(this.company);

  final Company company;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final network = context.demo.network;
    final entry = SearchData.companies.firstWhere(
      (entry) => entry.company == company,
      orElse: () => SearchCompany(company, '', 0),
    );
    final roles = entry.openRoles;

    return ListenableBuilder(
      listenable: network,
      builder: (context, _) => Dialog(
        style: DialogTheme(constraints: _previewConstraints),
        showCloseButton: true,
        semanticLabel: company.name,
        actions: _previewActions(context, [
          Button.outline(
            leading: const PhosphorIcon(PhosphorIconsRegular.briefcase),
            onPressed: () => Navigator.of(context).pop(DemoDestination.jobs),
            child: Text(roles == 0 ? 'Browse jobs' : 'See open roles'),
          ),
          Button(
            style: ButtonTheme(
              pressScale: 1,
            ),
            variant: network.isFollowingPage(company)
                ? ButtonVariant.secondary
                : ButtonVariant.primary,
            leading: PhosphorIcon(
              network.isFollowingPage(company)
                  ? PhosphorIconsRegular.check
                  : PhosphorIconsRegular.plus,
            ),
            onPressed: () => network.togglePage(company),
            child: Text(
              network.isFollowingPage(company) ? 'Following' : 'Follow',
            ),
          ),
        ]),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DemoMark(
              asset: company.logo,
              label: company.name,
              size: theme.avatarXl,
            ),
            const Gap.md(),
            Text(
              company.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.h3.copyWith(color: scheme.foreground),
            ),
            if (entry.tagline.isNotEmpty) ...[
              Text(
                entry.tagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.muted.copyWith(
                  color: scheme.foregroundSubtle,
                ),
              ),
            ],
            const Gap.md(),
            Text(
              [
                switch (roles) {
                  0 => 'No open roles right now',
                  1 => '1 open role',
                  _ => '$roles open roles',
                },
                ?company.website,
              ].join(' · '),
              textAlign: TextAlign.center,
              style: theme.textTheme.caption,
            ),
          ],
        ),
      ),
    );
  }
}
