import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myambii/features/profile/widgets/profile_edit_form.dart';
import 'package:myambii/models/profile.dart';
import 'package:myambii/theme/app_theme.dart';
import 'package:myambii/widgets/app_button.dart';

CandidateProfile _profile({String? location}) {
  return CandidateProfile(
    id: 'profile-1',
    fullName: 'Jordan Lee',
    email: 'jordan@example.com',
    headline: null,
    roleTitle: null,
    roleTitleOther: null,
    location: location,
    yearsOfExp: null,
    aiYearsOfExp: null,
    githubUrl: null,
    linkedinUrl: null,
    completeness: 50,
    hasResume: false,
    hasPhoto: false,
  );
}

Future<List<String>> _pump(WidgetTester tester, CandidateProfile profile) async {
  final handOffs = <String>[];
  // Wider than a phone on purpose. At 375px the pre-existing Role dropdown
  // overflows by ~139px (not caused by the location row), which fails the
  // harness's overflow check and would hide what these tests are for.
  tester.view.physicalSize = const Size(900, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        profileWebHandoffProvider.overrideWithValue((path) async => handOffs.add(path)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProfileEditForm(profile: profile, onDone: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return handOffs;
}

void main() {
  testWidgets('location is a read-only row, not an editable field', (tester) async {
    await _pump(tester, _profile(location: 'Mumbai, Maharashtra, IN'));

    expect(find.widgetWithText(TextFormField, 'Location'), findsNothing);
    expect(find.text('Mumbai, Maharashtra, IN'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Change on the web'), findsOneWidget);
  });

  testWidgets('an unset location says why it matters and offers to set it on the web', (tester) async {
    await _pump(tester, _profile());

    expect(find.text('Not set — set it on the web so employers can find you'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'Set on the web'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Location'), findsNothing);
  });

  testWidgets('tapping the location row hands off to /profile', (tester) async {
    final handOffs = await _pump(tester, _profile(location: 'Mumbai, Maharashtra, IN'));

    await tester.tap(find.widgetWithText(AppButton, 'Change on the web'));
    await tester.pumpAndSettle();

    expect(handOffs, ['/profile']);
  });
}
