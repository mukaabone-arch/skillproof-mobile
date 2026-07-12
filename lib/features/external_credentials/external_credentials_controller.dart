import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'external_credentials_repository.dart';
import 'external_credentials_state.dart';

final externalCredentialsControllerProvider =
    StateNotifierProvider.autoDispose<ExternalCredentialsController, ExternalCredentialsState>((ref) {
  return ExternalCredentialsController(ref.read(externalCredentialsRepositoryProvider))..load();
});

class ExternalCredentialsController extends StateNotifier<ExternalCredentialsState> {
  ExternalCredentialsController(this._repository) : super(const ExternalCredentialsLoading());

  final ExternalCredentialsRepository _repository;

  Future<void> load() async {
    state = const ExternalCredentialsLoading();
    try {
      final credentials = await _repository.list();
      state = ExternalCredentialsLoaded(credentials: credentials);
    } catch (e) {
      state = ExternalCredentialsError(_messageOf(e));
    }
  }

  /// Returns true on success so the caller (the add form) knows to clear
  /// its input — mirrors ProfileController.save's return-bool contract.
  Future<bool> add(String credentialUrl) async {
    final current = state;
    if (current is! ExternalCredentialsLoaded) return false;
    state = current.copyWith(adding: true, clearError: true);
    try {
      final created = await _repository.add(credentialUrl);
      state = current.copyWith(
        credentials: [created, ...current.credentials],
        adding: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = current.copyWith(adding: false, error: _messageOf(e));
      return false;
    }
  }

  Future<void> remove(String id) async {
    final current = state;
    if (current is! ExternalCredentialsLoaded) return;
    state = current.copyWith(deletingId: id, clearError: true);
    try {
      await _repository.remove(id);
      final current2 = state as ExternalCredentialsLoaded;
      state = current2.copyWith(
        credentials: current2.credentials.where((c) => c.id != id).toList(),
        clearDeletingId: true,
      );
    } catch (e) {
      final current2 = state as ExternalCredentialsLoaded;
      state = current2.copyWith(clearDeletingId: true, error: _messageOf(e));
    }
  }

  String _messageOf(Object e) => e is ApiException ? e.message : e.toString();
}
