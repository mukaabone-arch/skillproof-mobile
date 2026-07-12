import 'package:flutter/material.dart';

import '../../../models/badge.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/skill_badge.dart';

/// A single verified badge — the payoff card of the whole app. The big
/// verified-green medallion is the "prominent verified indicator" this
/// screen calls for; [SkillBadge] (also verified-green, reused rather than
/// duplicated) carries the level. Tapping opens the public certificate page
/// in the device browser — see [BadgesScreen].
class BadgeCard extends StatelessWidget {
  const BadgeCard({required this.badge, required this.onTap, super.key});

  final VerifiedBadge badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      elevated: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _VerifiedMedallion(),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(badge.skillName, style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.space2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SkillBadge(label: badge.level),
                    const SizedBox(width: AppSpacing.space2),
                    Flexible(
                      child: Text(
                        'Earned ${_formatDate(badge.issuedAt)}',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// Big circular verified-green checkmark — distinct from (and larger than)
/// the small [SkillBadge] pill, since this card is the payoff moment.
class _VerifiedMedallion extends StatelessWidget {
  const _VerifiedMedallion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.verifiedSoft,
        border: Border.all(color: AppColors.verified, width: 2),
      ),
      child: const Icon(Icons.verified_rounded, color: AppColors.verifiedBright, size: 30),
    );
  }
}
