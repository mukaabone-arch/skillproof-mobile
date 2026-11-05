import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// What the app needs from a push provider, behind an interface so
/// [PushService] can be unit-tested without Firebase (see
/// test/features/push/push_service_test.dart) and so the app still runs —
/// with push simply off — if Firebase failed to initialise.
abstract class PushMessaging {
  Future<String?> getToken();
  Stream<String> get onTokenRefresh;
  Future<void> deleteToken();

  Future<PushPermission> permission();
  Future<PushPermission> requestPermission();

  /// The notification that launched the app from terminated, if any.
  Future<PushOpened?> initialMessage();

  /// A notification tapped while the app was in the background.
  Stream<PushOpened> get onOpened;

  /// A notification that arrived while the app was in the foreground — the
  /// OS shows nothing then, so the app shows its own banner.
  Stream<PushOpened> get onForeground;
}

enum PushPermission { notDetermined, granted, denied }

/// The parts of a notification the app uses: the visible text (foreground
/// banner only) and the data payload, which carries where to go.
class PushOpened {
  const PushOpened({this.title, this.body, this.data = const {}});
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  /// Data payload contract shared with the API (phase 2): `route` names a
  /// destination, `id` an entity on it. See [tabForPushRoute].
  String? get route => data['route'] as String?;
  String? get id => data['id'] as String?;

  static PushOpened fromRemote(RemoteMessage m) =>
      PushOpened(title: m.notification?.title, body: m.notification?.body, data: m.data);
}

class FirebasePushMessaging implements PushMessaging {
  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  @override
  Future<String?> getToken() => _fm.getToken();

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Future<void> deleteToken() => _fm.deleteToken();

  static PushPermission _map(AuthorizationStatus s) => switch (s) {
        AuthorizationStatus.authorized || AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
        // denied, deniedPermanently (newer plugin versions) and anything added later.
        _ => PushPermission.denied,
      };

  @override
  Future<PushPermission> permission() async => _map((await _fm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushPermission> requestPermission() async => _map((await _fm.requestPermission()).authorizationStatus);

  @override
  Future<PushOpened?> initialMessage() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : PushOpened.fromRemote(m);
  }

  @override
  Stream<PushOpened> get onOpened => FirebaseMessaging.onMessageOpenedApp.map(PushOpened.fromRemote);

  @override
  Stream<PushOpened> get onForeground => FirebaseMessaging.onMessage.map(PushOpened.fromRemote);
}

/// Push off: Firebase didn't initialise (missing google-services.json /
/// GoogleService-Info.plist on a dev build) or we're under `flutter test`.
class NoopPushMessaging implements PushMessaging {
  const NoopPushMessaging();
  @override
  Future<String?> getToken() async => null;
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Future<void> deleteToken() async {}
  @override
  Future<PushPermission> permission() async => PushPermission.denied;
  @override
  Future<PushPermission> requestPermission() async => PushPermission.denied;
  @override
  Future<PushOpened?> initialMessage() async => null;
  @override
  Stream<PushOpened> get onOpened => const Stream.empty();
  @override
  Stream<PushOpened> get onForeground => const Stream.empty();
}

/// True once main() has initialised Firebase successfully.
bool get firebaseReady {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}
