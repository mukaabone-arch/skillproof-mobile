import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/external_link.dart';
import '../../models/badge.dart';
import '../../models/profile.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/collapsible_section.dart';
import '../auth/auth_controller.dart';
import '../badges/badges_controller.dart';
import '../badges/badges_state.dart';
import '../badges/widgets/earned_badges_section.dart';
import '../entitlements/entitlements_controller.dart';
import '../external_credentials/external_credentials_controller.dart';
import '../external_credentials/external_credentials_state.dart';
import '../external_credentials/widgets/external_credentials_section.dart';
import 'profile_controller.dart';
import 'profile_state.dart';
import 'profile_viewers_controller.dart';
import 'widgets/profile_edit_form.dart';
import 'widgets/profile_photo_section.dart';
import 'widgets/profile_view.dart';
import 'widgets/profile_viewers_section.dart';
import 'widgets/resume_export_card.dart';
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
    final credentialsState = ref.watch(externalCredentialsControllerProvider);
    final badgesState = ref.watch(badgesControllerProvider);

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
            onRefresh: () => Future.wait([
              ref.read(profileControllerProvider.notifier).load(),
              ref.read(profileViewersControllerProvider.notifier).load(),
              ref.read(entitlementsControllerProvider.notifier).load(),
            ]),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                ProfilePhotoSection(profile: state.profile),
                const SizedBox(height: AppSpacing.space3),
                _CompletenessCard(profile: state.profile),
                if (!state.profile.readyToApply) ...[
                  const SizedBox(height: AppSpacing.space3),
                  const _IncompleteProfileHint(),
                ],
                const SizedBox(height: AppSpacing.space3),
                CollapsibleSection(
                  title: 'Verified badges',
                  summary: _badgesSummary(badgesState),
                  child: EarnedBadgesSection(
                    state: badgesState,
                    onOpenCertificate: (b) => _openCertificate(context, b),
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                _editing
                    ? ProfileEditForm(
                        profile: state.profile,
                        onDone: () => setState(() => _editing = false),
                      )
                    : CollapsibleSection(
                        title: 'Profile details',
                        summary: _profileSummary(state.profile),
                        child: ProfileView(
                          profile: state.profile,
                          onEdit: () => setState(() => _editing = true),
                        ),
                      ),
                // TODO: resume upload — blocked on file_picker / compileSdk 36
                // conflict. Resume upload works on web; revisit when updating
                // the Android toolchain for release builds.
                // const SizedBox(height: AppSpacing.space3),
                // ResumeSection(state: state),
                const SizedBox(height: AppSpacing.space6),
                CollapsibleSection(
                  title: 'External credentials',
                  summary: _credentialsSummary(credentialsState),
                  child: const ExternalCredentialsSection(),
                ),
                const SizedBox(height: AppSpacing.space3),
                const CollapsibleSection(
                  title: 'Profile viewers',
                  child: ProfileViewersSection(),
                ),
                const SizedBox(height: AppSpacing.space3),
                const ResumeExportCard(),
              ],
            ),
          ),
      },
    );
  }

  /// Opens a badge's public certificate page in the device browser — same
  /// behavior as BadgesScreen's own certificate tap.
  Future<void> _openCertificate(BuildContext context, VerifiedBadge badge) async {
    try {
      await openInBrowser('${ApiConfig.webBaseUrl}/badges/${badge.verifyHash}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open certificate. Please try again.')),
        );
      }
    }
  }
}

/// Collapsed-state summary for the "Profile details" card — the same three
/// fields the web app's own compact profile chip leads with.
String _profileSummary(CandidateProfile profile) {
  final parts = [profile.headline, profile.roleTitleLabel, profile.location]
      .whereType<String>()
      .where((p) => p.trim().isNotEmpty)
      .toList();
  return parts.isEmpty ? 'Tap to add your details' : parts.join(' · ');
}

/// Collapsed-state summary for the "External credentials" card. Null while
/// still loading/errored, matching CollapsibleSection's "no summary line
/// yet" contract for that case.
String? _credentialsSummary(ExternalCredentialsState state) {
  if (state is! ExternalCredentialsLoaded) return null;
  final count = state.credentials.length;
  return count == 0 ? 'No external credentials yet' : '$count credential${count == 1 ? '' : 's'}';
}

/// Collapsed-state summary for the "Verified badges" card — same count
/// format as the standalone badge-count card this replaced. Null while
/// still loading/errored, matching the other two sections' contract.
String? _badgesSummary(BadgesState state) {
  if (state is! BadgesLoaded) return null;
  final count = state.badges.length;
  return '$count verified badge${count == 1 ? '' : 's'}';
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
                style: AppTypography.meta(size: 15, weight: FontWeight.w700, color: AppColors.primary),
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
