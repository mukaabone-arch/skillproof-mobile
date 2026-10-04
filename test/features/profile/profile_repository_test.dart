import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myambii/core/api_client.dart';
import 'package:myambii/core/token_storage.dart';
import 'package:myambii/features/profile/profile_repository.dart';

/// Keeps tests off the platform secure-storage channel: no stored session.
class _NoStoredTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;
}

void main() {
  test('update never sends location or locationLegacy', () async {
    Map<String, dynamic>? sentBody;
    final client = MockClient((request) async {
      sentBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response(
        jsonEncode({
          'id': 'profile-1',
          'fullName': 'Jordan Lee',
          'email': 'jordan@example.com',
          'headline': 'Builds ML pipelines',
          'location': 'Mumbai, Maharashtra, IN',
          'completeness': 60,
          'hasPhoto': false,
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final tokens = _NoStoredTokens();
    final repo = ProfileRepository(apiClient: ApiClient(httpClient: client, tokenStorage: tokens));

    await repo.update(headline: 'Builds ML pipelines', yearsOfExp: 3);

    expect(sentBody, isNotNull);
    expect(sentBody!.containsKey('locationLegacy'), isFalse);
    expect(sentBody!.containsKey('location'), isFalse);
    expect(sentBody!['headline'], 'Builds ML pipelines');
    expect(sentBody!['yearsOfExp'], 3);
  });
}
