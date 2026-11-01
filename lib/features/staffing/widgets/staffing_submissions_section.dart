import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/staffing.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../staffing_controller.dart';

/// Interviews → "Through staffing companies": approve or decline being put
/// forward to a named client, and see where each approved submission
/// stands. Approving means that company represents the candidate to that
/// client, and no other staffing company can submit them there. Renders
/// nothing until there's at least one. Mirrors
/// apps/web/components/StaffingSubmissionsInbox.tsx.
class StaffingSubmissionsSection extends ConsumerWidget {
  const StaffingSubmissionsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(staffingSubmissionsProvider).valueOrNull ?? const <StaffingSubmission>[];
    if (items.isEmpty) return const SizedBox.shrink();
    final pending = items.where((s) => s.awaitingApproval).toList();
    final rest = items.where((s) => !s.awaitingApproval).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Through staffing companies', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space3),
          for (final s in pending) _ApprovalCard(submission: s),
          for (final s in rest) _SubmissionRow(submission: s),
        ],
      ),
    );
  }
}

class _ApprovalCard extends ConsumerStatefulWidget {
  const _ApprovalCard({required this.submission});

  final StaffingSubmission submission;

  @override
  ConsumerState<_ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<_ApprovalCard> {
  bool _busy = false;
  String? _error;

  Future<void> _decide(bool approve) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(staffingSubmissionsProvider.notifier).decide(widget.submission.id, approve: approve);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.submission;
    final hoursLeft = s.consentExpiresAt.difference(DateTime.now()).inHours.clamp(0, 999);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${s.orgName} wants to put you forward to ${s.clientName}', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space1),
            Text(
              [s.roleTitle, if (s.clientIndustry != null) s.clientIndustry!, '${hoursLeft}h left to decide'].join(' · '),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space2),
            Text(
              'If you approve, ${s.orgName} represents you to ${s.clientName}, and no other staffing company can submit '
              'you there while it lasts.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: AppButton(label: 'Approve', busy: _busy, onPressed: _busy ? null : () => _decide(true)),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: AppButton(
                    label: 'Decline',
                    variant: AppButtonVariant.secondary,
                    onPressed: _busy ? null : () => _decide(false),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SubmissionRow extends ConsumerWidget {
  const _SubmissionRow({required this.submission});

  final StaffingSubmission submission;

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final s = submission;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Withdraw from ${s.clientName}?'),
        content: Text('${s.orgName} will no longer represent you there.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await ref.read(staffingSubmissionsProvider.notifier).withdraw(s.id);
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = submission;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${s.roleTitle} at ${s.clientName}'),
      subtitle: Text('via ${s.orgName} · ${submissionStatusLabels[s.status] ?? s.status}'),
      trailing: s.canWithdraw
          ? TextButton(onPressed: () => _withdraw(context, ref), child: const Text('Withdraw'))
          : null,
    );
  }
}
