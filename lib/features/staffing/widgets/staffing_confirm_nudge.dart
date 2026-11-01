import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../staffing_controller.dart';

/// Home: "Still available?" — shown only when the candidate is open to
/// staffing companies but their availability has gone stale (or is about to
/// be hidden). One tap re-confirms it. The API's daily reminder email links
/// to the same action on the web; this is the in-app equivalent (no push yet).
class StaffingConfirmNudge extends ConsumerStatefulWidget {
  const StaffingConfirmNudge({super.key});

  @override
  ConsumerState<StaffingConfirmNudge> createState() => _StaffingConfirmNudgeState();
}

class _StaffingConfirmNudgeState extends ConsumerState<StaffingConfirmNudge> {
  bool _busy = false;
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(staffingAvailabilityProvider).valueOrNull;
    if (_done) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space4),
        child: Text('Thanks — staffing companies can see your availability again.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
      );
    }
    if (a == null || !a.confirmSoon) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Still available?', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space1),
            Text(
              a.needsConfirming
                  ? 'You\'re open to staffing companies, but they can\'t see you until you confirm your availability '
                      '(${a.availabilityText}).'
                  : 'Staffing companies will stop seeing you in a few days unless you confirm your availability '
                      '(${a.availabilityText}).',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: 'Yes, still accurate',
              busy: _busy,
              expand: true,
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      final error = await ref.read(staffingAvailabilityProvider.notifier).confirm();
                      if (!mounted) return;
                      setState(() {
                        _busy = false;
                        _done = error == null;
                      });
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
