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

AssessmentCardDisplay resolveCardDisplay(AssessmentCatalogEntry entry) {
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
      final at = entry.retakeAvailableAt;
      return AssessmentCardDisplay(
        state: AssessmentCatalogState.cooldown,
        buttonLabel: 'Take assessment',
        buttonEnabled: false,
        metaText: at == null ? null : 'Retake available from ${_formatLocalDate(at)}',
      );
  }
}

/// Same y-m-d style as BadgeCard._formatDate, applied to the local-time
/// conversion of the (UTC) retakeAvailableAt the API sends.
String _formatLocalDate(DateTime utc) {
  final local = utc.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
