import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/empty_state.dart';
import '../external_credentials_controller.dart';
import '../external_credentials_state.dart';
import 'add_credential_form.dart';
import 'external_credential_card.dart';

/// Profile-screen section for external (non-SkillProof) credentials — see
/// ExternalCredentialCard / CredentialStatusChip for the two-tier visual
/// rule this whole feature exists to enforce.
class ExternalCredentialsSection extends ConsumerWidget {
  const ExternalCredentialsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(externalCredentialsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('External credentials', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space1),
        Text(
          'Certifications from other platforms. Credly badge URLs are verified '
          'automatically by checking the badge is public — shown to employers as a '
          'separate, distinctly-styled tier from your SkillProof-verified skills, and '
          'never affect your match score.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.space3),
        const AddCredentialForm(),
        const SizedBox(height: AppSpacing.space3),
        switch (state) {
          ExternalCredentialsLoading() => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
              child: Center(child: CircularProgressIndicator()),
            ),
          ExternalCredentialsError(:final message) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              child: Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.dangerBright)),
            ),
          ExternalCredentialsLoaded(:final credentials) when credentials.isEmpty => const EmptyState(
              message: 'No external credentials yet — paste a Credly badge URL above to add one.',
            ),
          ExternalCredentialsLoaded(:final credentials, :final deletingId) => Column(
              children: [
                for (final credential in credentials)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                    child: ExternalCredentialCard(
                      credential: credential,
                      deleting: deletingId == credential.id,
                      onDelete: () =>
                          ref.read(externalCredentialsControllerProvider.notifier).remove(credential.id),
                    ),
                  ),
              ],
            ),
        },
      ],
    );
  }
}
