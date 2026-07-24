import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/core/api_client.dart';
import 'package:skillproof/features/certifications/certifications_controller.dart';
import 'package:skillproof/features/certifications/certifications_repository.dart';
import 'package:skillproof/features/certifications/certifications_state.dart';
import 'package:skillproof/features/certifications/widgets/certification_form.dart';
import 'package:skillproof/features/certifications/widgets/certifications_section.dart';
import 'package:skillproof/models/certification.dart';
import 'package:skillproof/theme/app_theme.dart';

/// A controller whose state is set directly rather than fetched — these
/// tests are about layout at a phone width, not the load/save network path
/// (already covered structurally by mirroring ProfileEditForm/
/// AddCredentialForm's own validated patterns), so nothing here needs a
/// real repository or API call.
class _FixtureController extends CertificationsController {
  _FixtureController(CertificationsState initial)
      : super(CertificationsRepository(apiClient: ApiClient())) {
    state = initial;
  }
}

Certification _cert({
  required String id,
  required String name,
  required String issuer,
  String? issuerOther,
  required String verificationStatus,
  String? verificationSource,
  String? credentialUrl,
  String? fileUrl,
  DateTime? expiryDate,
  bool isExpiringSoon = false,
}) {
  return Certification.fromJson({
    'id': id,
    'name': name,
    'issuer': issuer,
    'issuerOther': issuerOther,
    'issueDate': DateTime(2024, 1, 15).toIso8601String(),
    'expiryDate': expiryDate?.toIso8601String(),
    'credentialId': null,
    'credentialUrl': credentialUrl,
    'fileUrl': fileUrl,
    'verificationStatus': verificationStatus,
    'verificationSource': verificationSource ?? 'URL',
    'skillTags': <String>[],
    'isExpiringSoon': isExpiringSoon,
    'createdAt': DateTime(2024, 1, 15).toIso8601String(),
    'updatedAt': DateTime(2024, 1, 15).toIso8601String(),
  });
}

Widget _host(Widget child, {required CertificationsState state, double height = 667}) {
  return ProviderScope(
    overrides: [
      certificationsControllerProvider.overrideWith((ref) => _FixtureController(state)),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(size: Size(375, height)),
        child: Scaffold(body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child)),
      ),
    ),
  );
}

void main() {
  setUp(() {});

  testWidgets('renders all four trust tiers and an expiring-soon indicator without overflow at 375 width',
      (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final certifications = [
      _cert(
        id: '1',
        name: 'AWS Certified Solutions Architect',
        issuer: 'CREDLY',
        verificationStatus: 'VERIFIED',
        verificationSource: 'CREDLY',
        credentialUrl: 'https://www.credly.com/badges/abc',
      ),
      _cert(
        id: '2',
        name: 'Project Management Professional (PMP)',
        issuer: 'PMI',
        verificationStatus: 'LINK_PROVIDED',
        credentialUrl: 'https://pmi.example.com/cert/2',
        expiryDate: now.add(const Duration(days: 30)),
        isExpiringSoon: true,
      ),
      _cert(
        id: '3',
        name: 'ITIL Foundation',
        issuer: 'OTHER',
        issuerOther: 'ITIL Training Co',
        verificationStatus: 'SELF_REPORTED',
        verificationSource: 'MANUAL_UPLOAD',
        fileUrl: '/profiles/me/certifications/3/file',
      ),
      _cert(
        id: '4',
        name: 'Scrum Master Certified',
        issuer: 'SCRUM_ALLIANCE',
        verificationStatus: 'EXPIRED',
        credentialUrl: 'https://example.com/cert/4',
        expiryDate: now.subtract(const Duration(days: 10)),
      ),
    ];

    await tester.pumpWidget(
      _host(const CertificationsSection(), state: CertificationsLoaded(certifications: certifications)),
    );
    await tester.pump();

    expect(find.text('Verified via Credly'), findsOneWidget);
    expect(find.text('Link provided — unverified'), findsOneWidget);
    expect(find.text('Candidate-provided'), findsOneWidget);
    expect(find.text('Expired'), findsOneWidget);
    expect(find.textContaining('Expires in'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('empty state renders without overflow at 375 width', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(const CertificationsSection(), state: const CertificationsLoaded(certifications: [])),
    );
    await tester.pump();

    expect(find.text('No certifications yet — add one above.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add form reveals the Other-issuer field and shows validation errors without overflow at 375 width',
      (tester) async {
    // Width is the dimension under test (see the isExpanded fix on the
    // issuer dropdown); height is generous so the dropdown's 13-item menu
    // renders in full instead of needing an in-popup scroll to reach 'Other'.
    tester.view.physicalSize = const Size(375, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _host(
        CertificationForm(onDone: () {}),
        state: const CertificationsLoaded(certifications: []),
        height: 1400,
      ),
    );
    await tester.pump();

    // Select "Other" from the issuer dropdown.
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    expect(find.text('Issuer name'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Submit empty: required-field and proof-of-credential errors surface.
    await tester.tap(find.text('Add certification'));
    await tester.pumpAndSettle();

    expect(find.text('Required.'), findsWidgets);
    expect(find.text('Provide either a credential URL or an upload (PNG/JPG).'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
