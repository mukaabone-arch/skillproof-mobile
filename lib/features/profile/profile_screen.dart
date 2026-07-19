import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../auth/auth_controller.dart';
import '../badges/badges_controller.dart';
import '../badges/badges_state.dart';
import '../external_credentials/widgets/external_credentials_section.dart';
import '../root/root_tab_provider.dart';
import 'profile_controller.dart';
import 'profile_state.dart';
import 'widgets/profile_edit_form.dart';
import 'widgets/profile_view.dart';
// TODO: resume upload — blocked on file_picker / compileSdk 36 conflict.
// Resume upload works on web; revisit when updating the Android toolchain
// for release builds.
// import 'widgets/resume_section.dart';

/// The candidate's profile — replaces the earlier placeholder. This is
/// also the fix for a real gap: a candidate who taps Apply with an
/// incomplete profile previously had nowhere in the app to fix it.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (state is ProfileLoaded)
            IconButton(
              icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
              tooltip: _editing ? 'Cancel editing' : 'Edit profile',
              onPressed: () => setState(() => _editing = !_editing),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: switch (state) {
        ProfileLoading() => const Center(child: CircularProgressIndicator()),
        ProfileError(:final message) => _ErrorRetry(
            message: message,
            onRetry: () => ref.read(profileControllerProvider.notifier).load(),
          ),
        ProfileLoaded() => RefreshIndicator(
            onRefresh: () => ref.read(profileControllerProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                _CompletenessCard(profile: state.profile),
                if (!state.profile.readyToApply) ...[
                  const SizedBox(height: AppSpacing.space3),
                  const _IncompleteProfileHint(),
                ],
                const SizedBox(height: AppSpacing.space3),
                const _BadgeCountLink(),
                const SizedBox(height: AppSpacing.space3),
                _editing
                    ? ProfileEditForm(
                        profile: state.profile,
                        onDone: () => setState(() => _editing = false),
                      )
                    : ProfileView(
                        profile: state.profile,
                        onEdit: () => setState(() => _editing = true),
                      ),
                // TODO: resume upload — blocked on file_picker / compileSdk 36
                // conflict. Resume upload works on web; revisit when updating
                // the Android toolchain for release builds.
                // const SizedBox(height: AppSpacing.space3),
                // ResumeSection(state: state),
                const SizedBox(height: AppSpacing.space6),
                const ExternalCredentialsSection(),
              ],
            ),
          ),
      },
    );
  }
}

/// Indigo, not success-green — profile completeness is progress, not a
/// verified-skill signal (see AppColors' class doc: green is exclusive to
/// verified skills/badges/certificates).
class _CompletenessCard extends StatelessWidget {
  const _CompletenessCard({required this.profile});

  final CandidateProfile profile;

  @override
  Widget build(BuildContext context) {
    final completeness = profile.completeness.clamp(0, 100);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Profile completeness', style: AppTypography.titleSmall),
              Text(
                '$completeness%',
                style: AppTypography.mono(size: 15, weight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: completeness / 100,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Heads-up shown when the candidate would currently hit the apply-time
/// PROFILE_INCOMPLETE wall (fullName + (headline OR yearsOfExp) missing —
/// see CandidateProfile.readyToApply). Amber/warning, matching the same
/// semantic color the web employer view uses for its own "Profile
/// incomplete" badge — this is a heads-up, not an error or a success.
class _IncompleteProfileHint extends StatelessWidget {
  const _IncompleteProfileHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              "Add your name and either a headline or years of experience so "
              "employers can see who's applying — you'll need this to apply to jobs.",
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Links to the Badges tab — the only success-green usage on this screen,
/// since this specifically counts *verified* badges.
class _BadgeCountLink extends ConsumerWidget {
  const _BadgeCountLink();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesState = ref.watch(badgesControllerProvider);
    final count = badgesState is BadgesLoaded ? badgesState.badges.length : null;

    return AppCard(
      onTap: () => ref.read(rootTabIndexProvider.notifier).state = RootTab.badges,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space5, vertical: AppSpacing.space4),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Text(
              count == null
                  ? 'Verified badges'
                  : '$count verified badge${count == 1 ? '' : 's'}',
              style: AppTypography.bodyLarge,
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.errorBright),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: 'Retry', variant: AppButtonVariant.secondary, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
