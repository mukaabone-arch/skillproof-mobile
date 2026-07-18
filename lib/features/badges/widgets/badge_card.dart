import 'package:flutter/material.dart';

import '../../../models/badge.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';

/// A single verified badge — the payoff card of the whole app. The big
/// coral medallion is the "prominent verified indicator" this screen calls
/// for; [_LevelPill] carries the level in the same coral treatment. Coral
/// is rationed to exactly these two elements app-wide (see AppColors.coral)
/// — this card does NOT reuse the shared [SkillBadge] widget (which is
/// success-green, for "verified" elsewhere) because these two spots are the
/// one deliberate exception to that rule. Tapping opens the public
/// certificate page in the device browser — see [BadgesScreen].
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
                    _LevelPill(label: badge.level),
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

/// Big circular coral checkmark — distinct from (and larger than) the small
/// [_LevelPill], since this card is the payoff moment.
class _VerifiedMedallion extends StatelessWidget {
  const _VerifiedMedallion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.coralSoft,
        border: Border.all(color: AppColors.coral, width: 2),
      ),
      child: const Icon(Icons.verified_rounded, color: AppColors.coral, size: 30),
    );
  }
}

/// The level chip on an earned badge — same shape/sizing as the shared
/// [SkillBadge] pill, but coral rather than success-green, since this is
/// one of the two elements coral is rationed to (see class doc).
class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
      decoration: BoxDecoration(
        color: AppColors.coralSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.coral),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 13, color: AppColors.coral),
          const SizedBox(width: 5),
          Text(label, style: AppTypography.monoLabel(color: AppColors.coral)),
        ],
      ),
    );
  }
}
