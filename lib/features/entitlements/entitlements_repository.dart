import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/entitlements.dart';

final entitlementsRepositoryProvider = Provider<EntitlementsRepository>((ref) {
  return EntitlementsRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to GET /me/entitlements — see apps/api's entitlements README for
/// the frozen contract. Both this app and the web app render every
/// upgrade/limit-reached gate from this response alone.
class EntitlementsRepository {
  EntitlementsRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<Entitlements> fetch() async {
    final response = await apiClient.get('/me/entitlements') as Map<String, dynamic>;
    return Entitlements.fromJson(response);
  }
}
