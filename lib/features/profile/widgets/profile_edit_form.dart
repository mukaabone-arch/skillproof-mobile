import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../profile_controller.dart';
import '../profile_state.dart';

/// Edit form for fullName/headline/location/yearsOfExp/email/githubUrl/
/// linkedinUrl. Client-side validation on email/years/URLs mirrors (but
/// doesn't replace) the server's own DTO validation — the server still
/// re-validates and is the source of truth (e.g. the email-conflict check
/// can only happen server-side).
class ProfileEditForm extends ConsumerStatefulWidget {
  const ProfileEditForm({required this.profile, required this.onDone, super.key});

  final CandidateProfile profile;
  final VoidCallback onDone;

  @override
  ConsumerState<ProfileEditForm> createState() => _ProfileEditFormState();
}

class _ProfileEditFormState extends ConsumerState<ProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late final _fullNameController = TextEditingController(text: widget.profile.fullName ?? '');
  late final _emailController = TextEditingController(text: widget.profile.email ?? '');
  late final _headlineController = TextEditingController(text: widget.profile.headline ?? '');
  late String? _roleTitle = widget.profile.roleTitle;
  late final _roleTitleOtherController = TextEditingController(text: widget.profile.roleTitleOther ?? '');
  late final _locationController = TextEditingController(text: widget.profile.location ?? '');
  late final _yearsController = TextEditingController(
    text: widget.profile.yearsOfExp != null ? _formatYears(widget.profile.yearsOfExp!) : '',
  );
  late final _githubController = TextEditingController(text: widget.profile.githubUrl ?? '');
  late final _linkedinController = TextEditingController(text: widget.profile.linkedinUrl ?? '');

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _headlineController.dispose();
    _roleTitleOtherController.dispose();
    _locationController.dispose();
    _yearsController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await ref.read(profileControllerProvider.notifier).save(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          headline: _headlineController.text.trim(),
          roleTitle: _roleTitle,
          roleTitleOther: _roleTitleOtherController.text.trim(),
          location: _locationController.text.trim(),
          yearsOfExp: double.tryParse(_yearsController.text.trim()),
          githubUrl: _githubController.text.trim(),
          linkedinUrl: _linkedinController.text.trim(),
        );
    if (ok && mounted) widget.onDone();
  }

  String? _validateEmail(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null; // optional field
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  String? _validateYears(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return 'Enter a number.';
    if (parsed < 0 || parsed > 80) return 'Enter a value between 0 and 80.';
    return null;
  }

  String? _validateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      return 'Enter a full URL starting with https://';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final saving = state is ProfileLoaded && state.saving;
    final saveError = state is ProfileLoaded ? state.saveError : null;

    return AppCard(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _fullNameController,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Full name', counterText: ''),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              maxLength: 255,
              validator: _validateEmail,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'you@example.com',
                helperText: 'Used to email you about job and application updates.',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _headlineController,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Headline',
                hintText: 'e.g. Backend engineer, 5 yrs Node/Go',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            // Structured role dropdown — display/filter only, shown to
            // employers and used in candidate search. NEVER wired into match
            // scoring; see candidateRoleTitleLabels' own doc comment.
            DropdownButtonFormField<String>(
              initialValue: _roleTitle,
              decoration: const InputDecoration(labelText: 'Role'),
              items: candidateRoleTitleOptions
                  .map((r) => DropdownMenuItem(value: r, child: Text(candidateRoleTitleLabels[r]!)))
                  .toList(),
              onChanged: (value) => setState(() => _roleTitle = value),
            ),
            if (_roleTitle == 'OTHER') ...[
              const SizedBox(height: AppSpacing.space3),
              TextFormField(
                controller: _roleTitleOtherController,
                maxLength: 160,
                decoration: const InputDecoration(labelText: 'Your role title', counterText: ''),
              ),
            ],
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _locationController,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Location', counterText: ''),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _yearsController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _validateYears,
              decoration: const InputDecoration(labelText: 'Years of experience'),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _githubController,
              keyboardType: TextInputType.url,
              maxLength: 255,
              validator: _validateUrl,
              decoration: const InputDecoration(
                labelText: 'GitHub URL',
                hintText: 'https://github.com/...',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _linkedinController,
              keyboardType: TextInputType.url,
              maxLength: 255,
              validator: _validateUrl,
              decoration: const InputDecoration(
                labelText: 'LinkedIn URL',
                hintText: 'https://linkedin.com/in/...',
                counterText: '',
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            // The server's error message is already human-readable (e.g.
            // the P2002 email-conflict case is a 409 with "This email
            // address is already in use by another account.", not a raw
            // 500) — shown directly, no extra parsing needed here.
            if (saveError != null) ...[
              Text(saveError, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
              const SizedBox(height: AppSpacing.space3),
            ],
            Row(
              children: [
                Expanded(
                  child: AppButton(label: 'Save profile', busy: saving, onPressed: _save),
                ),
                const SizedBox(width: AppSpacing.space2),
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: saving ? null : widget.onDone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatYears(double years) =>
      years == years.roundToDouble() ? years.toInt().toString() : years.toString();
}
