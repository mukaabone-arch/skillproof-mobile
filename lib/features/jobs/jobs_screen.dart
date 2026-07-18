import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/score_bar.dart';
import '../../widgets/skill_badge.dart';
import 'applications_controller.dart';
import 'browse_controller.dart';
import 'job_detail_screen.dart';
import 'jobs_state.dart';
import 'matched_controller.dart';
import 'widgets/job_card.dart';

/// Tabs: ranked matches, browse/search, and the candidate's own
/// applications. Each tab owns its own controller/state so switching tabs
/// doesn't re-trigger the others' network calls.
class JobsScreen extends StatelessWidget {
  const JobsScreen({super.key});

  /// Fixed three-tab labels, kept short enough to sit as equal thirds of
  /// the AppBar width without scrolling. The original labels ("Matched to
  /// you" / "My applications") clipped and overflowed on real narrow
  /// devices (reported on a Samsung A31, 1080px/~360dp-wide).
  static const List<String> _tabLabels = ['Matched', 'Browse', 'Applied'];
  static const EdgeInsets _tabLabelPadding = EdgeInsets.symmetric(horizontal: 8);

  @override
  Widget build(BuildContext context) {
    // TabBar isn't scrollable, so these three tabs always split the AppBar's
    // full width evenly — checked against the real screen width rather than
    // assumed, so this holds on any device rather than just the ones it was
    // eyeballed against. At the current labels/padding this comfortably
    // clears both the Samsung A31 (~411dp) and Android's 360dp "smallest
    // width" baseline (the narrowest width in common use) at the normal
    // labelMedium step — "Applied"/"Matched" (7 chars, the widest of the
    // three) measure well under a third of 360dp once label padding is
    // subtracted. If a future label change or a narrower device ever
    // doesn't clear it, this drops to the theme's next-smaller type step
    // (labelSmall) instead of clipping — never a hardcoded font size.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final tabLabelStyle =
        _fitsAtLabelMedium(screenWidth) ? AppTypography.labelMedium : AppTypography.labelSmall;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jobs'),
          bottom: TabBar(
            isScrollable: false,
            labelPadding: _tabLabelPadding,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textTertiary,
            indicatorColor: AppColors.primary,
            labelStyle: tabLabelStyle,
            unselectedLabelStyle: tabLabelStyle,
            tabs: [for (final label in _tabLabels) Tab(text: label)],
          ),
        ),
        body: const TabBarView(
          children: [
            _MatchedTab(),
            _BrowseTab(),
            _ApplicationsTab(),
          ],
        ),
      ),
    );
  }

  static bool _fitsAtLabelMedium(double screenWidth) {
    final perTabWidth = screenWidth / _tabLabels.length;
    final availableForText = perTabWidth - _tabLabelPadding.horizontal;
    final widest = _tabLabels
        .map((label) => _measureTextWidth(label, AppTypography.labelMedium))
        .reduce((a, b) => a > b ? a : b);
    return widest <= availableForText;
  }

  static double _measureTextWidth(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }
}

/// Application status pill color. APPLIED/REVIEWED/SHORTLISTED are all
/// "still in progress, moving forward" states, so they share the same
/// brand treatment as every other primary-action/progress color in the
/// app — this is intentional, not an oversight, and mirrors the design
/// system rule that success-green is reserved exclusively for verified
/// skills/badges/certificates (see AppColors' class doc), never for
/// application/progress states. REJECTED and WITHDRAWN are given their own
/// treatment rather than also defaulting to brand, since lumping a
/// rejection in with "still moving forward" would be actively misleading;
/// the web app has no equivalent per-status coloring to mirror (it renders
/// application status as plain meta text), so these were chosen to match
/// this app's own danger/neutral tokens.
({Color background, Color foreground}) _statusPillStyle(String status) {
  switch (status) {
    case 'REJECTED':
      return (background: AppColors.errorSoft, foreground: AppColors.errorBright);
    case 'WITHDRAWN':
      return (background: AppColors.surfaceElevated, foreground: AppColors.textSecondary);
    default: // APPLIED, REVIEWED, SHORTLISTED
      return (background: AppColors.primarySoft, foreground: AppColors.primary);
  }
}

void _openJob(BuildContext context, String jobId) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: jobId)),
  );
}

class _MatchedTab extends ConsumerWidget {
  const _MatchedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(matchedControllerProvider);

