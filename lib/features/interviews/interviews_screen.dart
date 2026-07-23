import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/interview.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/empty_state.dart';
import 'interviews_controller.dart';
import 'interviews_state.dart';
import 'widgets/interview_card.dart';
import 'widgets/interview_prep_section.dart';

/// The candidate's own view of every pipeline they're in, across every
/// employer — mirrors apps/web/components/CandidateInterviews.tsx. No
/// detail screen (there's no detail endpoint to back one); each card shows
/// everything GET /interviews/mine has for that employer.
class InterviewsScreen extends ConsumerWidget {
  const InterviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(interviewsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Interviews')),
      body: switch (state) {
        InterviewsLoading() => const Center(child: CircularProgressIndicator()),
        InterviewsError(:final message) => _ErrorRetry(
            message: message,
            onRetry: () => ref.read(interviewsControllerProvider.notifier).load(),
          ),
        InterviewsLoaded(:final interviews) when interviews.isEmpty => RefreshIndicator(
            onRefresh: () => ref.read(interviewsControllerProvider.notifier).load(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: const [
                EmptyState(
                  message: "No interviews yet — when an employer invites you, it'll show here.",
                ),
                SizedBox(height: AppSpacing.space4),
                InterviewPrepSection(),
              ],
            ),
          ),
        InterviewsLoaded(:final interviews, :final busyId, :final actionError) => _InterviewsList(
            interviews: interviews,
            busyId: busyId,
            actionError: actionError,
          ),
      },
    );
  }
}

class _InterviewsList extends ConsumerWidget {
  const _InterviewsList({required this.interviews, required this.busyId, required this.actionError});

  final List<Interview> interviews;
  final String? busyId;
  final String? actionError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(interviewsControllerProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.space4),
        children: [
          if (actionError != null) ...[
            Text(actionError!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
            const SizedBox(height: AppSpacing.space3),
          ],
          for (final interview in interviews)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space3),
              child: InterviewCard(
                interview: interview,
                busy: busyId == interview.id,
                onRespondInvite: (response) =>
                    ref.read(interviewsControllerProvider.notifier).respondInvite(interview.id, response),
                onRespondOffer: (response) =>
                    ref.read(interviewsControllerProvider.notifier).respondOffer(interview.id, response),
              ),
            ),
          const SizedBox(height: AppSpacing.space3),
          const InterviewPrepSection(),
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
