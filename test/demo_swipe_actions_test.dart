import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/messages_data.dart';
import 'package:una_demo/data/notifications_data.dart';
import 'package:una_demo/screens/messages_screen.dart';
import 'package:una_demo/screens/notifications_screen.dart';
import 'package:una_demo/widgets/messages_conversation_list.dart';

import 'demo_support.dart';

// The rows of the notifications and of the conversation list have actions
// behind them: a finger swipes a row, a mouse opens them as a menu. What
// they change is the session's.

DemoNotification _notification(String id) =>
    NotificationsData.all.firstWhere((n) => n.id == id);

Conversation _conversation(String name) =>
    MessagesData.conversations.firstWhere((c) => c.name == name);

/// The conversation rows on screen, top to bottom, by name.
List<String> _conversations(WidgetTester tester) => [
  for (final conversation in MessagesData.conversations)
    if (find
        .descendant(
          of: find.byType(MessagesConversationList),
          matching: find.byKey(ValueKey(conversation.id)),
        )
        .evaluate()
        .isNotEmpty)
      conversation.name,
];

/// Swipes the row [finder] is in by [dx], slowly enough to be a drag and
/// not a fling.
Future<void> _swipe(WidgetTester tester, Finder finder, double dx) async {
  await tester.timedDrag(
    finder,
    Offset(dx, 0),
    const Duration(milliseconds: 300),
  );
  await settleFrames(tester);
}

Future<void> _secondaryClick(WidgetTester tester, Finder finder) async {
  await tester.tap(
    finder,
    buttons: kSecondaryButton,
    kind: PointerDeviceKind.mouse,
  );
  await settleFrames(tester);
}

