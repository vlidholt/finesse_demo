import 'package:finesse_demo/assets.dart';
import 'package:finesse_demo/data.dart';
import 'package:finesse/finesse.dart';
import 'package:flutter/widgets.dart';

/// The filter chips above the conversation list.
enum MessageFilter {
  focused('Focused'),
  unread('Unread'),
  requests('Requests'),
  groups('Groups');

  const MessageFilter(this.label);

  final String label;
}

/// Something shared in a conversation: a document, a picture or a link.
@immutable
class SharedFile {
  const SharedFile({
    required this.name,
    required this.icon,
    required this.size,
    this.detail,
    this.shared = 'Today',
  });

  /// "calm-by-default-draft.pdf".
  final String name;

  final IconData icon;

  /// "4.2 MB", or "Link" for something with no size.
  final String size;

  /// What the attachment card adds after the size: "32 slides".
  final String? detail;

  /// When it was shared, as the details pane says it: "Today", "Last week".
  final String shared;

  /// The second line of the attachment card in the thread.
  String get attachmentCaption => detail == null ? size : '$size · $detail';

  /// The second line of the row in the details pane.
  String get listCaption => '$size · $shared';
}

/// A photograph sent as a message.
@immutable
class MessageImage {
  const MessageImage({required this.asset, required this.label});

  /// One of the `DemoAssets.photo*`.
  final String asset;

  /// What the picture shows, for assistive technology.
  final String label;
}

/// One entry of a conversation's thread: text, an attachment or a picture.
///
/// The designed messages are constants without an [id]; the controller gives
/// each one a stable id when it opens the thread, which is what lets the
/// list tell a message that moved from one that is new.
@immutable
class ChatMessage {
  /// A text message.
  const ChatMessage(
    String this.text, {
    this.outgoing = false,
    this.sender,
    this.receipt,
    this.reactions = 0,
    this.id = '',
    this.streaming = false,
  }) : file = null,
       image = null,
       pending = false;

  /// A document sent as an attachment card.
  const ChatMessage.file(
    SharedFile this.file, {
    this.outgoing = false,
    this.sender,
    this.receipt,
    this.id = '',
  }) : text = null,
       image = null,
       reactions = 0,
       pending = false,
       streaming = false;

  /// A picture.
  const ChatMessage.image(
    MessageImage this.image, {
    this.outgoing = false,
    this.sender,
    this.receipt,
    this.id = '',
  }) : text = null,
       file = null,
       reactions = 0,
       pending = false,
       streaming = false;

  /// A reply that is being written: three dots in a bubble, which the text
  /// takes the place of when it arrives.
  const ChatMessage.pending({this.sender, this.id = ''})
    : text = null,
      file = null,
      image = null,
      outgoing = false,
      receipt = null,
      reactions = 0,
      pending = true,
      streaming = false;

  const ChatMessage._({
    required this.id,
    required this.text,
    required this.file,
    required this.image,
    required this.outgoing,
    required this.sender,
    required this.receipt,
    required this.reactions,
    required this.pending,
    required this.streaming,
  });

  /// What the thread knows the message by. Empty for a designed message
  /// until the controller opens its thread.
  final String id;

  final String? text;
  final SharedFile? file;
  final MessageImage? image;

  /// Whether the signed-in user sent it.
  final bool outgoing;

  /// Who sent an incoming message in a group. Null means the person the
  /// conversation is with.
  final Person? sender;

  /// The delivery line under an outgoing message: "Seen 10:14".
  final String? receipt;

  /// How many hearts the message has collected.
  final int reactions;

  /// Whether nothing of the message has arrived yet: its sender is typing.
  final bool pending;

  /// Whether [text] is still arriving, a piece at a time.
  final bool streaming;

  /// The same message under [id].
  ChatMessage withId(String id) => _copy(id: id);

  /// The same message without its delivery line.
  ChatMessage withoutReceipt() => receipt == null
      ? this
      : ChatMessage._(
          id: id,
          text: text,
          file: file,
          image: image,
          outgoing: outgoing,
          sender: sender,
          receipt: null,
          reactions: reactions,
          pending: pending,
          streaming: streaming,
        );

  /// The reply this pending or streaming message has become so far.
  ChatMessage withText(String text, {required bool streaming}) =>
      _copy(text: text, pending: false, streaming: streaming);

