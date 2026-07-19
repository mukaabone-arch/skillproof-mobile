import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/interview.dart';

final interviewsRepositoryProvider = Provider<InterviewsRepository>((ref) {
  return InterviewsRepository(apiClient: ref.read(apiClientProvider));
});

/// The result of POST /interviews/:id/respond-invite — a patch, not the
/// full entry (see InterviewsRepository doc).
class InvitePatch {
  InvitePatch({required this.id, required this.stage});

  final String id;
  final String stage;
}

/// The result of POST /interviews/:id/respond-offer — a patch, not the
/// full entry.
class OfferPatch {
  OfferPatch({required this.id, required this.candidateResponse});

  final String id;
  final String candidateResponse;
}

/// Talks to the candidate-facing interview pipeline endpoints. Deliberately
/// sparser than the employer side: GET /interviews/mine only ever returns
/// the latest round (no history, no total count) and never returns
/// employer notes/reject reasons — see InterviewsService.present on the
/// API side. There is no detail endpoint; the two action endpoints return
/// a small patch object rather than the full updated entry, so callers
/// apply the patch to their local list (see Interview.withStage /
/// .withCandidateResponse) instead of refetching one entry.
class InterviewsRepository {
  InterviewsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<Interview>> mine() async {
    final response = await apiClient.get('/interviews/mine') as List<dynamic>;
    return response.map((i) => Interview.fromJson(i as Map<String, dynamic>)).toList();
  }

  Future<InvitePatch> respondInvite(String id, String response) async {
    final result = await apiClient.post('/interviews/$id/respond-invite', {'response': response}) as Map<String, dynamic>;
    return InvitePatch(id: result['id'] as String, stage: result['stage'] as String);
  }

  /// Can 409 if the employer already moved this entry past OFFER before
  /// the candidate's response landed — the offer decision window closed
  /// server-side. Callers should catch [ApiException] and treat a 409 as
  /// "refresh, don't retry", not a generic failure.
  Future<OfferPatch> respondOffer(String id, String response) async {
    final result = await apiClient.post('/interviews/$id/respond-offer', {'response': response}) as Map<String, dynamic>;
    return OfferPatch(id: result['id'] as String, candidateResponse: result['candidateResponse'] as String);
  }
}
