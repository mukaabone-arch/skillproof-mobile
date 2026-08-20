/// GitHub Sign-In config — same --dart-define pattern as [GoogleAuthConfig],
/// never hardcoded. Only the client ID lives here: the client secret stays
/// server-side only (apps/api's GITHUB_CLIENT_SECRET, see the API repo's own
/// docs/oauth-setup.md) and must never appear in this app or this repo.
///
/// Unlike Google, there's no separate Android/server client ID split — this
/// app talks to GitHub's OAuth endpoints directly over a browser redirect
/// (see AuthRepository.signInWithGithub), not through a platform-native SDK,
/// so a single GitHub OAuth App's client ID covers every platform.
class GithubAuthConfig {
  GithubAuthConfig._();

  /// flutter run --dart-define=GITHUB_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx
  /// Must be the same client ID as apps/api's GITHUB_CLIENT_ID.
  static const String clientId = String.fromEnvironment('GITHUB_CLIENT_ID');

  /// Registered in the GitHub OAuth App's "Authorization callback URL" and
  /// in this app's platform config (AndroidManifest.xml's CallbackActivity
  /// intent-filter, Info.plist's CFBundleURLSchemes) — a custom scheme, not
  /// this app's actual bundle id/applicationId (com.flairfuture.myambii);
  /// URL schemes used for OAuth redirects don't have to match either.
  static const String redirectUri = 'com.myambii://oauth/github';

  /// Bare scheme passed to FlutterWebAuth2.authenticate's callbackUrlScheme
  /// — the plugin matches on scheme alone, host/path in [redirectUri] are
  /// only meaningful to GitHub's own redirect_uri exact-match check.
  static const String callbackUrlScheme = 'com.myambii';

  /// read:user user:email — the API needs user:email specifically to read
  /// GET /user/emails for a verified primary email (read:user alone never
  /// exposes it; see apps/api's GithubOAuthProvider).
  static const String scope = 'read:user user:email';
}
