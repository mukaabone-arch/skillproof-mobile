/// Human-readable labels for the backend's `CredentialIssuer` enum —
/// mirrors apps/web/app/profile/page.tsx's ISSUER_LABELS exactly.
const Map<String, String> credentialIssuerLabels = {
  'CREDLY': 'Credly',
  'AWS': 'AWS',
  'GOOGLE': 'Google',
  'AZURE': 'Microsoft Azure',
  'NVIDIA': 'NVIDIA',
  'DATABRICKS': 'Databricks',
  'IBM': 'IBM',
  'OTHER': 'Unknown issuer',
};

/// A candidate-submitted, externally-issued credential (Credly badge, etc.)
/// — GET/POST /profiles/me/external-credentials. Kept entirely separate
/// from [VerifiedBadge]/skill claims: never mapped to the skill taxonomy,
/// never feeds match scoring. See the two-tier UI rule in
/// ExternalCredentialCard / CredentialStatusChip — this must never render
/// with the app's verified-green.
class ExternalCredential {
  ExternalCredential({
    required this.id,
    required this.issuer,
    required this.name,
    required this.credentialUrl,
    required this.verificationState,
    required this.verifiedAt,
    required this.issuedAt,
    required this.expiresAt,
  });

  factory ExternalCredential.fromJson(Map<String, dynamic> json) => ExternalCredential(
        id: json['id'] as String,
        issuer: json['issuer'] as String,
        name: json['name'] as String?,
        credentialUrl: json['credentialUrl'] as String,
        verificationState: json['verificationState'] as String,
        verifiedAt: _parseDate(json['verifiedAt']),
        issuedAt: _parseDate(json['issuedAt']),
        expiresAt: _parseDate(json['expiresAt']),
      );

  static DateTime? _parseDate(dynamic value) => value == null ? null : DateTime.parse(value as String);

  final String id;

  /// Raw `CredentialIssuer` enum value (e.g. 'IBM', 'OTHER') — use
  /// [issuerLabel] to display it.
  final String issuer;

  /// Null until a successful Credly fetch identifies the badge — a
  /// self-added URL starts with no name, same as the web app.
  final String? name;
  final String credentialUrl;

  /// Raw `CredentialVerificationState` enum value: PENDING | VERIFIED | FAILED.
  final String verificationState;
  final DateTime? verifiedAt;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  bool get isVerified => verificationState == 'VERIFIED';
  bool get isFailed => verificationState == 'FAILED';
  bool get isPending => verificationState == 'PENDING';

  String get issuerLabel => credentialIssuerLabels[issuer] ?? credentialIssuerLabels['OTHER']!;
}
