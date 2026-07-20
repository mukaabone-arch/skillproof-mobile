import 'package:flutter/material.dart';

import '../../../models/profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';

/// Read-only display of the candidate's profile fields, plus an "Edit
/// profile" action into [ProfileEditForm]. No [AppCard] of its own — the
/// caller (ProfileScreen) wraps this in a CollapsibleSection, which
/// supplies the card surface.
class ProfileView extends StatelessWidget {
  const ProfileView({required this.profile, required this.onEdit, super.key});

  final CandidateProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('Full name', profile.fullName),
        _field('Email', profile.email),
        _field('Headline', profile.headline),
        _field('Role', profile.roleTitleLabel),
        _field('Location', profile.location),
        _field('Years of experience', profile.yearsOfExp != null ? _formatYears(profile.yearsOfExp!) : null),
        _field('GitHub', profile.githubUrl),
        _field('LinkedIn', profile.linkedinUrl),
        const SizedBox(height: AppSpacing.space2),
        AppButton(
          label: 'Edit profile',
          variant: AppButtonVariant.secondary,
          expand: true,
          onPressed: onEdit,
        ),
      ],
    );
  }

  Widget _field(String label, String? value) {
    final hasValue = value?.trim().isNotEmpty ?? false;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.monoLabel()),
          const SizedBox(height: 3),
          Text(
            hasValue ? value! : 'Not set',
            style: AppTypography.bodyLarge.copyWith(
              color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatYears(double years) =>
      years == years.roundToDouble() ? years.toInt().toString() : years.toString();
}
