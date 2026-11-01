import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/staffing.dart';

final staffingRepositoryProvider = Provider<StaffingRepository>((ref) {
  return StaffingRepository(apiClient: ref.read(apiClientProvider));
});

/// GET/PATCH /staffing/me/* — see the API's StaffingCandidateController.
class StaffingRepository {
  StaffingRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<StaffingAvailability> availability() async =>
      StaffingAvailability.fromJson(await apiClient.get('/staffing/me/availability') as Map<String, dynamic>);

  /// PATCH (the API also accepts PUT) — ApiClient has no put().
  Future<StaffingAvailability> updateAvailability(Map<String, dynamic> body) async =>
      StaffingAvailability.fromJson(await apiClient.patch('/staffing/me/availability', body) as Map<String, dynamic>);

  Future<StaffingAvailability> confirm() async =>
      StaffingAvailability.fromJson(await apiClient.post('/staffing/me/availability/confirm') as Map<String, dynamic>);

  Future<List<StaffingRequest>> requests() async {
    final list = await apiClient.get('/staffing/me/requests') as List<dynamic>;
    return list.map((r) => StaffingRequest.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> respond(String id, String response, {String? message, bool block = false}) async {
    await apiClient.post('/staffing/me/requests/$id/respond', {
      'response': response,
      if (message != null && message.trim().isNotEmpty) 'message': message.trim(),
      'block': block,
    });
  }

  // ---- Phase 2a: submissions ----

  Future<List<StaffingSubmission>> submissions() async {
    final list = await apiClient.get('/staffing/me/submissions') as List<dynamic>;
    return list.map((s) => StaffingSubmission.fromJson(s as Map<String, dynamic>)).toList();
  }

  Future<void> decideSubmission(String id, {required bool approve}) async {
    await apiClient.post('/staffing/me/submissions/$id/decide', {'approve': approve});
  }

  Future<void> withdrawSubmission(String id) async {
    await apiClient.post('/staffing/me/submissions/$id/withdraw');
  }
}
