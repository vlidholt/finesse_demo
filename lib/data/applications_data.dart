import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_demo/data.dart';
import 'package:una_demo/data/jobs_data.dart';

/// How far an application has got: a column of the "My applications"
/// board.
enum ApplicationStage {
  saved('Saved', PhosphorIconsRegular.bookmarkSimple),
  applied('Applied', PhosphorIconsRegular.paperPlaneTilt),
  interviewing('Interviewing', PhosphorIconsRegular.chatsCircle),
  offer('Offer', PhosphorIconsRegular.sealCheck),
  archived('Archived', PhosphorIconsRegular.archive);

  const ApplicationStage(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// What an application's status line is about, which picks its colour.
enum ApplicationTone {
  /// Nothing to act on: grey.
  quiet,

  /// Something is happening: the theme's tint.
  active,

  /// Good news: green.
  good,

  /// A deadline: amber.
  urgent,
}

/// A role the current user is tracking: a card on the board.
@immutable
class JobApplication {
  const JobApplication({
    required this.id,
    required this.title,
    required this.company,
    required this.location,
    required this.status,
    required this.updated,
    required this.updatedHoursAgo,
    this.statusIcon = PhosphorIconsRegular.clock,
    this.tone = ApplicationTone.quiet,
  });

  /// A stable key: a card keeps it as it moves between stages.
  final String id;

  /// "Senior product designer".
  final String title;

  final Company company;

  /// "Copenhagen · Hybrid".
  final String location;

  /// The one thing to know now: "Interview Thu 10:00".
  final String status;
  final IconData statusIcon;
  final ApplicationTone tone;

  /// When the application last changed: "2d".
  final String updated;

  /// The same in hours, for "Sort by last updated".
  final int updatedHoursAgo;

  /// The application as it reads just after it was dragged to [stage].
  JobApplication movedTo(ApplicationStage stage) {
    final (status, icon, tone) = switch (stage) {
      ApplicationStage.saved => (
        'Saved for later',
        PhosphorIconsRegular.bookmarkSimple,
        ApplicationTone.quiet,
      ),
      ApplicationStage.applied => (
        'Application sent',
        PhosphorIconsRegular.paperPlaneTilt,
        ApplicationTone.quiet,
      ),
      ApplicationStage.interviewing => (
        'Interview to schedule',
        PhosphorIconsRegular.calendarBlank,
        ApplicationTone.active,
      ),
      ApplicationStage.offer => (
        'Offer received',
        PhosphorIconsRegular.confetti,
        ApplicationTone.good,
      ),
      ApplicationStage.archived => (
        'Archived',
        PhosphorIconsRegular.archive,
        ApplicationTone.quiet,
      ),
    };
    return JobApplication(
      id: id,
      title: title,
      company: company,
      location: location,
      status: status,
      statusIcon: icon,
      tone: tone,
      updated: 'Now',
      updatedHoursAgo: 0,
    );
  }
}

/// The content of the "My applications" board.
///
/// The Jobs screen's summary tiles count six saved jobs, four applications
/// and one interview this week, none of which is among the five listings
/// the screen shows; these are those roles. Saving or applying to a listing
/// adds it to the board on top of them.
abstract final class ApplicationsData {
  static const findTab = 'Find jobs';
  static const boardTab = 'My applications';

  static const addLabel = 'Add from job alerts';
  static const findMoreLabel = 'Find more jobs';

  static const Map<ApplicationStage, List<JobApplication>> initial = {
    ApplicationStage.saved: [
      JobApplication(
        id: 'halcyon-staff',
        title: 'Staff product designer',
        company: Companies.halcyon,
        location: 'Copenhagen · Hybrid',
        status: 'Closes in 3 days',
        statusIcon: PhosphorIconsRegular.hourglassMedium,
        tone: ApplicationTone.urgent,
        updated: '1d',
        updatedHoursAgo: 26,
      ),
      JobApplication(
        id: 'lumen-research',
        title: 'Design researcher',
        company: Companies.lumenLabs,
        location: 'Remote · EU',
        status: '3 connections work here',
        statusIcon: PhosphorIconsRegular.usersThree,
        updated: '2d',
        updatedHoursAgo: 50,
      ),
      JobApplication(
        id: 'tidewater-mobile',
        title: 'Product designer, Mobile',
        company: Companies.tidewater,
        location: 'Aarhus · On-site',
        status: 'Saved from a job alert',
        statusIcon: PhosphorIconsRegular.bell,
        updated: '3d',
        updatedHoursAgo: 74,
      ),
      JobApplication(
        id: 'orbital-brand',
        title: 'Brand and product designer',
        company: Companies.orbital,
        location: 'Berlin · Hybrid',
        status: 'Easy apply',
        statusIcon: PhosphorIconsRegular.lightning,
        tone: ApplicationTone.good,
        updated: '4d',
        updatedHoursAgo: 98,
      ),
      JobApplication(
        id: 'quill-growth',
        title: 'Senior designer, Growth',
        company: Companies.quill,
        location: 'Remote · EU',
        status: 'Salary €70k – €84k',
        statusIcon: PhosphorIconsRegular.currencyDollar,
        updated: '5d',
        updatedHoursAgo: 122,
      ),
      JobApplication(
        id: 'birchline-systems',
        title: 'Design systems engineer',
        company: Companies.birchline,
        location: 'Stockholm · Hybrid',
        status: 'Saved from search',
        statusIcon: PhosphorIconsRegular.magnifyingGlass,
        updated: '1w',
        updatedHoursAgo: 170,
      ),
    ],
    ApplicationStage.applied: [
      JobApplication(
        id: 'kestrel-care',
        title: 'Product designer, Care plans',
        company: Companies.kestrelHealth,
        location: 'Copenhagen · Hybrid',
        status: 'Viewed by the hiring team',
        statusIcon: PhosphorIconsRegular.eye,
        tone: ApplicationTone.active,
        updated: '5h',
        updatedHoursAgo: 5,
      ),
      JobApplication(
        id: 'halcyon-platform',
        title: 'Senior designer, Platform',
        company: Companies.halcyon,
        location: 'Copenhagen · Hybrid',
        status: 'Application sent',
        statusIcon: PhosphorIconsRegular.paperPlaneTilt,
        updated: '2d',
        updatedHoursAgo: 49,
      ),
      JobApplication(
        id: 'lumen-ai',
        title: 'Product designer, Assistants',
        company: Companies.lumenLabs,
        location: 'Remote · EU',
        status: 'Usually replies within a week',
        updated: '4d',
        updatedHoursAgo: 96,
      ),
      JobApplication(
        id: 'tidewater-lead',
        title: 'Lead designer, Logistics',
        company: Companies.tidewater,
        location: 'Aarhus · Hybrid',
        status: 'Application sent',
        statusIcon: PhosphorIconsRegular.paperPlaneTilt,
        updated: '1w',
        updatedHoursAgo: 168,
      ),
    ],
    ApplicationStage.interviewing: [
      JobApplication(
        id: 'orbital-senior',
        title: 'Senior product designer',
        company: Companies.orbital,
        location: 'Berlin · Remote',
        status: 'Portfolio review, Thu 10:00',
        statusIcon: PhosphorIconsRegular.calendarCheck,
        tone: ApplicationTone.active,
        updated: '3h',
        updatedHoursAgo: 3,
      ),
      JobApplication(
        id: 'quill-editor-lead',
        title: 'Design lead, Collaboration',
        company: Companies.quill,
        location: 'Remote · EU',
        status: 'Waiting for times from Quill',
        statusIcon: PhosphorIconsRegular.hourglassMedium,
        updated: '2d',
        updatedHoursAgo: 52,
      ),
    ],
    ApplicationStage.offer: [
      JobApplication(
        id: 'birchline-principal',
        title: 'Principal designer',
        company: Companies.birchline,
        location: 'Stockholm · Hybrid',
        status: '€104k offer · reply by Friday',
        statusIcon: PhosphorIconsRegular.confetti,
        tone: ApplicationTone.good,
        updated: '1d',
        updatedHoursAgo: 24,
      ),
    ],
    ApplicationStage.archived: [
      JobApplication(
        id: 'halcyon-manager',
        title: 'Design manager',
        company: Companies.halcyon,
        location: 'Copenhagen · On-site',
        status: 'Position filled',
        statusIcon: PhosphorIconsRegular.minusCircle,
        updated: '2w',
        updatedHoursAgo: 340,
      ),
      JobApplication(
        id: 'lumen-content',
        title: 'Content designer',
        company: Companies.lumenLabs,
        location: 'Remote · EU',
        status: 'You withdrew',
        statusIcon: PhosphorIconsRegular.arrowUUpLeft,
        updated: '3w',
        updatedHoursAgo: 510,
      ),
      JobApplication(
        id: 'tidewater-visual',
        title: 'Visual designer',
        company: Companies.tidewater,
        location: 'Aarhus · On-site',
        status: 'Not selected',
        statusIcon: PhosphorIconsRegular.xCircle,
        updated: '1mo',
        updatedHoursAgo: 740,
      ),
      JobApplication(
        id: 'orbital-junior',
        title: 'Product designer',
        company: Companies.orbital,
        location: 'Berlin · Hybrid',
        status: 'Position filled',
        statusIcon: PhosphorIconsRegular.minusCircle,
        updated: '1mo',
        updatedHoursAgo: 800,
      ),
      JobApplication(
        id: 'quill-docs',
        title: 'Designer, Documentation',
        company: Companies.quill,
        location: 'Remote · EU',
        status: 'Role closed',
        statusIcon: PhosphorIconsRegular.lockSimple,
        updated: '2mo',
        updatedHoursAgo: 1500,
      ),
      JobApplication(
        id: 'kestrel-research',
        title: 'UX researcher',
        company: Companies.kestrelHealth,
        location: 'Copenhagen · Hybrid',
        status: 'Not selected',
        statusIcon: PhosphorIconsRegular.xCircle,
        updated: '2mo',
        updatedHoursAgo: 1560,
      ),
      JobApplication(
        id: 'birchline-interim',
        title: 'Interim design lead',
        company: Companies.birchline,
        location: 'Stockholm · On-site',
        status: 'You withdrew',
        statusIcon: PhosphorIconsRegular.arrowUUpLeft,
        updated: '3mo',
        updatedHoursAgo: 2200,
      ),
    ],
  };

  /// Roles "Add from job alerts" brings in, in this order.
  static const suggestions = <JobApplication>[
    JobApplication(
      id: 'kestrel-ops',
      title: 'Product designer, Clinical ops',
      company: Companies.kestrelHealth,
      location: 'Copenhagen · Hybrid',
      status: 'New from your job alert',
      statusIcon: PhosphorIconsRegular.bell,
      tone: ApplicationTone.active,
      updated: 'Now',
      updatedHoursAgo: 0,
    ),
    JobApplication(
      id: 'orbital-motion',
      title: 'Motion designer, Product',
      company: Companies.orbital,
      location: 'Berlin · Remote',
      status: 'New from your job alert',
      statusIcon: PhosphorIconsRegular.bell,
      tone: ApplicationTone.active,
      updated: 'Now',
      updatedHoursAgo: 0,
    ),
    JobApplication(
      id: 'tidewater-design-ops',
      title: 'Design operations lead',
      company: Companies.tidewater,
      location: 'Aarhus · Hybrid',
      status: 'New from your job alert',
      statusIcon: PhosphorIconsRegular.bell,
      tone: ApplicationTone.active,
      updated: 'Now',
      updatedHoursAgo: 0,
    ),
  ];

  /// The card for a listing saved or applied to on the "Find jobs" side.
  static JobApplication fromJob(Job job, {required bool applied}) =>
      JobApplication(
        id: job.id,
        title: job.title,
        company: job.company,
        location: job.location,
        status: applied
            ? (job.easyApply ? 'Applied with Easy apply' : 'Application sent')
            : 'Salary ${job.salary}',
        statusIcon: applied
            ? PhosphorIconsRegular.paperPlaneTilt
            : PhosphorIconsRegular.currencyDollar,
        tone: applied ? ApplicationTone.active : ApplicationTone.quiet,
        updated: 'Now',
        updatedHoursAgo: 0,
      );
}
