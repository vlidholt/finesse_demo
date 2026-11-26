import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/home_data.dart';
import 'package:una_demo/data/jobs_data.dart';
import 'package:una_demo/data/network_data.dart';
import 'package:una_demo/data/profile_data.dart';

/// The tabs over the search results.
enum SearchCategory {
  all('All', PhosphorIconsRegular.magnifyingGlass),
  people('People', PhosphorIconsRegular.users),
  jobs('Jobs', PhosphorIconsRegular.briefcase),
  posts('Posts', PhosphorIconsRegular.article),
  companies('Companies', PhosphorIconsRegular.buildings);

  const SearchCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  /// The four kinds of result; everything but [all].
  static const kinds = [people, jobs, posts, companies];
}

/// A post as search finds it: from the home feed or from the user's own
/// profile.
@immutable
class SearchPost {
  const SearchPost({
    required this.author,
    required this.text,
    required this.age,
    required this.reactions,
    required this.comments,
    required this.own,
  });

  final Person author;
  final String text;

  /// "2h", "1w".
  final String age;
  final int reactions;
  final int comments;

  /// Whether the signed-in user wrote it: it opens the profile, not the
  /// feed.
  final bool own;
}

/// A company as search finds it.
@immutable
class SearchCompany {
  const SearchCompany(this.company, this.tagline, this.openRoles);

  final Company company;

  /// "Health tech · 1,200 employees".
  final String tagline;

  /// How many of the Jobs screen's listings are this company's.
  final int openRoles;
}

/// What a query found.
@immutable
class SearchResults {
  const SearchResults({
    this.people = const [],
    this.jobs = const [],
    this.posts = const [],
    this.companies = const [],
  });

  final List<Person> people;
  final List<Job> jobs;
  final List<SearchPost> posts;
  final List<SearchCompany> companies;

  int get total =>
      people.length + jobs.length + posts.length + companies.length;

  bool get isEmpty => total == 0;

  int countOf(SearchCategory category) => switch (category) {
    SearchCategory.all => total,
    SearchCategory.people => people.length,
    SearchCategory.jobs => jobs.length,
    SearchCategory.posts => posts.length,
    SearchCategory.companies => companies.length,
  };
}

/// Search over the app's own mock data: the people, job listings, posts and
/// companies the other screens show.
abstract final class SearchData {
  /// What the field has been searched for before, newest first, as the app
  /// starts.
  static const recents = ['Design systems', 'Kestrel Health', 'Omar Rahimi'];

  /// Searches other people are running; every one of them finds something.
  static const trending = [
    'Config Nordics',
    'Onboarding',
    'Product designer',
    'Accessibility',
    'Birchline',
    'Research',
  ];

  /// Everyone search can find: all of Demo but the signed-in user.
  static final people = <Person>[
    for (final person in [...People.all, ...People.beyondTheDesigns])
      if (person != People.me) person,
  ];

  static final posts = <SearchPost>[
    for (final post in HomeData.posts)
      SearchPost(
        author: post.author,
        text: post.body,
        age: post.age,
        reactions: post.reactionCount,
        comments: post.comments,
        own: false,
      ),
    for (final post in ProfileData.posts)
      SearchPost(
        author: People.me,
        text: post.text,
        age: post.time,
        reactions: post.reactions,
        comments: post.comments,
        own: true,
      ),
  ];

  static final companies = <SearchCompany>[
    for (final company in Companies.all)
      SearchCompany(
        company,
        _taglineOf(company),
        JobsData.jobs.where((job) => job.company == company).length,
      ),
  ];

  static String _taglineOf(Company company) {
    for (final page in NetworkData.pages) {
      if (page.company == company) return page.tagline;
    }
    return [?company.industry, ?company.size].join(' · ');
  }

  // The lower-case letters of Latin-1 and Latin Extended-A that are a
  // plain letter with a mark, and the plain letter each one is.
  static const _marked =
      'àáâãäåçèéêëìíîïñòóôõöøùúûüýÿāăąćĉċčďđēĕėęěĝğġģĥħĩīĭįıĵķĺļľłńņňōŏőŕŗřśŝ'
      'şšţťŧũūŭůűųŵŷźżž';
  static const _plain =
      'aaaaaaceeeeiiiinoooooouuuuyyaaaccccddeeeeegggghhiiiiijkllllnnnooorrrss'
      'sstttuuuuuuwyzzz';

  /// [text] as search compares it: lower-cased, and with the marks taken
  /// off its letters, so that "sorensen" finds "Sørensen".
  ///
  /// The result has exactly as many code units as [text] — every one is
  /// folded on its own, and a letter that would become two (`æ`, `ß`) is
  /// left as it is — so an offset found in the folded text is the same
  /// offset in the original, which is what the highlighting relies on.
  static String fold(String text) {
    final units = List<int>.of(text.codeUnits);
    for (var i = 0; i < units.length; i++) {
      // ASCII is most of any text.
      if (units[i] < 0x41) continue;
      final lower = String.fromCharCode(units[i]).toLowerCase();
      if (lower.length != 1) continue;
      final marked = _marked.indexOf(lower);
      units[i] = marked < 0 ? lower.codeUnitAt(0) : _plain.codeUnitAt(marked);
    }
    return String.fromCharCodes(units);
  }

  /// The words of [query], folded as [fold] does; a result has to contain
  /// them all.
  static List<String> termsOf(String query) => [
    for (final term in fold(query).split(RegExp(r'\s+')))
      if (term.isNotEmpty) term,
  ];

  /// Everything that matches [query]. A blank query matches nothing.
  static SearchResults search(String query) {
    final terms = termsOf(query);
    if (terms.isEmpty) return const SearchResults();

    bool matches(Iterable<String?> fields) {
      final haystack = fold(fields.nonNulls.join('\n'));
      return terms.every(haystack.contains);
    }

    return SearchResults(
      people: [
        for (final person in people)
          if (matches([person.name, person.headline, person.location])) person,
      ],
      jobs: [
        for (final job in JobsData.jobs)
          if (matches([job.title, job.company.name, job.location])) job,
      ],
      posts: [
        for (final post in posts)
          if (matches([post.text, post.author.name])) post,
      ],
      companies: [
        for (final entry in companies)
          if (matches([entry.company.name, entry.tagline])) entry,
      ],
    );
  }

  /// The stretch of [text] around the first match of [query], for a post
  /// too long to show whole: "…cutting six setup screens down to two…".
  static String excerpt(String text, String query, {int radius = 70}) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final lower = fold(flat);
    var first = -1;
    for (final term in termsOf(query)) {
      final index = lower.indexOf(term);
      if (index >= 0 && (first < 0 || index < first)) first = index;
    }
    if (first < radius) return flat;
    // Start on a word, a little before the match.
    final from = flat.indexOf(' ', first - radius ~/ 2) + 1;
    return '…${flat.substring(from)}';
  }
}