void main() {
  setUpAll(loadDemoTestFont);

  group('a notification on a phone', () {
    const id = 'comment-omar';

    testWidgets('swiped from the end edge shows Remove and Fewer; Remove '
        'takes it out of the session, and the toast puts it back', (
      tester,
    ) async {
      await pumpDemoScreen(
        tester,
        const NotificationsScreen(),
        size: demoPhone,
      );
      final controller = demoSession(tester).notifications;
      final target = _notification(id);
      final row = find.byKey(const ValueKey(id));
      expect(row, findsOneWidget);
      expect(controller.isUnread(target), isTrue);
      final before = controller.unreadCount;
      expect(find.text('Remove'), findsNothing);

      await _swipe(tester, row, -160);
      expect(find.text('Remove'), findsOneWidget);
      expect(find.text('Fewer'), findsOneWidget);

      await tester.tap(find.text('Remove'));
      await settleFrames(tester, frames: 20);
      expect(row, findsNothing);
      expect(controller.unreadCount, before - 1);
      expect(find.text('Notification removed'), findsOneWidget);

      await tester.tap(find.widgetWithText(Button, 'Undo'));
      await settleFrames(tester);
      expect(row, findsOneWidget);
      expect(controller.isUnread(target), isTrue);
      expect(controller.unreadCount, before);
      expect(tester.takeException(), isNull);
      await dismissToasts(tester);
    });

    testWidgets('swiped all the way across is removed in one go', (
      tester,
    ) async {
      await pumpDemoScreen(
        tester,
        const NotificationsScreen(),
        size: demoPhone,
      );
      final row = find.byKey(const ValueKey(id));
      await _swipe(tester, row, -330);
      await settleFrames(tester, frames: 20);
      expect(row, findsNothing);
      expect(find.text('Notification removed'), findsOneWidget);
      await dismissToasts(tester);
    });

    testWidgets('swiped from the start edge is marked read, and unread '
        'again', (tester) async {
      await pumpDemoScreen(
        tester,
        const NotificationsScreen(),
        size: demoPhone,
      );
      final controller = demoSession(tester).notifications;
      final target = _notification(id);
      final row = find.byKey(const ValueKey(id));

      await _swipe(tester, row, 110);
      await tester.tap(find.text('Read'));
      await settleFrames(tester);
      expect(controller.isUnread(target), isFalse);
      // The row has closed over its action.
      expect(find.text('Read').hitTestable(), findsNothing);

      await _swipe(tester, row, 110);
      await tester.tap(find.text('Unread'));
      await settleFrames(tester);
      expect(controller.isUnread(target), isTrue);
    });

    testWidgets('a tap on an open row closes it instead of following it', (
      tester,
    ) async {
      await pumpDemoScreen(
        tester,
        const NotificationsScreen(),
        size: demoPhone,
      );
      final controller = demoSession(tester).notifications;
      final row = find.byKey(const ValueKey(id));
      await _swipe(tester, row, -160);
      expect(find.text('Remove').hitTestable(), findsOneWidget);

      await tester.tapAt(tester.getTopLeft(row) + const Offset(30, 30));
      await settleFrames(tester);
      expect(find.text('Remove').hitTestable(), findsNothing);
      expect(controller.isUnread(_notification(id)), isTrue);
      expect(demoDestination(tester).name, 'home');
    });

    testWidgets('a vertical drag still scrolls the page', (tester) async {
      await pumpDemoScreen(
        tester,
        const NotificationsScreen(),
        size: demoPhone,
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      await tester.drag(
        find.byKey(const ValueKey(id)),
        const Offset(4, -200),
      );
      await settleFrames(tester);
      expect(position.pixels, greaterThan(100));
      expect(find.text('Remove'), findsNothing);
    });
  });

  testWidgets('on a desktop a secondary click on a notification opens its '
      'menu, every time', (tester) async {
    await pumpDemoScreen(tester, const NotificationsScreen());
    final controller = demoSession(tester).notifications;
    const id = 'comment-omar';
    final row = find.byKey(const ValueKey(id));
    final text = find.descendant(
      of: row,
      matching: find.textContaining('commented on your post'),
    );

    await _secondaryClick(tester, text);
    expect(find.text('Mark as read'), findsOneWidget);
    expect(find.text('Show fewer like this'), findsOneWidget);
    await tester.tap(find.text('Mark as read'));
    await settleFrames(tester);
    expect(controller.isUnread(_notification(id)), isFalse);

    // And again: the menu is not left half open.
    await _secondaryClick(tester, text);
    expect(find.text('Mark as unread'), findsOneWidget);
    await tester.tap(find.text('Remove'));
    await settleFrames(tester);
    expect(row, findsNothing);
    expect(tester.takeException(), isNull);
    await dismissToasts(tester);
  });

  group('a conversation on a phone', () {
    testWidgets('swiped from the end edge can be muted or deleted; Delete '
        'takes it out of the list and off the badge, and Undo brings it '
        'back', (tester) async {
      await pumpDemoScreen(
        tester,
        const MessagesScreen(),
        size: demoPhone,
      );
      final messages = demoSession(tester).messages;
      final sara = _conversation('Sara Lindqvist');
      expect(messages.unreadOf(sara), greaterThan(0));
      final unread = messages.unreadCount.value;

      await _swipe(tester, find.text(sara.name), -160);
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Mute'));
      await settleFrames(tester);
      expect(messages.isMuted(sara), isTrue);
      // A struck-out bell before the row's time.
      expect(
        find.descendant(
          of: find.byKey(ValueKey(sara.id)),
          matching: find.byIcon(PhosphorIconsRegular.bellSimpleSlash),
        ),
        findsOneWidget,
      );
      // Muting is not opening: the conversation is still unread.
      expect(messages.unreadOf(sara), greaterThan(0));

      await _swipe(tester, find.text(sara.name), -160);
      expect(find.text('Unmute'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await settleFrames(tester, frames: 20);
      expect(_conversations(tester), isNot(contains(sara.name)));
      expect(messages.isDeleted(sara), isTrue);
      expect(messages.unreadCount.value, unread - 1);
      expect(find.text('Conversation deleted'), findsOneWidget);

      await tester.tap(find.widgetWithText(Button, 'Undo'));
      await settleFrames(tester);
      expect(_conversations(tester), contains(sara.name));
      expect(messages.unreadCount.value, unread);
      // In its old place.
      expect(
        _conversations(tester).indexOf(sara.name),
        MessagesData.conversations
            .where((c) => !c.request)
            .toList()
            .indexOf(sara),
      );
      expect(tester.takeException(), isNull);
      await dismissToasts(tester);
    });

    testWidgets('swiped from the start edge is marked read or unread, and '
        'the badge follows', (tester) async {
      await pumpDemoScreen(
        tester,
        const MessagesScreen(),
        size: demoPhone,
      );
      final messages = demoSession(tester).messages;
      final sara = _conversation('Sara Lindqvist');
      final unread = messages.unreadCount.value;

      await _swipe(tester, find.text(sara.name), 110);
      await tester.tap(find.text('Read'));
      await settleFrames(tester);
      expect(messages.unreadOf(sara), 0);
      expect(messages.unreadCount.value, unread - 1);

      await _swipe(tester, find.text(sara.name), 110);
      // The list's filter chip is called "Unread" too; the action is the
      // one behind the row.
      await tester.tap(find.text('Unread').hitTestable().last);
      await settleFrames(tester);
      expect(messages.unreadOf(sara), 1);
      expect(messages.unreadCount.value, unread);
    });

    testWidgets('the assistant can be muted but not deleted', (tester) async {
      await pumpDemoScreen(
        tester,
        const MessagesScreen(),
        size: demoPhone,
      );
      await _swipe(tester, find.text('Demo Assistant'), -160);
      expect(find.text('Mute'), findsOneWidget);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('one row is open at a time', (tester) async {
      await pumpDemoScreen(
        tester,
        const MessagesScreen(),
        size: demoPhone,
      );
      await _swipe(tester, find.text('Sara Lindqvist'), -160);
      expect(find.text('Delete').hitTestable(), findsOneWidget);
      await _swipe(tester, find.text('Claire Dubois'), -160);
      await settleFrames(tester);
      expect(find.text('Delete').hitTestable(), findsOneWidget);
    });
  });

  testWidgets('on a desktop a secondary click on a conversation offers the '
      'same actions, and deleting the open one opens the next', (
    tester,
  ) async {
    await pumpDemoScreen(tester, const MessagesScreen());
    final messages = demoSession(tester).messages;
    final omar = _conversation('Omar Rahimi');
    expect(messages.selected, omar);
    final row = find.descendant(
      of: find.byType(MessagesConversationList),
      matching: find.text(omar.name),
    );

    await _secondaryClick(tester, row);
    for (final label in ['Unread', 'Delete', 'Mute']) {
      expect(find.widgetWithText(MenuItem, label), findsOneWidget);
    }
    await tester.tap(find.widgetWithText(MenuItem, 'Delete'));
    await settleFrames(tester, frames: 40);
    expect(_conversations(tester), isNot(contains(omar.name)));
    expect(messages.selected, isNot(omar));
    expect(messages.isDeleted(messages.selected), isFalse);

    // Writing to them again brings the conversation back.
    messages.select(omar);
    await settleFrames(tester);
    expect(_conversations(tester), contains(omar.name));
    expect(tester.takeException(), isNull);
    await dismissToasts(tester);
  });
}
