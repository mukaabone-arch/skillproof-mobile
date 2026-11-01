import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../models/staffing.dart';
import 'staffing_repository.dart';

/// The candidate's staffing opt-in + availability. AsyncValue rather than a
/// hand-written sealed state: loading / loaded / error is all this needs.
final staffingAvailabilityProvider =
    StateNotifierProvider.autoDispose<StaffingAvailabilityController, AsyncValue<StaffingAvailability>>((ref) {
  return StaffingAvailabilityController(ref.read(staffingRepositoryProvider))..load();
});

class StaffingAvailabilityController extends StateNotifier<AsyncValue<StaffingAvailability>> {
  StaffingAvailabilityController(this._repository) : super(const AsyncLoading());

  final StaffingRepository _repository;

  Future<void> load() async {
    try {
      state = AsyncData(await _repository.availability());
    } catch (e, st) {
      // Keep showing the last good value on a failed refresh.
      if (state is! AsyncData) state = AsyncError(e, st);
    }
  }

  /// Returns an error message to show, or null on success.
  Future<String?> save(Map<String, dynamic> body) async {
    try {
      state = AsyncData(await _repository.updateAvailability(body));
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> confirm() async {
    try {
      state = AsyncData(await _repository.confirm());
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Availability requests from staffing companies (newest first).
final staffingRequestsProvider =
    StateNotifierProvider.autoDispose<StaffingRequestsController, AsyncValue<List<StaffingRequest>>>((ref) {
  return StaffingRequestsController(ref.read(staffingRepositoryProvider))..load();
});

class StaffingRequestsController extends StateNotifier<AsyncValue<List<StaffingRequest>>> {
  StaffingRequestsController(this._repository) : super(const AsyncLoading());

  final StaffingRepository _repository;

  Future<void> load() async {
    try {
      state = AsyncData(await _repository.requests());
    } catch (e, st) {
      if (state is! AsyncData) state = AsyncError(e, st);
    }
  }

  /// [response] is AVAILABLE, CONDITIONAL or NOT_NOW. Returns an error message, or null.
  Future<String?> respond(String id, String response, {String? message, bool block = false}) async {
    try {
      await _repository.respond(id, response, message: message, block: block);
      final current = state.valueOrNull ?? const <StaffingRequest>[];
      state = AsyncData([for (final r in current) r.id == id ? r.withStatus(response, message) : r]);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}

/// Staffing companies asking to put the candidate forward to a named client,
/// and where each approved submission stands.
final staffingSubmissionsProvider =
    StateNotifierProvider.autoDispose<StaffingSubmissionsController, AsyncValue<List<StaffingSubmission>>>((ref) {
  return StaffingSubmissionsController(ref.read(staffingRepositoryProvider))..load();
});

class StaffingSubmissionsController extends StateNotifier<AsyncValue<List<StaffingSubmission>>> {
  StaffingSubmissionsController(this._repository) : super(const AsyncLoading());

  final StaffingRepository _repository;

  Future<void> load() async {
    try {
      state = AsyncData(await _repository.submissions());
    } catch (e, st) {
      if (state is! AsyncData) state = AsyncError(e, st);
    }
  }

  /// Returns an error message to show, or null. Reloads afterwards — the
  /// server decides the resulting status (an approval can be refused if
  /// another company already represents the candidate to that client).
  Future<String?> decide(String id, {required bool approve}) => _act(() => _repository.decideSubmission(id, approve: approve));

  Future<String?> withdraw(String id) => _act(() => _repository.withdrawSubmission(id));

  Future<String?> _act(Future<void> Function() call) async {
    try {
      await call();
      await load();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
