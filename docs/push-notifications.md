# Push notifications

Phase 1 (this release, 1.1.0+11): the app registers its FCM token with the
API and handles taps; the API stores tokens and **sends nothing**. Phase 2 is
API-only (the sender) and ships once tokens have accumulated.

## One-time setup (per Firebase project)

1. Firebase console → create project **MyAmbii** (Analytics off is fine).
2. Add an **Android app**: package `com.flairfuture.myambii`. Download
   `google-services.json` → `android/app/google-services.json` on the
   Windows build machine. Gitignored (public repo) — keep a copy in your
   password manager.
3. Add an **iOS app**: bundle id as in Xcode (Runner → General). Download
   `GoogleService-Info.plist` → `ios/Runner/GoogleService-Info.plist` on the
   Mac, and add it to the Runner target in Xcode (drag in, "Copy if needed",
   target Runner). Also gitignored.
4. Apple Developer → Keys: a key with **Apple Push Notifications service**
   enabled (a new key, or enable APNs on an existing one). Firebase → Project
   settings → Cloud Messaging → Apple app → upload the `.p8`, Key ID, Team ID.
5. Xcode → Runner → Signing & Capabilities → **+ Push Notifications** (the
   entitlement is already in Runner.entitlements; this registers it with the
   App ID). Background Modes → Remote notifications is already in Info.plist.

## Data payload contract (phase 2 sender)

`data.route` picks the tab a tap opens — `interviews`, `skills`, `jobs`,
`profile`, `home` (see lib/features/push/push_routes.dart); `data.id` is an
optional entity id. Visible text never names an employer, recruiter, client
or salary: it shows on lock screens.

## Where permission is asked

Never on first launch. Only when the value is obvious: after applying to a
job, and after saving "Open to recruiters" (checks expire in 48 hours). See
PushService.askAtMeaningfulMoment.
