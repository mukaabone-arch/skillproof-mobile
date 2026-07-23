import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/core/api_client.dart';
import 'package:skillproof/features/jobs/job_detail_controller.dart';
import 'package:skillproof/features/jobs/jobs_repository.dart';
import 'package:skillproof/features/jobs/jobs_state.dart';
import 'package:skillproof/models/job.dart';
import 'package:skillproof/models/matched_job.dart';

Job _job({required bool alreadyApplied}) => Job(
      id: 'job-1',
      title: 'ML Engineer',
      orgName: 'Acme',
      location: 'Remote',
      remote: true,
      employmentType: 'FULL_TIME',
      experienceMin: null,
      experienceMax: null,
      requiredSkills: const [],
      alreadyApplied: alreadyApplied,
    );

SkillMatch _gap(String skillId) => SkillMatch(
      skillId: skillId,
      skillName: skillId,
      requiredLevel: 'L2',
      candidateLevel: null,
      verified: false,
    );

Job _jobWithId(String jobId) => Job(
      id: jobId,
      title: 'Some role',
      orgName: 'Acme',
      location: 'Remote',
      remote: true,
      employmentType: 'FULL_TIME',
      experienceMin: null,
      experienceMax: null,
      requiredSkills: const [],
      alreadyApplied: false,
    );

MatchedJob _matchedJob(String jobId, List<String> missingSkillIds) => MatchedJob(
      job: _jobWithId(jobId),
      score: 0,
      matched: const [],
      missing: missingSkillIds.map(_gap).toList(),
    );

/// [JobsRepository] wraps a real [ApiClient]; a real (never-invoked) one is
/// fine here since every method used by [JobDetailController] is overridden
/// below — same idiom as entitlements_controller_test.dart's fake.
class _FakeJobsRepository extends JobsRepository {
  _FakeJobsRepository({this.applyError, this.matchedJobs = const []}) : super(apiClient: ApiClient());

  final Object? applyError;
  final List<MatchedJob> matchedJobs;
  bool applied = false;

  @override
  Future<Job> browseOne(String id) async => _job(alreadyApplied: applied);

  @override
  Future<void> apply(String jobId) async {
    if (applyError != null) throw applyError!;
    applied = true;
  }

  @override
  Future<List<MatchedJob>> matched() async => matchedJobs;
}

void main() {
  group('JobDetailController.apply — entitlements refetch', () {
    // The API refunds quota on a downstream 4xx, so a caller must never
    // optimistically decrement a local counter — refetching after *every*
    // outcome (success or failure) is the only correct way to keep usage
    // meters elsewhere accurate. See onQuotaConsumingAction's own doc comment.
    test('refetches entitlements after a successful apply', () async {
      var quotaRefreshes = 0;
      final controller = JobDetailController(
        _FakeJobsRepository(),
        'job-1',
        onQuotaConsumingAction: () async => quotaRefreshes++,
      );
      await controller.load();

      await controller.apply();

      expect(quotaRefreshes, 1);
      final state = controller.state as JobDetailLoaded;
      expect(state.job.alreadyApplied, isTrue);
      expect(state.applyError, isNull);
    });

    test('still refetches entitlements when apply fails on a refunded 4xx', () async {
      var quotaRefreshes = 0;
      final controller = JobDetailController(
        _FakeJobsRepository(applyError: ApiException('Badge required', 400, {'code': 'BADGE_REQUIRED'})),
        'job-1',
        onQuotaConsumingAction: () async => quotaRefreshes++,
      );
      await controller.load();

      await controller.apply();

      expect(quotaRefreshes, 1);
      final state = controller.state as JobDetailLoaded;
      expect(state.applyIssueCode, 'BADGE_REQUIRED');
    });
  });

  group('JobDetailController.load — gap analysis', () {
    // 'skill-a' is missing for job-1 and two other matched jobs; 'skill-b'
    // is missing only for job-1. This is the "role impact" signal the
    // detailed-tier UI ranks by — a candidate missing 'skill-a' is blocked
    // from 3 roles, not just this one.
    test('skillFrequency counts occurrences across every matched job, not just this one', () async {
      final controller = JobDetailController(
        _FakeJobsRepository(matchedJobs: [
          _matchedJob('job-1', ['skill-a', 'skill-b']),
          _matchedJob('job-2', ['skill-a']),
          _matchedJob('job-3', ['skill-a', 'skill-c']),
        ]),
        'job-1',
        onQuotaConsumingAction: () async {},
      );

      await controller.load();

      final state = controller.state as JobDetailLoaded;
      expect(state.missing.map((m) => m.skillId), unorderedEquals(['skill-a', 'skill-b']));
      expect(state.skillFrequency['skill-a'], 3);
      expect(state.skillFrequency['skill-b'], 1);
      expect(state.skillFrequency.containsKey('skill-c'), isTrue); // present even though irrelevant to job-1
    });

    test('an empty matched-jobs response yields empty missing/skillFrequency, not an error', () async {
      final controller = JobDetailController(
        _FakeJobsRepository(matchedJobs: const []),
        'job-1',
        onQuotaConsumingAction: () async {},
      );

      await controller.load();

      final state = controller.state as JobDetailLoaded;
      expect(state.missing, isEmpty);
      expect(state.skillFrequency, isEmpty);
    });
  });
}