  ChatMessage _copy({
    String? id,
    String? text,
    bool? pending,
    bool? streaming,
  }) => ChatMessage._(
    id: id ?? this.id,
    text: text ?? this.text,
    file: file,
    image: image,
    outgoing: outgoing,
    sender: sender,
    receipt: receipt,
    reactions: reactions,
    pending: pending ?? this.pending,
    streaming: streaming ?? this.streaming,
  );
}

/// A row of the Messages list and everything its three panes show.
@immutable
class Conversation {
  const Conversation({
    required this.id,
    required this.time,
    required this.preview,
    required this.messages,
    this.person,
    this.group,
    this.assistant = false,
    this.replies = const [],
    this.day = 'Today',
    this.unread = 0,
    this.online = false,
    this.typing = false,
    this.request = false,
    this.mutuals = const [],
    this.mutualsLabel,
    this.sharedFiles = const [],
    this.sharedGroups = const [],
  }) : assert(
         (person == null) != (group == null),
         'A conversation is with a person or with a group',
       );

  final String id;

  /// Who the conversation is with; null for a [group].
  final Person? person;

  /// The group the conversation belongs to; null for a [person].
  final Group? group;

  /// Whether the other side is Demo's assistant rather than someone on
  /// the network: its replies are written as they are read, a piece at a
  /// time, and its picture is a mark, not a portrait.
  final bool assistant;

  /// What the other person answers when the user writes to them, one after
  /// the other. Empty for a conversation nobody answers in.
  final List<String> replies;

  /// When the last message arrived, as the list says it: "2m", "Mon".
  final String time;

  /// The last message, as the list shows it.
  final String preview;

  /// The label of the divider that opens the thread.
  final String day;

  /// How many messages are unread.
  final int unread;

  /// Whether the other person is active right now.
  final bool online;

  /// Whether the other person is typing.
  final bool typing;

  /// Whether this is a message request rather than a conversation the user
  /// has accepted.
  final bool request;

  final List<ChatMessage> messages;

  /// The portraits of the "Mutual connections" stack.
  final List<String> mutuals;

  /// "Sara, Freya and 22 others".
  final String? mutualsLabel;

  final List<SharedFile> sharedFiles;
  final List<Group> sharedGroups;

  bool get isGroup => group != null;

  String get name => person?.name ?? group!.name;

  /// The line under the name in the details pane and, after "Active now", in
  /// the conversation header.
  String get headline => person?.headline ?? group!.members;
}

/// The content of the Messages screen.
///
/// Omar's conversation is the one the designs show and is verbatim. The
/// designs give every other conversation only a row in the list, so their
/// threads are a few plausible messages ending in that row's preview. The
/// two requests are not in the designs at all: only their count is, on the
/// "Requests · 2" chip.
abstract final class MessagesData {
  static const draftDeck = SharedFile(
    name: 'calm-by-default-draft.pdf',
    icon: PhosphorIconsRegular.filePdf,
    size: '4.2 MB',
    detail: '32 slides',
  );

  static const _onboardingMap = SharedFile(
    name: 'onboarding-map.jpg',
    icon: PhosphorIconsRegular.image,
    size: '1.1 MB',
  );

  static const _onboardingFile = SharedFile(
    name: 'figma.com/file/onboarding-v2',
    icon: PhosphorIconsRegular.link,
    size: 'Link',
    shared: 'Last week',
  );

  static const _portfolio = SharedFile(
    name: 'noor-haddad-portfolio.pdf',
    icon: PhosphorIconsRegular.filePdf,
    size: '8.6 MB',
    detail: '24 pages',
  );

  static const _releaseNotes = SharedFile(
    name: 'quill.design/tokens/v3',
    icon: PhosphorIconsRegular.link,
    size: 'Link',
  );

  /// What someone answers when the designs have nothing for them to say.
  static const _replies = [
    'Sounds good!',
    'Let me check and get back to you.',
    'Thanks, Noor. Talk soon.',
  ];

  /// The assistant, as the list and the panes name it. It has no portrait:
  /// `ConversationAvatar` draws its mark instead.
  static const assistantProfile = Person(
    name: 'Demo Assistant',
    headline: 'Drafts, summaries and second opinions',
    avatar: '',
  );

