// The Messages screen as a conversation: what is sent animates in, the
// other side answers, and the assistant's answer is streamed.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_demo/screens/messages_screen.dart';
import 'package:una_demo/teal_color_scheme.dart';
import 'package:una_demo/widgets/messages_assistant.dart';
import 'package:una_demo/widgets/messages_composer.dart';
import 'package:una_demo/widgets/messages_conversation.dart';
import 'package:una_demo/widgets/messages_conversation_list.dart';

import 'demo_support.dart';

const _desktop = Size(1440, 1000);
const _phone = Size(390, 844);
const _frame = Duration(milliseconds: 16);

Future<void> _pump(
  WidgetTester tester, {
  required Size size,
  required MessagesReplies replies,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    // The conversations are the session's, so the screen needs one; this
    // one answers the way the test asked.
    DemoSessionHost(
      replies: replies,
      child: UnaApp(
        theme: ThemeData(colorScheme: TealColorScheme.of(brightness)),
        home: const Scaffold(
          appBar: AppBar(title: Text('demo')),
          body: MessagesScreen(),
        ),
      ),
    ),
  );
  await _settle(tester);
}

/// Fixed frames: a typing indicator never settles.
Future<void> _settle(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Finder _inList(Finder finder) => find.descendant(
  of: find.byType(MessagesConversationList),
  matching: finder,
);

Finder _inThread(Finder finder) => find.descendant(
  of: find.byType(MessagesConversationView),
  matching: finder,
);

Finder _bubble(String text) => _inThread(find.widgetWithText(ChatBubble, text));

final _field = find.descendant(
  of: find.byType(MessagesComposer),
  matching: find.byType(EditableText),
);

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(_field, text);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
}

Future<void> _open(WidgetTester tester, String name) async {
  await tester.tap(_inList(find.text(name)));
  await _settle(tester);
}

ScrollPosition _thread(WidgetTester tester) => tester
    .state<ScrollableState>(_inThread(find.byType(Scrollable)).first)
    .position;

/// The text the streaming bubble has revealed so far, in code units.
int _revealed(WidgetTester tester) {
  final paragraph = find.byWidgetPredicate(
    (widget) => '${widget.runtimeType}' == '_StreamingParagraph',
  );
  if (paragraph.evaluate().isEmpty) return -1;
  final node = tester.renderObject(paragraph).toDiagnosticsNode();
  return node.getProperties().firstWhere((p) => p.name == 'revealed').value!
      as int;
}

