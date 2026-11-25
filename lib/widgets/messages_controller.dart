import 'dart:async';

import 'package:finesse_demo/data/messages_data.dart';
import 'package:finesse_demo/widgets/messages_assistant.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// The state of the user's messages: which conversation is open, the list's
/// filter and search, and what has been sent, received and read since the
/// app started.
///
/// It lives in the `DemoSession`, not in the Messages screen: the
/// navigation's badge counts the conversations with something unread
/// ([unreadCount]) on every screen, a reply goes on arriving after the user
/// has left for another one, and a phone shows the conversation in a pushed
/// route, outside the screen's subtree.
///
/// It also plays the other side of every conversation, through [replies]:
/// a person starts typing a moment after they are written to and then
/// answers, and the assistant's answer arrives a piece at a time. A reply
/// that lands in a thread nobody is looking at ([threadVisible]) is unread.
class MessagesController extends ChangeNotifier {
  MessagesController({
    this.conversations = MessagesData.conversations,
    this.replies = const MessagesReplies(),
    String? selectedId,
  }) : _selectedId =
           selectedId ??
           // The assistant is pinned above the conversations; the designs
           // open on the first of those.
           conversations
               .firstWhere((c) => !c.assistant, orElse: () => conversations[0])
               .id {
    search.addListener(notifyListeners);
  }

  /// Every conversation, in list order.
  final List<Conversation> conversations;

  /// How the other side answers.
  final MessagesReplies replies;

  /// What is typed in the list's search field.
  ///
  /// Kept here, not in the field, because the list is rebuilt in a different
  /// place when the window crosses a breakpoint: the text has to survive
  /// that, or the list would stay filtered by a search nobody can see.
  final search = TextEditingController();

  String _selectedId;
  MessageFilter _filter = MessageFilter.focused;
  bool _detailsVisible = true;
  final _threads = <String, List<ChatMessage>>{};
  final _touched = <String>{};
  final _sentCount = <String, int>{};
  final _replyCount = <String, int>{};
  final _timers = <String, Timer>{};
  final _streams = <String, StreamSubscription<String>>{};
  // The unread count of every conversation it has changed for: read here,
  // or written to since.
  final _unread = <String, int>{};
  late final _unreadCount = ValueNotifier<int>(_countUnread());
  bool _threadVisible = false;
  final _muted = <String>{};
  final _deleted = <String>{};
  bool _disposed = false;

  /// The conversation the desktop panes show.
  Conversation get selected => byId(_selectedId);

  Conversation byId(String id) =>
      conversations.firstWhere((conversation) => conversation.id == id);

  MessageFilter get filter => _filter;

