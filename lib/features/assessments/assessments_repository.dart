import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/assessment_catalog_entry.dart';

final assessmentsRepositoryProvider = Provider<AssessmentsRepository>((ref) {
  return AssessmentsRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to GET /assessments/catalog/summary — the mobile-simplified
/// projection of the candidate assessment catalog (one card per
/// not-yet-fully-earned skill). See AssessmentsService.getCandidateSummary
/// on the API side for how each entry is derived.
class AssessmentsRepository {
  AssessmentsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<AssessmentCatalogEntry>> catalogSummary() async {
    final response = await apiClient.get('/assessments/catalog/summary') as Map<String, dynamic>;
    final skills = (response['skills'] as List<dynamic>?) ?? const [];
    return skills
        .cast<Map<String, dynamic>>()
        .map(AssessmentCatalogEntry.fromJson)
        .toList();
  }
}
