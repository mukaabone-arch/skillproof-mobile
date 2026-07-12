import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    apiClient: ref.read(apiClientProvider),
    tokenStorage: ref.read(tokenStorageProvider),
  );
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final controller = AuthController(ref.read(authRepositoryProvider));
  ref.read(apiClientProvider).onSessionExpired = controller.handleSessionExpired;
  return controller;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository) : super(const AuthInitial()) {
    _restoreSession();
  }

  final AuthRepository _repository;

  Future<void> _restoreSession() async {
    if (!await _repository.hasStoredSession()) {
      state = const AuthUnauthenticated();
      return;
    }
    state = const AuthLoading();
    try {
      final user = await _repository.fetchMe();
      state = AuthAuthenticated(user);
    } catch (_) {
      state = const AuthUnauthenticated();
    }
  }

  Future<void> requestOtp(String phone) => _repository.requestOtp(phone);

  Future<void> verifyOtp({required String phone, required String otp}) async {
    state = const AuthLoading();
    try {
      final user = await _repository.verifyOtp(phone: phone, otp: otp);
      state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthUnauthenticated(error: e.toString());
      rethrow;
    }
  }

  /// Same shared AuthState/RootScreen routing as [verifyOtp] — a
  /// successful sign-in of either kind flips state to [AuthAuthenticated]
  /// and the rest of the app doesn't know or care which one happened.
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final user = await _repository.signInWithGoogle();
      state = AuthAuthenticated(user);
    } on GoogleSignInCancelled {
      // Not an error — back to how things were, no error message, so the
      // login screen doesn't show a banner for an ordinary cancel.
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthUnauthenticated(error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthUnauthenticated();
  }

  /// Invoked by [ApiClient] when a background token refresh is rejected
  /// by the server (expired/revoked refresh token).
  void handleSessionExpired() {
    state = const AuthUnauthenticated(
      error: 'Your session expired. Please sign in again.',
    );
  }
}
