import 'dart:io' show Platform;

/// Whether the app may mention a paid plan ("MyAmbii Premium", "free plan",
/// "Premium removes…", locked previews).
///
/// iOS: never. App Store guidelines 3.1.1 / 3.1.3 — the app must not point
/// to, preview or describe a paid upgrade it doesn't sell through In-App
/// Purchase, and it doesn't (Apple asked about exactly these mentions in the
/// 1.1.0 review). Android keeps the informational mentions: no links to
/// checkout anywhere, which is what Google Play's billing policy requires.
///
/// Every Premium/plan mention in the app goes through this one getter, so
/// the day iOS gets In-App Purchase this is the only switch to flip.
bool get mentionPaidPlans => debugMentionPaidPlansOverride ?? !Platform.isIOS;

/// Tests only: force either platform's behaviour. Reset to null in tearDown.
bool? debugMentionPaidPlansOverride;
