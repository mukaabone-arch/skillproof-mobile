/// Google Sign-In client IDs — never hardcoded, same --dart-define pattern
/// as [ApiConfig]. Two are needed because their roles are different:
///
///  - [androidClientId]: the "Android" OAuth client registered in Google
///    Cloud Console, keyed to this app's package name
///    (com.flairfuture.skillproof) and its signing SHA-1 certificate
///    fingerprint. This is what lets the native sign-in sheet run at all
///    on this platform — Android resolves it itself via Play Services, so
///    it isn't actually passed to the plugin on this platform, but it
///    still has to exist and be correctly registered or sign-in fails
///    with a DEVELOPER_ERROR (ApiException: 10).
///  - [serverClientId]: the *web* OAuth client ID — the same one
///    apps/api's GOOGLE_CLIENT_ID/GOOGLE_CLIENT_SECRET already use (see
///    docs/oauth-setup.md). Passing this to GoogleSignIn's
///    `serverClientId` is what makes Google return a server auth code
///    redeemable by that web client's secret, which is what lets our API
///    — not this app — complete the code-for-token exchange.
class GoogleAuthConfig {
  GoogleAuthConfig._();

  /// flutter run --dart-define=GOOGLE_ANDROID_CLIENT_ID=xxxxx.apps.googleusercontent.com
  static const String androidClientId = String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID');

  /// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com
  /// Must be the exact same client ID as apps/api's GOOGLE_CLIENT_ID.
  static const String serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
}
