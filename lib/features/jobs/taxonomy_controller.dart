import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/skill.dart';
import 'jobs_repository.dart';

/// Skill list backing the Browse tab's filter dropdown. Best-effort, like
/// web's own fetch (CandidateJobs.tsx: `.catch(() => undefined)`, no error
/// state stored) — filtering by skill is a convenience on top of Location/
/// Remote, never a blocking requirement to browse jobs at all, so a failed
/// fetch just leaves the dropdown at "Any skill" rather than showing an
/// error over the whole tab.
final taxonomySkillsProvider =
    StateNotifierProvider.autoDispose<TaxonomySkillsController, List<Skill>>((ref) {
  return TaxonomySkillsController(ref.read(jobsRepositoryProvider))..load();
});

class TaxonomySkillsController extends StateNotifier<List<Skill>> {
  TaxonomySkillsController(this._repository) : super(const []);

  final JobsRepository _repository;

  Future<void> load() async {
    try {
      state = await _repository.taxonomySkills();
    } catch (_) {
      // Best-effort — see provider doc comment.
    }
  }
}
