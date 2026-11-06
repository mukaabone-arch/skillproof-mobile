import 'dart:async';

import 'push_messaging.dart';
import 'devices_repository.dart';

/// Push phase 1: keep the API's device-token table correct. Nothing in the
/// app reacts to *what* a notification says yet beyond routing a tap — the
/// sender ships later, API-only (see the push spec).
///
/// The rules this class exists to enforce:
///  - register after every sign-in, and again whenever FCM rotates the
///    token ([PushMessaging.onTokenRefresh]) — register-once silently stops
///    working for a slice of users every month;
///  - on every sign-out, tell the API to forget this device *and* delete the
///    token locally, so the next account on this phone starts clean;
///  - ask for notification permission only at a moment where the value is
///    obvious ([askAtMeaningfulMoment]), never cold on first launch — on
///    Android 13+ a denial is effectively permanent.
class PushService {
  PushService({
    required PushMessaging messaging,
    required DevicesRepository devices,
    required String platform,
    Future<String?> Function()? appVersion,
  })  : _messaging = messaging,
        _devices = devices,
        _platform = platform,
        _appVersion = appVersion ?? (() async => null);

  final PushMessaging _messaging;
  final DevicesRepository _devices;
  final String _platform;
  final Future<String?> Function() _appVersion;

  String? _token;
  bool _signedIn = false;
  StreamSubscription<String>? _refreshSub;

  /// The token last registered for this install, if any.
  String? get token => _token;

  Future<void> onSignedIn() async {
    if (_signedIn) return;
    _signedIn = true;
    _refreshSub ??= _messaging.onTokenRefresh.listen(_onRefresh);
    await _registerCurrent();
  }

  Future<void> _registerCurrent() async {
    try {
      final t = await _messaging.getToken();
      if (t == null || !_signedIn) return;
      _token = t;
      await _devices.register(token: t, platform: _platform, appVersion: await _appVersion());
    } catch (_) {
      // Best-effort. iOS can refuse a token until APNs is ready; we retry
      // after a permission grant and on the next sign-in or app start.
    }
  }

  Future<void> _onRefresh(String fresh) async {
    final old = _token;
    _token = fresh;
    if (!_signedIn) return;
    try {
      await _devices.register(token: fresh, platform: _platform, appVersion: await _appVersion());
      if (old != null && old != fresh) await _devices.unregister(old);
    } catch (_) {}
  }

  /// Called by AuthController.logout BEFORE the session is cleared, so the
  /// token can travel with /auth/logout (see AuthRepository.logout).
  Future<String?> tokenForLogout() async {
    if (_token != null) return _token;
    try {
      return await _messaging.getToken();
    } catch (_) {
      return null;
    }
  }

  /// After a sign-out of any kind: stop listening and drop the local token.
  Future<void> onSignedOut() async {
    _signedIn = false;
    await _refreshSub?.cancel();
    _refreshSub = null;
    _token = null;
    try {
      await _messaging.deleteToken();
    } catch (_) {}
  }

  /// The refresh token was rejected server-side: the access token is gone
  /// too, so unregister through /auth/logout, which needs neither.
  Future<void> onSessionExpired() async {
    final t = _token;
    if (t != null) {
      try {
        await _devices.forgetAfterSessionEnded(t);
      } catch (_) {}
    }
    await onSignedOut();
  }

  /// Ask for permission once, at a moment where a notification is plainly
  /// useful (just applied to a job, just opened up to recruiters). No-op if
  /// already granted or denied.
  Future<void> askAtMeaningfulMoment() async {
    try {
      if (await _messaging.permission() != PushPermission.notDetermined) return;
      final result = await _messaging.requestPermission();
      if (result == PushPermission.granted && _signedIn && _token == null) await _registerCurrent();
    } catch (_) {}
  }
}