  /// The one conversation whose replies are streamed.
  static const assistant = Conversation(
    id: 'assistant',
    person: assistantProfile,
    assistant: true,
    time: '1m',
    preview: 'Ask me to draft a post, tighten a message or prepare for a call.',
    online: true,
    messages: [
      ChatMessage(
        'Hi Noor. Ask me to draft a post, tighten a message or prepare for '
        'a call.',
      ),
    ],
  );

  static const omar = Conversation(
    id: 'omar',
    person: People.omar,
    replies: [
      'Got it, opening the deck now.',
      'Slide 14 reads much better with the flow next to it. Keep that.',
      'Send me the next draft whenever it is ready.',
    ],
    time: '2m',
    preview: 'You: Sending the deck now. Slides 12 to 18…',
    online: true,
    typing: true,
    messages: [
      ChatMessage(
        'Hey Noor! Loved your talk proposal for Config Nordics. Do you have '
        'slides yet?',
      ),
      ChatMessage('Happy to give feedback this afternoon if that helps.'),
      ChatMessage(
        'Thank you! I have a rough draft. Would love a second pair of eyes '
        'before I polish it.',
        outgoing: true,
      ),
      ChatMessage.file(draftDeck, outgoing: true),
      ChatMessage(
        'Sending the deck now. Slides 12 to 18 are the ones I’m unsure about.',
        outgoing: true,
        receipt: 'Seen 10:14',
      ),
      ChatMessage.image(
        MessageImage(
          asset: DemoAssets.photoWhiteboardUserFlow,
          label: 'Whiteboard with a mapped user flow',
        ),
      ),
      ChatMessage(
        'This is how we mapped ours. Might help with slide 14.',
        reactions: 1,
      ),
    ],
    mutuals: [
      DemoAssets.avatarSaraLindqvist,
      DemoAssets.avatarFreyaHolm,
      DemoAssets.avatarConnectionA,
      DemoAssets.avatarConnectionB,
    ],
    mutualsLabel: 'Sara, Freya and 22 others',
    sharedFiles: [draftDeck, _onboardingMap, _onboardingFile],
    sharedGroups: [Groups.designSystemsGuild],
  );

  static const sara = Conversation(
    id: 'sara',
    person: People.sara,
    replies: _replies,
    time: '18m',
    preview: 'Can we move the research sync to Thursday?',
    unread: 1,
    online: true,
    messages: [
      ChatMessage(
        'The interview notes are in the shared folder whenever you want them.',
        outgoing: true,
      ),
      ChatMessage('Perfect, thank you. Reading them tonight.'),
      ChatMessage('Can we move the research sync to Thursday?'),
    ],
    mutuals: [
      DemoAssets.avatarOmarRahimi,
      DemoAssets.avatarIrinaVolkova,
      DemoAssets.avatarConnectionA,
    ],
    mutualsLabel: 'Omar, Irina and 31 others',
    sharedGroups: [Groups.copenhagenProductCircle],
  );

  static const designSystemsGuild = Conversation(
    id: 'design-systems-guild',
    group: Groups.designSystemsGuild,
    time: '1h',
    preview: 'Freya: Tokens v3 is live, release notes in thread',
    unread: 4,
    messages: [
      ChatMessage(
        'Has anyone audited the new focus ring tokens yet?',
        sender: People.aisha,
      ),
      ChatMessage('On my list for tomorrow morning.', outgoing: true),
      ChatMessage(
        'We renamed the surface scale, so expect a few noisy diffs.',
        sender: People.freya,
      ),
      ChatMessage(
        'Tokens v3 is live, release notes in thread',
        sender: People.freya,
      ),
    ],
    mutuals: [
      DemoAssets.avatarFreyaHolm,
      DemoAssets.avatarAishaRahman,
      DemoAssets.avatarOmarRahimi,
      DemoAssets.avatarMateoAlvarez,
    ],
    mutualsLabel: 'Freya, Aisha and 18,399 others',
    sharedFiles: [_releaseNotes],
  );

  static const claire = Conversation(
    id: 'claire',
    person: People.claire,
    replies: _replies,
    time: '3h',
    preview: 'Thanks Noor, I’ve shared your portfolio with the team.',
    messages: [
      ChatMessage(
        'Hi Noor, do you have an updated portfolio I could pass along?',
      ),
      ChatMessage('Of course. Here is the latest version.', outgoing: true),
      ChatMessage.file(_portfolio, outgoing: true),
      ChatMessage('Thanks Noor, I’ve shared your portfolio with the team.'),
    ],
    mutuals: [DemoAssets.avatarJulianReyes, DemoAssets.avatarConnectionB],
    mutualsLabel: 'Julian and 3 others',
    sharedFiles: [_portfolio],
  );

