import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// "N of M left this month" meter, shown near the action it gates (Apply,
/// Take assessment) — the point is the candidate sees this *before* hitting
/// the wall, not after. Mirrors apps/web/components/UsageMeter.tsx: renders
/// nothing when [limit] is null (unlimited), and shifts to
/// [AppColors.warning] at zero remaining rather than an error color — the
/// intent is "you've used your plan's allowance, right on schedule", not
/// "something went wrong".
class UsageMeter extends StatelessWidget {
  const UsageMeter({
    required this.label,
    required this.used,
    required this.limit,
    required this.resetsAt,
    super.key,
  });

  /// Plural noun describing what's counted, e.g. "applications", "assessment starts".
  final String label;
  final int used;
  final int? limit;
  final DateTime resetsAt;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    if (limit == null) return const SizedBox.shrink();

    final cap = limit!;
    final remaining = (cap - used).clamp(0, cap);
    // Fill represents what's left, not what's been consumed, so it agrees
    // with the "N left" label right above it: a full bar means the whole
    // allowance is still available, and it drains toward empty (and
    // [AppColors.warning]) as quota is used. Matches the apps/web fix to
    // UsageMeter.tsx, which had the same used/limit-vs-remaining/limit bug.
    final pct = cap > 0 ? (remaining / cap).clamp(0.0, 1.0) : 1.0;
    final atZero = remaining == 0;
    final tone = atZero ? AppColors.warning : AppColors.primary;
    final local = resetsAt.toLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$remaining of $cap $label left this month',
          style: AppTypography.bodySmall.copyWith(color: atZero ? AppColors.warning : AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.space1),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation(tone),
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text('Resets ${_months[local.month - 1]} ${local.day}', style: AppTypography.bodySmall),
      ],
    );
  }
}
