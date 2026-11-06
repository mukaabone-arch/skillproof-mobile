import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/core/api_client.dart';
import 'package:myambii/features/push/devices_repository.dart';
import 'package:myambii/features/push/push_messaging.dart';
import 'package:myambii/features/push/push_routes.dart';
import 'package:myambii/features/push/push_service.dart';
import 'package:myambii/features/root/root_tab_provider.dart';

class _FakeMessaging implements PushMessaging {
  String? token = 'token-1';
  final refresh = StreamController<String>.broadcast();
  PushPermission perm = PushPermission.notDetermined;
  int permissionRequests = 0;
  int deletes = 0;

  @override
  Future<String?> getToken() async => token;
  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Future<void> deleteToken() async {
    deletes++;
    token = null;
  }

  @override
  Future<PushPermission> permission() async => perm;
  @override
  Future<PushPermission> requestPermission() async {
    permissionRequests++;
    perm = PushPermission.granted;
    return perm;
  }

  @override
  Future<PushOpened?> initialMessage() async => null;
  @override
  Stream<PushOpened> get onOpened => const Stream.empty();
  @override
  Stream<PushOpened> get onForeground => const Stream.empty();
}

/// Records API calls instead of making them.
class _FakeDevices extends DevicesRepository {
  _FakeDevices() : super(ApiClient());
  final calls = <String>[];

  @override
  Future<void> register({required String token, required String platform, String? appVersion}) async =>
      calls.add('register $token $platform $appVersion');
  @override
  Future<void> unregister(String token) async => calls.add('unregister $token');
  @override
  Future<void> forgetAfterSessionEnded(String token) async => calls.add('forget $token');
}

void main() {
  late _FakeMessaging messaging;
  late _FakeDevices devices;
  late PushService push;

  setUp(() {
    messaging = _FakeMessaging();
    devices = _FakeDevices();
    push = PushService(messaging: messaging, devices: devices, platform: 'android', appVersion: () async => '1.0.2+11');
  });

  test('registers the token after sign-in, once even if sign-in is reported twice', () async {
    await push.onSignedIn();
    await push.onSignedIn();
    expect(devices.calls, ['register token-1 android 1.0.2+11']);
  });

  test('a rotated token is registered and the old one unregistered', () async {
    await push.onSignedIn();
    messaging.refresh.add('token-2');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(devices.calls, [
      'register token-1 android 1.0.2+11',
      'register token-2 android 1.0.2+11',
      'unregister token-1',
    ]);
    expect(push.token, 'token-2');
  });

  test('sign-out hands over the token for /auth/logout, then deletes it and stops listening', () async {
    await push.onSignedIn();
    expect(await push.tokenForLogout(), 'token-1');
    await push.onSignedOut();
    expect(messaging.deletes, 1);
    messaging.refresh.add('token-3');
    await Future<void>.delayed(Duration.zero);
    expect(devices.calls, ['register token-1 android 1.0.2+11']);
  });

  test('an expired session forgets the device through /auth/logout', () async {
    await push.onSignedIn();
    await push.onSessionExpired();
    expect(devices.calls.last, 'forget token-1');
    expect(messaging.deletes, 1);
  });

  test('asks for permission only while undecided', () async {
    await push.askAtMeaningfulMoment();
    await push.askAtMeaningfulMoment();
    expect(messaging.permissionRequests, 1);
    messaging.perm = PushPermission.denied;
    await push.askAtMeaningfulMoment();
    expect(messaging.permissionRequests, 1);
  });

  test('a token that only appears after permission is granted still gets registered', () async {
    messaging.token = null;
    await push.onSignedIn();
    expect(devices.calls, isEmpty);
    messaging.token = 'late-token';
    await push.askAtMeaningfulMoment();
    expect(devices.calls, ['register late-token android 1.0.2+11']);
  });

  test('routes map to tabs, unknown routes fall back to Home', () {
    expect(tabForPushRoute('interviews'), RootTab.interviews);
    expect(tabForPushRoute('skills'), RootTab.badges);
    expect(tabForPushRoute('jobs'), RootTab.jobs);
    expect(tabForPushRoute('profile'), RootTab.profile);
    expect(tabForPushRoute(null), RootTab.home);
    expect(tabForPushRoute('something-new'), RootTab.home);
  });
}
