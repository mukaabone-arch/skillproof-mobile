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

/// [JobsRepository] wraps a real [ApiClient]; a real (never-invoked) one is
/// fine here since every method used by [JobDetailController] is overridden
/// below — same idiom as entitlements_controller_test.dart's fake.
class _FakeJobsRepository extends JobsRepository {
  _FakeJobsRepository({this.applyError}) : super(apiClient: ApiClient());

  final Object? applyError;
  bool applied = false;

  @override
  Future<Job> browseOne(String id) async => _job(alreadyApplied: applied);

  @override
  Future<void> apply(String jobId) async {
    if (applyError != null) throw applyError!;
    applied = true;
  }

  @override
  Future<List<MatchedJob>> matched() async => const [];
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
}
