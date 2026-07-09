import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'jobs_repository.dart';
import 'jobs_state.dart';

/// One controller instance per job id (`.family`), since a candidate can
/// have several job detail screens stacked in the nav at once (e.g. after
/// tapping through from both "Matched" and "Browse").
final jobDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<JobDetailController, JobDetailState, String>((ref, jobId) {
  return JobDetailController(ref.read(jobsRepositoryProvider), jobId)..load();
});

class JobDetailController extends StateNotifier<JobDetailState> {
  JobDetailController(this._repository, this._jobId) : super(const JobDetailLoading());

  final JobsRepository _repository;
  final String _jobId;

  Future<void> load() async {
    state = const JobDetailLoading();
    try {
      final job = await _repository.browseOne(_jobId);
      state = JobDetailLoaded(job: job);
    } catch (e) {
      state = JobDetailError(e.toString());
    }
  }

  /// Mirrors apps/web/app/jobs/[id]/page.tsx: a 400 with a machine-readable
  /// `code` (PROFILE_INCOMPLETE / BADGE_REQUIRED) means the request was
  /// well-formed but the candidate needs to take an action first, so it
  /// gets a targeted prompt instead of surfacing as a raw error string.
  Future<void> apply() async {
    final current = state;
    if (current is! JobDetailLoaded) return;

    // Base every outcome off this cleared snapshot, not `current` — otherwise
    // a stale issue/error from a previous failed attempt would leak into the
    // next one.
    final cleared = JobDetailLoaded(job: current.job, applying: true);
    state = cleared;

    try {
      await _repository.apply(_jobId);
      // Re-fetch rather than locally flipping `alreadyApplied`, so the
      // screen reflects exactly what the server now has.
      final refreshed = await _repository.browseOne(_jobId);
      state = JobDetailLoaded(job: refreshed);
    } on ApiException catch (e) {
      final code = e.body is Map ? (e.body as Map)['code'] as String? : null;
      if (code == 'PROFILE_INCOMPLETE' || code == 'BADGE_REQUIRED') {
        state = cleared.copyWith(
          applying: false,
          applyIssueCode: code,
          applyIssueMessage: e.message,
        );
      } else {
        state = cleared.copyWith(applying: false, applyError: e.message);
      }
    } catch (e) {
      state = cleared.copyWith(applying: false, applyError: e.toString());
    }
  }
}
