import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/staffing.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../staffing_controller.dart';

/// Interviews → staffing-company availability requests. Renders nothing until
/// there's at least one. Saying yes (with or without conditions) is what
/// shares the candidate's name and contact details with that one company.
/// Mirrors apps/web/components/StaffingRequestsInbox.tsx.
class StaffingRequestsSection extends ConsumerWidget {
  const StaffingRequestsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(staffingRequestsProvider).valueOrNull ?? const <StaffingRequest>[];
    if (requests.isEmpty) return const SizedBox.shrink();
    final open = requests.where((r) => r.isOpen).toList();
    final past = requests.where((r) => !r.isOpen).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Staffing availability requests', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'Verified staffing companies asking if you\'re available for a client role. They see your name and contact '
            'details only if you say yes.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space3),
          for (final r in open) _OpenRequestCard(request: r),
          if (past.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text('Earlier requests (${past.length})', style: AppTypography.bodySmall),
              children: [
                for (final r in past)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text('${r.roleTitle} · ${r.orgName}'),
                    subtitle: Text(requestStatusLabels[r.status] ?? r.status),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OpenRequestCard extends ConsumerStatefulWidget {
  const _OpenRequestCard({required this.request});

  final StaffingRequest request;

  @override
  ConsumerState<_OpenRequestCard> createState() => _OpenRequestCardState();
}

class _OpenRequestCardState extends ConsumerState<_OpenRequestCard> {
  bool _busy = false;
  bool _block = false;
  String? _error;

  Future<void> _respond(String response, {String? message}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref
        .read(staffingRequestsProvider.notifier)
        .respond(widget.request.id, response, message: message, block: _block);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }

  Future<void> _withConditions() async {
    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your conditions'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          maxLength: 500,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Available from 15 Dec, minimum ₹9,000 per day, remote only'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Send & share my details'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (message != null && message.isNotEmpty) await _respond('CONDITIONAL', message: message);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final hoursLeft = r.expiresAt.difference(DateTime.now()).inHours.clamp(0, 999);
    final rate = formatRate(r.rateMinInr, r.rateMaxInr, r.rateUnit);
    final where = [r.location, if (r.remote) 'remote OK'].whereType<String>().join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space3),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(r.roleTitle, style: AppTypography.titleMedium)),
                Text('${hoursLeft}h left', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
            const SizedBox(height: AppSpacing.space1),
            Text('From ${r.orgName} · ${r.clientLine}', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.space2),
            Text(r.summary, style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.space2),
            Text(
              [workTypeLabels[r.workType] ?? r.workType, if (rate != null) rate, if (where.isNotEmpty) where].join(' · '),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: "I'm available", busy: _busy, onPressed: _busy ? null : () => _respond('AVAILABLE'), expand: true),
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'With conditions',
                    variant: AppButtonVariant.secondary,
                    onPressed: _busy ? null : _withConditions,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: AppButton(
                    label: 'Not right now',
                    variant: AppButtonVariant.secondary,
                    onPressed: _busy ? null : () => _respond('NOT_NOW'),
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              value: _block,
              onChanged: _busy ? null : (v) => setState(() => _block = v ?? false),
              title: Text("Don't let ${r.orgName} contact me again", style: AppTypography.bodySmall),
            ),
            if (_error != null) Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
          ],
        ),
      ),
    );
  }
}
