import 'package:finesse_demo/data.dart';
import 'package:finesse_demo/data/network_data.dart';
import 'package:finesse_demo/navigation.dart';
import 'package:finesse_demo/screens/network_screen.dart';
import 'package:finesse_demo/widgets/network_controller.dart';
import 'package:finesse_demo/widgets/network_invitations_card.dart';
import 'package:finesse_demo/widgets/network_rail.dart';
import 'package:finesse_demo/widgets/network_section_view.dart';
import 'package:finesse_demo/widgets/network_suggestions.dart';
import 'package:finesse_demo/widgets/demo_pieces.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'demo_support.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = demoDesktop,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => pumpDemoScreen(
  tester,
  const NetworkScreen(),
  size: size,
  brightness: brightness,
  textScale: textScale,
);

NetworkController _network(WidgetTester tester) => demoSession(tester).network;

Finder _in(Type type, Finder finder) =>
    find.descendant(of: find.byType(type), matching: finder);

/// The pill of [label] nearest to the text [name]: the one in its row.
Finder _pillFor(String name, String label) {
  final anchor = find.text(name).evaluate().first.renderObject! as RenderBox;
  final origin = anchor.localToGlobal(anchor.size.centerLeft(Offset.zero));
  final pills = find.widgetWithText(DemoPillButton, label);
  var best = 0;
  var bestDistance = double.infinity;
  for (final (index, element) in pills.evaluate().indexed) {
    final box = element.renderObject! as RenderBox;
    final centre = box.localToGlobal(box.size.center(Offset.zero));
    // A row is wide and short: being level counts for more than being near.
    final distance =
        (centre.dy - origin.dy).abs() * 4 + (centre.dx - origin.dx).abs();
    if (distance < bestDistance) {
      best = index;
      bestDistance = distance;
    }
  }
  return pills.at(best);
}

/// The pill of [label] in the invitation from [name].
Finder _invitationPill(String name, String label) => find.descendant(
  of: find.byKey(ValueKey(name)),
  matching: find.widgetWithText(DemoPillButton, label),
);

