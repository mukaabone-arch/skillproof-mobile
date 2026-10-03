import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../config/github_auth_config.dart';
import '../../config/google_auth_config.dart';
import '../../core/api_client.dart';
import '../../core/pkce.dart';
import '../../core/token_storage.dart';
import '../../models/user.dart';

/// Thrown when the candidate dismisses the native Google account chooser.
/// Distinct from a real failure so callers can treat it silently instead
/// of surfacing an error banner for an ordinary "changed my mind" tap.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// GitHub counterpart to [GoogleSignInCancelled] — thrown when the user
/// dismisses the browser tab/ASWebAuthenticationSession before completing
/// sign-in, or declines on GitHub's own consent screen. Same contract:
/// callers treat this silently rather than showing an error banner.
class GithubSignInCancelled implements Exception {
  const GithubSignInCancelled();
}

/// Result of [AuthRepository.verifyLinkEmailOtp] — a bare [MyambiiUser]
/// isn't enough once the API can respond with `switchedAccount: true` (the
/// 2026-09-30 duplicate-account fix): the candidate who just typed an OTP
/// may have been signed into a DIFFERENT, pre-existing account rather than
/// having the email attached to the one they started with. [switchedAccount]
/// is what VerifyScreen uses to decide whether to show a "we found your
/// existing account" notice before the app moves on; [message] is only ever
/// present alongside a switch, and only when there's something the app
/// couldn't otherwise tell the candidate — e.g. which phone number survived.
class LinkEmailResult {
  const LinkEmailResult({required this.user, required this.switchedAccount, this.message});

  final MyambiiUser user;
  final bool switchedAccount;
  final String? message;
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

  Future<MyambiiUser> verifyOtp({
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

    try {
      return MyambiiUser.fromJson(response['user'] as Map<String, dynamic>);
    } catch (_) {
      // Tokens are already saved above, so the handshake itself genuinely
      // succeeded — a malformed embedded user object shouldn't be reported
      // as a failed sign-in (AuthController would otherwise set
      // AuthUnauthenticated and rethrow despite a valid session now sitting
      // in storage). Recover the user the same way session restoration does.
      return fetchMe();
    }
  }

  /// Candidate email sign-in. Deliberately the candidate endpoints, not
  /// /auth/employer/otp/* — those reject a candidate's email outright.
  /// Response shape matches verifyOtp, so the token/user handling below is
  /// the same.
  Future<void> requestCandidateEmailOtp(String email) async {
    await apiClient.post('/auth/email/otp/request', {'email': email});
  }

  Future<MyambiiUser> verifyCandidateEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await apiClient.post('/auth/email/otp/verify', {
      'email': email,
      'otp': otp,
    }) as Map<String, dynamic>;

    await tokenStorage.saveTokens(
      accessToken: response['accessToken'] as String,
      refreshToken: response['refreshToken'] as String,
    );

    try {
      return MyambiiUser.fromJson(response['user'] as Map<String, dynamic>);
    } catch (_) {
      // Same reasoning as verifyOtp above: tokens are already saved, so a
      // malformed embedded user object is not a failed sign-in.
      return fetchMe();
    }
  }

