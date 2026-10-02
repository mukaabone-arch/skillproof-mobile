import 'package:flutter/material.dart';

import '../../../models/assessment_catalog_entry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/actionable_notice.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../card_state.dart';
import '../level_info.dart';

/// One "available to verify" skill on the Badges screen. Deliberately
/// brand, not [SkillBadge]'s success-green — this is an *offered* level,
/// not a verified one; see the color rule on AppColors and SkillBadge's own
/// doc comment ("must never be reused for a plain required-skill chip").
///
/// Copy mirrors apps/web/app/assessments/page.tsx's LevelRow/AvailabilityMeta
/// where the same concept applies to this app's simplified one-card-per-skill
/// projection — see [AssessmentCatalogEntry]'s own doc comment for how it
/// diverges (no LOCKED/SUBSUMED/EARNED rows, no test/discussion choice).
class AssessmentCatalogCard extends StatelessWidget {
  const AssessmentCatalogCard({
    required this.entry,
    required this.onTakeAssessment,
    this.highlighted = false,
    this.premium = false,
    this.profileReady = true,
    this.profileGateMessage,
    this.onCompleteProfile,
    this.freeSkillLocked,
    super.key,
  });

  final AssessmentCatalogEntry entry;
  final VoidCallback onTakeAssessment;
  final bool highlighted;

  /// Only affects the retake-cooldown/lifetime-cap nudge wording — see
  /// resolveCardDisplay's own doc comment. Passed down from the caller
  /// (which reads entitlementsControllerProvider) rather than watched here,
  /// so this card stays a plain, pure StatelessWidget.
  final bool premium;

  /// See resolveCardDisplay's own doc comment on the profileReady param —
  /// same default-true, same "only the available state is affected" scope.
  /// [profileGateMessage]/[onCompleteProfile] are only read when this is
  /// false and the entry would otherwise be startable; both should be
  /// non-null in that case (the caller — BadgesScreen's _AvailableSection —
  /// always supplies them together), but this widget degrades to a generic
  /// message and no action rather than asserting, since a StatelessWidget
  /// is the wrong place to enforce that invariant.
  final bool profileReady;
  final String? profileGateMessage;
  final VoidCallback? onCompleteProfile;

  /// This skill's name if a FREE candidate is locked to a *different* skill,
  /// else null — the caller (BadgesScreen's _AvailableSection) computes this
  /// per entry from entitlementsControllerProvider, same as web's
  /// CategorySection. Takes precedence over the profile gate below; see
  /// resolveCardDisplay's own doc comment.
  final String? freeSkillLocked;

  @override
  Widget build(BuildContext context) {
    final display = resolveCardDisplay(
      entry,
      premium: premium,
      profileReady: profileReady,
      freeSkillLocked: freeSkillLocked,
    );
    final showLockGate = entry.state == AssessmentCatalogState.available && freeSkillLocked != null;
    final showProfileGate = entry.state == AssessmentCatalogState.available && !showLockGate && !profileReady;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: highlighted ? Border.all(color: AppColors.primary, width: 2) : null,
        boxShadow: highlighted
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1)]
            : null,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(entry.skillName, style: AppTypography.titleMedium)),
                const SizedBox(width: AppSpacing.space2),
                _LevelChip(label: levelName(entry.badgeLevel)),
              ],
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              'Level ${entry.badgeLevel} · ${levelDescription(entry.badgeLevel)}',
              style: AppTypography.bodySmall,
            ),
            if (entry.relevanceCount > 0) ...[
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Required on ${entry.relevanceCount} role${entry.relevanceCount == 1 ? '' : 's'} you\'re close to',
                style: AppTypography.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.space2),
            Text(
              entry.isDiscussion ? 'Live discussion · ${entry.estMinutes} min' : 'Timed test · ${entry.estMinutes} min',
              style: AppTypography.meta(),
            ),
            if (entry.isDiscussion) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                "A reviewer talks through your reasoning live, not just your final answer — it's the same "
                'verified badge as a timed test, just a different way to prove it.',
                style: AppTypography.bodySmall,
              ),
            ],
              if (showLockGate) ...[
              const SizedBox(height: AppSpacing.space2),
              // Informational only — no tappable route to checkout. Google
              // Play's billing policy restricts steering users toward
              // external payment, not just in-app processing, so the
              // outbound /upgrade link was removed for v1. Restore it only
              // if the Tier B advisers confirm linking out is acceptable
              // under India's framework.
              ActionableNotice(
                message: '🔒 Your free plan\'s assessments are locked to $freeSkillLocked. '
                    'Attempting ${entry.skillName} is part of MyAmbii Premium.',
              ),
            ] else if (showProfileGate) ...[
              const SizedBox(height: AppSpacing.space2),
              ActionableNotice(
                message: profileGateMessage ?? 'Complete your profile to start earning verified badges.',
                actionLabel: 'Go to Profile',
                onAction: onCompleteProfile,
              ),
            ] else if (display.metaText != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(
                display.metaText!,
                style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
              ),
            ],
            const SizedBox(height: AppSpacing.space4),
            AppButton(
              label: display.buttonLabel,
              expand: true,
              onPressed: display.buttonEnabled ? onTakeAssessment : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary),
      ),
      child: Text(label, style: AppTypography.metaLabel(color: AppColors.primary)),
    );
  }
}
