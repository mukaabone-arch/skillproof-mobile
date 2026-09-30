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

  /// Same shared AuthState/RootScreen routing as [signInWithGoogle] — a
  /// successful sign-in flips state to [AuthAuthenticated] regardless of
  /// which provider it came from.
  Future<void> signInWithGithub() async {
    state = const AuthLoading();
    try {
      final user = await _repository.signInWithGithub();
      state = AuthAuthenticated(user);
    } on GithubSignInCancelled {
      // Same as GoogleSignInCancelled above — an ordinary cancel, not an
      // error, so no message for the login screen to show.
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthUnauthenticated(error: e.toString());
      rethrow;
    }
  }

  /// The four methods below back VerifyScreen — see AuthRepository's own
  /// doc comment on why they work even while [state] is an unverified
  /// AuthAuthenticated. Deliberately don't route through AuthLoading like
  /// verifyOtp/signInWithGoogle do: VerifyScreen manages its own per-field
  /// busy/error state (mirroring LoginScreen's OTP flow), and flipping the
  /// whole app to AuthLoading mid-link would tear down the screen the user
  /// is actively typing into.
  Future<void> requestLinkPhoneOtp(String phone) => _repository.requestLinkPhoneOtp(phone);

  Future<void> verifyLinkPhoneOtp({required String phone, required String otp}) async {
    final user = await _repository.verifyLinkPhoneOtp(phone: phone, otp: otp);
    state = AuthAuthenticated(user);
  }

  Future<void> requestLinkEmailOtp(String email) => _repository.requestLinkEmailOtp(email);

  /// Unlike every other verifyLink*/verifyChange* method here, this does
  /// NOT flip [state] itself. When the result is a duplicate-account
  /// switch, VerifyScreen (its own call site) has to show a blocking
  /// "we found your existing account" notice and let the candidate
  /// acknowledge it BEFORE [state] flips to the (now fully verified)
  /// account — flipping first would swap VerifyScreen out from under that
  /// notice before it ever had a chance to show, since satisfying both
  /// link requirements at once is exactly what a switch does. Call
  /// [applyLinkEmailResult] once that's done — or immediately, for the
  /// ordinary non-switch case, where there's nothing to show first.
  Future<LinkEmailResult> verifyLinkEmailOtp({required String email, required String otp}) {
    return _repository.verifyLinkEmailOtp(email: email, otp: otp);
  }

  /// See [verifyLinkEmailOtp]'s own doc comment on why this is separate.
  void applyLinkEmailResult(LinkEmailResult result) {
    state = AuthAuthenticated(result.user);
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
