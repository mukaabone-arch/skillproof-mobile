import 'package:flutter/material.dart';

import '../../../models/assessment_catalog_entry.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../card_state.dart';

/// One "available to verify" skill on the Badges screen. Deliberately
/// brand, not [SkillBadge]'s success-green — this is an *offered* level,
/// not a verified one; see the color rule on AppColors and SkillBadge's own
/// doc comment ("must never be reused for a plain required-skill chip").
class AssessmentCatalogCard extends StatelessWidget {
  const AssessmentCatalogCard({
    required this.entry,
    required this.onTakeAssessment,
    this.highlighted = false,
    super.key,
  });

  final AssessmentCatalogEntry entry;
  final VoidCallback onTakeAssessment;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final display = resolveCardDisplay(entry);

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
                _LevelChip(label: entry.badgeLevel),
              ],
            ),
            if (entry.relevanceCount > 0) ...[
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Required on ${entry.relevanceCount} role${entry.relevanceCount == 1 ? '' : 's'} you\'re close to',
                style: AppTypography.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.space2),
            Text('${entry.estMinutes} min', style: AppTypography.meta()),
            if (display.metaText != null) ...[
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
