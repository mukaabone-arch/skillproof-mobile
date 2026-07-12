import 'package:google_sign_in/google_sign_in.dart';

import '../../config/google_auth_config.dart';
import '../../core/api_client.dart';
import '../../core/token_storage.dart';
import '../../models/user.dart';

/// Thrown when the candidate dismisses the native Google account chooser.
/// Distinct from a real failure so callers can treat it silently instead
/// of surfacing an error banner for an ordinary "changed my mind" tap.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// Talks to the /auth and /users/me endpoints. Field names below must
/// match the API's DTOs exactly — a global ValidationPipe with
/// forbidNonWhitelisted rejects any request body with extra fields.
class AuthRepository {
  AuthRepository({required this.apiClient, required this.tokenStorage})
      : _googleSignIn = GoogleSignIn(
          scopes: const ['openid', 'email', 'profile'],
          clientId: GoogleAuthConfig.androidClientId.isEmpty ? null : GoogleAuthConfig.androidClientId,
          serverClientId: GoogleAuthConfig.serverClientId.isEmpty ? null : GoogleAuthConfig.serverClientId,
        );

  final ApiClient apiClient;
  final TokenStorage tokenStorage;
  final GoogleSignIn _googleSignIn;

  Future<void> requestOtp(String phone) async {
    await apiClient.post('/auth/otp/request', {'phone': phone});
  }

  Future<SkillProofUser> verifyOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await apiClient.post('/auth/otp/verify', {
      'phone': phone,
      'otp': otp,
    }) as Map<String, dynamic>;

    await tokenStorage.saveTokens(
      accessToken: response['accessToken'] as String,
      refreshToken: response['refreshToken'] as String,
    );

    return SkillProofUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  /// Native Google sign-in → server auth code → POST /auth/google, which
  /// does the actual code-for-token exchange server-side using the web
  /// client's secret (apps/api's GoogleOAuthProvider) and returns the same
  /// { accessToken, refreshToken, user } shape as phone OTP verify — so
  /// everything past this method is identical to the OTP path.
  Future<SkillProofUser> signInWithGoogle() async {
    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      // Native chooser was dismissed — GoogleSignIn.signIn() resolves to
      // null for this (not a thrown exception), so this is the one place
      // that translates it into one.
      throw const GoogleSignInCancelled();
    }

    final serverAuthCode = account.serverAuthCode;
    if (serverAuthCode == null) {
      throw Exception(
        'Google did not return a server auth code — check that '
        'GOOGLE_SERVER_CLIENT_ID is configured correctly.',
      );
    }

    final response = await apiClient.post('/auth/google', {
      'code': serverAuthCode,
      // Empty on purpose, not omitted: a server auth code obtained via the
      // native SDK (through serverClientId) was never tied to a browser
      // redirect, and Google's documented pattern for this exact "mobile
      // app requests a code for a server client" flow is to exchange it
      // with an empty redirect_uri — see
      // https://developers.google.com/identity/sign-in/android/offline-access.
      // codeVerifier is omitted entirely: this is Google Play Services'
      // own secure channel, not a manual PKCE flow, so there's no
      // verifier to send (the API's OAuthCodeDto already treats it as
      // optional for exactly this reason).
      'redirectUri': '',
    }) as Map<String, dynamic>;

    await tokenStorage.saveTokens(
      accessToken: response['accessToken'] as String,
      refreshToken: response['refreshToken'] as String,
    );

    return SkillProofUser.fromJson(response['user'] as Map<String, dynamic>);
  }

  Future<SkillProofUser> fetchMe() async {
    final response = await apiClient.get('/users/me') as Map<String, dynamic>;
    return SkillProofUser.fromJson(response);
  }

  Future<void> logout() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken != null) {
      try {
        await apiClient.post('/auth/logout', {'refreshToken': refreshToken});
      } catch (_) {
        // Best-effort server-side revoke; the local session is cleared
        // regardless of whether this call succeeds.
      }
    }
    // Best-effort: signOut() clears the cached native Google session so a
    // later "Sign in with Google" shows the account chooser again instead
    // of silently re-authenticating the same account. Never block logout
    // on this — a Play Services hiccup here shouldn't prevent the local
    // session from clearing.
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await tokenStorage.clear();
  }

  Future<bool> hasStoredSession() async {
    return (await tokenStorage.readAccessToken()) != null;
  }
}
