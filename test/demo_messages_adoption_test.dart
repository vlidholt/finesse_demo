import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/data/messages_data.dart';
import 'package:una_demo/screens/messages_screen.dart';
import 'package:una_demo/widgets/messages_conversation.dart';
import 'package:una_demo/widgets/messages_conversation_list.dart';

import 'demo_support.dart';

// Messages on the package's list-detail layout, and "New message" on its
// autocomplete field.

Conversation _conversation(String name) =>
    MessagesData.conversations.firstWhere((c) => c.name == name);

Future<void> _openNewMessage(WidgetTester tester) async {
  await tester.tap(find.bySemanticsLabel('New message'));
  await settleFrames(tester);
}

Finder get _toField => find.descendant(
  of: find.byType(Autocomplete<Conversation>),
  matching: find.byType(EditableText),
);

Button _primary(WidgetTester tester, String label) =>
    tester.widget<Button>(find.widgetWithText(Button, label));

void main() {
  setUpAll(loadDemoTestFont);

  testWidgets('on a desktop the list and the conversation are a '
      'ListDetailLayout, the list 360 wide', (tester) async {
    await pumpDemoScreen(tester, const MessagesScreen());
    final layout = find.byType(ListDetailLayout);
    expect(layout, findsOneWidget);
    final list = find.descendant(
      of: layout,
      matching: find.byType(MessagesConversationList),
    );
    final pane = find.descendant(
      of: layout,
      matching: find.byType(MessagesConversationPane),
    );
    expect(tester.getSize(list).width, MessagesScreen.listWidth);
    // A hairline between them, and nothing else.
    expect(
      tester.getTopLeft(pane).dx - tester.getTopRight(list).dx,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('on a phone the list is the page and a row pushes the '
      'conversation over the whole screen', (tester) async {
    await pumpDemoScreen(tester, const MessagesScreen(), size: demoPhone);
    // No nested navigator under the shell's bars.
    expect(find.byType(ListDetailLayout), findsNothing);
    await tester.tap(find.text('Claire Dubois'));
    await settleFrames(tester);
    expect(find.byType(MessagesConversationPage), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await settleFrames(tester);
    expect(find.byType(MessagesConversationPage), findsNothing);
  });

  group('"New message"', () {
    testWidgets('completes the recipient as it is typed, and Send sends in '
        'their conversation', (tester) async {
      await pumpDemoScreen(tester, const MessagesScreen());
      final messages = demoSession(tester).messages;
      final claire = _conversation('Claire Dubois');
      await _openNewMessage(tester);

      expect(find.byType(Autocomplete<Conversation>), findsOneWidget);
      // Nobody is named yet.
      expect(_primary(tester, 'Open conversation').enabled, isFalse);

      await tester.enterText(_toField, 'cla');
      await settleFrames(tester);
      // The list under the field has the one who matches, and not the rest.
      expect(find.text(claire.headline), findsOneWidget);
      expect(find.text(_conversation('Julian Reyes').headline), findsNothing);

      // Enter takes the highlighted match, and the caret moves on.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleFrames(tester);
      expect(
        tester.widget<EditableText>(_toField).controller.text,
        claire.name,
      );
      expect(_primary(tester, 'Open conversation').enabled, isTrue);

      await tester.enterText(find.byType(Textarea), 'Thanks for the intro');
      await tester.pump();
      expect(find.widgetWithText(Button, 'Send'), findsOneWidget);
      await tester.tap(find.widgetWithText(Button, 'Send'));
      await settleFrames(tester);

      expect(find.byType(Dialog), findsNothing);
      expect(messages.selected, claire);
      final last = messages.messagesOf(claire).lastWhere((m) => m.outgoing);
      expect(last.text, 'Thanks for the intro');
      // The pane beside the list shows it.
      expect(find.text('Thanks for the intro'), findsWidgets);
      expect(tester.takeException(), isNull);
      // The reply that follows is the session's business, not the test's.
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('with nothing written it opens the conversation, and a '
        'name that is edited again is nobody', (tester) async {
      await pumpDemoScreen(tester, const MessagesScreen());
      final messages = demoSession(tester).messages;
      final julian = _conversation('Julian Reyes');
      final sent = messages.messagesOf(julian).length;
      await _openNewMessage(tester);

      // Focused, the field lists everyone at once.
      await tester.tap(_toField);
      await settleFrames(tester);
      await tester.tap(find.text(julian.headline));
      await settleFrames(tester);
      expect(_primary(tester, 'Open conversation').enabled, isTrue);

      await tester.enterText(_toField, 'Julian Rey');
      await tester.pump();
      expect(_primary(tester, 'Open conversation').enabled, isFalse);
      await tester.enterText(_toField, julian.name);
      await settleFrames(tester);
      expect(_primary(tester, 'Open conversation').enabled, isTrue);

      await tester.tap(find.widgetWithText(Button, 'Open conversation'));
      await settleFrames(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(messages.selected, julian);
      expect(messages.messagesOf(julian), hasLength(sent));
    });

    testWidgets('says so when nobody matches, and Cancel changes nothing', (
      tester,
    ) async {
      await pumpDemoScreen(tester, const MessagesScreen());
      final messages = demoSession(tester).messages;
      final selected = messages.selected;
      await _openNewMessage(tester);
      await tester.enterText(_toField, 'zzz');
      await settleFrames(tester);
      expect(
        find.text('No one in your conversations is called “zzz”.'),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settleFrames(tester);
      await tester.tap(find.widgetWithText(Button, 'Cancel'));
      await settleFrames(tester);
      expect(find.byType(Dialog), findsNothing);
      expect(messages.selected, selected);
    });

    testWidgets('on a phone Send opens the conversation as a page', (
      tester,
    ) async {
      await pumpDemoScreen(
        tester,
        const MessagesScreen(),
        size: demoPhone,
      );
      final messages = demoSession(tester).messages;
      final mateo = _conversation('Mateo Alvarez');
      await _openNewMessage(tester);
      await tester.enterText(_toField, 'mateo');
      await settleFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleFrames(tester);
      await tester.enterText(find.byType(Textarea), 'Found the bug');
      await tester.pump();
      await tester.tap(find.widgetWithText(Button, 'Send'));
      await settleFrames(tester);

      expect(find.byType(MessagesConversationPage), findsOneWidget);
      expect(messages.selected, mateo);
      expect(find.text('Found the bug'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('a deleted conversation comes back when it is written to', (
      tester,
    ) async {
      await pumpDemoScreen(tester, const MessagesScreen());
      final messages = demoSession(tester).messages;
      final aisha = _conversation('Aisha Rahman');
      messages.delete(aisha);
      await settleFrames(tester);
      expect(messages.visible, isNot(contains(aisha)));

      await _openNewMessage(tester);
      await tester.enterText(_toField, 'aisha');
      await settleFrames(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settleFrames(tester);
      await tester.tap(find.widgetWithText(Button, 'Open conversation'));
      await settleFrames(tester);
      expect(messages.isDeleted(aisha), isFalse);
      expect(messages.visible, contains(aisha));
      expect(messages.selected, aisha);
    });
  });

  testWidgets('the filters are a chip group of one choice that scrolls', (
    tester,
  ) async {
    await pumpDemoScreen(tester, const MessagesScreen(), size: demoPhone);
    final group = find.byType(ChipGroup<MessageFilter>);
    expect(group, findsOneWidget);
    expect(tester.widget<ChipGroup<MessageFilter>>(group).wrap, isFalse);

    final list = tester.widget<MessagesConversationList>(
      find.byType(MessagesConversationList),
    );
    expect(list.controller.filter, MessageFilter.focused);
    await tester.tap(find.widgetWithText(Chip, 'Unread'));
    await settleFrames(tester, frames: 4);
    expect(list.controller.filter, MessageFilter.unread);
    // One is always chosen.
    await tester.tap(find.widgetWithText(Chip, 'Unread'));
    await settleFrames(tester, frames: 4);
    expect(list.controller.filter, MessageFilter.unread);
    expect(tester.takeException(), isNull);
  });
}
