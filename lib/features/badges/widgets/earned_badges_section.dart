import 'package:flutter/material.dart';

import '../../../models/badge.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../badges_state.dart';
import 'badge_card.dart';

/// Renders the "earned" half of [BadgesState] as a column of [BadgeCard]s.
/// Shared by BadgesScreen's own Earned section and ProfileScreen's
/// collapsible badge card, so both surfaces render the exact same cards
/// (same provenance chips, same styling) instead of two copies drifting
/// apart. [emptyMessage] lets each caller phrase the empty state for its
/// own surrounding context (e.g. BadgesScreen can point at its own
/// "Available to verify" section below; ProfileScreen has no such section).
class EarnedBadgesSection extends StatelessWidget {
  const EarnedBadgesSection({
    required this.state,
    required this.onOpenCertificate,
    this.emptyMessage = 'No verified badges yet.',
    super.key,
  });

  final BadgesState state;
  final void Function(VerifiedBadge badge) onOpenCertificate;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      BadgesLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
          child: Center(child: CircularProgressIndicator()),
        ),
      BadgesError(:final message) =>
        Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
      BadgesLoaded(:final badges) when badges.isEmpty =>
        Text(emptyMessage, style: AppTypography.bodySmall),
      BadgesLoaded(:final badges) => Column(
          children: [
            for (final badge in badges)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: BadgeCard(badge: badge, onTap: () => onOpenCertificate(badge)),
              ),
          ],
        ),
    };
  }
}
