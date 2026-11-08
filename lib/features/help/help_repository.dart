import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import 'help_models.dart';

/// API side of the help assistant (POST /help/ask) and of reporting one of
/// its answers (POST /ai-content-reports, targetType HELP_ANSWER — Google
/// Play's AI-generated content policy wants that reachable in the app).
class HelpRepository {
  HelpRepository(this._api, {String? platform}) : _platform = platform;

  final ApiClient _api;
  final String? _platform;

  String get platform => _platform ?? (Platform.isIOS ? 'ios' : 'android');

  Future<HelpAnswer> ask(List<HelpTurn> conversation) async {
    final json = await _api.post('/help/ask', {
      'messages': [for (final t in conversation) t.toJson()],
      'platform': platform,
    });
    return HelpAnswer.fromJson(json as Map<String, dynamic>);
  }

  Future<void> report({required String answerId, required String reason, String? note}) async {
    await _api.post('/ai-content-reports', {
      'sessionId': answerId,
      'targetType': 'HELP_ANSWER',
      'targetId': answerId,
      'reason': reason,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
  }
}

final helpRepositoryProvider = Provider<HelpRepository>((ref) => HelpRepository(ref.read(apiClientProvider)));

/// Remembers that this device agreed to questions going to our AI provider.
/// Secure storage is just the store this app already has; nothing secret here.
class HelpConsentStore {
  HelpConsentStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));

  final FlutterSecureStorage _storage;
  static const _key = 'help_ai_consent';

  Future<bool> hasConsented() async {
    try {
      return await _storage.read(key: _key).timeout(const Duration(seconds: 3)) == 'yes';
    } catch (_) {
      return false;
    }
  }

  Future<void> recordConsent() async {
    try {
      await _storage.write(key: _key, value: 'yes');
    } catch (_) {
      // Worst case the notice shows again next time.
    }
  }
}

final helpConsentStoreProvider = Provider<HelpConsentStore>((ref) => HelpConsentStore());
