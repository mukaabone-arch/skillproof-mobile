# OAuth setup (mobile)

This app's OAuth flows never hold a client secret — the code-for-token
exchange always happens server-side, in the `skillproof` (API) repo's
`apps/api/src/modules/auth/oauth`. This doc only covers what's specific to
*this* repo: client IDs (never secrets), platform redirect registration, and
which flow each provider uses. For `GITHUB_CLIENT_ID`/`GITHUB_CLIENT_SECRET`
and `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` env var setup, see the API
repo's own `docs/oauth-setup.md` — not duplicated here, so the two docs
can't drift apart on the one thing that actually matters for server config.

## Google — native SDK, no PKCE

`lib/config/google_auth_config.dart` + `AuthRepository.signInWithGoogle()`.
Uses the `google_sign_in` package's native Android/iOS SDK, which returns a
`serverAuthCode` through Google Play Services' own secure channel — not a
manual browser redirect, so there's no PKCE step on this app's side (the
API's `OAuthCodeDto.codeVerifier` is optional for exactly this reason; this
flow sends `redirectUri: ''`, Google's documented pattern for a mobile app
requesting a code for a *server* client).

```
flutter run --dart-define=GOOGLE_ANDROID_CLIENT_ID=xxxxx.apps.googleusercontent.com
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxxx.apps.googleusercontent.com
```

`GOOGLE_SERVER_CLIENT_ID` must be the same client ID as the API's
`GOOGLE_CLIENT_ID`.

## GitHub — browser redirect + PKCE (mandatory)

`lib/config/github_auth_config.dart` + `AuthRepository.signInWithGithub()`.
GitHub has no platform-native SDK this app can use, so this drives the OAuth
authorization-code flow manually via `flutter_web_auth_2` (opens
`ASWebAuthenticationSession` on iOS, a Chrome Auth Tab on Android, at
GitHub's own `/login/oauth/authorize` page) — a genuinely public client
flying a code through a system browser, which is exactly PKCE's threat
model. **PKCE (S256) is mandatory here, not optional** — confirmed against
GitHub's own current docs, not assumed: `code_challenge`/
`code_challenge_method` on the authorize request and `code_verifier` on the
token exchange are real, currently-documented, "strongly recommended"
parameters on GitHub's OAuth Apps. (If you're reading this from the API
repo's older oauth-setup.md note claiming GitHub OAuth Apps don't support
PKCE — that note is stale; GitHub added support for it at some point after
that was written. This repo's implementation uses it fully.)

```
flutter run --dart-define=GITHUB_CLIENT_ID=xxxxxxxxxxxxxxxxxxxx
```

Must be the same client ID as the API's `GITHUB_CLIENT_ID`. There's no
separate Android/server client ID split the way Google has — one GitHub
OAuth App's client ID covers every platform, since this app talks to
GitHub's endpoints directly rather than through a per-platform native SDK.

### GitHub OAuth App console

In the same GitHub OAuth App the API repo's docs walk through creating
(Settings → Developer settings → OAuth Apps):

1. Add an additional **Authorization callback URL**: `com.myambii://oauth/github`
   (alongside the web app's `http(s)://.../auth/github/callback` — a GitHub
   OAuth App accepts multiple callback URLs on the same client ID/secret).
2. Scopes: `read:user user:email` — same as the web app's requirement.
   `read:user` alone never exposes a verified email; the API's
   `GithubOAuthProvider` needs `GET /user/emails` for that, which needs
   `user:email`.

`com.myambii` is a custom URL scheme, not this app's actual bundle
id/`applicationId` (`com.flairfuture.myambii`) — a redirect scheme
registered for OAuth doesn't have to match either. It's wired into:

- **Android** (`android/app/src/main/AndroidManifest.xml`): a
  `com.linusu.flutter_web_auth_2.CallbackActivity` entry with an
  intent-filter on `android:scheme="com.myambii"` — this exact activity
  class is `flutter_web_auth_2`'s own redirect-capture activity, not
  something this app defines; adding an intent-filter to `MainActivity`
  instead does not work with this plugin.
- **iOS** (`ios/Runner/Info.plist`): a `CFBundleURLTypes` entry with
  `CFBundleURLSchemes: ["com.myambii"]`. No Associated Domains/Universal
  Links setup needed — that's only required for an `https` callback scheme
  (Universal Links), not a plain custom scheme like this one.

### Cancellation

`GithubSignInCancelled` (in `auth_repository.dart`, mirroring
`GoogleSignInCancelled`) covers two distinct ways a sign-in attempt ends
without completing, both treated identically (no error banner):

- The user dismisses the browser tab/`ASWebAuthenticationSession` before
  finishing — `flutter_web_auth_2` surfaces this as a `PlatformException`
  with `code: 'CANCELED'` on both platforms (verified directly against the
  plugin's Android/iOS source, not just its README).
- The user declines on GitHub's own consent screen — GitHub redirects back
  with an `error` query parameter rather than throwing; there's no
  exception to catch, so this is checked explicitly against the parsed
  callback URL.
