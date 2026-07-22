import 'package:flutter/material.dart';

import '../../../core/limit_reached.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';

/// Wraps RootScreen — the one place a 402 { code: 'LIMIT_REACHED' } response
/// ever becomes UI. Subscribes to LimitReachedBus (populated by
/// core/api_client.dart on every such response, from any call site in the
/// authenticated app) and shows a bottom sheet naming the specific limit
/// and its reset date. Never a generic error toast for this case.
///
/// Deliberately ignores the two retake-specific metrics
/// (retakeCooldownDays / retakesPerSkillLifetime) — same reasoning as
/// apps/web/components/LimitReachedModal.tsx: those get a tailored, inline
/// message right on the assessment card where the attempt was blocked
/// (cooldown-until-date vs. lifetime-cap read very differently), so a
/// second, generic sheet on top of that would be redundant. In practice
/// mobile never even calls the endpoint that could return those two
/// anyway — assessments are only ever started in the browser (see
/// core/external_link.dart) — so this only ever fires for the two
/// countable monthly metrics reachable from in-app actions (applications,
/// assessments).
class LimitReachedListener extends StatefulWidget {
  const LimitReachedListener({required this.child, super.key});

  final Widget child;

  @override
  State<LimitReachedListener> createState() => _LimitReachedListenerState();
}

class _LimitReachedListenerState extends State<LimitReachedListener> {
  void Function()? _unsubscribe;

  static const Map<String, String> _metricLabel = {
    'assessments': 'assessment starts',
    'applications': 'job applications',
  };

  @override
  void initState() {
    super.initState();
    _unsubscribe = LimitReachedBus.instance.addListener(_onLimitReached);
  }

  @override
  void dispose() {
    _unsubscribe?.call();
    super.dispose();
  }

  void _onLimitReached(LimitReachedPayload payload) {
    if (payload.metric != 'assessments' && payload.metric != 'applications') return;
    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _LimitReachedSheet(
        label: _metricLabel[payload.metric] ?? payload.metric,
        limit: payload.limit,
        resetsAt: payload.resetsAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _LimitReachedSheet extends StatelessWidget {
  const _LimitReachedSheet({required this.label, required this.limit, required this.resetsAt});

  final String label;
  final int? limit;
  final DateTime? resetsAt;

  @override
  Widget build(BuildContext context) {
    final resetLine = resetsAt == null ? '' : ' — more open up on ${_formatDate(resetsAt!)}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monthly limit reached', style: AppTypography.metaLabel(color: AppColors.warning)),
            const SizedBox(height: AppSpacing.space2),
            Text("You've used all ${limit ?? ''} of your $label this month", style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space3),
            Text(
              'Free plans include $limit $label per calendar month$resetLine. '
              'Upgrade to Premium for unlimited $label — no monthly wall.',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.space5),
            AppButton(
              label: 'Got it',
              variant: AppButtonVariant.secondary,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime utc) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = utc.toLocal();
    return '${months[local.month - 1]} ${local.day}';
  }
}
