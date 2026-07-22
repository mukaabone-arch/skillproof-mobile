import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/matched_job.dart' show SkillMatch;
import '../entitlements/entitlements_controller.dart';
import 'jobs_repository.dart';
import 'jobs_state.dart';

/// One controller instance per job id (`.family`), since a candidate can
/// have several job detail screens stacked in the nav at once (e.g. after
/// tapping through from both "Matched" and "Browse").
final jobDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<JobDetailController, JobDetailState, String>((ref, jobId) {
  return JobDetailController(
    ref.read(jobsRepositoryProvider),
    jobId,
    // Applying consumes a unit of the 'applications' quota — refetch so
    // usage meters elsewhere reflect reality rather than being optimistically
    // patched. The API also refunds quota on a downstream 4xx, so this fires
    // after every outcome (see apply() below), not just success.
    onQuotaConsumingAction: () => ref.read(entitlementsControllerProvider.notifier).load(),
  )..load();
});

class JobDetailController extends StateNotifier<JobDetailState> {
  JobDetailController(this._repository, this._jobId, {required this.onQuotaConsumingAction})
      : super(const JobDetailLoading());

  final JobsRepository _repository;
  final String _jobId;

  /// Injected rather than read directly (same DI idiom as
  /// AssessmentsController's launcher) so this stays testable without a
  /// Riverpod container.
  final Future<void> Function() onQuotaConsumingAction;

  Future<void> load() async {
    state = const JobDetailLoading();
    try {
      final job = await _repository.browseOne(_jobId);
      state = JobDetailLoaded(job: job, missing: await _loadMissingSkills());
    } catch (e) {
      state = JobDetailError(e.toString());
    }
  }

  /// Best-effort — mirrors apps/web/app/jobs/[id]/page.tsx's own
  /// `.catch(() => undefined)`: no verified skills yet (an empty /jobs/matched)
  /// or a failed fetch just means no gap section renders, not an error on
  /// top of the job detail itself.
  Future<List<SkillMatch>> _loadMissingSkills() async {
    try {
      final matched = await _repository.matched();
      for (final m in matched) {
        if (m.job.id == _jobId) return m.missing;
      }
      return const [];
    } catch (_) {
      return const [];
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
    // next one. `missing` carries forward unchanged (applying doesn't affect
    // the candidate's skill gap for this job).
    final cleared = JobDetailLoaded(job: current.job, applying: true, missing: current.missing);
    state = cleared;

    try {
      await _repository.apply(_jobId);
      // Re-fetch rather than locally flipping `alreadyApplied`, so the
      // screen reflects exactly what the server now has.
      final refreshed = await _repository.browseOne(_jobId);
      state = JobDetailLoaded(job: refreshed, missing: current.missing);
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
    } finally {
      // Any outcome here (success, a refunded 4xx like PROFILE_INCOMPLETE/
      // BADGE_REQUIRED/LIMIT_REACHED, or a genuine failure) can change the
      // applications quota server-side — never assume it's unaffected.
      unawaited(onQuotaConsumingAction());
    }
  }
}
