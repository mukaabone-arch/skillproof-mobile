import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/web_handoff.dart';
import '../../models/assessment_catalog_entry.dart';
import '../auth/auth_controller.dart';
import 'assessments_repository.dart';
import 'assessments_state.dart';

final assessmentsControllerProvider =
    StateNotifierProvider.autoDispose<AssessmentsController, AssessmentsState>((ref) {
  return AssessmentsController(
    ref.read(assessmentsRepositoryProvider),
    launcher: (path) => openWebAuthenticated(path, () => ref.read(authRepositoryProvider).createWebSessionCode()),
  )..load();
});

/// Opens a web path for a "Take assessment" tap — real callers get
/// openWebAuthenticated (the mobile→web session bridge, so the browser
/// opens already signed in); tests inject a fake so the double-launch guard
/// below can be verified without a platform channel or a network call.
typedef AssessmentLauncher = Future<void> Function(String path);

class AssessmentsController extends StateNotifier<AssessmentsState> {
  AssessmentsController(this._repository, {required AssessmentLauncher launcher})
      : _launch = launcher,
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
      await _launch(entry.webPath);
    } finally {
      _launching.remove(entry.skillId);
    }
  }
}