  set filter(MessageFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  /// Whether the details pane is shown when there is room for it.
  bool get detailsVisible => _detailsVisible;

  void toggleDetails() {
    _detailsVisible = !_detailsVisible;
    notifyListeners();
  }

  /// How many message requests are waiting: the number on the chip.
  int get requestCount => conversations
      .where((conversation) => conversation.request)
      .where((conversation) => !_deleted.contains(conversation.id))
      .length;

  /// The conversations the list shows for the current filter and search.
  List<Conversation> get visible {
    final needle = search.text.trim().toLowerCase();
    return [
      for (final conversation in conversations)
        if (!_deleted.contains(conversation.id) &&
            _matchesFilter(conversation) &&
            (needle.isEmpty ||
                conversation.name.toLowerCase().contains(needle) ||
                previewOf(conversation).toLowerCase().contains(needle)))
          conversation,
    ];
  }

  bool _matchesFilter(Conversation conversation) => switch (_filter) {
    MessageFilter.focused => !conversation.request,
    // The open conversation stays put: it was unread until it was opened,
    // and a row that vanishes under the pointer is disorienting.
    MessageFilter.unread =>
      !conversation.request &&
          (unreadOf(conversation) > 0 || conversation.id == _selectedId),
    MessageFilter.requests => conversation.request,
    MessageFilter.groups => conversation.isGroup && !conversation.request,
  };

  /// Opens [conversation] and marks it read.
  void select(Conversation conversation) {
    // Opening a deleted conversation — from "New message" — is how it
    // comes back.
    final restored = _deleted.remove(conversation.id);
    final changed = _selectedId != conversation.id || restored;
    _selectedId = conversation.id;
    final wasUnread = _markRead(conversation);
    if (changed || wasUnread) notifyListeners();
  }

  /// Whether the thread of the [selected] conversation is on screen: beside
  /// the list on a desktop while Messages is the destination showing, or as
  /// the page a phone pushes. The Messages screen says so.
  ///
  /// It decides what a reply is on arrival. In the thread being looked at
  /// it is read; anywhere else — another conversation, the same one after
  /// the user went back to the list or on to another screen — it is unread,
  /// and counts.
  ///
  /// Showing a thread reads it. That is announced after the current frame,
  /// so this may be set while building or laying out.
  bool get threadVisible => _threadVisible;

  set threadVisible(bool value) {
    if (_disposed || _threadVisible == value) return;
    _threadVisible = value;
    if (!value || unreadOf(selected) == 0) return;
    scheduleMicrotask(() {
      if (_disposed || !_threadVisible) return;
      if (_markRead(selected)) notifyListeners();
    });
  }

  /// How many conversations have something unread: the number on the
  /// navigation's Messages badge, and the rows the list's "Unread" filter
  /// shows before any is opened.
  ///
  /// Requests are not conversations yet and are not counted; theirs is the
  /// number on the list's chip ([requestCount]). A listenable of its own,
  /// so that the navigation is not rebuilt for every word the assistant
  /// streams.
  ValueListenable<int> get unreadCount => _unreadCount;

  int _countUnread() => conversations
      .where((conversation) => !conversation.request)
      .where((conversation) => !_deleted.contains(conversation.id))
      .where((conversation) => unreadOf(conversation) > 0)
      .length;

  bool _markRead(Conversation conversation) {
    if (unreadOf(conversation) == 0) return false;
    _unread[conversation.id] = 0;
    _unreadCount.value = _countUnread();
    return true;
  }

  /// A message from the other side has landed in [conversation].
  void _arrived(Conversation conversation) {
    if (_threadVisible && conversation.id == _selectedId) return;
    _unread[conversation.id] = unreadOf(conversation) + 1;
    _unreadCount.value = _countUnread();
  }

  /// The thread of [conversation], oldest first: the designed messages,
  /// whatever has been said since, and — last — a reply on its way.
  ///
  /// Every message has a stable `id`, which is what the thread's list
  /// animates by. The returned list is replaced, never changed, when the
  /// thread changes.
  List<ChatMessage> messagesOf(
    Conversation conversation,
  ) => _threads[conversation.id] ??= List.unmodifiable([
    for (final (index, message) in conversation.messages.indexed)
      message.withId('${conversation.id}-$index'),
    // The designs catch the other person mid-sentence.
    if (conversation.typing) ChatMessage.pending(id: _replyId(conversation, 0)),
  ]);

  String _replyId(Conversation conversation, int index) =>
      '${conversation.id}-reply-$index';

  void _update(
    Conversation conversation,
    List<ChatMessage> Function(List<ChatMessage> thread) change,
  ) {
    if (_disposed) return;
    _threads[conversation.id] = List.unmodifiable(
      change(messagesOf(conversation)),
    );
    _touched.add(conversation.id);
    notifyListeners();
  }

  /// Appends [text] to [conversation] as a message from the user, and has
  /// the other side answer.
  ///
  /// Returns whether anything was sent; blank text is not.
  bool send(Conversation conversation, String text) {
    final message = text.trim();
    if (message.isEmpty) return false;
    final number = _sentCount.update(
      conversation.id,
      (count) => count + 1,
      ifAbsent: () => 0,
    );
    final sent = ChatMessage(
      message,
      outgoing: true,
      receipt: 'Delivered',
      id: '${conversation.id}-sent-$number',
    );
    _update(conversation, (thread) {
      // Only the newest message carries a receipt, and a reply that is
      // being written stays under it.
      final waiting = thread.isNotEmpty && thread.last.pending;
      final settled = waiting ? thread.sublist(0, thread.length - 1) : thread;
      return [
        for (final earlier in settled)
          earlier.outgoing ? earlier.withoutReceipt() : earlier,
        sent,
        if (waiting) thread.last,
      ];
    });
    _answer(conversation, message);
    return true;
  }

  /// Whether the assistant is in the middle of an answer in [conversation]:
  /// thinking, or writing.
  bool isStreaming(Conversation conversation) =>
      _streams.containsKey(conversation.id);

  /// Stops the assistant where it is. What it has written stays, as a
  /// finished message; an answer that had not started is taken back.
  void stopStreaming(Conversation conversation) {
    final subscription = _streams.remove(conversation.id);
    if (subscription == null) return;
    unawaited(subscription.cancel());
    _finishStream(conversation);
  }

  void _finishStream(Conversation conversation) {
    _streams.remove(conversation.id);
    _update(conversation, (thread) {
      if (thread.isEmpty) return thread;
      final last = thread.last;
      if (last.pending) return thread.sublist(0, thread.length - 1);
      if (!last.streaming) return thread;
      return [
        ...thread.sublist(0, thread.length - 1),
        last.withText(last.text!, streaming: false),
      ];
    });
  }

  void _answer(Conversation conversation, String prompt) {
    if (conversation.assistant) {
      _stream(conversation, prompt);
    } else if (conversation.replies.isNotEmpty &&
        replies.replyDelay > Duration.zero) {
      _type(conversation);
    }
  }

  /// The assistant: a bubble of dots at once, then its words as they come.
  void _stream(Conversation conversation, String prompt) {
    final source = replies.assistant;
    if (source == null) return;
    // A question asked while it is still answering the last one cuts that
    // answer short.
    stopStreaming(conversation);
    final number = _replyCount.update(
      conversation.id,
      (count) => count + 1,
      ifAbsent: () => 0,
    );
    final id = _replyId(conversation, number);
    _update(conversation, (thread) => [...thread, ChatMessage.pending(id: id)]);

    _streams[conversation.id] = source(prompt).listen(
      (chunk) {
        if (chunk.isEmpty) return;
        _update(conversation, (thread) {
          final last = thread.last;
          // Its first words are when the answer arrives.
          if (last.pending) _arrived(conversation);
          return [
            ...thread.sublist(0, thread.length - 1),
            last.withText('${last.text ?? ''}$chunk', streaming: true),
          ];
        });
      },
      onDone: () => _finishStream(conversation),
      // What arrived before the connection dropped is the answer.
      onError: (Object _) => _finishStream(conversation),
      cancelOnError: true,
    );
    // The row for the conversation shows "now" from the first moment.
    notifyListeners();
  }

  /// A person: they start typing after a moment, and then send.
  void _type(Conversation conversation) {
    _timers.remove(conversation.id)?.cancel();
    final already = messagesOf(conversation).lastOrNull?.pending ?? false;
    void reply() {
      final number = _replyCount.update(
        conversation.id,
        (count) => count + 1,
        ifAbsent: () => 0,
      );
      final text = conversation.replies[number % conversation.replies.length];
      _timers.remove(conversation.id);
      _update(conversation, (thread) {
        final last = thread.lastOrNull;
        if (last == null || !last.pending) return thread;
        _arrived(conversation);
        return [
          ...thread.sublist(0, thread.length - 1),
          last.withText(text, streaming: false),
        ];
      });
    }

    void startTyping() {
      final next = _replyCount[conversation.id];
      final id = _replyId(conversation, next == null ? 0 : next + 1);
      _update(
        conversation,
        (thread) => thread.lastOrNull?.pending ?? false
            ? thread
            : [...thread, ChatMessage.pending(id: id)],
      );
      _timers[conversation.id] = Timer(replies.replyDelay, reply);
    }

    _timers[conversation.id] = already
        ? Timer(replies.replyDelay, reply)
        : Timer(replies.typingDelay, startTyping);
  }

  /// Empties the assistant's thread back to its greeting.
  void clear(Conversation conversation) {
    stopStreaming(conversation);
    _timers.remove(conversation.id)?.cancel();
    _threads.remove(conversation.id);
    _touched.remove(conversation.id);
    // Nothing is left of what was unread in it.
    _unread.remove(conversation.id);
    _unreadCount.value = _countUnread();
    notifyListeners();
  }

  /// How many messages of [conversation] have not been read: the designs'
  /// figure until it is opened, and every reply that has arrived since
  /// while its thread was not on screen.
  int unreadOf(Conversation conversation) =>
      _unread[conversation.id] ?? conversation.unread;

  /// The newest message that has something to say.
  ChatMessage? _latest(Conversation conversation) {
    final thread = messagesOf(conversation);
    for (var i = thread.length - 1; i >= 0; i--) {
      if (thread[i].text?.isNotEmpty ?? false) return thread[i];
    }
    return null;
  }

  /// The last message, as the list shows it.
  String previewOf(Conversation conversation) {
    if (!_touched.contains(conversation.id)) return conversation.preview;
    final latest = _latest(conversation);
    if (latest == null) return conversation.preview;
    // One line of it: the row cuts the rest off.
    final text = latest.text!.replaceAll(RegExp(r'\s+'), ' ');
    return latest.outgoing ? 'You: $text' : text;
  }

  /// When the last message was sent, as the list shows it.
  String timeOf(Conversation conversation) =>
      _touched.contains(conversation.id) ? 'now' : conversation.time;

  /// Marks [conversation] read if anything in it is unread, and unread —
  /// one message, as far as the list's badge goes — if nothing is: what the
  /// row's swipe and its menu offer.
  void toggleRead(Conversation conversation) {
    _unread[conversation.id] = unreadOf(conversation) > 0 ? 0 : 1;
    _unreadCount.value = _countUnread();
    notifyListeners();
  }

  /// Whether [conversation] has been deleted from the list.
  bool isDeleted(Conversation conversation) =>
      _deleted.contains(conversation.id);

  /// Takes [conversation] out of the list. If it was the open one, the
  /// first that is left is opened in its place — without being read: the
  /// user did not choose it.
  ///
  /// Nothing of it is thrown away, so [restore] brings it back as it was.
  void delete(Conversation conversation) {
    if (!_deleted.add(conversation.id)) return;
    if (_selectedId == conversation.id) {
      final next = conversations.where(
        (other) => !_deleted.contains(other.id) && !other.request,
      );
      if (next.isNotEmpty) _selectedId = next.first.id;
    }
    _unreadCount.value = _countUnread();
    notifyListeners();
  }

  /// Puts a deleted conversation back in its place: the toast's "Undo",
  /// and what writing to its person again does.
  void restore(Conversation conversation) {
    if (!_deleted.remove(conversation.id)) return;
    _unreadCount.value = _countUnread();
    notifyListeners();
  }

  bool isMuted(Conversation conversation) => _muted.contains(conversation.id);

  void toggleMuted(Conversation conversation) {
    if (!_muted.remove(conversation.id)) _muted.add(conversation.id);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timers.values) {
      timer.cancel();
    }
    for (final subscription in _streams.values) {
      unawaited(subscription.cancel());
    }
    search.dispose();
    _unreadCount.dispose();
    super.dispose();
  }
}
