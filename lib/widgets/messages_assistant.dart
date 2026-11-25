import 'dart:async';
import 'dart:math' as math;

/// How the other side of a conversation answers: how long someone takes to
/// start typing and to send, and where the assistant's words come from.
///
/// The Messages screen has no backend, so this stands in for one. A test
/// passes its own — no delays, and a stream it feeds by hand — which makes
/// every reply deterministic.
class MessagesReplies {
  const MessagesReplies({
    this.typingDelay = const Duration(milliseconds: 900),
    this.replyDelay = const Duration(milliseconds: 2400),
    this.assistant = assistantReply,
  });

  /// Nobody answers: for a test that is about something else.
  const MessagesReplies.none()
    : typingDelay = Duration.zero,
      replyDelay = Duration.zero,
      assistant = null;

  /// How long after a message is sent the other person starts typing.
  final Duration typingDelay;

  /// How long after that their reply arrives.
  final Duration replyDelay;

  /// The assistant's answer to [prompt], as the chunks a language model
  /// would send. Null leaves the assistant silent.
  final Stream<String> Function(String prompt)? assistant;

  /// Whether anyone answers at all.
  bool get enabled => assistant != null || replyDelay > Duration.zero;
}

/// What the assistant has to say. It does not read the prompt closely: a
/// few key words pick the answer.
String assistantAnswerFor(String prompt) {
  final asked = prompt.toLowerCase();
  if (asked.contains('post') || asked.contains('draft')) {
    return 'Here is a first draft you can make your own.\n\n'
        'Calm by default is not about doing less. It is about deciding '
        'what deserves attention before the interface asks for it. Three '
        'things changed how our team ships: we write the empty state '
        'first, we give every screen one job, and we treat a notification '
        'as a cost the reader pays.\n\n'
        'Want it shorter, or with a question at the end to invite replies?';
  }
  if (asked.contains('call') || asked.contains('interview')) {
    return 'A short plan for the call:\n\n'
        '1. Open with the outcome you want, in one sentence.\n'
        '2. Walk through the onboarding case study: the problem, the two '
        'options you weighed, and what the numbers said afterwards.\n'
        '3. Keep ten minutes for their questions. Ask what a great first '
        'ninety days looks like to them.\n\n'
        'I can turn any of these into talking points if that helps.';
  }
  return 'Happy to help with that. A good next step is to say who it is '
      'for and what you want them to do after reading it. With those two '
      'I can suggest a structure, a first line that earns the second, and '
      'a version short enough to read on a phone. \u{1F44D}\n\n'
      'Paste what you have and I will start from there.';
}

/// [assistantAnswerFor] as a model would stream it: after a pause to
/// "think", in pieces of uneven size at uneven intervals.
///
/// The pieces and the pauses come from a generator seeded by the prompt,
/// so the same question is always answered the same way.
Stream<String> assistantReply(String prompt) =>
    chunked(assistantAnswerFor(prompt), seed: prompt.length);

/// Splits [text] into chunks of one to six words — and now and then cuts a
/// word in two, as a tokenizer does — each sent after a pause of 20 to 160
/// milliseconds, with a longer breath at the end of a paragraph.
///
/// The pauses are timers the stream cancels with its subscription, so a
/// listener that goes away leaves nothing running.
Stream<String> chunked(
  String text, {
  int seed = 0,
  Duration thinking = const Duration(milliseconds: 700),
}) {
  final random = math.Random(seed);
  late final StreamController<String> controller;
  Timer? timer;
  var start = 0;

  void next() {
    if (start >= text.length) {
      unawaited(controller.close());
      return;
    }
    var end = start;
    final words = 1 + random.nextInt(6);
    for (var word = 0; word < words && end < text.length; word++) {
      final space = text.indexOf(' ', end + 1);
      end = space < 0 ? text.length : space;
    }
    // A token boundary in the middle of a word, every so often.
    if (end - start > 6 && random.nextInt(4) == 0) end -= 3;
    // Never between the two halves of a surrogate pair: the list's preview
    // shows what has arrived in a plain `Text`, which would not lay it out.
    final last = text.codeUnitAt(end - 1);
    if (last >= 0xD800 && last <= 0xDBFF) end++;
    final chunk = text.substring(start, end);
    start = end;
    controller.add(chunk);
    final pause = chunk.contains('\n')
        ? 320
        : 20 + random.nextInt(random.nextInt(5) == 0 ? 140 : 60);
    timer = Timer(Duration(milliseconds: pause), next);
  }

  controller = StreamController<String>(
    onListen: () => timer = Timer(thinking, next),
    onCancel: () => timer?.cancel(),
  );
  return controller.stream;
}
