import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/providers.dart';
import 'devices_repository.dart';
import 'push_messaging.dart';
import 'push_service.dart';

final pushMessagingProvider = Provider<PushMessaging>(
  (ref) => firebaseReady ? FirebasePushMessaging() : const NoopPushMessaging(),
);

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(
    messaging: ref.read(pushMessagingProvider),
    devices: DevicesRepository(ref.read(apiClientProvider)),
    platform: Platform.isIOS ? 'ios' : 'android',
    appVersion: () async {
      try {
        final info = await PackageInfo.fromPlatform();
        return '${info.version}+${info.buildNumber}';
      } catch (_) {
        return null;
      }
    },
  );
});

/// A tapped notification's route waiting for the signed-in shell — the
/// terminated case: the tap launches the app, which is still restoring the
/// session when the message is read. Applied by PushCoordinator once
/// RootScreen is showing.
final pendingPushRouteProvider = StateProvider<String?>((ref) => null);
