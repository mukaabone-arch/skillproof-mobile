import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/interview.dart';
import 'interviews_repository.dart';
import 'interviews_state.dart';

final interviewsControllerProvider =
    StateNotifierProvider.autoDispose<InterviewsController, InterviewsState>((ref) {
  return InterviewsController(ref.read(interviewsRepositoryProvider))..load();
});

class InterviewsController extends StateNotifier<InterviewsState> {
  InterviewsController(this._repository) : super(const InterviewsLoading());

  final InterviewsRepository _repository;

  Future<void> load() async {
    state = const InterviewsLoading();
    try {
      final interviews = await _repository.mine();
      state = InterviewsLoaded(interviews);
    } catch (e) {
      state = InterviewsError(e.toString());
    }
  }

  Future<void> respondInvite(String id, String response) async {
    final current = state;
    if (current is! InterviewsLoaded || current.busyId != null) return;

    // Built fresh (not a copyWith merge) so a stale actionError from a
    // previous failed attempt never leaks into this one — same idiom as
    // JobDetailController.apply.
    final cleared = InterviewsLoaded(current.interviews, busyId: id);
    state = cleared;

    try {
      final patch = await _repository.respondInvite(id, response);
      state = InterviewsLoaded(_replaceStage(cleared.interviews, patch.id, patch.stage));
    } on ApiException catch (e) {
      state = InterviewsLoaded(cleared.interviews, actionError: e.message);
    } catch (e) {
      state = InterviewsLoaded(cleared.interviews, actionError: e.toString());
    }
  }

  Future<void> respondOffer(String id, String response) async {
    final current = state;
    if (current is! InterviewsLoaded || current.busyId != null) return;

    final cleared = InterviewsLoaded(current.interviews, busyId: id);
    state = cleared;

    try {
      final patch = await _repository.respondOffer(id, response);
      state = InterviewsLoaded(_replaceCandidateResponse(cleared.interviews, patch.id, patch.candidateResponse));
    } on ApiException catch (e) {
      if (e.statusCode == 409) {
        // Documented case: the employer already moved this entry past
        // OFFER before the response landed. Refetch rather than retry —
        // the card needs to catch up to whatever the server now has, not
        // repeat a request that will only 409 again.
        await _refreshAfterConflict(e.message);
      } else {
        state = InterviewsLoaded(cleared.interviews, actionError: e.message);
      }
    } catch (e) {
      state = InterviewsLoaded(cleared.interviews, actionError: e.toString());
    }
  }

  Future<void> _refreshAfterConflict(String message) async {
    try {
      final refreshed = await _repository.mine();
      state = InterviewsLoaded(refreshed, actionError: message);
    } catch (_) {
      // Refresh itself failed (e.g. offline) — keep the conflict message,
      // stale list is better than none.
      final current = state;
      if (current is InterviewsLoaded) state = InterviewsLoaded(current.interviews, actionError: message);
    }
  }

  List<Interview> _replaceStage(List<Interview> interviews, String id, String stage) {
    return [for (final i in interviews) if (i.id == id) i.withStage(stage) else i];
  }

  List<Interview> _replaceCandidateResponse(List<Interview> interviews, String id, String candidateResponse) {
    return [for (final i in interviews) if (i.id == id) i.withCandidateResponse(candidateResponse) else i];
  }
}
