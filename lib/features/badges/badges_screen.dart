import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/external_link.dart';
import '../../models/assessment_catalog_entry.dart';
import '../../models/badge.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/empty_state.dart';
import '../assessments/assessments_controller.dart';
import '../assessments/assessments_state.dart';
import '../assessments/widgets/assessment_catalog_card.dart';
import 'badges_controller.dart';
import 'badges_highlight_provider.dart';
import 'badges_state.dart';
import 'widgets/badge_card.dart';

/// The candidate's badges: what's earned (GET /users/me) and what's
/// available to verify (GET /assessments/catalog/summary). Each section
/// loads and errors independently — a slow/broken catalog fetch shouldn't
/// blank out badges the candidate has already earned, or vice versa.
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  final Map<String, GlobalKey> _cardKeys = {};
  String? _highlightedSkillId;
  String? _pendingHighlightSkillId;

  GlobalKey _keyFor(String skillId) => _cardKeys.putIfAbsent(skillId, () => GlobalKey());

  @override
  Widget build(BuildContext context) {
    // BadgesScreen is kept alive in RootScreen's IndexedStack, so it won't
    // rebuild from scratch on every tab switch — ref.listen (not a one-shot
    // initState read) is what lets a later CTA tap re-trigger the
    // scroll-and-highlight on an already-mounted screen.
    ref.listen<String?>(badgesHighlightSkillIdProvider, (previous, next) {
      if (next == null) return;
      _pendingHighlightSkillId = next;
      ref.read(badgesHighlightSkillIdProvider.notifier).state = null;
    });

    final badgesState = ref.watch(badgesControllerProvider);
    final assessmentsState = ref.watch(assessmentsControllerProvider);

    if (_pendingHighlightSkillId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryScrollToPending());
    }

    final earnedEmpty = badgesState is BadgesLoaded && badgesState.badges.isEmpty;
    final availableEmpty = assessmentsState is AssessmentsLoaded && assessmentsState.entries.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([
          ref.read(badgesControllerProvider.notifier).load(),
          ref.read(assessmentsControllerProvider.notifier).load(),
        ]),
        child: earnedEmpty && availableEmpty
            ? ListView(
                children: [
                  EmptyState(
                    message: "You haven't earned any verified badges yet, and there's nothing "
                        'to verify right now. Check back once new assessments open up.',
                    actionLabel: 'Open assessments',
                    onAction: () => _openAssessments(context),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [
                  Text('Earned', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.space3),
                  _EarnedSection(state: badgesState, onOpenCertificate: (b) => _openCertificate(context, b)),
                  const SizedBox(height: AppSpacing.space6),
                  Text('Available to verify', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.space3),
                  _AvailableSection(
                    state: assessmentsState,
                    keyFor: _keyFor,
                    highlightedSkillId: _highlightedSkillId,
                  ),
                ],
              ),
      ),
    );
  }

  void _tryScrollToPending() {
    final id = _pendingHighlightSkillId;
    if (id == null) return;
    final ctx = _cardKeys[id]?.currentContext;
    if (ctx == null) return; // catalog still loading — retried on the next build once it lands

    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 400), alignment: 0.15);
    setState(() {
      _highlightedSkillId = id;
      _pendingHighlightSkillId = null;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _highlightedSkillId = null);
    });
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

class _EarnedSection extends StatelessWidget {
  const _EarnedSection({required this.state, required this.onOpenCertificate});

  final BadgesState state;
  final void Function(VerifiedBadge) onOpenCertificate;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      BadgesLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
          child: Center(child: CircularProgressIndicator()),
        ),
      BadgesError(:final message) => Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
      BadgesLoaded(:final badges) when badges.isEmpty =>
        Text("No verified badges yet — earn one below.", style: AppTypography.bodySmall),
      BadgesLoaded(:final badges) => Column(
          children: [
            for (final badge in badges)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: BadgeCard(badge: badge, onTap: () => onOpenCertificate(badge)),
              ),
          ],
        ),
    };
  }
}

class _AvailableSection extends ConsumerWidget {
  const _AvailableSection({required this.state, required this.keyFor, required this.highlightedSkillId});

  final AssessmentsState state;
  final GlobalKey Function(String skillId) keyFor;
  final String? highlightedSkillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (state) {
      AssessmentsLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
          child: Center(child: CircularProgressIndicator()),
        ),
      AssessmentsError(:final message) =>
        Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
      AssessmentsLoaded(:final entries) when entries.isEmpty =>
        Text('Nothing new to verify right now — check back later.', style: AppTypography.bodySmall),
      AssessmentsLoaded(:final entries) => Column(
          children: [
            for (final entry in entries)
              Padding(
                key: keyFor(entry.skillId),
                padding: const EdgeInsets.only(bottom: AppSpacing.space3),
                child: AssessmentCatalogCard(
                  entry: entry,
                  highlighted: entry.skillId == highlightedSkillId,
                  onTakeAssessment: () => _takeAssessment(context, ref, entry),
                ),
              ),
          ],
        ),
    };
  }

  Future<void> _takeAssessment(BuildContext context, WidgetRef ref, AssessmentCatalogEntry entry) async {
    try {
      await ref.read(assessmentsControllerProvider.notifier).takeAssessment(entry);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the assessment. Please try again.')),
        );
      }
    }
  }
}
