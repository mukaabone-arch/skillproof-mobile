import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/application.dart';
import '../../models/job.dart';
import '../../models/matched_job.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepository(apiClient: ref.read(apiClientProvider));
});

/// Total count alongside the page of jobs, so the Browse tab can show
/// "N jobs found" without a second round trip.
class JobsPage {
  JobsPage({required this.total, required this.jobs});

  final int total;
  final List<Job> jobs;
}

/// Talks to the candidate-facing job endpoints: browse/search LIVE jobs,
/// the personalized match ranking, job detail, applying, and the
/// candidate's own application history. Field names below must match the
/// API's response shape exactly, same constraint as AuthRepository.
class JobsRepository {
  JobsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<JobsPage> browse({
    String? skillId,
    String? location,
    bool? remote,
    int limit = 20,
    int offset = 0,
  }) async {
    final query = <String, String>{
      if (skillId != null && skillId.isNotEmpty) 'skillId': skillId,
      if (location != null && location.isNotEmpty) 'location': location,
      if (remote != null) 'remote': remote.toString(),
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    final path = Uri(path: '/jobs/browse', queryParameters: query).toString();
    final response = await apiClient.get(path) as Map<String, dynamic>;
    return JobsPage(
      total: response['total'] as int,
      jobs: (response['jobs'] as List<dynamic>)
          .map((j) => Job.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<Job> browseOne(String id) async {
    final response = await apiClient.get('/jobs/browse/$id') as Map<String, dynamic>;
    return Job.fromJson(response);
  }

  /// Empty when the candidate has no verified skill claim yet — scoring
  /// against zero verified skills would rank every job 0, so the API
  /// short-circuits to `{ jobs: [] }` rather than returning a wall of
  /// zeroes. Callers should treat an empty list as "no verified skills yet",
  /// not "no jobs available".
  Future<List<MatchedJob>> matched() async {
    final response = await apiClient.get('/jobs/matched') as Map<String, dynamic>;
    return (response['jobs'] as List<dynamic>)
        .map((j) => MatchedJob.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// On failure the API returns 400 with a machine-readable `code`
  /// (PROFILE_INCOMPLETE / BADGE_REQUIRED) inside [ApiException.body] —
  /// callers should branch on that instead of showing the raw message.
  Future<void> apply(String jobId) => apiClient.post('/jobs/$jobId/apply');

  Future<List<Application>> myApplications() async {
    final response = await apiClient.get('/applications/me') as List<dynamic>;
    return response.map((a) => Application.fromJson(a as Map<String, dynamic>)).toList();
  }
}
