import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/assets.dart';
import 'package:una_demo/data.dart';

/// A job listing, as a card in the results list and as the detail pane.
@immutable
class Job {
  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.detailLocation,
    required this.salary,
    required this.connections,
    required this.posted,
    required this.postedLong,
    required this.postedHoursAgo,
    required this.applicants,
    required this.salaryCeiling,
    this.easyApply = false,
    this.topPick = false,
  });

  /// A stable key for selection and the saved set.
  final String id;

  /// "Senior product designer, Design systems".
  final String title;

  final Company company;

  /// The card's short place line: "Copenhagen · Hybrid".
  final String location;

  /// The detail pane's place: "Copenhagen, Denmark".
  final String detailLocation;

  /// "€78k – €95k".
  final String salary;

  /// Whether the card carries the "Easy apply" tag.
  final bool easyApply;

  /// The people the current user knows at the company, first on top.
  final List<Person> connections;

  /// The card's age: "2d ago".
  final String posted;

  /// The detail pane's age: "2 days ago".
  final String postedLong;

  /// The age in hours, for the "Most recent" sort.
  final int postedHoursAgo;

  final int applicants;

  /// The top of the salary band in thousands, for the "Highest salary" sort.
  final int salaryCeiling;

  /// Whether a phone lists the job under "Top picks for you".
  final bool topPick;

  /// "2 connections work here" — the design's wording, singular included.
  String get connectionsLabel {
    final count = connections.length;
    return '$count ${count == 1 ? 'connection' : 'connections'} work here';
  }

  /// "Posted 2d ago · 41 applicants".
  String get postedLabel => 'Posted $posted · $applicants applicants';

  /// "Copenhagen, Denmark · Posted 2 days ago · 41 applicants".
  String get detailMeta =>
      '$detailLocation · Posted $postedLong · $applicants applicants';
}

/// One of the unnamed faces in a "connections work here" stack.
const _connectionB = Person(
  name: 'Connection',
  headline: '',
  avatar: DemoAssets.avatarConnectionB,
);

/// A filter chip under the desktop search fields.
@immutable
class JobFilter {
  const JobFilter(this.label, {this.icon});

  final String label;
  final IconData? icon;
}

/// One of the four summary tiles.
@immutable
class JobStat {
  const JobStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final int value;
  final String label;
}

/// One of the four fact tiles in the detail pane.
@immutable
class JobFact {
  const JobFact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// A skill in the "Strong match" panel.
@immutable
class JobSkill {
  const JobSkill(this.name, {this.matched = true});

  final String name;

  /// Whether the current user's profile lists it.
  final bool matched;
}

/// How the results list is ordered.
enum JobSort {
  relevant('Most relevant'),
  recent('Most recent'),
  salary('Highest salary');

  const JobSort(this.label);

  final String label;
}

/// The content of the Jobs screen, copied from the Demo designs.
abstract final class JobsData {
  static const title = 'Jobs';
  static const subtitle = '12 new roles match your profile since Monday.';

  static const titleQuery = 'Product designer';
  static const titlePlaceholder = 'Title, skill or company';
  static const locationQuery = 'Copenhagen, Denmark';
  static const locationPlaceholder = 'City or remote';

  static const resultCount = 248;

  static const filters = <JobFilter>[
    JobFilter('Remote', icon: PhosphorIconsRegular.globe),
    JobFilter('Hybrid'),
    JobFilter('Senior'),
    JobFilter('Posted this week', icon: PhosphorIconsRegular.clock),
    JobFilter('€70k+', icon: PhosphorIconsRegular.currencyDollar),
    JobFilter('Easy apply', icon: PhosphorIconsRegular.lightning),
    JobFilter('Under 50 applicants'),
  ];

  /// The filters the designs show switched on.
  static const initialFilters = {'Remote'};

  static const savedJobs = JobStat(
    icon: PhosphorIconsRegular.bookmarkSimple,
    value: 6,
    label: 'Saved jobs',
  );
  static const applicationsSent = JobStat(
    icon: PhosphorIconsRegular.paperPlaneTilt,
    value: 4,
    label: 'Applications sent',
  );
  static const interviews = JobStat(
    icon: PhosphorIconsRegular.calendarBlank,
    value: 1,
    label: 'Interview this week',
  );
  static const profileViews = JobStat(
    icon: PhosphorIconsRegular.eye,
    value: 18,
    label: 'Recruiter profile views',
  );

  static const kestrel = Job(
    id: 'kestrel-design-systems',
    title: 'Senior product designer, Design systems',
    company: Companies.kestrelHealth,
    location: 'Copenhagen · Hybrid',
    detailLocation: 'Copenhagen, Denmark',
    salary: '€78k – €95k',
    salaryCeiling: 95,
    easyApply: true,
    connections: [People.julian, People.elena],
    posted: '2d ago',
    postedLong: '2 days ago',
    postedHoursAgo: 48,
    applicants: 41,
    topPick: true,
  );

