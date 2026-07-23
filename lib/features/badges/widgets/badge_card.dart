import 'package:flutter/material.dart';

import '../../../models/badge.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../assessments/level_info.dart';

/// A single verified badge — the payoff card of the whole app. The big
/// coral medallion is the "prominent verified indicator" this screen calls
/// for; [_LevelPill] carries the level in the same coral treatment. Coral
/// is rationed to exactly these two elements app-wide (see AppColors.coral)
/// — this card does NOT reuse the shared [SkillBadge] widget (which is
/// success-green, for "verified" elsewhere) because these two spots are the
/// one deliberate exception to that rule. Tapping opens the public
/// certificate page in the device browser — see [BadgesScreen].
///
/// The level name/description and the "verified by X, employers can
/// independently confirm it" line mirror apps/web/app/assessments/page.tsx's
/// earned-level LevelRow branch — keep the two in sync when either changes.
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
                const SizedBox(height: AppSpacing.space1),
                Text(
                  'Level ${badge.level} · ${levelDescription(badge.level)}',
                  style: AppTypography.bodySmall,
                ),
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _LevelPill(label: levelName(badge.level)),
                    Text(
                      'Earned ${_formatDate(badge.issuedAt)}'
                      '${badge.attemptNumber != null ? ' · attempt #${badge.attemptNumber}' : ''}',
                      style: AppTypography.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    _ProvenanceChip(method: badge.verifiedBy),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  badge.verifiedBy == BadgeVerificationMethod.discussion
                      ? 'Verified by a live discussion review — employers can independently confirm it.'
                      : 'Verified by an automated test — employers can independently confirm it.',
                  style: AppTypography.bodySmall,
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
          Text(label, style: AppTypography.metaLabel(color: AppColors.coral)),
        ],
      ),
    );
  }
}

/// How this badge was earned — mirrors web's Dashboard.tsx chip treatment
/// (💬/✓ + a "Verified by discussion"/"Verified by test" tooltip) with the
/// same semantics: discussion is the stronger evidence (a reviewer watching
/// a candidate reason live, vs. a multiple-choice score), so it gets the
/// brand-colored, slightly more prominent pill; test gets a quiet neutral
/// one. Neither reaches for coral — that's rationed to the medallion and
/// [_LevelPill] only (see [BadgeCard] doc).
class _ProvenanceChip extends StatelessWidget {
  const _ProvenanceChip({required this.method});

  final BadgeVerificationMethod method;

  @override
  Widget build(BuildContext context) {
    final isDiscussion = method == BadgeVerificationMethod.discussion;
    final color = isDiscussion ? AppColors.primary : AppColors.textSecondary;

    return Tooltip(
      message: isDiscussion ? 'Verified by discussion' : 'Verified by test',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: 2),
        decoration: BoxDecoration(
          color: isDiscussion ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: isDiscussion ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isDiscussion ? Icons.forum_rounded : Icons.fact_check_rounded, size: 12, color: color),
            const SizedBox(width: 4),
            Text(isDiscussion ? 'Discussion' : 'Test', style: AppTypography.metaLabel(color: color)),
          ],
        ),
      ),
    );
  }
}
