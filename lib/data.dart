import 'package:flutter/foundation.dart';
import 'package:una_demo/assets.dart';

/// Someone on Demo.
///
/// The people, companies and groups below are shared by several screens.
/// Data only one screen needs (posts, job listings, conversations, the
/// profile's sections) lives in `data/<screen>_data.dart`.
@immutable
class Person {
  const Person({
    required this.name,
    required this.headline,
    required this.avatar,
    this.verified = false,
    this.location,
    this.pronouns,
    this.online = false,
  });

  /// The full name, as shown next to posts and messages.
  final String name;

  /// The one-line role under the name: "Design lead at Birchline".
  final String headline;

  /// The asset path of the portrait; one of the `DemoAssets.avatar*`.
  final String avatar;

  /// Whether the name carries the verified seal.
  final bool verified;

  /// "Copenhagen, Denmark", when the designs say.
  final String? location;

  /// "she/her", when the designs say.
  final String? pronouns;

  /// Whether the person is shown as active right now.
  final bool online;

  /// The given name, for the places the designs shorten to it ("Sara and
  /// 214 others", story labels on a phone).
  String get firstName => name.split(' ').first;

  /// The fallback shown while the portrait loads.
  String get initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0])
      .join();
}

/// A company or a school.
@immutable
class Company {
  const Company({
    required this.name,
    required this.logo,
    this.industry,
    this.size,
    this.website,
  });

  final String name;

  /// The asset path of the mark; one of the `DemoAssets.logo*`.
  final String logo;

  /// "Health tech", when the designs say.
  final String? industry;

  /// "1,200 employees", when the designs say.
  final String? size;

  /// "kestrel.health", when the designs say.
  final String? website;
}

/// A community the current user belongs to.
@immutable
class Group {
  const Group({
    required this.name,
    required this.logo,
    required this.members,
    required this.newPosts,
  });

  final String name;

  /// The asset path of the mark; one of the `DemoAssets.logo*`.
  final String logo;

  /// "18,402 members", as the profile and Messages list it.
  final String members;

  /// How many unread posts the home feed's "Your groups" card shows.
  final int newPosts;
}

/// Everyone who appears in the Demo designs.
abstract final class People {
  /// The signed-in user.
  static const noor = Person(
    name: 'Noor Haddad',
    headline:
        'Product designer at Halcyon. Building calmer tools for busy teams.',
    avatar: DemoAssets.avatarNoorHaddad,
    verified: true,
    location: 'Copenhagen, Denmark',
    pronouns: 'she/her',
  );

  static const omar = Person(
    name: 'Omar Rahimi',
    headline: 'Design lead at Birchline',
    avatar: DemoAssets.avatarOmarRahimi,
    verified: true,
    location: 'Stockholm, Sweden',
    online: true,
  );

  static const julian = Person(
    name: 'Julian Reyes',
    headline: 'VP Design at Kestrel Health',
    avatar: DemoAssets.avatarJulianReyes,
    verified: true,
  );

  static const sara = Person(
    name: 'Sara Lindqvist',
    headline: 'Head of Research at Birchline',
    avatar: DemoAssets.avatarSaraLindqvist,
  );

  static const aisha = Person(
    name: 'Aisha Rahman',
    headline: 'Accessibility lead at Orbital',
    avatar: DemoAssets.avatarAishaRahman,
    verified: true,
  );

  static const freya = Person(
    name: 'Freya Holm',
    headline: 'Design engineer at Quill',
    avatar: DemoAssets.avatarFreyaHolm,
  );

  static const mei = Person(
    name: 'Mei Tanaka',
    headline: 'Brand designer, independent',
    avatar: DemoAssets.avatarMeiTanaka,
  );

  static const mateo = Person(
    name: 'Mateo Alvarez',
    headline: 'Product designer at Tidewater',
    avatar: DemoAssets.avatarMateoAlvarez,
  );

  static const rafael = Person(
    name: 'Rafael Cruz',
    headline: 'Engineering manager at Tidewater',
    avatar: DemoAssets.avatarRafaelCruz,
  );

  static const elena = Person(
    name: 'Elena Petrova',
    headline: 'Principal PM at Kestrel Health',
    avatar: DemoAssets.avatarElenaPetrova,
  );

  static const irina = Person(
    name: 'Irina Volkova',
    headline: 'UX writer at Birchline',
    avatar: DemoAssets.avatarIrinaVolkova,
  );

  /// Only appears in the Messages list; the designs give her no headline.
  static const claire = Person(
    name: 'Claire Dubois',
    headline: 'Talent partner',
    avatar: DemoAssets.avatarClaireDubois,
  );