  static const quill = Job(
    id: 'quill-editor',
    title: 'Product designer, Editor',
    company: Companies.quill,
    location: 'Remote · EU',
    detailLocation: 'Remote, EU',
    salary: '€65k – €80k',
    salaryCeiling: 80,
    easyApply: true,
    connections: [_connectionB, People.freya],
    posted: '5h ago',
    postedLong: '5 hours ago',
    postedHoursAgo: 5,
    applicants: 12,
    topPick: true,
  );

  static const birchline = Job(
    id: 'birchline-onboarding',
    title: 'Design lead, Onboarding',
    company: Companies.birchline,
    location: 'Stockholm · Hybrid',
    detailLocation: 'Stockholm, Sweden',
    salary: '€85k – €105k',
    salaryCeiling: 105,
    connections: [People.omar, People.sara, People.irina],
    posted: '1d ago',
    postedLong: '1 day ago',
    postedHoursAgo: 24,
    applicants: 67,
  );

  static const tidewater = Job(
    id: 'tidewater-ux',
    title: 'Senior UX designer',
    company: Companies.tidewater,
    location: 'Aarhus · Hybrid',
    detailLocation: 'Aarhus, Denmark',
    salary: '€60k – €75k',
    salaryCeiling: 75,
    easyApply: true,
    connections: [People.mateo],
    posted: '3d ago',
    postedLong: '3 days ago',
    postedHoursAgo: 72,
    applicants: 28,
    topPick: true,
  );

  static const orbital = Job(
    id: 'orbital-platform',
    title: 'Principal designer, Platform',
    company: Companies.orbital,
    location: 'Remote · Europe',
    detailLocation: 'Remote, Europe',
    salary: '€95k – €120k',
    salaryCeiling: 120,
    connections: [People.aisha],
    posted: '1w ago',
    postedLong: '1 week ago',
    postedHoursAgo: 168,
    applicants: 104,
  );

  /// The results, in the designs' "Most relevant" order.
  static const jobs = <Job>[kestrel, quill, birchline, tidewater, orbital];

  // The detail pane. The designs only detail the Kestrel Health role; the
  // other four reuse its copy under their own title, company and salary.

  static const companyTagline = 'Health tech · 1,200 employees';

  static const workplace = JobFact(
    icon: PhosphorIconsRegular.buildings,
    label: 'Workplace',
    value: 'Hybrid, 2 days in office',
  );
  static const team = JobFact(
    icon: PhosphorIconsRegular.usersThree,
    label: 'Team',
    value: '4 designers, 12 engineers',
  );
  static const responseTime = JobFact(
    icon: PhosphorIconsRegular.clock,
    label: 'Response time',
    value: 'Usually within a week',
  );

  /// The four fact tiles of [job].
  static List<JobFact> factsFor(Job job) => [
    JobFact(
      icon: PhosphorIconsRegular.currencyDollar,
      label: 'Salary',
      value: '${job.salary} a year',
    ),
    workplace,
    team,
    responseTime,
  ];

  static const matchTitle = 'Strong match for your profile';
  static const matchSummary = 'You have 8 of 10 skills listed in this role';
  static const matchScore = .8;
  static const matchScoreLabel = '80%';

  static const skills = <JobSkill>[
    JobSkill('Design systems'),
    JobSkill('Figma'),
    JobSkill('Accessibility'),
    JobSkill('Prototyping'),
    JobSkill('User research'),
    JobSkill('Workshops'),
    JobSkill('Healthcare', matched: false),
    JobSkill('Native iOS', matched: false),
  ];

  static const hiringTeamTitle = 'Meet the hiring team';
  static const hiringManager = People.julian;
  static const hiringManagerDegree = '2nd';
  static const hiringManagerRole = 'VP Design at Kestrel Health · Job poster';

  static const aboutRoleTitle = 'About the role';
  static const aboutRole =
      'Kestrel’s patient and clinician apps are used across the Nordics. '
      'You’ll own the design system that sits underneath both, working with '
      'a team of four designers and twelve front-end engineers.';

  static const responsibilitiesTitle = 'What you’ll do';
  static const responsibilities = <String>[
    'Set the direction for components, tokens and documentation across web '
        'and mobile',
    'Pair with engineering to ship accessible components that meet WCAG 2.2 '
        'AA',
    'Run monthly critiques and office hours with product teams',
    'Measure adoption and make the case for where to invest next',
  ];

  // "Easy Apply". The designs stop at the button; these fill its steps.

  /// The phone number the application form starts with.
  static const applicantPhone = '+45 20 41 18 07';

  /// The files the user can send, with when each last changed.
  static const resumes = <(String, String)>[
    ('CV 2026.pdf', 'Updated 3 days ago'),
    ('Portfolio.pdf', 'Updated last month'),
  ];

  static const companyFacts = <(IconData, String)>[
    (PhosphorIconsRegular.usersThree, '1,200 employees'),
    (PhosphorIconsRegular.globe, 'Offices in 4 Nordic cities'),
    (PhosphorIconsRegular.link, 'kestrel.health'),
  ];
}
