import '../../models/assessment_catalog_entry.dart';

sealed class AssessmentsState {
  const AssessmentsState();
}

class AssessmentsLoading extends AssessmentsState {
  const AssessmentsLoading();
}

class AssessmentsLoaded extends AssessmentsState {
  const AssessmentsLoaded(this.entries);

  final List<AssessmentCatalogEntry> entries;
}

class AssessmentsError extends AssessmentsState {
  const AssessmentsError(this.message);

  final String message;
}
