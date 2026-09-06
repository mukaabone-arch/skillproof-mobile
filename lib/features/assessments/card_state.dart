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
///
/// [profileReady] mirrors the same profile-readiness gate the backend
/// enforces on assessment start (PROFILE_INCOMPLETE_FOR_ASSESSMENT — see
/// CandidateProfile.readyToApply/readinessGateMessage, the same rule the
/// web catalog's Start button already gates on) and apps.web/app/
/// assessments/page.tsx's own "assumed ready until the profile actually
/// loads and says otherwise" default: true, so a ready candidate never
/// sees a flash of a disabled button while the profile is still loading.
/// Only the `available` case can ever be affected — inProgress/cooldown
/// are already disabled for their own unrelated reasons, and adding a
/// second, contradictory reason to an already-disabled button would only
/// confuse which explanation is the real one. metaText stays null here on
/// purpose (rather than carrying the gate message itself) — the caller
/// (AssessmentCatalogCard) renders an ActionableNotice with a "Go to
/// Profile" action instead of a plain Text in this specific case, so the
/// message lives there, not duplicated into this field too.
/// [freeSkillLocked] mirrors apps/web/app/assessments/page.tsx's
/// CategorySection: computed by the caller as `freeSkillLock.skillName`
/// whenever this entry's skill differs from the one skill a FREE candidate
/// already locked in, else null — this function never re-derives that
/// itself. Takes precedence over [profileReady] for the `available` case,
/// exactly like web: a locked-out skill is hidden from starting at all,
/// it doesn't queue up a second, less-relevant reason behind the profile
/// gate. Skills the candidate already holds a badge in are never `available`
/// in the first place (they're `inProgress`/earned elsewhere), so this can
/// never contradict a badge already on record.
AssessmentCardDisplay resolveCardDisplay(
  AssessmentCatalogEntry entry, {
  bool premium = false,
  bool profileReady = true,
  String? freeSkillLocked,
}) {
  switch (entry.state) {
    case AssessmentCatalogState.available:
      if (freeSkillLocked != null) {
        return const AssessmentCardDisplay(
          state: AssessmentCatalogState.available,
          buttonLabel: 'Take assessment',
          buttonEnabled: false,
        );
      }
      if (!profileReady) {
        return const AssessmentCardDisplay(
          state: AssessmentCatalogState.available,
          buttonLabel: 'Take assessment',
          buttonEnabled: false,
        );
      }
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
