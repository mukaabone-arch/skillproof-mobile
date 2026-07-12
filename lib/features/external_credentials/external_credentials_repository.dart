import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/external_credential.dart';

final externalCredentialsRepositoryProvider = Provider<ExternalCredentialsRepository>((ref) {
  return ExternalCredentialsRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to /profiles/me/external-credentials. Verification (VERIFIED vs.
/// FAILED vs. PENDING) happens server-side, synchronously, inside [add] —
/// the returned credential already carries its resulting state.
class ExternalCredentialsRepository {
  ExternalCredentialsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<ExternalCredential>> list() async {
    final response = await apiClient.get('/profiles/me/external-credentials') as List<dynamic>;
    return response.cast<Map<String, dynamic>>().map(ExternalCredential.fromJson).toList();
  }

  Future<ExternalCredential> add(String credentialUrl) async {
    final response = await apiClient.post(
      '/profiles/me/external-credentials',
      {'credentialUrl': credentialUrl},
    ) as Map<String, dynamic>;
    return ExternalCredential.fromJson(response);
  }

  Future<void> remove(String id) async {
    await apiClient.delete('/profiles/me/external-credentials/$id');
  }
}