  // People who appear only on the screens built after the designs —
  // Network, Notifications and Search. The first two have one of the
  // designs' unnamed portraits; the rest have none, so their avatar is
  // their initials.

  static const leo = Person(
    name: 'Leo Navarro',
    headline: 'Motion designer at Orbital',
    avatar: DemoAssets.avatarConnectionA,
    location: 'Barcelona, Spain',
  );

  static const emil = Person(
    name: 'Emil Sandberg',
    headline: 'Front-end engineer at Halcyon',
    avatar: DemoAssets.avatarConnectionB,
    location: 'Copenhagen, Denmark',
    online: true,
  );

  static const hanna = Person(
    name: 'Hanna Sørensen',
    headline: 'Staff researcher at Orbital',
    avatar: '',
    location: 'Aarhus, Denmark',
  );

  static const tobias = Person(
    name: 'Tobias Lund',
    headline: 'Design operations lead at Halcyon',
    avatar: '',
    location: 'Copenhagen, Denmark',
  );

  static const priya = Person(
    name: 'Priya Nair',
    headline: 'Content designer at Quill',
    avatar: '',
    verified: true,
    location: 'London, United Kingdom',
  );

  static const jonas = Person(
    name: 'Jonas Berg',
    headline: 'Senior recruiter at Lumen Labs',
    avatar: '',
    location: 'Oslo, Norway',
  );

  static const ingrid = Person(
    name: 'Ingrid Dahl',
    headline: 'Design director at Halcyon',
    avatar: '',
    verified: true,
    location: 'Copenhagen, Denmark',
  );

  /// The signed-in user; an alias of [noor] that reads better at call sites.
  static const me = noor;

  /// The people above who are not in the designs; [all] stays the designs'
  /// twelve.
  static const beyondTheDesigns = <Person>[
    leo,
    emil,
    hanna,
    tobias,
    priya,
    jonas,
    ingrid,
  ];

  static const all = <Person>[
    noor,
    omar,
    julian,
    sara,
    aisha,
    freya,
    mei,
    mateo,
    rafael,
    elena,
    irina,
    claire,
  ];
}

/// The companies and the school that appear in more than one screen.
abstract final class Companies {
  static const halcyon = Company(
    name: 'Halcyon',
    logo: DemoAssets.logoHalcyon,
  );

  static const birchline = Company(
    name: 'Birchline',
    logo: DemoAssets.logoBirchline,
  );

  static const kestrelHealth = Company(
    name: 'Kestrel Health',
    logo: DemoAssets.logoKestrelHealth,
    industry: 'Health tech',
    size: '1,200 employees',
    website: 'kestrel.health',
  );

  static const lumenLabs = Company(
    name: 'Lumen Labs',
    logo: DemoAssets.logoLumenLabs,
  );

  static const orbital = Company(
    name: 'Orbital',
    logo: DemoAssets.logoOrbital,
    website: 'orbital.design',
  );

  static const quill = Company(name: 'Quill', logo: DemoAssets.logoQuill);

  static const tidewater = Company(
    name: 'Tidewater',
    logo: DemoAssets.logoTidewater,
  );

  static const nordhavnSchoolOfDesign = Company(
    name: 'Nordhavn School of Design',
    logo: DemoAssets.logoNordhavnSchoolOfDesign,
  );

  static const all = <Company>[
    halcyon,
    birchline,
    kestrelHealth,
    lumenLabs,
    orbital,
    quill,
    tidewater,
    nordhavnSchoolOfDesign,
  ];
}

/// The current user's groups: the home feed's "Your groups" card, the
/// profile, and the shared groups listed beside a conversation.
abstract final class Groups {
  static const designSystemsGuild = Group(
    name: 'Design Systems Guild',
    logo: DemoAssets.logoDesignSystemsGuild,
    members: '18,402 members',
    newPosts: 12,
  );

  static const copenhagenProductCircle = Group(
    name: 'Copenhagen Product Circle',
    logo: DemoAssets.logoCopenhagenProductCircle,
    members: '2,310 members',
    newPosts: 3,
  );

  static const accessibilityCollective = Group(
    name: 'Accessibility Collective',
    logo: DemoAssets.logoAccessibilityCollective,
    members: '9,875 members',
    newPosts: 8,
  );

  static const all = <Group>[
    designSystemsGuild,
    copenhagenProductCircle,
    accessibilityCollective,
  ];
}

/// The unread counts the navigation shows.
///
/// The Messages badge has no figure here: it counts the session's
/// conversations with something unread
/// (`MessagesController.unreadCount`).
abstract final class DemoCounts {
  /// The designs' figure. The bell itself counts the session's unread
  /// notifications (`NotificationsController.unreadCount`), which start at
  /// this many — a test holds the two together.
  static const unreadNotifications = 12;
}
