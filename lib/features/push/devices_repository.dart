import '../../core/api_client.dart';

/// API side of push tokens — see apps/api src/modules/devices.
class DevicesRepository {
  DevicesRepository(this._api);
  final ApiClient _api;

  Future<void> register({required String token, required String platform, String? appVersion}) async {
    await _api.post('/devices', {
      'token': token,
      'platform': platform,
      if (appVersion != null) 'appVersion': appVersion,
    });
  }

  Future<void> unregister(String token) async {
    await _api.delete('/devices/${Uri.encodeComponent(token)}');
  }

  /// For a session that already ended (rejected refresh): /auth/logout needs
  /// no access token and forgets the device by its token alone.
  Future<void> forgetAfterSessionEnded(String token) async {
    await _api.post('/auth/logout', {'deviceToken': token});
  }
}
