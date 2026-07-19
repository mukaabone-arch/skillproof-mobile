import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/external_link.dart';
import '../../models/assessment_catalog_entry.dart';
import 'assessments_repository.dart';
import 'assessments_state.dart';

final assessmentsControllerProvider =
    StateNotifierProvider.autoDispose<AssessmentsController, AssessmentsState>((ref) {
  return AssessmentsController(ref.read(assessmentsRepositoryProvider))..load();
});

/// Opens a URL for a "Take assessment" tap. Real callers get
/// core/external_link.dart's openInBrowser; tests inject a fake so the
/// double-launch guard below can be verified without a platform channel.
typedef AssessmentLauncher = Future<void> Function(String url);

class AssessmentsController extends StateNotifier<AssessmentsState> {
  AssessmentsController(this._repository, {AssessmentLauncher? launcher})
      : _launch = launcher ?? openInBrowser,
        super(const AssessmentsLoading());

  final AssessmentsRepository _repository;
  final AssessmentLauncher _launch;

  /// Skill IDs with a launch currently in flight — guards a rapid
  /// double-tap on "Take assessment" from firing the browser intent twice
  /// for the same card. Per-skill rather than a single flag so launching
  /// one card never blocks a different one.
  final Set<String> _launching = {};

  Future<void> load() async {
    state = const AssessmentsLoading();
    try {
      final entries = await _repository.catalogSummary();
      state = AssessmentsLoaded(entries);
    } catch (e) {
      final message = _formatErrorMessage(e.toString());
      state = AssessmentsError(message);
    }
  }

  String _formatErrorMessage(String error) {
    // Provide user-friendly messages for common errors
    if (error.contains('404') || error.contains('Cannot GET')) {
      return 'Assessments not available right now. Please try again later.';
    }
    if (error.contains('401') || error.contains('Unauthorized')) {
      return 'Session expired. Please log in again.';
    }
    if (error.contains('Connection refused') || error.contains('Unable to connect')) {
      return 'Connection error. Check your internet and try again.';
    }
    return 'Failed to load assessments: $error';
  }

  Future<void> takeAssessment(AssessmentCatalogEntry entry) async {
    if (_launching.contains(entry.skillId)) return;
    _launching.add(entry.skillId);
    try {
      await _launch('${ApiConfig.webBaseUrl}${entry.webPath}');
    } finally {
      _launching.remove(entry.skillId);
    }
  }
}
