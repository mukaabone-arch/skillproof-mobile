import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';

class NextStep {
  const NextStep({
    required this.kicker,
    required this.title,
    required this.ctaLabel,
    required this.onTap,
  });

  final String kicker;
  final String title;
  final String ctaLabel;
  final VoidCallback onTap;
}

/// The single "what should I do next" prompt — mirrors the web dashboard's
/// `.next-step-card`. Whole card is tappable, not just the CTA row, so it
/// reads as one obvious action rather than a card with a button buried
/// inside it.
class NextStepCard extends StatelessWidget {
  const NextStepCard({required this.step, super.key});

  final NextStep step;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: step.onTap,
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(step.kicker.toUpperCase(), style: AppTypography.monoLabel(color: AppColors.indigoLight)),
          const SizedBox(height: AppSpacing.space2),
          Text(step.title, style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  step.ctaLabel,
                  style: AppTypography.labelLarge.copyWith(color: AppColors.indigoLight),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.indigoLight),
            ],
          ),
        ],
      ),
    );
  }
}
