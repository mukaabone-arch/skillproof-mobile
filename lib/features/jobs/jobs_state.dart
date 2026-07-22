import '../../models/application.dart';
import '../../models/job.dart';
import '../../models/matched_job.dart' show MatchedJob, SkillMatch;

sealed class MatchedState {
  const MatchedState();
}

class MatchedLoading extends MatchedState {
  const MatchedLoading();
}

class MatchedLoaded extends MatchedState {
  const MatchedLoaded(this.jobs);

  final List<MatchedJob> jobs;
}

class MatchedError extends MatchedState {
  const MatchedError(this.message);

  final String message;
}

sealed class BrowseState {
  const BrowseState();
}

class BrowseLoading extends BrowseState {
  const BrowseLoading();
}

class BrowseLoaded extends BrowseState {
  const BrowseLoaded({required this.jobs, required this.total});

  final List<Job> jobs;
  final int total;
}

class BrowseError extends BrowseState {
  const BrowseError(this.message);

  final String message;
}

sealed class ApplicationsState {
  const ApplicationsState();
}

class ApplicationsLoading extends ApplicationsState {
  const ApplicationsLoading();
}

class ApplicationsLoaded extends ApplicationsState {
  const ApplicationsLoaded(this.applications);

  final List<Application> applications;
}

class ApplicationsError extends ApplicationsState {
  const ApplicationsError(this.message);

  final String message;
}

sealed class JobDetailState {
  const JobDetailState();
}

class JobDetailLoading extends JobDetailState {
  const JobDetailLoading();
}

class JobDetailError extends JobDetailState {
  const JobDetailError(this.message);

  final String message;
}

class JobDetailLoaded extends JobDetailState {
  const JobDetailLoaded({
    required this.job,
    this.applying = false,
    this.applyIssueCode,
    this.applyIssueMessage,
    this.applyError,
    this.missing = const [],
  });

  final Job job;
  final bool applying;

  /// 'PROFILE_INCOMPLETE' or 'BADGE_REQUIRED' — drives an actionable prompt
  /// in place of the raw API error text.
  final String? applyIssueCode;
  final String? applyIssueMessage;
  final String? applyError;

  /// This job's skill gap against the candidate's own verified skills —
  /// best-effort, from GET /jobs/matched (see JobDetailController.load).
  /// Empty when the candidate has no verified skills yet, or when the
  /// matched fetch itself fails; either way there's nothing to show, not
  /// an error worth surfacing on top of the job detail itself.
  final List<SkillMatch> missing;

  JobDetailLoaded copyWith({
    Job? job,
    bool? applying,
    String? applyIssueCode,
    String? applyIssueMessage,
    String? applyError,
    List<SkillMatch>? missing,
  }) {
    return JobDetailLoaded(
      job: job ?? this.job,
      applying: applying ?? this.applying,
      applyIssueCode: applyIssueCode ?? this.applyIssueCode,
      applyIssueMessage: applyIssueMessage ?? this.applyIssueMessage,
      applyError: applyError ?? this.applyError,
      missing: missing ?? this.missing,
    );
  }
}
