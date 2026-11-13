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

  /// After sign-in, AuthController checks /users/me when the account still
  /// looks unverified (it learns there whether a phone is required). Answer
  /// from here so the test never reaches the real API client.
  @override
  Future<MyambiiUser> fetchMe() async => user;

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
  testWidgets('one field: an email goes to the email endpoint, and the code is verified there', (tester) async {
    final repo = await _pump(tester);

    expect(find.text('Email'), findsNothing); // no tabs any more
    await tester.enterText(find.widgetWithText(TextField, 'Email or mobile number'), '  jane@example.com ');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pumpAndSettle();

    expect(repo.emailRequests, ['jane@example.com']);
    expect(repo.phoneRequests, isEmpty);
    expect(find.text('We sent a code to jane@example.com', findRichText: true), findsOneWidget);

    // Six digits verify on their own — typed or filled in by the keyboard.
    await tester.enterText(find.widgetWithText(TextField, '6-digit code'), '123456');
    await tester.pumpAndSettle();
    expect(repo.emailVerifies, ['jane@example.com:123456']);
    expect(repo.phoneVerifies, isEmpty);
  });

  testWidgets('a mobile number goes to the phone endpoints, with +91 added to a bare 10-digit number', (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email or mobile number'), '98765 43210');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '6-digit code'), '654321');
    await tester.pumpAndSettle();

    expect(repo.phoneRequests, ['+919876543210']);
    expect(repo.phoneVerifies, ['+919876543210:654321']);
    expect(repo.emailRequests, isEmpty);
  });

  testWidgets('a number outside India is told to use email, with no request sent', (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email or mobile number'), '+1 732 309 5108');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pumpAndSettle();

    expect(find.text(kOutsideIndiaMessage), findsOneWidget);
    expect(repo.phoneRequests, isEmpty);
    expect(repo.emailRequests, isEmpty);
  });

  testWidgets('something that is neither is caught before any request', (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email or mobile number'), 'jane');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your email address or mobile number.'), findsOneWidget);
    expect(repo.emailRequests, isEmpty);
    expect(repo.phoneRequests, isEmpty);
  });

  testWidgets('changing the address after a code is sent drops the code', (tester) async {
    await _pump(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Email or mobile number'), 'jane@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Send code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '6-digit code'), '12');
    await tester.tap(find.text('Use a different email or number'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '6-digit code'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Send code'), findsOneWidget);
  });

  test('parseLoginIdentifier', () {
    expect(parseLoginIdentifier(' a@b.co '), isA<EmailIdentifier>());
    expect(parseLoginIdentifier('a@b'), isNull);
    expect((parseLoginIdentifier('+971 50 123 4567') as PhoneIdentifier).e164, '+971501234567');
    expect((parseLoginIdentifier('09876543210') as PhoneIdentifier).e164, '+919876543210');
    expect((parseLoginIdentifier('(987) 654-3210') as PhoneIdentifier).e164, '+919876543210');
    expect(parseLoginIdentifier('12345'), isNull);
    expect(parseLoginIdentifier(''), isNull);
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
