import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/external_link.dart';
import '../../models/badge.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import 'badges_controller.dart';
import 'badges_state.dart';
import 'widgets/badge_card.dart';

/// The candidate's verified badges — the payoff screen. Built entirely
/// from GET /users/me (see BadgesRepository); there is no dedicated
/// badges endpoint.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(badgesControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: switch (state) {
        BadgesLoading() => const Center(child: CircularProgressIndicator()),
        BadgesError(:final message) => _ErrorRetry(
            message: message,
            onRetry: () => ref.read(badgesControllerProvider.notifier).load(),
          ),
        // The common case for a new candidate — no verified skill claim
        // yet. Assessments (where a badge is earned) are deliberately
        // browser-only, so the CTA opens the web app rather than
        // navigating anywhere in this app.
        BadgesLoaded(:final badges) when badges.isEmpty => EmptyState(
            message: "You haven't earned any verified badges yet. "
                'Take an assessment to prove your skills.',
            actionLabel: 'Take an assessment',
            onAction: () => _openAssessments(context),
          ),
        BadgesLoaded(:final badges) => RefreshIndicator(
            onRefresh: () => ref.read(badgesControllerProvider.notifier).load(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.space4),
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                  child: BadgeCard(badge: badge, onTap: () => _openCertificate(context, badge)),
                );
              },
            ),
          ),
      },
    );
  }

  Future<void> _openCertificate(BuildContext context, VerifiedBadge badge) async {
    try {
      await openInBrowser('${ApiConfig.webBaseUrl}/badges/${badge.verifyHash}');
    } catch (_) {
      if (context.mounted) _showOpenFailedSnackBar(context, 'certificate');
    }
  }

  Future<void> _openAssessments(BuildContext context) async {
    try {
      await openInBrowser('${ApiConfig.webBaseUrl}/assessments');
    } catch (_) {
      if (context.mounted) _showOpenFailedSnackBar(context, 'assessments');
    }
  }

  void _showOpenFailedSnackBar(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open $what. Please try again.')),
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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.dangerBright),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: 'Retry', variant: AppButtonVariant.secondary, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