  /// Native Google sign-in → server auth code → POST /auth/google, which
  /// does the actual code-for-token exchange server-side using the web
  /// client's secret (apps/api's GoogleOAuthProvider) and returns the same
  /// { accessToken, refreshToken, user } shape as phone OTP verify — so
  /// everything past this method is identical to the OTP path.
  Future<MyambiiUser> signInWithGoogle() async {
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

    final Map<String, dynamic> response;
    try {
      response = await apiClient.post('/auth/google', {
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
    } catch (e) {
      rethrow;
    }

    await tokenStorage.saveTokens(
      accessToken: response['accessToken'] as String,
      refreshToken: response['refreshToken'] as String,
    );

    try {
      return MyambiiUser.fromJson(response['user'] as Map<String, dynamic>);
    } catch (_) {
      // Same reasoning as verifyOtp above: the code-for-token exchange
      // already succeeded and tokens are saved, so a malformed embedded
      // user object shouldn't discard a valid session.
      return fetchMe();
    }
  }

  /// Browser-based GitHub OAuth (PKCE) → POST /auth/github, same server-
  /// side exchange contract as [signInWithGoogle] (apps/api's
  /// GithubOAuthProvider completes the code-for-token exchange with the
  /// client secret, which never leaves the API). Unlike Google, GitHub has
  /// no platform-native SDK this app can use, so this drives the OAuth
  /// redirect manually: flutter_web_auth_2 opens the system browser
  /// (ASWebAuthenticationSession on iOS, Chrome Auth Tab on Android) at
  /// GitHub's authorize URL and resolves once GitHub redirects back to
  /// [GithubAuthConfig.redirectUri].
  ///
  /// PKCE (RFC 7636, S256) is mandatory here, unlike the optional
  /// `codeVerifier` on the Google path above: this is a manual
  /// authorization-code flow a public client (this app, no client secret)
  /// drives over a system browser — exactly PKCE's threat model (some other
  /// app on the device intercepting the redirect and racing to redeem the
  /// code first). `state` is a separate, non-PKCE CSRF check — it proves
  /// the redirect this call received actually answers the authorize request
  /// *this call* sent, not a stale or forged one.
  Future<MyambiiUser> signInWithGithub() async {
    final verifier = Pkce.generateVerifier();
    final challenge = Pkce.challengeFor(verifier);
    final state = Pkce.generateState();

    final authorizeUri = Uri.https('github.com', '/login/oauth/authorize', {
      'client_id': GithubAuthConfig.clientId,
      'redirect_uri': GithubAuthConfig.redirectUri,
      'scope': GithubAuthConfig.scope,
      'state': state,
      'code_challenge': challenge,
      'code_challenge_method': 'S256',
    });

    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: authorizeUri.toString(),
        callbackUrlScheme: GithubAuthConfig.callbackUrlScheme,
      );
    } on PlatformException catch (e) {
      // Both platforms use this code for "user dismissed the browser
      // without completing sign-in" — verified directly against the
      // plugin's own source (AuthenticationManagementActivity.kt on
      // Android, FlutterWebAuth2Plugin.swift on iOS), not just its docs.
      if (e.code == 'CANCELED') {
        throw const GithubSignInCancelled();
      }
      rethrow;
    }

    final callback = Uri.parse(result);

    // GitHub redirects with `error` (not a thrown exception) when the user
    // declines on its own consent screen — the same "changed my mind"
    // outcome as dismissing the browser tab, so it gets the same
    // cancellation treatment rather than an error banner.
    if (callback.queryParameters['error'] != null) {
      throw const GithubSignInCancelled();
    }

    final returnedState = callback.queryParameters['state'];
    if (returnedState == null || returnedState != state) {
      throw Exception('GitHub sign-in could not be verified. Please try again.');
    }

    final code = callback.queryParameters['code'];
    if (code == null) {
      throw Exception('GitHub did not return an authorization code.');
    }

    final response = await apiClient.post('/auth/github', {
      'code': code,
      'redirectUri': GithubAuthConfig.redirectUri,
      'codeVerifier': verifier,
    }) as Map<String, dynamic>;

    await tokenStorage.saveTokens(
      accessToken: response['accessToken'] as String,
      refreshToken: response['refreshToken'] as String,
    );

    try {
      return MyambiiUser.fromJson(response['user'] as Map<String, dynamic>);
    } catch (_) {
      // Same reasoning as signInWithGoogle/verifyOtp above: the exchange
      // already succeeded and tokens are saved, so a malformed embedded
      // user object shouldn't discard a valid session.
      return fetchMe();
    }
  }

  Future<MyambiiUser> fetchMe() async {
    final response = await apiClient.get('/users/me') as Map<String, dynamic>;
    return MyambiiUser.fromJson(response);
  }

  /// Mints a short-lived, single-use code the web app can redeem for a
  /// session — see core/web_handoff.dart's openWebAuthenticated, which is
  /// what this backs. The JWT itself never leaves this call: only the
  /// exchange code does, in the URL the caller hands to the browser.
  Future<String> createWebSessionCode() async {
    final response = await apiClient.post('/auth/web-session') as Map<String, dynamic>;
    return response['code'] as String;
  }

  /// The four /auth/link/* calls below back VerifyScreen. All four (plus
  /// fetchMe and logout above) are exempt from CandidateVerificationGuard
  /// server-side — AuthController is @SkipVerificationGate() class-wide,
  /// UsersController.me method-wide — so they work for an unverified
  /// candidate; this is deliberately the one screen in the app that isn't
  /// blocked by the gate it exists to satisfy.
  Future<void> requestLinkPhoneOtp(String phone) async {
    await apiClient.post('/auth/link/phone/request', {'phone': phone});
  }

  Future<MyambiiUser> verifyLinkPhoneOtp({
    required String phone,
    required String otp,
  }) async {
    await apiClient.post('/auth/link/phone/verify', {'phone': phone, 'otp': otp});
    // The link/verify response is a bare ack, not a full user — see
    // AuthController.verifyLinkPhoneOtp's own return contract — so refetch
    // rather than try to construct MyambiiUser from it.
    return fetchMe();
  }

  Future<void> requestLinkEmailOtp(String email) async {
    await apiClient.post('/auth/link/email/request', {'email': email});
  }

  /// 2026-09-30 duplicate-account fix: this OTP verify can resolve onto a
  /// DIFFERENT, pre-existing account than the one this call started on —
  /// see AuthController.verifyLinkEmailOtp's own doc comment on how the
  /// response's `switchedAccount: true` is threaded up to VerifyScreen.
  /// When it's true, the tokens this request itself was authenticated with
  /// belong to an account the server just deleted — they're swapped for
  /// the new pair the server minted for the real account BEFORE fetchMe()
  /// runs, or that call (and every one after it) 401s against a user that
  /// no longer exists.
  Future<LinkEmailResult> verifyLinkEmailOtp({
    required String email,
    required String otp,
  }) async {
    final response = await apiClient.post('/auth/link/email/verify', {'email': email, 'otp': otp}) as Map<String, dynamic>;

    final switchedAccount = response['switchedAccount'] == true;
    if (switchedAccount) {
      await tokenStorage.saveTokens(
        accessToken: response['accessToken'] as String,
        refreshToken: response['refreshToken'] as String,
      );
    }

    final user = await fetchMe();
    return LinkEmailResult(user: user, switchedAccount: switchedAccount, message: response['message'] as String?);
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
