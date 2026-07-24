import 'package:flutter_test/flutter_test.dart';
import 'package:skillproof/features/profile/profile_screen.dart';
import 'package:skillproof/models/profile.dart';

CandidateProfile _profile({
  String? headline,
  String? roleTitle,
  String? roleTitleOther,
  String? location,
}) {
  return CandidateProfile(
    id: 'profile-1',
    fullName: 'Jordan Lee',
    email: 'jordan@example.com',
    headline: headline,
    roleTitle: roleTitle,
    roleTitleOther: roleTitleOther,
    location: location,
    yearsOfExp: null,
    githubUrl: null,
    linkedinUrl: null,
    completeness: 50,
    hasResume: false,
    hasPhoto: false,
  );
}

void main() {
  group('profileSummary', () {
    test('joins headline, role title, and location when all three differ', () {
      final summary = profileSummary(
        _profile(headline: 'Builds ML pipelines', roleTitle: 'ML_ENGINEER', location: 'Remote'),
      );

      expect(summary, 'Builds ML pipelines · ML Engineer · Remote');
    });

    test('drops the role-title label when it just repeats the headline', () {
      // A candidate whose free-text headline and role-title picklist
      // selection are both "ML Engineer" — this used to render as
      // "ML Engineer · ML Engineer".
      final summary = profileSummary(
        _profile(headline: 'ML Engineer', roleTitle: 'ML_ENGINEER', location: 'Remote'),
      );

      expect(summary, 'ML Engineer · Remote');
    });

    test('still shows the role-title label when headline is unset', () {
      final summary = profileSummary(_profile(roleTitle: 'ML_ENGINEER', location: 'Remote'));

      expect(summary, 'ML Engineer · Remote');
    });

    test('falls back to a prompt when nothing is set', () {
      final summary = profileSummary(_profile());

      expect(summary, 'Tap to add your details');
    });
  });
}
