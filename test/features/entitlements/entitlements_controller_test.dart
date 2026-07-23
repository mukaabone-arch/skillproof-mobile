import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/core/api_client.dart';
import 'package:skillproof/features/entitlements/entitlements_controller.dart';
import 'package:skillproof/features/entitlements/entitlements_repository.dart';
import 'package:skillproof/features/entitlements/entitlements_state.dart';
import 'package:skillproof/models/entitlements.dart';

Entitlements _entitlements({String tier = 'FREE', int? applicationsLimit = 10}) {
  return Entitlements(
    tier: tier,
    limits: PlanLimits(
      assessmentsPerMonth: 2,
      retakeCooldownDays: 60,
      retakesPerSkillLifetime: 1,
      applicationsPerMonth: applicationsLimit,
      profileViewers: 'count_only',
      applicationStatusDetail: false,
      searchRankBoost: 0,
      gapAnalysis: 'basic',
      resumeBranding: true,
      resumeTemplates: const ['default'],
      interviewPrep: false,
    ),
    assessmentsUsage: UsageEntry(used: 1, limit: 2, resetsAt: DateTime.utc(2026, 8, 1)),
    applicationsUsage: UsageEntry(used: 4, limit: applicationsLimit, resetsAt: DateTime.utc(2026, 8, 1)),
  );
}

/// [EntitlementsRepository] wraps a real [ApiClient]; a real (never-invoked)
/// one is fine here since [fetch] is overridden below and none of these
/// tests trigger an actual network call — same idiom as
/// assessments_controller_test.dart's `_unusedRepository()`.
class _FakeRepository extends EntitlementsRepository {
  _FakeRepository({this.result, this.error}) : super(apiClient: ApiClient());

  final Entitlements? result;
  final Object? error;

  @override
  Future<Entitlements> fetch() async {
    if (error != null) throw error!;
    return result!;
  }
}

void main() {
  group('EntitlementsController.load', () {
    test('starts loading, then exposes the fetched entitlements', () async {
      final controller = EntitlementsController(_FakeRepository(result: _entitlements(tier: 'PREMIUM')));
      expect(controller.state, isA<EntitlementsLoading>());

      await controller.load();

      final state = controller.state;
      expect(state, isA<EntitlementsLoaded>());
      expect((state as EntitlementsLoaded).entitlements.isPremium, isTrue);
    });

    test('an unlimited plan (limit: null) is carried through untouched', () async {
      final controller = EntitlementsController(_FakeRepository(result: _entitlements(applicationsLimit: null)));

      await controller.load();

      final state = controller.state as EntitlementsLoaded;
      expect(state.entitlements.applicationsUsage.limit, isNull);
    });

    test('surfaces ApiException.message, not a raw stack trace, on failure', () async {
      final controller = EntitlementsController(
        _FakeRepository(error: ApiException('Entitlements service unavailable', 503)),
      );

      await controller.load();

      final state = controller.state;
      expect(state, isA<EntitlementsError>());
      expect((state as EntitlementsError).message, 'Entitlements service unavailable');
    });
  });
}
