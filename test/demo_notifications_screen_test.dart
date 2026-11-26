import 'dart:ui' show Tristate;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/notifications_data.dart';
import 'package:una_demo/navigation.dart';
import 'package:una_demo/screens/notifications_screen.dart';
import 'package:una_demo/widgets/demo_pieces.dart';
import 'package:una_demo/widgets/home_trending_card.dart';
import 'package:una_demo/widgets/notifications_controller.dart';
import 'package:una_demo/widgets/notifications_rail.dart';

import 'demo_support.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = demoDesktop,
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) => pumpDemoScreen(
  tester,
  const NotificationsScreen(),
  size: size,
  brightness: brightness,
  textScale: textScale,
);

NotificationsController _controller(WidgetTester tester) =>
    demoSession(tester).notifications;

DemoNotification _byId(String id) =>
    NotificationsData.all.firstWhere((n) => n.id == id);

Finder _row(String id) => find.byKey(ValueKey(id));

Finder _inRow(String id, Finder finder) =>
    find.descendant(of: _row(id), matching: finder);

/// The dots on unread rows. Their label is merged into the row's own, so
/// they are found as widgets rather than as semantics nodes.
final _unreadDots = find.byWidgetPredicate(
  (widget) => widget is Semantics && widget.properties.label == 'Unread',
);

/// The rows on screen, top to bottom.
List<String> _rows(WidgetTester tester) => [
  for (final notification in NotificationsData.all)
    if (_row(notification.id).evaluate().isNotEmpty) notification.id,
];

Future<void> _selectTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byType(Tabs<NotificationFilter>),
      matching: find.text(label),
    ),
  );
  await settleFrames(tester, frames: 6);
}

