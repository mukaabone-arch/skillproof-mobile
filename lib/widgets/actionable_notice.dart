import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Actionable prompt for an issue the candidate can resolve themselves —
/// originally the job-apply screen's PROFILE_INCOMPLETE/BADGE_REQUIRED
/// notice, extracted here so the assessments catalog's own profile-gate
/// prompt (same underlying readiness rule, see CandidateProfile.readyToApply)
/// renders identically instead of a second hand-rolled copy. Styled
/// distinctly from a raw error — indigo, not green: this is guidance about
/// *earning* a badge or completing a profile, not a verified skill/badge/
/// certificate itself, so it stays out of the success-green color family
/// per the rule on AppColors.
class ActionableNotice extends StatelessWidget {
  const ActionableNotice({required this.message, this.actionLabel, this.onAction, super.key});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: actionLabel!, variant: AppButtonVariant.secondary, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}
