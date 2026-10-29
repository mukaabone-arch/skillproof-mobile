import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists auth tokens in the platform keystore (Android Keystore /
/// iOS Keychain via flutter_secure_storage) — never SharedPreferences,
/// since these are credentials, not app preferences.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'sp_access_token';
  static const _refreshTokenKey = 'sp_refresh_token';

  Future<String?> readAccessToken() => _safeRead(_accessTokenKey);

  Future<String?> readRefreshToken() => _safeRead(_refreshTokenKey);

  /// A token restored by Android backup (or left by an older install) can't be
  /// decrypted on this device — the read throws, or on some Android 16 builds
  /// never returns, and the app sat on the splash forever. Treat any such
  /// failure as "signed out": wipe the unreadable store and return null so
  /// the login screen shows instead.
  Future<String?> _safeRead(String key) async {
    try {
      final read = _storage.read(key: key);
      // The hang was Android-only; a timer elsewhere just leaks into tests.
      return Platform.isAndroid ? await read.timeout(const Duration(seconds: 5)) : await read;
    } catch (_) {
      try {
        await _storage.deleteAll().timeout(const Duration(seconds: 5));
      } catch (_) {}
      return null;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
