import 'package:flutter/material.dart';

import '../../../theme/app_typography.dart';

/// Matches apps/web/app/profile/account/page.tsx's REASON_OPTIONS exactly —
/// same six categories, same wording, same "always skippable" contract:
/// neither the dropdown nor the free-text field is ever required to submit
/// deactivate or delete.
const Map<String, String> reasonCategoryLabels = {
  'FOUND_JOB_SKILLPROOF': 'Found a job through MyAmbii',
  'FOUND_JOB_ELSEWHERE': 'Found a job elsewhere',
  'NOT_FINDING_ROLES': 'Not finding relevant roles',
  'TOO_MANY_EMAILS': 'Too many emails',
  'PRIVACY_CONCERNS': 'Privacy concerns',
  'OTHER': 'Other',
};

/// Shared by the deactivate and delete flows on AccountSettingsScreen — a
/// single-select plus optional free text, always skippable.
class ReasonPicker extends StatelessWidget {
  const ReasonPicker({
    required this.reason,
    required this.onReasonChanged,
    required this.reasonTextController,
    super.key,
  });

  final String? reason;
  final ValueChanged<String?> onReasonChanged;
  final TextEditingController reasonTextController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mind telling us why? (optional)', style: AppTypography.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: reason,
          hint: const Text('Prefer not to say'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Prefer not to say')),
            ...reasonCategoryLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
          ],
          onChanged: onReasonChanged,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: reasonTextController,
          maxLines: 2,
          decoration: const InputDecoration(hintText: "Anything else you'd like to add (optional)"),
        ),
        const SizedBox(height: 4),
        Text(
          "This is just for our own understanding — answering isn't required either way.",
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}