void main() {
  setUpAll(loadDemoTestFont);

  group('builds without overflowing', () {
    for (final size in demoSizes) {
      for (final brightness in Brightness.values) {
        testWidgets('at ${size.width.toInt()}x${size.height.toInt()}, '
            '${brightness.name}', (tester) async {
          await _pump(tester, size: size, brightness: brightness);

          expect(find.text('Network'), findsOneWidget);
          expect(find.byType(NetworkSuggestions), findsOneWidget);
          expect(tester.takeException(), isNull);

          await scrollThrough(tester);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('at 1.3x text, on every form factor', (tester) async {
      for (final size in const [demoDesktop, Size(900, 800), demoPhone]) {
        await _pump(tester, size: size, textScale: 1.3);
        await scrollThrough(tester);
        expect(tester.takeException(), isNull, reason: '$size');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('every list behind "Manage my network", wide and narrow', (
      tester,
    ) async {
      for (final size in const [demoDesktop, Size(800, 800)]) {
        await _pump(tester, size: size);
        for (final section in NetworkSection.managed) {
          _network(tester).section = section;
          await settleFrames(tester, frames: 3);
          expect(find.byType(NetworkSectionView), findsOneWidget);
          await scrollThrough(tester);
          expect(tester.takeException(), isNull, reason: '$section at $size');
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });

  group('on a desktop (1440)', () {
    testWidgets('shows the header, both rails and the two main blocks', (
      tester,
    ) async {
      await _pump(tester);

      expect(
        find.text('3 invitations waiting · 512 connections'),
        findsOneWidget,
      );
      expect(find.widgetWithText(Button, 'Invite people'), findsOneWidget);
      expect(
        find.widgetWithText(Button, 'Invitation settings'),
        findsOneWidget,
      );

      // The left rail: the default view, then the five lists with counts.
      expect(find.text('Manage my network'), findsOneWidget);
      for (final (label, count) in [
        ('Connections', '512'),
        ('Following', '86'),
        ('Groups', '3'),
        ('Events', '1'),
        ('Pages', '4'),
      ]) {
        final row = _in(NetworkManageCard, find.widgetWithText(Button, label));
        expect(row, findsOneWidget, reason: label);
        expect(
          find.descendant(of: row, matching: find.text(count)),
          findsOneWidget,
          reason: label,
        );
      }

      // The main column.
      expect(find.text('Invitations'), findsOneWidget);
      for (final invitation in NetworkData.invitations) {
        expect(
          _in(NetworkInvitationsCard, find.text(invitation.person.name)),
          findsOneWidget,
        );
      }
      expect(find.text('9 mutual · 3h ago'), findsOneWidget);
      expect(find.textContaining('We overlapped at Birchline'), findsOneWidget);
      expect(find.text('People you may know'), findsOneWidget);
      // Two whole rows of three, and a button for the rest.
      expect(
        _in(
          NetworkSuggestions,
          find.widgetWithText(DemoPillButton, 'Connect'),
        ),
        findsNWidgets(6),
      );
      expect(find.text('Show 2 more people'), findsOneWidget);

      // The right rail.
      expect(find.text('Upcoming events'), findsOneWidget);
      expect(find.text('Config Nordics 2026'), findsOneWidget);
      expect(find.byType(DemoDateTile), findsNWidgets(3));
      expect(find.text('Groups you may like'), findsOneWidget);
      expect(find.text('Research Ops Nordics'), findsOneWidget);
    });

    testWidgets('the rails drop away as the window narrows', (tester) async {
      await _pump(tester, size: const Size(1024, 800));
      expect(find.byType(NetworkManageCard), findsOneWidget);
      expect(find.byType(NetworkEventsCard), findsNothing);

      await _pump(tester, size: const Size(800, 800));
      expect(find.byType(NetworkManageCard), findsNothing);
      // Its rows are chips over the main column instead.
      expect(find.widgetWithText(Chip, 'Connections · 512'), findsOneWidget);
      expect(
        tester.widget<Chip>(find.widgetWithText(Chip, 'Grow · 3')).selected,
        isTrue,
      );
    });

    testWidgets('accepting an invitation moves every count', (tester) async {
      await _pump(tester);

      await tester.tap(_invitationPill('Irina Volkova', 'Accept'));
      await settleFrames(tester);

      expect(
        _in(NetworkInvitationsCard, find.text('Irina Volkova')),
        findsNothing,
      );
      expect(
        find.text('2 invitations waiting · 513 connections'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _in(
            NetworkManageCard,
            find.widgetWithText(Button, 'Connections'),
          ),
          matching: find.text('513'),
        ),
        findsOneWidget,
      );
      expect(_network(tester).isConnected(People.irina), isTrue);
      expect(
        find.text('You and Irina are now connected'),
        findsOneWidget,
      );

      // "Undo" on the toast puts the invitation back.
      await tester.tap(find.widgetWithText(Button, 'Undo'));
      await settleFrames(tester);
      expect(
        _in(NetworkInvitationsCard, find.text('Irina Volkova')),
        findsOneWidget,
      );
      expect(
        find.text('3 invitations waiting · 512 connections'),
        findsOneWidget,
      );
      await dismissToasts(tester);
    });

    test('"Undo" on an ignored invitation does not undo a later Accept', () {
      final network = NetworkController();
      final invitation = NetworkData.invitations.first;
      final person = invitation.person;

      // "Ignore" on the Network screen; its toast offers Undo for a while.
      network.ignore(invitation);
      expect(network.pending, isNot(contains(invitation)));
      // The notification about it still offers "Accept".
      network.accept(invitation);
      expect(network.isConnected(person), isTrue);

      // The first toast's "Undo" takes back the ignore, and only that.
      network.undoIgnore(invitation);
      expect(network.isConnected(person), isTrue);
      expect(network.pending, isNot(contains(invitation)));

      // The accept's own undo puts the invitation back in the list — not
      // back among the ignored.
      network.undoAccept(invitation);
      expect(network.isConnected(person), isFalse);
      expect(network.pending, contains(invitation));
    });

    testWidgets('"Undo" on the toast puts an ignored invitation back', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(_invitationPill('Irina Volkova', 'Ignore'));
      await settleFrames(tester);
      expect(
        _in(NetworkInvitationsCard, find.text('Irina Volkova')),
        findsNothing,
      );
      await tester.tap(find.widgetWithText(Button, 'Undo'));
      await settleFrames(tester);
      expect(
        _in(NetworkInvitationsCard, find.text('Irina Volkova')),
        findsOneWidget,
      );
      expect(_network(tester).isConnected(People.irina), isFalse);
      await dismissToasts(tester);
    });

    testWidgets('answering them all leaves a note, not a hole', (tester) async {
      await _pump(tester);

      await tester.tap(_invitationPill('Irina Volkova', 'Ignore'));
      await settleFrames(tester, frames: 3);
      await tester.tap(_invitationPill('Mateo Alvarez', 'Accept'));
      await settleFrames(tester, frames: 3);
      await tester.tap(_invitationPill('Jonas Berg', 'Ignore'));
      await settleFrames(tester, frames: 3);

      expect(find.text('You are all caught up'), findsOneWidget);
      expect(
        find.text('No invitations waiting · 513 connections'),
        findsOneWidget,
      );
      expect(find.byType(NetworkInvitationsCard), findsOneWidget);
      await dismissToasts(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Connect toggles to Pending, and a card can be dismissed', (
      tester,
    ) async {
      await _pump(tester);
      final card = find.byKey(const ValueKey('Elena Petrova'));
      Finder inCard(Finder finder) =>
          find.descendant(of: card, matching: finder);

      await scrollToAndTap(tester, inCard(find.text('Connect')));
      expect(inCard(find.text('Pending')), findsOneWidget);
      expect(_network(tester).isRequested(People.elena), isTrue);

      await scrollToAndTap(tester, inCard(find.text('Pending')));
      expect(inCard(find.text('Connect')), findsOneWidget);

      await scrollToAndTap(
        tester,
        inCard(find.bySemanticsLabel('Dismiss Elena Petrova')),
      );
      expect(card, findsNothing);
      // The next suggestion takes the empty place: still two whole rows.
      expect(
        _in(
          NetworkSuggestions,
          find.widgetWithText(DemoPillButton, 'Connect'),
        ),
        findsNWidgets(6),
      );
      expect(find.text('Show 1 more person'), findsOneWidget);
    });

    testWidgets('"Show more people" reveals the rest of the grid', (
      tester,
    ) async {
      await _pump(tester);

      await scrollToAndTap(tester, find.text('Show 2 more people'));
      expect(
        _in(
          NetworkSuggestions,
          find.widgetWithText(DemoPillButton, 'Connect'),
        ),
        findsNWidgets(8),
      );
      expect(find.textContaining('more people'), findsNothing);
    });

    testWidgets('a rail row swaps the main column for its list', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(
        _in(NetworkManageCard, find.widgetWithText(Button, 'Connections')),
      );
      await settleFrames(tester, frames: 3);

      expect(find.byType(NetworkInvitationsCard), findsNothing);
      expect(find.byType(NetworkSuggestions), findsNothing);
      final list = find.byType(NetworkSectionView);
      expect(list, findsOneWidget);
      expect(find.text('512 connections'), findsOneWidget);
      expect(
        find.descendant(of: list, matching: find.text('Omar Rahimi')),
        findsOneWidget,
      );
      expect(find.text('Connected in April 2020'), findsOneWidget);

      // The sort menu reorders it.
      List<String> names() => [
        for (final entry in _network(tester).connections) entry.person.name,
      ];
      expect(names().first, 'Emil Sandberg');
      await tester.tap(find.text('Recently added'));
      await settleFrames(tester);
      await tester.tap(find.text('First name'));
      await settleFrames(tester);
      expect(names().first, 'Aisha Rahman');
      expect(
        tester.getTopLeft(find.text('Aisha Rahman')).dy,
        lessThan(tester.getTopLeft(find.text('Emil Sandberg')).dy),
      );

      // "Message" leaves for Messages.
      await scrollToAndTap(
        tester,
        find.widgetWithText(Button, 'Message').first,
      );
      expect(demoDestination(tester), DemoDestination.messages);

      // And the first row leads back.
      await tester.tap(
        _in(
          NetworkManageCard,
          find.widgetWithText(Button, 'Grow your network'),
        ),
      );
      await settleFrames(tester, frames: 3);
      expect(find.byType(NetworkSuggestions), findsOneWidget);
    });

    testWidgets('joining, attending and following move the rail counts', (
      tester,
    ) async {
      await _pump(tester);
      Finder count(String label, String value) => find.descendant(
        of: _in(NetworkManageCard, find.widgetWithText(Button, label)),
        matching: find.text(value),
      );

      // From the right rail.
      await tester.tap(_pillFor('Research Ops Nordics', 'Join'));
      await settleFrames(tester, frames: 3);
      expect(count('Groups', '4'), findsOneWidget);
      expect(_pillFor('Research Ops Nordics', 'Joined'), findsOneWidget);

      await tester.tap(
        _in(
          NetworkEventsCard,
          find.widgetWithText(DemoPillButton, 'Attend'),
        ).first,
      );
      await settleFrames(tester, frames: 3);
      expect(count('Events', '2'), findsOneWidget);

      // "See all" opens the list, where the same answer shows.
      await tester.tap(_in(NetworkEventsCard, find.text('See all')));
      await settleFrames(tester, frames: 3);
      expect(_network(tester).section, NetworkSection.events);
      expect(find.text('You are going to 2 events'), findsOneWidget);
      expect(find.text('387 going'), findsOneWidget);

      await tester.tap(
        _in(NetworkManageCard, find.widgetWithText(Button, 'Pages')),
      );
      await settleFrames(tester, frames: 3);
      await scrollToAndTap(tester, _pillFor('Kestrel Health', 'Follow'));
      expect(count('Pages', '5'), findsOneWidget);
      expect(find.text('You follow 5 pages'), findsOneWidget);
    });

    testWidgets('a name opens a preview, whose buttons work', (tester) async {
      await _pump(tester);

      await tester.tap(
        _in(NetworkInvitationsCard, find.text('Mateo Alvarez')),
      );
      await settleFrames(tester);

      final dialog = find.byType(Dialog);
      Finder inDialog(Finder finder) =>
          find.descendant(of: dialog, matching: finder);
      expect(dialog, findsOneWidget);
      expect(inDialog(find.text('Product designer at Tidewater')), findsOne);
      expect(inDialog(find.text('6 mutual connections')), findsOneWidget);

      await tester.tap(inDialog(find.widgetWithText(Button, 'Connect')));
      await settleFrames(tester, frames: 3);
      expect(inDialog(find.widgetWithText(Button, 'Pending')), findsOneWidget);
      expect(_network(tester).isRequested(People.mateo), isTrue);

      await tester.tap(inDialog(find.widgetWithText(Button, 'Message')));
      await settleFrames(tester);
      expect(dialog, findsNothing);
      expect(demoDestination(tester), DemoDestination.messages);
    });

    testWidgets('"Invite people" asks for an address and confirms', (
      tester,
    ) async {
      await _pump(tester);

      await tester.tap(find.widgetWithText(Button, 'Invite people'));
      await settleFrames(tester);
      final send = find.widgetWithText(Button, 'Send invitation');
      expect(tester.widget<Button>(send).enabled, isFalse);

      await tester.enterText(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        ),
        'freja@halcyon.app',
      );
      await tester.pump();
      expect(tester.widget<Button>(send).enabled, isTrue);
      await tester.tap(send);
      await settleFrames(tester);

      expect(find.byType(Dialog), findsNothing);
      expect(find.text('Invitation sent'), findsOneWidget);
      expect(find.textContaining('freja@halcyon.app'), findsOneWidget);
      await dismissToasts(tester);
    });
  });

  group('on a phone (390x844)', () {
    testWidgets('opens on Grow, with the invitations a tab away', (
      tester,
    ) async {
      await _pump(tester, size: demoPhone);

      for (final label in ['Grow', 'Invitations · 3', 'My network']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // The desktop's header line and rails are gone.
      expect(find.textContaining('connections'), findsNothing);
      expect(find.byType(NetworkManageCard), findsNothing);
      expect(find.byType(NetworkInvitationsCard), findsNothing);

      expect(find.text('3 invitations waiting'), findsOneWidget);
      expect(find.text('People you may know'), findsOneWidget);
      // Two across.
      final first = tester.getTopLeft(
        find.byKey(const ValueKey('Elena Petrova')),
      );
      final second = tester.getTopLeft(
        find.byKey(const ValueKey('Ingrid Dahl')),
      );
      expect(first.dy, second.dy);
      expect(second.dx, greaterThan(first.dx));

      // The teaser is a shortcut to the tab.
      await tester.tap(find.text('3 invitations waiting'));
      await settleFrames(tester, frames: 4);
      expect(find.byType(NetworkInvitationsCard), findsOneWidget);
      expect(find.byType(NetworkSuggestions), findsNothing);

      await tester.tap(_invitationPill('Mateo Alvarez', 'Accept'));
      await settleFrames(tester, frames: 4);
      expect(find.text('Invitations · 2'), findsOneWidget);
      await dismissToasts(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"My network" rows open their lists as pages', (tester) async {
      await _pump(tester, size: demoPhone);

      await tester.tap(find.text('My network'));
      await settleFrames(tester, frames: 4);
      expect(find.byType(NetworkManageCard), findsOneWidget);
      // No "Grow" row here: it is a tab.
      expect(find.text('Grow your network'), findsNothing);
      expect(find.byType(NetworkEventsCard), findsOneWidget);

      await tester.tap(
        _in(NetworkManageCard, find.widgetWithText(Button, 'Groups')),
      );
      await settleFrames(tester);

      final page = find.byType(NetworkSectionPage);
      expect(page, findsOneWidget);
      expect(
        find.descendant(
          of: find.descendant(of: page, matching: find.byType(AppBar)),
          matching: find.text('Groups'),
        ),
        findsOneWidget,
      );
      expect(find.text('You are in 3 groups'), findsOneWidget);
      expect(find.text('18,402 members · 12 new posts'), findsOneWidget);

      await scrollToAndTap(tester, _pillFor('Calm Software Club', 'Join'));
      expect(find.text('You are in 4 groups'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await settleFrames(tester);
      expect(page, findsNothing);
      // The page and the list under it are one state.
      expect(
        find.descendant(
          of: _in(NetworkManageCard, find.widgetWithText(Button, 'Groups')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
