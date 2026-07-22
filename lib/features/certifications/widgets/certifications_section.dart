import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/certification.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/empty_state.dart';
import '../certifications_controller.dart';
import '../certifications_state.dart';
import 'certification_card.dart';
import 'certification_form.dart';

/// Profile-screen section for certifications from any issuer (Credly,
/// Coursera, LinkedIn Learning, PMI, PeopleCert, AWS, Microsoft, Google,
/// Scrum Alliance, Udemy, edX, NPTEL, or a free-text Other) — the
/// multi-issuer successor to the old Credly-only ExternalCredentialsSection.
/// No title of its own — the caller (ProfileScreen) wraps this in a
/// CollapsibleSection, which supplies the "Certifications" heading and card
/// surface, same convention the section it replaces used.
///
/// Owns the add/edit form's open/closed and which-row-is-editing state
/// locally (mirrors web's formOpen/editingId component state) — the
/// controller/repository only ever deal with the server-backed list itself.
class CertificationsSection extends ConsumerStatefulWidget {
  const CertificationsSection({super.key});

  @override
  ConsumerState<CertificationsSection> createState() => _CertificationsSectionState();
}

class _CertificationsSectionState extends ConsumerState<CertificationsSection> {
  bool _formOpen = false;
  Certification? _editing;

  void _startAdd() => setState(() {
        _editing = null;
        _formOpen = true;
      });

  void _startEdit(Certification c) => setState(() {
        _editing = c;
        _formOpen = true;
      });

  void _closeForm() => setState(() {
        _formOpen = false;
        _editing = null;
      });

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(certificationsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add certifications from Credly, Coursera, LinkedIn Learning, PMI, PeopleCert, and other '
          'platforms. A live-verified Credly badge gets the strongest tier; a credential link is '
          'shown as unverified; a self-uploaded file is labelled candidate-provided — employers '
          'always see which is which, and only the verified tier ever affects your match score.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.space3),
        if (!_formOpen)
          AppButton(label: 'Add certification', onPressed: _startAdd)
        else
          CertificationForm(editing: _editing, onDone: _closeForm),
        const SizedBox(height: AppSpacing.space3),
        switch (state) {
          CertificationsLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
              child: Center(child: CircularProgressIndicator()),
            ),
          CertificationsError(:final message) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              child: Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
            ),
          CertificationsLoaded(:final certifications) when certifications.isEmpty => const EmptyState(
              message: 'No certifications yet — add one above.',
            ),
          CertificationsLoaded(:final certifications, :final deletingId) => Column(
              children: [
                for (final cert in certifications)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: CertificationCard(
                      certification: cert,
                      deleting: deletingId == cert.id,
                      onEdit: () => _startEdit(cert),
                      onDelete: () => ref.read(certificationsControllerProvider.notifier).remove(cert.id),
                    ),
                  ),
              ],
            ),
        },
      ],
    );
  }
}
