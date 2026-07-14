import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';

/// Mirrors the web dashboard's SegmentedProgressState (done/active/upcoming)
/// — each stage's state is derived from the same booleans that drive the
/// "next step" card, so the two can never disagree about what the
/// candidate should do next. See HeroSection.
enum JourneyStepState { done, active, upcoming }

class JourneyStep {
  const JourneyStep({required this.label, required this.state});

  final String label;
  final JourneyStepState state;
}

/// Mirrors web's journeySubLabel in Dashboard.tsx — keep the two in sync.
String journeySubLabel(JourneyStepState state) {
  switch (state) {
    case JourneyStepState.done:
      return 'Complete';
    case JourneyStepState.active:
      return 'In progress';
    case JourneyStepState.upcoming:
      return 'Not started';
  }
}

/// Compact, phone-native version of the web's SegmentedProgress — a bar per
/// stage, a short label, and a status sub-label ("Complete" / "In progress"
/// / "Not started"), matching web's SegmentedProgress caption for parity.
/// Indigo only, at every stage — progress is never a verified-skill
/// signal, so it must never reach for [AppColors.verified]/[verifiedBright].
class JourneyProgress extends StatelessWidget {
  const JourneyProgress({required this.steps, super.key});

  final List<JourneyStep> steps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i != 0) const SizedBox(width: AppSpacing.space2),
          Expanded(child: _Segment(step: steps[i])),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.step});

  final JourneyStep step;

  @override
  Widget build(BuildContext context) {
    final barColor = switch (step.state) {
      JourneyStepState.done => AppColors.indigoLight,
      JourneyStepState.active => AppColors.indigo,
      JourneyStepState.upcoming => AppColors.border,
    };
    final labelColor =
        step.state == JourneyStepState.upcoming ? AppColors.textTertiary : AppColors.textPrimary;
    final subLabelColor =
        step.state == JourneyStepState.upcoming ? AppColors.textTertiary : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: Container(height: 5, color: barColor),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          step.label,
          style: AppTypography.labelSmall.copyWith(color: labelColor),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          journeySubLabel(step.state),
          style: AppTypography.mono(size: 9.5, weight: FontWeight.w500, color: subLabelColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