    return switch (state) {
      MatchedLoading() => const Center(child: CircularProgressIndicator()),
      MatchedError(:final message) => _ErrorRetry(
          message: message,
          onRetry: () => ref.read(matchedControllerProvider.notifier).load(),
        ),
      // The API returns an empty list specifically when the candidate has
      // no verified skill claim yet (see JobsRepository.matched) — that is
      // not the same as "no jobs exist", so it gets its own explanation
      // rather than rendering a blank list.
      MatchedLoaded(:final jobs) when jobs.isEmpty => const EmptyState(
          message: 'Job matches are based on your verified skills. '
              'Earn a badge to see roles that match you.',
        ),
      MatchedLoaded(:final jobs) => RefreshIndicator(
          onRefresh: () => ref.read(matchedControllerProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.space4),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final matchedJob = jobs[index];
              final verifiedMatches = matchedJob.matched.where((m) => m.verified).toList();
              return JobCard(
                job: matchedJob.job,
                onTap: () => _openJob(context, matchedJob.job.id),
                trailing: ScoreBar(score: matchedJob.score),
                child: verifiedMatches.isEmpty
                    ? null
                    : Wrap(
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space2,
                        children: [
                          for (final m in verifiedMatches.take(4))
                            SkillBadge(label: m.skillName, level: m.candidateLevel),
                        ],
                      ),
              );
            },
          ),
        ),
    };
  }
}

class _BrowseTab extends ConsumerStatefulWidget {
  const _BrowseTab();

  @override
  ConsumerState<_BrowseTab> createState() => _BrowseTabState();
}

class _BrowseTabState extends ConsumerState<_BrowseTab> {
  final _locationController = TextEditingController();
  bool _remoteOnly = false;

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _search() {
    ref.read(browseControllerProvider.notifier).search(
          location: _locationController.text.trim(),
          remote: _remoteOnly ? true : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browseControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _locationController,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    hintText: 'e.g. Bengaluru',
                  ),
                  onSubmitted: (_) => _search(),
                ),
                CheckboxListTile(
                  value: _remoteOnly,
                  onChanged: (value) => setState(() => _remoteOnly = value ?? false),
                  activeColor: AppColors.primary,
                  title: Text('Remote only', style: AppTypography.bodyLarge),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: AppSpacing.space2),
                AppButton(
                  label: 'Search',
                  busy: state is BrowseLoading,
                  expand: true,
                  onPressed: _search,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: switch (state) {
            BrowseLoading() => const Center(child: CircularProgressIndicator()),
            BrowseError(:final message) => _ErrorRetry(message: message, onRetry: _search),
            BrowseLoaded(:final jobs) when jobs.isEmpty =>
              const EmptyState(message: 'No jobs match those filters yet.'),
            BrowseLoaded(:final jobs, :final total) => ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  0,
                  AppSpacing.space4,
                  AppSpacing.space4,
                ),
                itemCount: jobs.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
                      child: Text(
                        '$total job${total == 1 ? '' : 's'} found',
                        style: AppTypography.bodySmall,
                      ),
                    );
                  }
                  final job = jobs[index - 1];
                  return JobCard(job: job, onTap: () => _openJob(context, job.id));
                },
              ),
          },
        ),
      ],
    );
  }
}

class _ApplicationsTab extends ConsumerWidget {
  const _ApplicationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applicationsControllerProvider);

    return switch (state) {
      ApplicationsLoading() => const Center(child: CircularProgressIndicator()),
      ApplicationsError(:final message) => _ErrorRetry(
          message: message,
          onRetry: () => ref.read(applicationsControllerProvider.notifier).load(),
        ),
      ApplicationsLoaded(:final applications) when applications.isEmpty =>
        const EmptyState(message: "You haven't applied to any jobs yet."),
      ApplicationsLoaded(:final applications) => RefreshIndicator(
          onRefresh: () => ref.read(applicationsControllerProvider.notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.space4),
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final application = applications[index];
              final statusStyle = _statusPillStyle(application.status);
              return AppCard(
                onTap: () => _openJob(context, application.jobId),
                padding: const EdgeInsets.all(AppSpacing.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(application.jobTitle, style: AppTypography.titleMedium)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space3,
                            vertical: AppSpacing.space1,
                          ),
                          decoration: BoxDecoration(
                            color: statusStyle.background,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            application.status,
                            style: AppTypography.monoLabel(color: statusStyle.foreground),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(application.orgName, style: AppTypography.bodySmall),
                    const SizedBox(height: AppSpacing.space1),
                    Text('Applied ${_formatDate(application.createdAt)}', style: AppTypography.bodySmall),
                  ],
                ),
              );
            },
          ),
        ),
    };
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