void main() {
  group('sending', () {
    testWidgets('a sent message rises into place and the thread follows', (
      tester,
    ) async {
      await _pump(
        tester,
        size: _desktop,
        replies: const MessagesReplies.none(),
      );
      await _open(tester, 'Sara Lindqvist');
      final last = _bubble('Can we move the research sync to Thursday?');
      final before = tester.getRect(last);

      await _send(tester, 'Thursday works.');
      // Nothing has jumped in the frame it was sent.
      expect(tester.getRect(last), before);

      var top = before.top;
      var frames = 0;
      var moved = 0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(_frame);
        final now = tester.getRect(last).top;
        // The desktop thread rests against the top: a message appears
        // under the last one, which stays where it is.
        expect(now, closeTo(top, 1e-6));
        top = now;
        if (_bubble('Thursday works.').evaluate().isNotEmpty) moved++;
        frames++;
      }
      expect(frames, 60);
      expect(moved, greaterThan(40));
      final sent = tester.getRect(_bubble('Thursday works.'));
      expect(sent.top, greaterThan(before.bottom));
      expect(_inThread(find.text('Delivered')), findsOneWidget);
      expect(_thread(tester).pixels, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('in a thread that fills the pane the earlier messages glide '
        'up', (tester) async {
      await _pump(
        tester,
        size: const Size(1440, 700),
        replies: const MessagesReplies.none(),
      );
      // Omar's thread does not fit; he is typing at its end.
      final typing = _inThread(find.byType(TypingIndicator));
      final anchor = _bubble(
        'This is how we mapped ours. Might help with slide 14.',
      );
      final before = tester.getRect(anchor);
      final dots = tester.getRect(typing);

      await _send(tester, 'On it.');
      expect(tester.getRect(anchor), before);
      var last = before.top;
      var largest = 0.0;
      for (var i = 0; i < 60; i++) {
        await tester.pump(_frame);
        final top = tester.getRect(anchor).top;
        expect(top, lessThanOrEqualTo(last + 1e-6));
        if (last - top > largest) largest = last - top;
        last = top;
        // Whoever is typing stays at the end, under what was just sent.
        expect(tester.getRect(typing).bottom, closeTo(dots.bottom, 1e-6));
        expect(_thread(tester).pixels, 0);
      }
      expect(last, lessThan(before.top - 30));
      // A little a frame: never the whole way at once.
      expect(largest, lessThan(20));
      final sent = tester.getRect(_bubble('On it.'));
      expect(sent.bottom, lessThan(tester.getRect(typing).top));
      expect(sent.top, greaterThan(tester.getRect(anchor).bottom));
    });

    testWidgets('the delivery line moves to the newest message', (
      tester,
    ) async {
      await _pump(
        tester,
        size: _desktop,
        replies: const MessagesReplies.none(),
      );
      await _open(tester, 'Mei Tanaka');
      await _send(tester, 'One');
      await _settle(tester);
      await _send(tester, 'Two');
      await _settle(tester);
      expect(_inThread(find.text('Delivered')), findsOneWidget);
      expect(
        tester.getRect(_inThread(find.text('Delivered'))).top,
        greaterThan(tester.getRect(_bubble('Two')).bottom),
      );
    });
  });

  group('the other person', () {
    const replies = MessagesReplies(
      typingDelay: Duration(milliseconds: 300),
      replyDelay: Duration(milliseconds: 800),
      assistant: null,
    );

    testWidgets('starts typing, then answers in the same bubble', (
      tester,
    ) async {
      await _pump(tester, size: _desktop, replies: replies);
      await _open(tester, 'Sara Lindqvist');
      final typing = _inThread(find.byType(TypingIndicator));
      expect(typing, findsNothing);

      await _send(tester, 'Thursday works.');
      await tester.pump(const Duration(milliseconds: 200));
      expect(typing, findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(_frame);
      expect(typing, findsOneWidget);
      expect(
        tester.getSemantics(typing).label,
        contains('Sara is typing'),
      );
      await _settle(tester, frames: 8);
      final bubble = tester.element(
        find.ancestor(of: typing, matching: find.byType(ChatBubble)),
      );
      final dots = tester.getRect(
        find
            .descendant(
              of: find.byWidget(bubble.widget),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );

      // The reply arrives.
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump(_frame);
      // Same bubble, growing from its tail corner rather than replaced.
      final reply = find.byWidgetPredicate(
        (widget) => widget is StreamingText && widget.data == 'Sounds good!',
      );
      expect(reply, findsOneWidget);
      expect(
        tester.element(
          find.ancestor(of: reply, matching: find.byType(ChatBubble)),
        ),
        same(bubble),
      );
      var width = dots.width;
      for (var i = 0; i < 40; i++) {
        await tester.pump(_frame);
        final rect = tester.getRect(
          find
              .descendant(
                of: find.ancestor(of: reply, matching: find.byType(ChatBubble)),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(rect.left, dots.left);
        // Never narrower than the dots' pill, give or take the difference
        // in padding between the two.
        expect(rect.width, greaterThanOrEqualTo(dots.width - 4.5));
        width = rect.width;
      }
      expect(width, greaterThan(dots.width));
      await _settle(tester);
      expect(typing, findsNothing);
      expect(_bubble('Sounds good!'), findsOneWidget);
      // The list's row follows.
      expect(_inList(find.text('Sounds good!')), findsOneWidget);
      // And with nobody typing, nothing is left running.
      await tester.pumpAndSettle();
    });

    testWidgets('who was already typing answers under what was sent', (
      tester,
    ) async {
      await _pump(tester, size: _desktop, replies: replies);
      final typing = _inThread(find.byType(TypingIndicator));
      expect(typing, findsOneWidget);

      await _send(tester, 'Here it is.');
      await _settle(tester, frames: 8);
      // Still typing, below the new message.
      expect(typing, findsOneWidget);
      expect(
        tester.getRect(typing).top,
        greaterThan(tester.getRect(_bubble('Here it is.')).bottom),
      );

      await tester.pump(const Duration(milliseconds: 500));
      await _settle(tester);
      expect(typing, findsNothing);
      expect(_bubble('Got it, opening the deck now.'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('a conversation left before the answer does not break', (
      tester,
    ) async {
      await _pump(tester, size: _desktop, replies: replies);
      await _open(tester, 'Mei Tanaka');
      await _send(tester, 'Thank you!');
      await _open(tester, 'Sara Lindqvist');
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);
      expect(tester.takeException(), isNull);
      // It was answered all the same.
      expect(_inList(find.text('Sounds good!')), findsOneWidget);
      await _open(tester, 'Mei Tanaka');
      expect(_bubble('Sounds good!'), findsOneWidget);
    });
  });

  group('the assistant', () {
    late StreamController<String> answer;
    late List<String> prompts;
    late MessagesReplies replies;

    setUp(() {
      prompts = [];
      replies = MessagesReplies(
        typingDelay: Duration.zero,
        replyDelay: Duration.zero,
        assistant: (prompt) {
          prompts.add(prompt);
          answer = StreamController<String>();
          return answer.stream;
        },
      );
    });

    final stop = find.byIcon(PhosphorIconsFill.stop);
    final plane = find.byIcon(PhosphorIconsRegular.paperPlaneTilt);

    testWidgets('is pinned above the conversations', (tester) async {
      await _pump(tester, size: _desktop, replies: replies);
      final rows = tester.widgetList<ListTile>(_inList(find.byType(ListTile)));
      expect(
        find.descendant(
          of: find.byWidget(rows.first),
          matching: find.text('Una Assistant'),
        ),
        findsOneWidget,
      );
      // But the designs' conversation is the one that is open.
      expect(rows.first.selected, isFalse);
      await _open(tester, 'Una Assistant');
      expect(find.text('Ask the assistant…'), findsOneWidget);
      expect(_inThread(find.byIcon(PhosphorIconsFill.sparkle)), findsOneWidget);
    });

    for (final size in [_desktop, _phone]) {
      for (final brightness in Brightness.values) {
        testWidgets('streams its answer into one growing bubble '
            '(${size.width.toInt()} ${brightness.name})', (tester) async {
          await _pump(
            tester,
            size: size,
            replies: replies,
            brightness: brightness,
          );
          await _open(tester, 'Una Assistant');
          expect(stop, findsNothing);

          await _send(tester, 'Draft a post about calm interfaces');
          await _settle(tester, frames: 8);
          expect(prompts, ['Draft a post about calm interfaces']);
          // Thinking: three dots, and the send button is a stop button.
          expect(_inThread(find.byType(TypingIndicator)), findsOneWidget);
          expect(stop, findsOneWidget);
          expect(plane, findsNothing);

          // Uneven chunks at uneven intervals.
          const chunks = [
            'Here ',
            'is a first draft you can ma',
            'ke your own. ',
            'Calm by default is not about doing less. It is about deciding '
                'what deserves attention ',
            'before',
            ' the interface asks for it.',
          ];
          const gaps = [2, 11, 4, 17, 3, 9];
          final streaming = find.byWidgetPredicate(
            (widget) => widget is StreamingText && widget.streaming,
          );
          Rect? bubble;
          var revealed = 0;
          for (final (index, chunk) in chunks.indexed) {
            answer.add(chunk);
            for (var i = 0; i < gaps[index] + 6; i++) {
              await tester.pump(_frame);
              expect(tester.takeException(), isNull);
              final now = _revealed(tester);
              if (now < 0) continue;
              // Only ever more of it.
              expect(now, greaterThanOrEqualTo(revealed));
              revealed = now;
              final rect = tester.getRect(
                find
                    .descendant(
                      of: find.ancestor(
                        of: streaming,
                        matching: find.byType(ChatBubble),
                      ),
                      matching: find.byType(DecoratedBox),
                    )
                    .first,
              );
              if (bubble != null) {
                expect(rect.height, greaterThanOrEqualTo(bubble.height - 1e-6));
                expect(rect.left, bubble.left);
              }
              bubble = rect;
              // The thread stays on its end throughout.
              expect(_thread(tester).pixels, 0);
            }
          }
          expect(revealed, greaterThan(40));
          expect(_inThread(find.byType(TypingIndicator)), findsNothing);
          expect(stop, findsOneWidget);

          unawaited(answer.close());
          await tester.pumpAndSettle();
          final whole = chunks.join();
          expect(_bubble(whole), findsOneWidget);
          expect(stop, findsNothing);
          expect(plane, findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('stop leaves what was written as a finished message', (
      tester,
    ) async {
      await _pump(tester, size: _desktop, replies: replies);
      await _open(tester, 'Una Assistant');
      await _send(tester, 'Help me prepare for a call');
      await _settle(tester, frames: 4);
      answer.add('A short plan for the call: open with the outcome ');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(_revealed(tester), inExclusiveRange(0, 49));

      await tester.tap(stop);
      await tester.pumpAndSettle();
      expect(answer.hasListener, isFalse);
      expect(
        _bubble('A short plan for the call: open with the outcome '),
        findsOneWidget,
      );
      expect(_revealed(tester), -1, reason: 'a plain Text again');
      expect(stop, findsNothing);
      expect(plane, findsOneWidget);
      // The row shows what there is of it.
      expect(
        _inList(find.text('A short plan for the call: open with the outcome ')),
        findsOneWidget,
      );
    });

    testWidgets('stopped before a word arrived, the answer is taken back', (
      tester,
    ) async {
      await _pump(tester, size: _desktop, replies: replies);
      await _open(tester, 'Una Assistant');
      await _send(tester, 'Anything');
      await _settle(tester, frames: 6);
      expect(_inThread(find.byType(TypingIndicator)), findsOneWidget);

      await tester.tap(stop);
      await tester.pumpAndSettle();
      expect(
        _inThread(find.byType(TypingIndicator, skipOffstage: false)),
        findsNothing,
      );
      expect(_bubble('Anything'), findsOneWidget);
      expect(plane, findsOneWidget);
    });

    testWidgets('an error mid-answer ends it cleanly', (tester) async {
      await _pump(tester, size: _desktop, replies: replies);
      await _open(tester, 'Una Assistant');
      await _send(tester, 'Anything');
      await _settle(tester, frames: 4);
      answer
        ..add('Half an ans')
        ..addError(StateError('connection lost'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(_bubble('Half an ans'), findsOneWidget);
      expect(stop, findsNothing);
    });

    testWidgets('scrolled back while it writes, the thread holds still and '
        'offers the way down', (tester) async {
      await _pump(tester, size: const Size(1440, 620), replies: replies);
      await _open(tester, 'Una Assistant');
      await _send(tester, 'Draft a post');
      await _settle(tester, frames: 4);
      answer.add(List.filled(40, 'A long first paragraph.').join(' '));
      for (var i = 0; i < 90; i++) {
        await tester.pump(_frame);
      }
      // Tall enough to scroll by now. Read back up.
      expect(_thread(tester).maxScrollExtent, greaterThan(150));
      await tester.drag(
        _inThread(find.byType(Scrollable)).first,
        const Offset(0, 150),
      );
      await _settle(tester);
      final offset = _thread(tester).pixels;
      expect(offset, greaterThan(100));
      // The reply's own top is out of view above; it must not move.
      final reply = _inThread(find.byType(StreamingText));
      final held = tester.getTopLeft(reply);

      answer.add(' ${List.filled(30, 'And a second one.').join(' ')}');
      for (var i = 0; i < 90; i++) {
        await tester.pump(_frame);
        expect(tester.getTopLeft(reply).dy, closeTo(held.dy, 1e-6));
      }
      expect(_thread(tester).pixels, greaterThan(offset));
      // The round button is showing; it leads back to the end.
      final jump = _inThread(find.bySemanticsLabel('Jump to latest'));
      expect(jump, findsOneWidget);
      await tester.tap(jump);
      await _settle(tester, frames: 16);
      expect(_thread(tester).pixels, 0);
      unawaited(answer.close());
      await tester.pumpAndSettle();
    });

    testWidgets('Clear chat goes back to the greeting', (tester) async {
      await _pump(tester, size: _desktop, replies: replies);
      await _open(tester, 'Una Assistant');
      await _send(tester, 'Anything');
      await _settle(tester, frames: 4);
      answer.add('Some of an answer');
      await _settle(tester);

      await tester.tap(find.text('Clear chat'));
      await tester.pumpAndSettle();
      expect(answer.hasListener, isFalse);
      expect(_bubble('Anything'), findsNothing);
      expect(
        _inThread(find.textContaining('Hi Noor. Ask me to draft a post')),
        findsOneWidget,
      );
      expect(stop, findsNothing);
    });
  });

  group('the example\'s own stream', () {
    testWidgets('sends the whole answer, unevenly, the same way each time', (
      tester,
    ) async {
      Future<(List<String>, List<int>)> collect() async {
        final chunks = <String>[];
        final at = <int>[];
        var elapsed = 0;
        var done = false;
        final subscription = assistantReply('Draft a post').listen(
          (chunk) {
            chunks.add(chunk);
            at.add(elapsed);
          },
          onDone: () => done = true,
        );
        while (!done && elapsed < 60000) {
          await tester.pump(const Duration(milliseconds: 10));
          elapsed += 10;
        }
        // Not awaited: under the test's fake clock it would never return.
        unawaited(subscription.cancel());
        expect(done, isTrue);
        return (chunks, at);
      }

      final (chunks, at) = await collect();
      expect(chunks.join(), assistantAnswerFor('Draft a post'));
      // It thinks first.
      expect(at.first, greaterThanOrEqualTo(600));
      // Chunks of different sizes at different intervals.
      expect(
        chunks.map((chunk) => chunk.length).toSet().length,
        greaterThan(5),
      );
      final gaps = {for (var i = 1; i < at.length; i++) at[i] - at[i - 1]};
      expect(gaps.length, greaterThan(5));
      // And no chunk ends between the halves of a surrogate pair.
      for (final chunk in chunks) {
        final last = chunk.codeUnitAt(chunk.length - 1);
        expect(last >= 0xD800 && last <= 0xDBFF, isFalse);
      }

      final (again, againAt) = await collect();
      expect(again, chunks);
      expect(againAt, at);
    });

    testWidgets('answers in the app, start to finish', (tester) async {
      await _pump(tester, size: _phone, replies: const MessagesReplies());
      await _open(tester, 'Una Assistant');
      await _send(tester, 'Help me prepare for a call');
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      // Under way: some of it is showing, and it can be stopped.
      expect(_revealed(tester), greaterThan(0));
      expect(find.byIcon(PhosphorIconsFill.stop), findsOneWidget);
      // Let it finish.
      for (var i = 0; i < 400; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byIcon(PhosphorIconsFill.stop), findsNothing);
      expect(tester.takeException(), isNull);
      expect(
        _inThread(
          find.textContaining('I can turn any of these into talking points'),
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });
  });
}
