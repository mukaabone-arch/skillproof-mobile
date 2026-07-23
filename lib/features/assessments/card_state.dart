import '../../models/assessment_catalog_entry.dart';

/// What the catalog card actually renders for a given entry — the state
/// machine's only job is this mapping (available/in_progress/cooldown are
/// resolved server-side; nothing here re-derives them from raw dates).
/// Pure and dependency-free so it's unit-testable without a widget tree or
/// network access.
class AssessmentCardDisplay {
  const AssessmentCardDisplay({
    required this.state,
    required this.buttonLabel,
    required this.buttonEnabled,
    this.metaText,
  });

  final AssessmentCatalogState state;
  final String buttonLabel;
  final bool buttonEnabled;
  final String? metaText;
}

/// [premium] only changes the wording of the upgrade nudge below — the
/// button state/date logic is identical either way; retakesPerSkillLifetime
/// still applies on Premium too, just at a higher cap (see
/// plans.config.ts), so it's never framed as fully removed like the
/// cooldown is.
AssessmentCardDisplay resolveCardDisplay(AssessmentCatalogEntry entry, {bool premium = false}) {
  switch (entry.state) {
    case AssessmentCatalogState.available:
      return const AssessmentCardDisplay(
        state: AssessmentCatalogState.available,
        buttonLabel: 'Take assessment',
        buttonEnabled: true,
      );
    case AssessmentCatalogState.inProgress:
      return const AssessmentCardDisplay(
        state: AssessmentCatalogState.inProgress,
        buttonLabel: 'Assessment in progress',
        buttonEnabled: false,
        metaText: "You've already started this — finish it on the assessment site.",
      );
    case AssessmentCatalogState.cooldown:
      // Mirrors apps/api's entitlements README: a lifetime-cap breach always
      // has resetsAt (here, retakeAvailableAt) null — there is no reset —
      // while a cooldown always carries a real date. That's the only signal
      // this catalog entry gives for telling the two apart, since retake
      // attempts are never started in-app (see AssessmentsController), so
      // this app never sees the 402 LIMIT_REACHED shape that would otherwise
      // distinguish them by `metric`.
      final at = entry.retakeAvailableAt;
      if (at == null) {
        return AssessmentCardDisplay(
          state: AssessmentCatalogState.cooldown,
          buttonLabel: 'Take assessment',
          buttonEnabled: false,
          metaText: "You've used all retakes allowed for this skill — this cap doesn't reset."
              '${premium ? '' : ' Premium allows more retakes per skill.'}',
        );
      }
      // Explains *why* the retake is locked, not just the bare date —
      // mirrors apps/web's DiscussionAction cooldown copy.
      return AssessmentCardDisplay(
        state: AssessmentCatalogState.cooldown,
        buttonLabel: 'Take assessment',
        buttonEnabled: false,
        metaText: 'Retakes are limited so badges stay credible to employers — you can try again '
            'from ${_formatLocalDate(at)}.'
            '${premium ? '' : ' Premium removes retake cooldowns entirely.'}',
      );
  }
}

/// Same y-m-d style as BadgeCard._formatDate, applied to the local-time
/// conversion of the (UTC) retakeAvailableAt the API sends.
String _formatLocalDate(DateTime utc) {
  final local = utc.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
