import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/application.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_card.dart';
import '../../badges/badges_controller.dart';
import '../../badges/badges_state.dart';
import '../../certifications/certifications_controller.dart';
import '../../certifications/certifications_state.dart';
import '../../jobs/applications_controller.dart';
import '../../jobs/jobs_state.dart';
import '../../profile/profile_controller.dart';
import '../../profile/profile_state.dart';
import '../../root/root_tab_provider.dart';

/// Three compact, independently-loading status tiles — mirrors the web
/// dashboard's `.status-grid`. Each card watches only the provider(s) it
/// needs, so a slow endpoint only stalls its own tile, never the whole row.
class StatusCardsRow extends StatelessWidget {
  const StatusCardsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ProfileStatusCard()),
        SizedBox(width: AppSpacing.space3),
        Expanded(child: _VerifiedSkillsStatusCard()),
        SizedBox(width: AppSpacing.space3),
        Expanded(child: _ApplicationsStatusCard()),
      ],
    );
  }
}

/// Shared compact shell: mono label, a big stat, a short meta line below.
class _StatusCardShell extends StatelessWidget {
  const _StatusCardShell({required this.label, required this.stat, required this.meta, this.onTap});

  final String label;
  final Widget stat;
  final Widget meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.metaLabel(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.space2),
          stat,
          const SizedBox(height: AppSpacing.space1),
          meta,
        ],
      ),
    );
  }
}

Widget _loadingStat() =>
    const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2));

Widget _errorStat() => const Icon(Icons.error_outline, color: AppColors.errorBright, size: 22);

Widget _loadingMeta() => Text('Loading…', style: AppTypography.bodySmall);

Widget _errorMeta() =>
    Text("Couldn't load", style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright));

class _ProfileStatusCard extends ConsumerWidget {
  const _ProfileStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);

    Widget stat;
    Widget meta;
    if (state is ProfileLoaded) {
      final completeness = state.profile.completeness.clamp(0, 100);
      stat = Text(
        '$completeness%',
        style: AppTypography.meta(size: 22, weight: FontWeight.w700, color: AppColors.primary),
      );
      meta = Text(
        completeness >= 100 ? 'Complete' : 'Add details',
        style: AppTypography.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else if (state is ProfileError) {
      stat = _errorStat();
      meta = _errorMeta();
    } else {
      stat = _loadingStat();
      meta = _loadingMeta();
    }

    return _StatusCardShell(
      label: 'Profile',
      stat: stat,
      meta: meta,
      onTap: () => ref.read(rootTabIndexProvider.notifier).state = RootTab.profile,
    );
  }
}

/// The one card that blends both proof tiers into a single count (per
/// spec: "verified skills count (badges + certifications)"). The headline
/// number itself is deliberately neutral (textPrimary), not green — it's a
/// mixed metric, not literally "a verified SkillProof skill" — and the
/// breakdown line underneath is the only place color appears, with green
/// reserved strictly for the actual badge sub-count and brand for the
/// verified-certification sub-count. This keeps the two-tier rule intact
/// even in a rolled-up summary tile: green never touches anything that
/// isn't a SkillProof-assessed badge.
class _VerifiedSkillsStatusCard extends ConsumerWidget {
  const _VerifiedSkillsStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesState = ref.watch(badgesControllerProvider);
    final certificationsState = ref.watch(certificationsControllerProvider);

    final loading = badgesState is BadgesLoading || certificationsState is CertificationsLoading;
    final hasError = badgesState is BadgesError || certificationsState is CertificationsError;

    Widget stat;
    Widget meta;

    if (loading) {
      stat = _loadingStat();
      meta = _loadingMeta();
    } else if (hasError) {
      stat = _errorStat();
      meta = _errorMeta();
    } else {
      final badgeCount = (badgesState as BadgesLoaded).badges.length;
      final certificationCount =
          (certificationsState as CertificationsLoaded).certifications.where((c) => c.isVerified).length;
      final total = badgeCount + certificationCount;

      stat = Text(
        '$total',
        style: AppTypography.meta(size: 22, weight: FontWeight.w700, color: AppColors.textPrimary),
      );
      meta = total == 0
          ? Text(
              'Earn a badge or add a certification',
              style: AppTypography.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          : Wrap(
              spacing: AppSpacing.space2,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (badgeCount > 0) _TierDot(label: '$badgeCount SkillProof', color: AppColors.success),
                if (certificationCount > 0)
                  _TierDot(label: '$certificationCount certified', color: AppColors.primary),
              ],
            );
    }

    return _StatusCardShell(
      label: 'Verified',
      stat: stat,
      meta: meta,
      onTap: () => ref.read(rootTabIndexProvider.notifier).state = RootTab.badges,
    );
  }
}

class _TierDot extends StatelessWidget {
  const _TierDot({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.bodySmall.copyWith(color: color)),
      ],
    );
  }
}

class _ApplicationsStatusCard extends ConsumerWidget {
  const _ApplicationsStatusCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applicationsControllerProvider);

    Widget stat;
    Widget meta;
    if (state is ApplicationsLoaded) {
      final count = state.applications.length;
      stat = Text(
        '$count',
        style: AppTypography.meta(size: 22, weight: FontWeight.w700, color: AppColors.primary),
      );
      meta = Text(
        count == 0 ? 'Browse jobs' : _statusSummary(state.applications),
        style: AppTypography.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } else if (state is ApplicationsError) {
      stat = _errorStat();
      meta = _errorMeta();
    } else {
      stat = _loadingStat();
      meta = _loadingMeta();
    }

    return _StatusCardShell(
      label: 'Applied',
      stat: stat,
      meta: meta,
      onTap: () => ref.read(rootTabIndexProvider.notifier).state = RootTab.jobs,
    );
  }

  String _statusSummary(List<Application> applications) {
    final counts = <String, int>{};
    for (final application in applications) {
      counts[application.status] = (counts[application.status] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.value} ${e.key.toLowerCase()}').join(', ');
  }
}
