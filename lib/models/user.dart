class MyambiiUser {
  MyambiiUser({
    required this.id,
    required this.role,
    this.phone,
    this.email,
    this.phoneRequired = true,
  });

  factory MyambiiUser.fromJson(Map<String, dynamic> json) => MyambiiUser(
        id: json['id'] as String,
        role: json['role'] as String? ?? 'CANDIDATE',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        // Only GET /users/me sends this; sign-in responses don't, so it
        // defaults to the strict rule until /users/me says otherwise (see
        // AuthController._settle).
        phoneRequired: json['phoneRequired'] as bool? ?? true,
      );

  final String id;
  final String role;
  final String? phone;
  final String? email;

  /// From the API: a verified phone is required only in India (our SMS
  /// codes only reach Indian numbers). Elsewhere a verified email is enough.
  final bool phoneRequired;

  /// Mirrors the API's own gate — see candidate-verification-readiness.ts's
  /// isCandidateVerified: a verified email, plus a verified phone where one
  /// is required. A candidate missing either is blocked from every route
  /// except /users/me and /auth/* (see app.dart's routing off this getter).
  bool get isVerified => email != null && (phone != null || !phoneRequired);
}
