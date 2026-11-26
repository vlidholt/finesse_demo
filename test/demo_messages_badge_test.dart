// The navigation's Messages badge: it counts the session's conversations
// with something unread, on every screen, as they are read and as replies
// arrive.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/messages_data.dart';
import 'package:una_demo/screens/messages_screen.dart';
import 'package:una_demo/session.dart';
import 'package:una_demo/widgets/messages_assistant.dart';
import 'package:una_demo/widgets/messages_composer.dart';
import 'package:una_demo/widgets/messages_controller.dart';
import 'package:una_demo/widgets/messages_conversation.dart';
import 'package:una_demo/widgets/messages_conversation_list.dart';

import 'support.dart';

void main() {
  setUpAll(setUpFonts);

  group('the controller', () {
    // Quick, and nobody but the people: a test feeds the assistant by hand.
    const replies = MessagesReplies(
      typingDelay: Duration(milliseconds: 100),
      replyDelay: Duration(milliseconds: 200),
      assistant: null,
    );

    MessagesController controller({
      MessagesReplies replies = replies,
    }) {
      final controller = MessagesController(replies: replies);
      addTearDown(controller.dispose);
      return controller;
    }

    test('counts the conversations with something unread, not the '
        'requests', () {
      final messages = controller();
      final unread = [
        for (final conversation in MessagesData.conversations)
          if (messages.unreadOf(conversation) > 0) conversation.id,
      ];
      // Two conversations and two requests, in the designs' data.
      expect(unread, ['sara', 'design-systems-guild', 'rafael', 'irina']);
      expect(messages.unreadCount.value, 2);
      // The same rows the list's "Unread" filter shows.
      messages.filter = MessageFilter.unread;
      expect(
        messages.visible.where((c) => messages.unreadOf(c) > 0),
        hasLength(messages.unreadCount.value),
      );
    });

    test('opening a conversation reads it, and the count says so once', () {
      final messages = controller();
      final counts = <int>[];
      messages.unreadCount.addListener(
        () => counts.add(messages.unreadCount.value),
      );

      messages.select(MessagesData.sara);
      expect(messages.unreadOf(MessagesData.sara), 0);
      expect(counts, [1]);
      // Again, and a conversation with nothing unread: no news.
      messages
        ..select(MessagesData.sara)
        ..select(MessagesData.claire);
      expect(counts, [1]);

      messages.select(MessagesData.designSystemsGuild);
      expect(counts, [1, 0]);
      // A request that is opened is read too, and was never counted.
      messages.select(MessagesData.rafael);
      expect(messages.unreadOf(MessagesData.rafael), 0);
      expect(counts, [1, 0]);
    });

    testWidgets('a reply is read in the thread on screen and unread '
        'anywhere else', (tester) async {
      final messages = controller()
        ..select(MessagesData.sara)
        ..select(MessagesData.designSystemsGuild)
        ..threadVisible = true;
      expect(messages.unreadCount.value, 0);

      // Watching the thread it lands in.
      messages
        ..select(MessagesData.claire)
        ..send(MessagesData.claire, 'Are you free on Thursday?');
      await tester.pump(const Duration(milliseconds: 400));
      expect(messages.messagesOf(MessagesData.claire).last.text, isNotNull);
      expect(messages.unreadOf(MessagesData.claire), 0);
      expect(messages.unreadCount.value, 0);

      // Written to, then left for another conversation.
      messages
        ..send(MessagesData.claire, 'Or Friday?')
        ..select(MessagesData.sara);
      await tester.pump(const Duration(milliseconds: 400));
      expect(messages.unreadOf(MessagesData.claire), 1);
      expect(messages.unreadCount.value, 1);
      expect(messages.unreadOf(MessagesData.sara), 0);

      // Still selected, but no longer on screen: the list of a phone, or
      // another destination.
      messages
        ..send(MessagesData.sara, 'See you there.')
        ..threadVisible = false;
      await tester.pump(const Duration(milliseconds: 400));
      expect(messages.unreadOf(MessagesData.sara), 1);
      expect(messages.unreadCount.value, 2);

      // A second reply to the same conversation is one more message in
      // it, not one more conversation.
      messages.send(MessagesData.sara, 'Hello?');
      await tester.pump(const Duration(milliseconds: 400));
      expect(messages.unreadOf(MessagesData.sara), 2);
      expect(messages.unreadCount.value, 2);
    });

    testWidgets('a thread that comes on screen is read, after the frame', (
      tester,
    ) async {
      final messages = controller()..select(MessagesData.claire);
      messages
        ..send(MessagesData.claire, 'Are you free on Thursday?')
        ..threadVisible = false;
      await tester.pump(const Duration(milliseconds: 400));
      expect(messages.unreadOf(MessagesData.claire), 1);
      expect(messages.unreadCount.value, 3);

      var notified = 0;
      messages.addListener(() => notified++);
      // As the screen does it: from a build. Nothing is announced yet.
      messages.threadVisible = true;
      expect(notified, 0);
      expect(messages.unreadCount.value, 3);
      await tester.pump();
      expect(messages.unreadOf(MessagesData.claire), 0);
      expect(messages.unreadCount.value, 2);
      expect(notified, 1);
    });

    testWidgets("the assistant's answer counts once, when its first words "
        'arrive', (tester) async {
      final answer = StreamController<String>();
      addTearDown(answer.close);
      final messages = controller(
        replies: MessagesReplies(
          typingDelay: Duration.zero,
          replyDelay: Duration.zero,
          assistant: (_) => answer.stream,
        ),
      );
      messages
        ..select(MessagesData.assistant)
        ..send(MessagesData.assistant, 'Draft a post')
        ..select(MessagesData.claire);
      await tester.pump();
      // Thinking is not an answer.
      expect(messages.unreadOf(MessagesData.assistant), 0);

      answer.add('Here ');
      await tester.pump();
      expect(messages.unreadOf(MessagesData.assistant), 1);
      expect(messages.unreadCount.value, 3);
      answer
        ..add('is a ')
        ..add('draft.');
      await tester.pump();
      expect(messages.unreadOf(MessagesData.assistant), 1);
      expect(messages.unreadCount.value, 3);

      // Clearing the thread leaves nothing unread in it.
      messages.clear(MessagesData.assistant);
      expect(messages.unreadOf(MessagesData.assistant), 0);
      expect(messages.unreadCount.value, 2);
    });
  });

  group('in the app', () {
    Finder inTopBar(Finder finder) =>
        find.descendant(of: find.byType(NavigationBar), matching: finder);
    Finder inAppBar(Finder finder) =>
        find.descendant(of: find.byType(AppBar), matching: finder);
    Finder inList(Finder finder) => find.descendant(
      of: find.byType(MessagesConversationList),
      matching: finder,
    );
    final field = find.descendant(
      of: find.byType(MessagesComposer),
      matching: find.byType(EditableText),
    );

    MessagesController messages(WidgetTester tester) =>
        demoSessionProvider.of(appContext(tester)).messages;

    Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
      await tester.tap(finder);
      await settle(tester);
    }

    Future<void> send(WidgetTester tester, String text) async {
      await tester.enterText(field, text);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pump();
    }

    /// Long enough for someone to start typing and to answer, at the
    /// app's own pace.
    Future<void> waitForReply(WidgetTester tester) =>
        settle(tester, frames: 80);

    testWidgets('on a desktop the badge goes down as conversations are '
        'opened', (tester) async {
      await pumpApp(tester);
      expect(inTopBar(find.text('2')), findsOneWidget);
      expect(messages(tester).unreadCount.value, 2);

      await tapAndSettle(tester, inTopBar(find.text('Messages')));
      // The open conversation had nothing unread.
      expect(inTopBar(find.text('2')), findsOneWidget);

      await tapAndSettle(tester, inList(find.text('Sara Lindqvist')));
      expect(inTopBar(find.text('2')), findsNothing);
      expect(inTopBar(find.text('1')), findsOneWidget);

      await tapAndSettle(tester, inList(find.text('Design Systems Guild')));
      expect(messages(tester).unreadCount.value, 0);
      expect(inTopBar(find.text('1')), findsNothing);
      // The bell's count is its own.
      expect(inTopBar(find.text('12')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a reply to a conversation that was left for another one '
        'counts', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, inTopBar(find.text('Messages')));
      await tapAndSettle(tester, inList(find.text('Sara Lindqvist')));
      expect(inTopBar(find.text('1')), findsOneWidget);

      await send(tester, 'Thursday works.');
      await tapAndSettle(tester, inList(find.text('Claire Dubois')));
      expect(inTopBar(find.text('1')), findsOneWidget);

      await waitForReply(tester);
      expect(messages(tester).unreadOf(MessagesData.sara), 1);
      expect(inTopBar(find.text('2')), findsOneWidget);

      // Opening it again reads it.
      await tapAndSettle(tester, inList(find.text('Sara Lindqvist')));
      expect(inTopBar(find.text('2')), findsNothing);
      expect(inTopBar(find.text('1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a reply that arrives while another screen is showing '
        'counts, and is read on coming back', (tester) async {
      await pumpApp(tester);
      await tapAndSettle(tester, inTopBar(find.text('Messages')));
      expect(messages(tester).threadVisible, isTrue);
      await tapAndSettle(tester, inList(find.text('Claire Dubois')));
      await send(tester, 'Are you free on Thursday?');

      await tapAndSettle(tester, inTopBar(find.text('Home')));
      expect(find.byType(MessagesScreen), findsNothing);
      expect(messages(tester).threadVisible, isFalse);
      expect(inTopBar(find.text('2')), findsOneWidget);

      await waitForReply(tester);
      expect(messages(tester).unreadOf(MessagesData.claire), 1);
      expect(inTopBar(find.text('3')), findsOneWidget);

      // Back on Messages her thread is the one showing.
      await tapAndSettle(tester, inTopBar(find.text('Messages')));
      expect(messages(tester).unreadOf(MessagesData.claire), 0);
      expect(inTopBar(find.text('3')), findsNothing);
      expect(inTopBar(find.text('2')), findsOneWidget);

      // And a reply that arrives while it shows is read as it lands.
      await send(tester, 'Or Friday?');
      await waitForReply(tester);
      expect(messages(tester).unreadOf(MessagesData.claire), 0);
      expect(inTopBar(find.text('2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a phone the app bar counts too: a conversation is read '
        'while its page is open and not after', (tester) async {
      await pumpApp(tester, size: mobileSize);
      expect(inAppBar(find.text('2')), findsOneWidget);

      await tapAndSettle(
        tester,
        inAppBar(find.byIcon(PhosphorIconsRegular.chatCircleDots)),
      );
      // The list is not a thread.
      expect(messages(tester).threadVisible, isFalse);

      await tapAndSettle(tester, inList(find.text('Sara Lindqvist')));
      expect(find.byType(MessagesConversationPage), findsOneWidget);
      expect(messages(tester).threadVisible, isTrue);
      expect(messages(tester).unreadCount.value, 1);

      // Answered while the page is open: read.
      await send(tester, 'Thursday works.');
      await waitForReply(tester);
      expect(messages(tester).unreadOf(MessagesData.sara), 0);

      // Written to again, and back to the list before she answers.
      await send(tester, 'See you there.');
      await tapAndSettle(tester, find.bySemanticsLabel('Back'));
      expect(find.byType(MessagesConversationPage), findsNothing);
      expect(messages(tester).threadVisible, isFalse);
      expect(inAppBar(find.text('1')), findsOneWidget);

      await waitForReply(tester);
      expect(messages(tester).unreadOf(MessagesData.sara), 1);
      expect(inAppBar(find.text('2')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
