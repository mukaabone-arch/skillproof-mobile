import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

/// Runs in its own isolate when a message arrives with the app in the
/// background or terminated. Notification messages are displayed by the OS
/// without any work here; this only has to exist (and initialise Firebase)
/// for data messages. Must stay top-level and annotated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // No options: reads android/app/google-services.json and
  // ios/Runner/GoogleService-Info.plist. If either is missing (a fresh
  // clone — both are gitignored), the app still runs with push off
  // (see push_messaging.dart's firebaseReady / NoopPushMessaging).
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    // ignore: avoid_print
    print('PUSH_INIT_FAILED: $e');
  }
  runApp(const ProviderScope(child: MyambiiApp()));
}
