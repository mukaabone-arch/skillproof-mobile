import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/core/api_client.dart';
import 'package:myambii/core/store_policy.dart';
import 'package:myambii/features/help/help_assistant_screen.dart';
import 'package:myambii/features/help/help_controller.dart';
import 'package:myambii/features/help/help_models.dart';
import 'package:myambii/features/help/help_repository.dart';
import 'package:myambii/theme/app_theme.dart';

HelpAnswer _answer([String text = 'Open Assessments and pick a skill.']) => HelpAnswer(
      id: 'hq-1',
      answer: text,
      covered: true,
      sources: const [HelpSource(id: 'assessments', label: 'Taking an assessment')],
      guidePath: '/help/candidate',
    );

/// Never touches the network: [ask] and [report] are overridden.
class _FakeRepository extends HelpRepository {
  _FakeRepository({this.error}) : super(ApiClient(), platform: 'android');

  final Object? error;
  final List<List<Map<String, dynamic>>> sent = [];
  final List<String> reported = [];

  @override
  Future<HelpAnswer> ask(List<HelpTurn> conversation) async {
    sent.add([for (final t in conversation) t.toJson()]);
    if (error != null) throw error!;
    return _answer();
  }

  @override
  Future<void> report({required String answerId, required String reason, String? note}) async {
    reported.add('$answerId:$reason');
  }
}

class _FakeConsent extends HelpConsentStore {
  _FakeConsent(this.value);
  bool value;

  @override
  Future<bool> hasConsented() async => value;

  @override
  Future<void> recordConsent() async => value = true;
}

void main() {
  group('HelpController', () {
    test('sends the question and adds the answer', () async {
      final repo = _FakeRepository();
      final c = HelpController(repo, _FakeConsent(true));
      expect(await c.ask('  How do I get a badge?  '), isTrue);

      expect(repo.sent.single, [
        {'role': 'user', 'content': 'How do I get a badge?'},
      ]);
      expect(c.state.turns.map((t) => t.isUser), [true, false]);
      expect(c.state.turns.last.answer!.id, 'hq-1');
      expect(c.state.sending, isFalse);
    });

    test('sends earlier turns with a follow-up', () async {
      final repo = _FakeRepository();
      final c = HelpController(repo, _FakeConsent(true));
      await c.ask('First');
      await c.ask('Second');
      expect(repo.sent.last.map((m) => m['role']), ['user', 'assistant', 'user']);
    });

    test('keeps at most 19 messages, always starting with a question', () async {
      final repo = _FakeRepository();
      final c = HelpController(repo, _FakeConsent(true));
      for (var i = 0; i < 12; i++) {
        await c.ask('Q$i');
      }
      expect(repo.sent.last.length, 19);
      expect(repo.sent.last.first['role'], 'user');
      expect(repo.sent.last.last['content'], 'Q11');
    });

    test('on an error drops the question and shows the server message', () async {
      final c = HelpController(
        _FakeRepository(error: ApiException("You've reached today's limit for help questions.", 429)),
        _FakeConsent(true),
      );
      expect(await c.ask('One more'), isFalse);
      expect(c.state.turns, isEmpty);
      expect(c.state.error, contains("today's limit"));
    });

    test('refuses an over-long question without sending it', () async {
      final repo = _FakeRepository();
      final c = HelpController(repo, _FakeConsent(true));
      expect(await c.ask('x' * (maxQuestionChars + 1)), isFalse);
      expect(repo.sent, isEmpty);
      expect(c.state.error, isNotNull);
    });
  });

  group('HelpAssistantScreen', () {
    tearDown(() => debugMentionPaidPlansOverride = null);

    Future<_FakeRepository> pumpScreen(WidgetTester tester, {required bool consented}) async {
      tester.view.physicalSize = const Size(375, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      final repo = _FakeRepository();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          helpRepositoryProvider.overrideWithValue(repo),
          helpConsentStoreProvider.overrideWithValue(_FakeConsent(consented)),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const HelpAssistantScreen()),
      ));
      await tester.pumpAndSettle();
      return repo;
    }

    testWidgets('asks for agreement first, then shows starter questions', (tester) async {
      await pumpScreen(tester, consented: false);
      expect(find.text('Before you start'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      await tester.tap(find.text('Agree and continue'));
      await tester.pumpAndSettle();
      expect(find.text('How do I get my first verified badge?'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a starter question shows the answer, its guide section and Report', (tester) async {
      debugMentionPaidPlansOverride = true;
      final repo = await pumpScreen(tester, consented: true);

      await tester.tap(find.text('How does the live discussion work?'));
      await tester.pumpAndSettle();

      expect(repo.sent.single.single['content'], 'How does the live discussion work?');
      expect(find.text('Open Assessments and pick a skill.'), findsOneWidget);
      expect(find.text('Taking an assessment'), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('iOS: no links out to the web guide', (tester) async {
      debugMentionPaidPlansOverride = false;
      await pumpScreen(tester, consented: true);

      await tester.tap(find.text('How do I get my first verified badge?'));
      await tester.pumpAndSettle();

      expect(find.text('Open Assessments and pick a skill.'), findsOneWidget);
      expect(find.text('Taking an assessment'), findsNothing);
      expect(find.text('Report'), findsOneWidget);
    });

    testWidgets('Report sends the chosen reason for that answer', (tester) async {
      final repo = await pumpScreen(tester, consented: true);
      await tester.tap(find.text('How do I let recruiters find me?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Misleading or wrong'));
      await tester.pump();
      await tester.tap(find.text('Send report'));
      await tester.pumpAndSettle();

      expect(repo.reported, ['hq-1:MISLEADING']);
      expect(find.text('Thanks — reported. Our team will review it.'), findsOneWidget);
    });
  });
}
