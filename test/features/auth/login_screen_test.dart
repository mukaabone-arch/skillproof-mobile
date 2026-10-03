import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:myambii/core/api_client.dart';
import 'package:myambii/core/token_storage.dart';
import 'package:myambii/features/auth/auth_controller.dart';
import 'package:myambii/features/auth/auth_repository.dart';
import 'package:myambii/features/auth/login_screen.dart';
import 'package:myambii/models/user.dart';
import 'package:myambii/theme/app_theme.dart';

/// Keeps tests off the platform secure-storage channel: no stored session.
class _NoStoredTokens extends TokenStorage {
  @override
  Future<String?> readAccessToken() async => null;

  @override
  Future<String?> readRefreshToken() async => null;
}

/// Records which auth endpoints the screen called, and returns a canned
/// signed-in user from the verify calls. Nothing here touches the network
/// or secure storage.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository()
      : super(apiClient: ApiClient(), tokenStorage: TokenStorage());

  final emailRequests = <String>[];
  final phoneRequests = <String>[];
  final emailVerifies = <String>[];
  final phoneVerifies = <String>[];

  static final user = MyambiiUser.fromJson({
    'id': 'u1',
    'email': 'jane@example.com',
    'phone': null,
    'role': 'CANDIDATE',
    'isVerified': true,
  });

  @override
  Future<bool> hasStoredSession() async => false;

  @override
  Future<void> requestCandidateEmailOtp(String email) async => emailRequests.add(email);

  @override
  Future<void> requestOtp(String phone) async => phoneRequests.add(phone);

  @override
  Future<MyambiiUser> verifyCandidateEmailOtp({required String email, required String otp}) async {
    emailVerifies.add('$email:$otp');
    return user;
  }

  @override
  Future<MyambiiUser> verifyOtp({required String phone, required String otp}) async {
    phoneVerifies.add('$phone:$otp');
    return user;
  }
}

Future<_FakeAuthRepository> _pump(WidgetTester tester) async {
  final repo = _FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('defaults to the email tab and sends the OTP to the email endpoint', (tester) async {
    final repo = await _pump(tester);

    expect(find.text('Email'), findsWidgets);
    expect(find.text('Phone number'), findsNothing);
    // The +91 prefill belongs to the phone tab only.
    expect(find.text('+91'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), '  jane@example.com ');
    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pumpAndSettle();

    expect(repo.emailRequests, ['jane@example.com']);
    expect(repo.phoneRequests, isEmpty);
    expect(find.widgetWithText(FilledButton, 'Verify OTP'), findsOneWidget);
  });

  testWidgets('switching tabs after an OTP is sent clears the OTP state', (tester) async {
    await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'jane@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'OTP (dev: 123456)'), '123456');

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Send OTP'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'OTP (dev: 123456)'), findsNothing);
    expect(find.text('+91'), findsOneWidget);
  });

  testWidgets('a returning candidate signs in by email without the phone endpoints', (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'jane@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'OTP (dev: 123456)'), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Verify OTP'));
    await tester.pumpAndSettle();

    expect(repo.emailVerifies, ['jane@example.com:123456']);
    expect(repo.phoneVerifies, isEmpty);
  });

  testWidgets('phone tab still uses the phone endpoints', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Send OTP'));
    await tester.pumpAndSettle();

    expect(repo.phoneRequests, ['+91']);
    expect(repo.emailRequests, isEmpty);
  });

  test('requestCandidateEmailOtp posts to the candidate endpoint, not the employer one', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      return http.Response('{"message":"ok"}', 200, headers: {'content-type': 'application/json'});
    });
    final tokens = _NoStoredTokens();
    final repo = AuthRepository(
      apiClient: ApiClient(httpClient: client, tokenStorage: tokens),
      tokenStorage: tokens,
    );

    await repo.requestCandidateEmailOtp('jane@example.com');

    expect(paths, hasLength(1));
    expect(paths.single, endsWith('/auth/email/otp/request'));
    expect(paths.single, isNot(contains('/employer/')));
  });
}
