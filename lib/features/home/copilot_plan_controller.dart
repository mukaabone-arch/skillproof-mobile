import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/copilot_plan.dart';

final copilotRepositoryProvider = Provider<CopilotRepository>((ref) {
  return CopilotRepository(apiClient: ref.read(apiClientProvider));
});

class CopilotRepository {
  CopilotRepository({required this.apiClient});

  final ApiClient apiClient;

  /// No `?tz=`: Dart has no IANA zone name without an extra package, and
  /// the server already defaults to Asia/Kolkata for interview times.
  /// Bounded: Home waits for this before showing the co-pilot card, so a
  /// slow plan must fall back to the on-device message rather than hold the
  /// skeleton (a TimeoutException lands in CopilotPlanUnavailable).
  Future<CopilotPlan> plan() async {
    final response =
        await apiClient.get('/copilot/plan').timeout(const Duration(seconds: 8)) as Map<String, dynamic>;
    return CopilotPlan.fromJson(response);
  }
}

sealed class CopilotPlanState {
  const CopilotPlanState();
}

class CopilotPlanLoading extends CopilotPlanState {
  const CopilotPlanLoading();
}

class CopilotPlanLoaded extends CopilotPlanState {
  const CopilotPlanLoaded(this.plan);

  final CopilotPlan plan;
}

/// The plan couldn't be fetched (older API, network blip). Deliberately not
/// an error the candidate sees: HeroSection falls back to the on-device
/// buildCopilotMessage, exactly like the website does.
class CopilotPlanUnavailable extends CopilotPlanState {
  const CopilotPlanUnavailable(this.reason);

  final String reason;
}

final copilotPlanControllerProvider =
    StateNotifierProvider.autoDispose<CopilotPlanController, CopilotPlanState>((ref) {
  return CopilotPlanController(ref.read(copilotRepositoryProvider))..load();
});

class CopilotPlanController extends StateNotifier<CopilotPlanState> {
  CopilotPlanController(this._repository) : super(const CopilotPlanLoading());

  final CopilotRepository _repository;

  Future<void> load() async {
    // Keep showing the previous plan while refreshing (pull-to-refresh, app
    // resume) instead of flashing the loading skeleton.
    if (state is! CopilotPlanLoaded) state = const CopilotPlanLoading();
    try {
      final plan = await _repository.plan();
      if (mounted) state = CopilotPlanLoaded(plan);
    } catch (e) {
      if (mounted) state = CopilotPlanUnavailable(e.toString());
    }
  }
}
