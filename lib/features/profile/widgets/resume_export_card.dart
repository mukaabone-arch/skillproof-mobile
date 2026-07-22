import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/api_config.dart';
import '../../../core/external_link.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../entitlements/entitlements_controller.dart';
import '../../entitlements/entitlements_state.dart';

/// Entry point only — the actual AI resume builder + PDF generation is a
/// full multi-step web flow (see apps/web/app/resume/page.tsx) that isn't
/// worth re-implementing natively here. This card just gates the
/// *presentation* (what the candidate is told to expect before they leave
/// the app) and opens it in the browser; web enforces resumeBranding /
/// resumeTemplates itself, same pattern as assessments.
class ResumeExportCard extends ConsumerWidget {
  const ResumeExportCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementsState = ref.watch(entitlementsControllerProvider);
    final limits = entitlementsState is EntitlementsLoaded ? entitlementsState.entitlements.limits : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Resume', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Build a resume from your profile and verified badges — opens in your browser.',
            style: AppTypography.bodyMedium,
          ),
          if (limits != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              limits.resumeBranding
                  ? 'Your PDF includes a "Verified by SkillProof" footer — Premium removes this.'
                  : 'Your PDF has no SkillProof branding — Premium benefit.',
              style: AppTypography.bodySmall,
            ),
            // Deliberately not driven by limits.resumeTemplates here: every
            // plan resolves to the same single layout today (see
            // plans.config.ts's own comment on PLANS.PREMIUM.resumeTemplates)
            // — showing a template count would promise something the PDF
            // generator can't yet deliver.
            const SizedBox(height: AppSpacing.space1),
            Text(
              'Every plan uses the same layout today.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: 'Build resume',
            variant: AppButtonVariant.secondary,
            onPressed: () => _openResumeBuilder(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openResumeBuilder(BuildContext context) async {
    try {
      await openInBrowser('${ApiConfig.webBaseUrl}/resume');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the resume builder. Please try again.')),
        );
      }
    }
  }
}
