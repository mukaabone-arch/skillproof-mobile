import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/external_link.dart';
import '../../core/web_handoff.dart';
import '../../models/assessment_catalog_entry.dart';
import '../../models/badge.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/usage_meter.dart';
import '../assessments/assessments_controller.dart';
import '../assessments/assessments_state.dart';
import '../assessments/widgets/assessment_catalog_card.dart';
import '../auth/auth_controller.dart';
import '../entitlements/entitlements_controller.dart';
import '../entitlements/entitlements_state.dart';
import '../profile/profile_controller.dart';
import '../profile/profile_repository.dart';
import '../profile/profile_state.dart';
import 'badges_controller.dart';
import 'badges_highlight_provider.dart';
import 'badges_state.dart';
import 'widgets/earned_badges_section.dart';

/// "Skills" (formerly "Badges"): what to verify next and what's already
/// verified. Layout, top to bottom:
///  1. A one-time "before your first skill check" form — only while the
///     profile isn't ready (name + headline or years). Previously that gate
///     was repeated on every catalog card with a disabled button; now it's
///     asked once, inline, and the cards below simply unlock when it's saved.
///  2. "Start here" — one recommended skill (the available one required on
///     the most roles the candidate is close to, per relevanceCount).
///  3. "More skills" — the rest of the catalog.
///  4. "Your badges" — earned badges, shown only when there are any.
/// Each section still loads and errors independently.
class BadgesScreen extends ConsumerStatefulWidget {
  const BadgesScreen({super.key});

  @override
  ConsumerState<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends ConsumerState<BadgesScreen> {
  final Map<String, GlobalKey> _cardKeys = {};
  String? _highlightedSkillId;
  String? _pendingHighlightSkillId;

  @override
  void initState() {
    super.initState();
    // Opened as a fresh page rather than kept alive in a tab stack, so a
    // highlight set just before opening (co-pilot "Close the gap") won't
    // reach the ref.listen below — read it once here instead.
    _pendingHighlightSkillId = ref.read(badgesHighlightSkillIdProvider);
    if (_pendingHighlightSkillId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(badgesHighlightSkillIdProvider.notifier).state = null,
      );
    }
  }

  GlobalKey _keyFor(String skillId) => _cardKeys.putIfAbsent(skillId, () => GlobalKey());

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(title: const Text('Skills')),
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
                        'to verify right now. Check back once new skill checks open up.',
                    actionLabel: 'Open skill checks',
                    onAction: () => _openAssessments(context),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.space4),
                children: [
                  Text(
                    'Prove a skill with a short check and earn a verified badge. Employers see every badge '
                    "you earn — it's verified skills, not self-reported ones, that drive your job matches.",
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  const _ProfileQuickForm(),
                  _AvailableSection(
                    state: assessmentsState,
                    keyFor: _keyFor,
                    highlightedSkillId: _highlightedSkillId,
                  ),
                  if (!earnedEmpty) ...[
                    const SizedBox(height: AppSpacing.space6),
                    Text('Your badges', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.space3),
                    EarnedBadgesSection(
                      state: badgesState,
                      onOpenCertificate: (b) => _openCertificate(context, b),
                    ),
                  ],
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
      await openWebAuthenticated('/assessments', () => ref.read(authRepositoryProvider).createWebSessionCode());
    } catch (_) {
      if (context.mounted) _showOpenFailedSnackBar(context, 'skill checks');
    }
  }

  void _showOpenFailedSnackBar(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open $what. Please try again.')),
    );
  }
}

/// The profile-readiness gate (CandidateProfile.readyToApply — name plus a
/// headline or years of experience; the API enforces the same rule on
/// assessment start), asked ONCE here instead of on every catalog card.
/// Renders nothing while the profile is loading, failed, or already ready.
class _ProfileQuickForm extends ConsumerStatefulWidget {
  const _ProfileQuickForm();

  @override
  ConsumerState<_ProfileQuickForm> createState() => _ProfileQuickFormState();
}

class _ProfileQuickFormState extends ConsumerState<_ProfileQuickForm> {
  final _name = TextEditingController();
  final _headline = TextEditingController();
  final _years = TextEditingController();
  bool _prefilled = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _years.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final headline = _headline.text.trim();
    final yearsText = _years.text.trim();
    final years = yearsText.isEmpty ? null : double.tryParse(yearsText);