  static const julian = Conversation(
    id: 'julian',
    person: People.julian,
    replies: _replies,
    time: 'Mon',
    preview: 'See you at Config! Lounge after my talk?',
    day: 'Monday',
    online: true,
    messages: [
      ChatMessage(
        'Just saw the schedule. Your talk is right before mine!',
        outgoing: true,
      ),
      ChatMessage('See you at Config! Lounge after my talk?'),
    ],
    mutuals: [
      DemoAssets.avatarElenaPetrova,
      DemoAssets.avatarOmarRahimi,
      DemoAssets.avatarConnectionA,
    ],
    mutualsLabel: 'Elena, Omar and 14 others',
    sharedGroups: [Groups.designSystemsGuild],
  );

  static const aisha = Conversation(
    id: 'aisha',
    person: People.aisha,
    replies: _replies,
    time: 'Sun',
    preview: 'Sharing the interview guide here',
    day: 'Sunday',
    messages: [
      ChatMessage(
        'Could you send the guide you used for the accessibility interviews?',
        outgoing: true,
      ),
      ChatMessage('Sharing the interview guide here'),
    ],
    mutuals: [DemoAssets.avatarFreyaHolm, DemoAssets.avatarSaraLindqvist],
    mutualsLabel: 'Freya, Sara and 9 others',
    sharedGroups: [Groups.accessibilityCollective],
  );

  static const mateo = Conversation(
    id: 'mateo',
    person: People.mateo,
    replies: _replies,
    time: 'Nov 14',
    preview: 'Ha, yes. That bug again.',
    day: 'November 14',
    messages: [
      ChatMessage(
        'Is the export dialog still eating the last row for you?',
        outgoing: true,
      ),
      ChatMessage('Ha, yes. That bug again.'),
    ],
    mutuals: [DemoAssets.avatarRafaelCruz, DemoAssets.avatarConnectionB],
    mutualsLabel: 'Rafael and 6 others',
  );

  static const mei = Conversation(
    id: 'mei',
    person: People.mei,
    replies: _replies,
    time: 'Nov 12',
    preview: 'Love the new brand work!',
    day: 'November 12',
    messages: [
      ChatMessage(
        'We finally shipped the Halcyon refresh. Would love your eye on it.',
        outgoing: true,
      ),
      ChatMessage('Love the new brand work!'),
    ],
    mutuals: [DemoAssets.avatarJulianReyes, DemoAssets.avatarFreyaHolm],
    mutualsLabel: 'Julian, Freya and 4 others',
  );

  static const rafael = Conversation(
    id: 'rafael',
    person: People.rafael,
    time: 'Tue',
    preview: 'Would you be open to a chat about a role at Tidewater?',
    day: 'Tuesday',
    unread: 1,
    request: true,
    messages: [
      ChatMessage(
        'Hi Noor, Mateo pointed me to your onboarding case study. Great '
        'work.',
      ),
      ChatMessage('Would you be open to a chat about a role at Tidewater?'),
    ],
    mutuals: [DemoAssets.avatarMateoAlvarez],
    mutualsLabel: 'Mateo and 2 others',
  );

  static const irina = Conversation(
    id: 'irina',
    person: People.irina,
    time: 'Nov 9',
    preview: 'Could I ask how you wrote the empty states?',
    day: 'November 9',
    unread: 1,
    request: true,
    messages: [
      ChatMessage('Hi Noor, I enjoyed your talk on calm interfaces.'),
      ChatMessage('Could I ask how you wrote the empty states?'),
    ],
    mutuals: [DemoAssets.avatarSaraLindqvist, DemoAssets.avatarOmarRahimi],
    mutualsLabel: 'Sara, Omar and 5 others',
  );

  /// Every conversation, in the order of the list. The first is the one a
  /// desktop opens on.
  static const conversations = <Conversation>[
    assistant,
    omar,
    sara,
    designSystemsGuild,
    claire,
    julian,
    aisha,
    mateo,
    mei,
    rafael,
    irina,
  ];
}
