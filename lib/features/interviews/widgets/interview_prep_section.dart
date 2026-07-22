import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/locked_preview.dart';
import '../../entitlements/entitlements_controller.dart';
import '../../entitlements/entitlements_state.dart';

class _Guide {
  const _Guide(this.title, this.body);
  final String title;
  final String body;
}

/// interviewPrep (Free: false, Premium: true) — static, bundled content (no
/// backend data involved, unlike the other gated surfaces), so the gate here
/// is purely limits.interviewPrep. Free sees the real section titles (a
/// genuine, specific teaser — three named guides exist) with the actual
/// guidance blurred behind the usual locked-preview treatment. Mirrors
/// apps/web/components/InterviewPrepPanel.tsx verbatim (same three guides),
/// placed on this screen — not Profile — to match where web puts it
/// (apps/web/app/interviews/page.tsx).
class InterviewPrepSection extends ConsumerWidget {
  const InterviewPrepSection({super.key});

  static const _guides = [
    _Guide(
      'Behavioral questions to expect',
      'Interviewers commonly ask how you handled a project where requirements changed mid-way, a '
          'time you disagreed with a technical decision, and how you explain a complex model choice '
          'to a non-technical stakeholder. Prepare one concrete story for each — specific, with a '
          'measurable outcome.',
    ),
    _Guide(
      'Deep-dive prompts for your verified skills',
      'For each skill badge on your profile, expect at least one question asking you to justify a '
          'trade-off (e.g. why you chose one chunking strategy, evaluation metric, or fine-tuning '
          'approach over another) rather than just define the term. Practice explaining the '
          'reasoning, not just the result.',
    ),
    _Guide(
      'Questions worth asking the interviewer',
      'Ask what "good" looks like in the role\'s first 90 days, how the team currently evaluates '
          'model/product quality, and what the biggest technical debt or open problem is. These '
          'signal genuine interest and often reveal more about the role than the job description did.',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementsState = ref.watch(entitlementsControllerProvider);
    final interviewPrep = entitlementsState is EntitlementsLoaded
        ? entitlementsState.entitlements.limits.interviewPrep
        : null;

    if (interviewPrep == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Interview prep', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space2),
          Text('Guidance for turning a verified badge into an interview that goes well.', style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space4),
          interviewPrep
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [for (final g in _guides) _GuideCard(guide: g)],
                )
              : LockedPreview(
                  teaser: '${_guides.length} prep guides available, tailored to your verified skills.',
                  overlayLabel: 'Premium unlocks the guidance',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final g in _guides) _GuideCard(guide: g)],
                  ),
                ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final _Guide guide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.space3),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(guide.title, style: AppTypography.titleSmall),
            const SizedBox(height: AppSpacing.space1),
            Text(guide.body, style: AppTypography.bodySmall),
          ],
        ),
      ),
    );
  }
}