    if (name.isEmpty) {
      setState(() => _error = 'Add your name.');
      return;
    }
    if (yearsText.isNotEmpty && (years == null || years < 0 || years > 60)) {
      setState(() => _error = 'Years of experience should be a number, like 2 or 3.5.');
      return;
    }
    if (headline.isEmpty && years == null) {
      setState(() => _error = 'Add a headline or your years of experience.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).update(
            fullName: name,
            headline: headline.isEmpty ? null : headline,
            yearsOfExp: years,
          );
      // Re-fetch so readyToApply flips and every card below unlocks.
      await ref.read(profileControllerProvider.notifier).load();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    if (profileState is! ProfileLoaded) return const SizedBox.shrink();
    final profile = profileState.profile;
    if (profile.readyToApply) return const SizedBox.shrink();

    if (!_prefilled) {
      _name.text = profile.fullName ?? '';
      _headline.text = profile.headline ?? '';
      _years.text = profile.yearsOfExp == null ? '' : _trimNumber(profile.yearsOfExp!);
      _prefilled = true;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: AppCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Before your first skill check', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space1),
            Text('Employers see these with your result.', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              controller: _name,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: AppSpacing.space2),
            TextField(
              controller: _headline,
              enabled: !_saving,
              decoration: const InputDecoration(labelText: 'Headline', hintText: 'e.g. ML engineer'),
            ),
            const SizedBox(height: AppSpacing.space2),
            TextField(
              controller: _years,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Years of experience'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
            ],
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: _saving ? 'Saving…' : 'Save & continue', expand: true, onPressed: _saving ? null : _save),
          ],
        ),
      ),
    );
  }

  static String _trimNumber(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}

class _AvailableSection extends ConsumerWidget {
  const _AvailableSection({required this.state, required this.keyFor, required this.highlightedSkillId});

  final AssessmentsState state;
  final GlobalKey Function(String skillId) keyFor;
  final String? highlightedSkillId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementsState = ref.watch(entitlementsControllerProvider);
    final entitlements = entitlementsState is EntitlementsLoaded ? entitlementsState.entitlements : null;

    // Assumed ready while the profile loads/fails (server enforces the real
    // gate) — same default as before. When NOT ready, the one-time
    // _ProfileQuickForm above explains why; the cards no longer each repeat it.
    final profileState = ref.watch(profileControllerProvider);
    final profile = profileState is ProfileLoaded ? profileState.profile : null;
    final profileReady = profile?.readyToApply ?? true;

    // Same FREE single-skill lock as before (mirrors web's CategorySection).
    final freeSkillLock =
        (entitlements != null && entitlements.tier == 'FREE' && entitlements.limits.singleSkillRestriction)
            ? entitlements.freeSkillLock
            : null;
    String? lockedFor(AssessmentCatalogEntry e) =>
        freeSkillLock != null && freeSkillLock.skillId != e.skillId ? freeSkillLock.skillName : null;

    Widget cardFor(AssessmentCatalogEntry entry, {bool recommended = false}) => Padding(
          key: keyFor(entry.skillId),
          padding: const EdgeInsets.only(bottom: AppSpacing.space3),
          child: AssessmentCatalogCard(
            entry: entry,
            highlighted: recommended || entry.skillId == highlightedSkillId,
            premium: entitlements?.isPremium ?? false,
            profileReady: profileReady,
            showProfileGateNotice: false,
            freeSkillLocked: lockedFor(entry),
            onTakeAssessment: () => _takeAssessment(context, ref, entry),
          ),
        );

    return switch (state) {
      AssessmentsLoading() => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.space4),
          child: Center(child: CircularProgressIndicator()),
        ),
      AssessmentsError(:final message) =>
        Text(message, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
      AssessmentsLoaded(:final entries) when entries.isEmpty =>
        Text('Nothing new to verify right now — check back later.', style: AppTypography.bodySmall),
      AssessmentsLoaded(:final entries) => () {
          final recommended = _pickRecommended(entries, lockedFor);
          final rest = [for (final e in entries) if (e.skillId != recommended?.skillId) e];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entitlements != null) ...[
                UsageMeter(
                  label: 'skill checks',
                  used: entitlements.assessmentsUsage.used,
                  limit: entitlements.assessmentsUsage.limit,
                  resetsAt: entitlements.assessmentsUsage.resetsAt,
                ),
                const SizedBox(height: AppSpacing.space4),
              ],
              if (recommended != null) ...[
                Text('START HERE', style: AppTypography.metaLabel(color: AppColors.primary)),
                const SizedBox(height: AppSpacing.space2),
                cardFor(recommended, recommended: true),
                const SizedBox(height: AppSpacing.space3),
              ],
              if (rest.isNotEmpty) ...[
                Text(recommended != null ? 'More skills' : 'Skills to verify', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.space3),
                for (final entry in rest) cardFor(entry),
              ],
            ],
          );
        }(),
    };
  }

  /// The available skill required on the most roles the candidate is close
  /// to (relevanceCount, from the catalog endpoint); ties keep catalog order.
  /// Skips skills a FREE candidate is locked out of. Null when nothing is
  /// startable (all in progress / cooling down / locked).
  static AssessmentCatalogEntry? _pickRecommended(
    List<AssessmentCatalogEntry> entries,
    String? Function(AssessmentCatalogEntry) lockedFor,
  ) {
    AssessmentCatalogEntry? best;
    for (final e in entries) {
      if (e.state != AssessmentCatalogState.available || lockedFor(e) != null) continue;
      if (best == null || e.relevanceCount > best.relevanceCount) best = e;
    }
    return best;
  }

  Future<void> _takeAssessment(BuildContext context, WidgetRef ref, AssessmentCatalogEntry entry) async {
    try {
      await ref.read(assessmentsControllerProvider.notifier).takeAssessment(entry);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the skill check. Please try again.')),
        );
      }
    }
  }
}