void main() {
  setUpAll(loadDemoTestFont);

  test('the data has the twelve unread the bell is drawn with', () {
    expect(NotificationsData.all, hasLength(18));
    expect(
      NotificationsData.all.where((n) => n.unread),
      hasLength(DemoCounts.unreadNotifications),
    );
    expect(
      {for (final n in NotificationsData.all) n.id},
      hasLength(NotificationsData.all.length),
      reason: 'ids are unique',
    );
    // Unread ones are the newest: none after the first read one.
    final firstRead = NotificationsData.all.indexWhere((n) => !n.unread);
    expect(NotificationsData.all.skip(firstRead).any((n) => n.unread), isFalse);
  });

  group('builds without overflowing', () {
    for (final size in demoSizes) {
      for (final brightness in Brightness.values) {
        testWidgets('at ${size.width.toInt()}x${size.height.toInt()}, '
            '${brightness.name}', (tester) async {
          await _pump(tester, size: size, brightness: brightness);

          expect(find.text('Notifications'), findsOneWidget);
          expect(_rows(tester), hasLength(18));
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
  });

  group('on a desktop (1440)', () {
    testWidgets('lists every notification under its period', (tester) async {
      await _pump(tester);

      expect(find.text('12 unread notifications.'), findsOneWidget);
      for (final (heading, fresh) in [
        ('Today', '6 new'),
        ('This week', '6 new'),
        ('Earlier', null),
      ]) {
        expect(find.text(heading), findsOneWidget);
        if (fresh != null) expect(find.text(fresh), findsNWidgets(2));
      }
      expect(_rows(tester), [for (final n in NotificationsData.all) n.id]);

      // A sentence with its names set apart, a quote, an age and a button.
      expect(
        _inRow(
          'comment-omar',
          find.text('Omar Rahimi commented on your post', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(
        _inRow('comment-omar', find.textContaining('The flow map')),
        findsOneWidget,
      );
      expect(_inRow('comment-omar', find.text('38m')), findsOneWidget);
      expect(
        _inRow('comment-omar', find.widgetWithText(DemoPillButton, 'Reply')),
        findsOneWidget,
      );
      // Unread rows carry the dot; read ones do not.
      expect(
        _inRow('comment-omar', _unreadDots),
        findsOneWidget,
      );
      expect(
        _inRow('reply-sara', _unreadDots),
        findsNothing,
      );

      // Both rails.
      expect(find.byType(NotificationsManageCard), findsOneWidget);
      expect(find.text('Your week'), findsOneWidget);
      expect(find.byType(HomeTrendingCard), findsOneWidget);
    });

    testWidgets('the rails drop away as the window narrows', (tester) async {
      await _pump(tester, size: const Size(1024, 800));
      expect(find.byType(NotificationsManageCard), findsOneWidget);
      expect(find.text('Your week'), findsNothing);

      await _pump(tester, size: const Size(800, 800));
      expect(find.byType(NotificationsManageCard), findsNothing);
      expect(find.widgetWithText(Button, 'Mark all as read'), findsOneWidget);
    });

    testWidgets('the tabs filter the list', (tester) async {
      await _pump(tester);

      await _selectTab(tester, 'Mentions');
      expect(_rows(tester), ['mention-aisha', 'mention-julian']);

      await _selectTab(tester, 'Jobs');
      expect(_rows(tester), [
        'job-kestrel',
        'application-quill',
        'job-birchline',
      ]);

      await _selectTab(tester, 'My posts');
      expect(_rows(tester), [
        'reactions-onboarding',
        'comment-omar',
        'repost-mei',
        'reactions-interviews',
        'reply-sara',
      ]);

      await _selectTab(tester, 'All');
      expect(_rows(tester), hasLength(18));
    });

    testWidgets('"Mark all as read" clears every dot and the count', (
      tester,
    ) async {
      await _pump(tester);
      final markAll = find.widgetWithText(Button, 'Mark all as read');
      expect(tester.widget<Button>(markAll).enabled, isTrue);
      expect(_unreadDots, findsNWidgets(12));

      await tester.tap(markAll);
      await settleFrames(tester, frames: 4);

      expect(find.text('You are all caught up.'), findsOneWidget);
      expect(_unreadDots, findsNothing);
      expect(find.textContaining(' new'), findsNothing);
      expect(tester.widget<Button>(markAll).enabled, isFalse);
      expect(_controller(tester).unreadCount, 0);
    });

    testWidgets('a row is read once opened, and leads to its subject', (
      tester,
    ) async {
      await _pump(tester);
      expect(demoDestination(tester), DemoDestination.home);

      await tester.tap(
        _inRow('job-kestrel', find.textContaining('strong match')),
      );
      await settleFrames(tester, frames: 4);

      expect(demoDestination(tester), DemoDestination.jobs);
      expect(_controller(tester).isUnread(_byId('job-kestrel')), isFalse);
      expect(find.text('11 unread notifications.'), findsOneWidget);

      await scrollToAndTap(
        tester,
        _inRow('views-week', find.textContaining('viewed your profile')),
      );
      expect(demoDestination(tester), DemoDestination.profile);

      // A row's button goes there too.
      await scrollToAndTap(
        tester,
        _inRow(
          'connection-emil',
          find.widgetWithText(DemoPillButton, 'Message'),
        ),
      );
      expect(demoDestination(tester), DemoDestination.messages);
      expect(_controller(tester).unreadCount, 9);
    });

    testWidgets('"Accept" answers the invitation in place', (tester) async {
      await _pump(tester);
      final network = demoSession(tester).network;
      expect(network.pending, hasLength(3));

      await scrollToAndTap(
        tester,
        _inRow(
          'invitation-irina',
          find.widgetWithText(DemoPillButton, 'Accept'),
        ),
      );

      expect(network.isConnected(People.irina), isTrue);
      expect(network.pending, hasLength(2));
      expect(
        _inRow(
          'invitation-irina',
          find.widgetWithText(DemoPillButton, 'Connected'),
        ),
        findsOneWidget,
      );
      expect(_controller(tester).isUnread(_byId('invitation-irina')), isFalse);
      // Still here: answering is not navigating.
      expect(demoDestination(tester), DemoDestination.home);
      await dismissToasts(tester);
    });

    testWidgets('a button that sends something says so, once', (tester) async {
      await _pump(tester);

      final wish = _inRow(
        'birthday-claire',
        find.widgetWithText(DemoPillButton, 'Say happy birthday'),
      );
      await scrollToAndTap(tester, wish);

      expect(find.text('Birthday wishes sent to Claire'), findsOneWidget);
      final sent = _inRow(
        'birthday-claire',
        find.widgetWithText(DemoPillButton, 'Sent'),
      );
      expect(sent, findsOneWidget);
      expect(tester.widget<DemoPillButton>(sent).onPressed, isNull);
      await dismissToasts(tester);
    });

    testWidgets('a row\'s menu marks it unread and removes it', (tester) async {
      await _pump(tester);
      final controller = _controller(tester);
      final target = _byId('reply-sara');

      Future<void> openMenu() async {
        await scrollToAndTap(
          tester,
          _inRow('reply-sara', find.bySemanticsLabel('More options')),
        );
      }

      await openMenu();
      await tester.tap(find.text('Mark as unread'));
      await settleFrames(tester);
      expect(controller.isUnread(target), isTrue);
      expect(find.text('13 unread notifications.'), findsOneWidget);

      await openMenu();
      expect(find.text('Mark as read'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await settleFrames(tester);
      expect(_row('reply-sara'), findsNothing);
      expect(controller.unreadCount, 12);
      expect(find.text('Notification removed'), findsOneWidget);

      // "Undo" puts it back, unread as it was.
      await tester.tap(find.widgetWithText(Button, 'Undo'));
      await settleFrames(tester);
      expect(_row('reply-sara'), findsOneWidget);
      expect(controller.isUnread(target), isTrue);
      await dismissToasts(tester);
    });

    testWidgets('an emptied tab says so and offers the rest', (tester) async {
      await _pump(tester);
      final controller = _controller(tester);
      controller
        ..remove(_byId('mention-aisha'))
        ..remove(_byId('mention-julian'));

      await _selectTab(tester, 'Mentions');
      expect(find.text('Nothing here'), findsOneWidget);
      expect(
        find.text('No notifications under Mentions right now.'),
        findsOneWidget,
      );

      await tester.tap(
        find.widgetWithText(Button, 'Show all notifications'),
      );
      await settleFrames(tester, frames: 6);
      expect(controller.filter, NotificationFilter.all);
      expect(_rows(tester), hasLength(16));
    });

    testWidgets('the quick switches are the settings\' own', (tester) async {
      await _pump(tester);
      final settings = demoSession(tester).settings;
      expect(settings.pauseAll, isFalse);

      await tester.tap(
        find
            .descendant(
              of: find.byType(NotificationsManageCard),
              matching: find.byType(Switch),
            )
            .first,
      );
      await settleFrames(tester, frames: 6);
      expect(settings.pauseAll, isTrue);
    });

    testWidgets('a row\'s hover fill follows the theme\'s motion', (
      tester,
    ) async {
      // A read row: an unread one carries its wash whether hovered or not.
      final read = NotificationsData.all.firstWhere((n) => !n.unread);
      Color? fill() {
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.descendant(
                  of: _row(read.id),
                  matching: find.byType(AnimatedFill),
                ),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (box.decoration as BoxDecoration).color;
      }

      Future<List<double>> hover(ThemeData theme) async {
        await pumpDemoScreen(
          tester,
          const NotificationsScreen(),
          theme: theme,
        );
        await Scrollable.ensureVisible(
          tester.element(_row(read.id)),
          alignment: .5,
        );
        await tester.pump();
        expect(fill()?.a ?? 0, 0);
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);
        await mouse.moveTo(
          tester.getTopLeft(_row(read.id)) + const Offset(8, 8),
        );
        await tester.pump();
        final alphas = <double>[];
        for (var i = 0; i < 12; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          alphas.add(fill()?.a ?? 0);
        }
        await mouse.removePointer();
        await tester.pumpWidget(const SizedBox.shrink());
        return alphas;
      }

      final font = TextTheme(family: demoTestFont);
      // The fill a hovered row ends on; a translucent wash in this scheme.
      final full = ThemeData(textTheme: font).colorScheme.muted.a;
      // With motion off the fill is simply there on the next frame…
      final still = await hover(
        ThemeData(textTheme: font, motion: Motion.none),
      );
      expect(still.first, moreOrLessEquals(full));
      // …and with it on, it fades in and never dips on the way.
      final moving = await hover(ThemeData(textTheme: font));
      expect(moving.first, inExclusiveRange(0, full));
      expect(moving.last, moreOrLessEquals(full));
      for (var i = 1; i < moving.length; i++) {
        expect(moving[i], greaterThanOrEqualTo(moving[i - 1]));
      }
    });

    testWidgets('each quick switch is announced once, under its label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      final labels = [
        for (final text in tester.widgetList<Text>(
          find.descendant(
            of: find.descendant(
              of: find.byType(NotificationsManageCard),
              matching: find.byType(MergeSemantics),
            ),
            matching: find.byType(Text),
          ),
        ))
          text.data!,
      ];
      // A label and a sentence for each of the three switches.
      expect(labels, hasLength(6));
      for (var i = 0; i < labels.length; i += 2) {
        // "Mentions" is also one of the page's filter tabs: a button.
        final stops = [
          for (final stop in announced(tester, labels[i]))
            if (!stop.flagsCollection.isButton) stop,
        ];
        expect(stops, hasLength(1), reason: labels[i]);
        expect(
          stops.single.flagsCollection.isToggled,
          isNot(Tristate.none),
          reason: labels[i],
        );
      }
      handle.dispose();
    });
  });

  group('on a phone (390x844)', () {
    testWidgets('shows the title, its two actions and the control', (
      tester,
    ) async {
      await _pump(tester, size: demoPhone);

      expect(find.text('Notifications'), findsOneWidget);
      // The desktop's lead line, rails and text buttons are gone.
      expect(find.textContaining('unread notifications'), findsNothing);
      expect(find.byType(NotificationsManageCard), findsNothing);
      expect(find.widgetWithText(Button, 'Mark all as read'), findsNothing);
      expect(find.bySemanticsLabel('Mark all as read'), findsOneWidget);
      expect(find.bySemanticsLabel('Notification settings'), findsOneWidget);

      // The control fills the width.
      final tabs = find.byType(Tabs<NotificationFilter>);
      expect(tester.getSize(tabs).width, demoPhone.width - 32);

      await _selectTab(tester, 'Jobs');
      expect(_rows(tester), hasLength(3));

      await tester.tap(find.bySemanticsLabel('Mark all as read'));
      await settleFrames(tester, frames: 4);
      expect(_controller(tester).unreadCount, 0);
      expect(tester.takeException(), isNull);
    });
  });
}
