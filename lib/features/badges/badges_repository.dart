import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../models/badge.dart';

final badgesRepositoryProvider = Provider<BadgesRepository>((ref) {
  return BadgesRepository(apiClient: ref.read(apiClientProvider));
});

/// Talks to GET /users/me — there is no dedicated badges endpoint. A
/// candidate's verified badges are exactly the subset of their
/// `profile.skillClaims` where `status == 'VERIFIED'` and the linked badge
/// hasn't been revoked; everything else (UNVERIFIED, EXPIRED, or a
/// VERIFIED claim whose badge was later revoked) is filtered out here
/// before it ever reaches the UI.
class BadgesRepository {
  BadgesRepository({required this.apiClient});

  final ApiClient apiClient;

  Future<List<VerifiedBadge>> verifiedBadges() async {
    final response = await apiClient.get('/users/me') as Map<String, dynamic>;
    final profile = response['profile'] as Map<String, dynamic>?;
    final claims = (profile?['skillClaims'] as List<dynamic>?) ?? const [];

    final badges = claims
        .cast<Map<String, dynamic>>()
        .where((claim) {
          final badge = claim['badge'] as Map<String, dynamic>?;
          return claim['status'] == 'VERIFIED' && badge != null && badge['revokedAt'] == null;
        })
        .map(VerifiedBadge.fromJson)
        .toList();

    badges.sort((a, b) => b.issuedAt.compareTo(a.issuedAt)); // most recently earned first
    return badges;
  }
}
