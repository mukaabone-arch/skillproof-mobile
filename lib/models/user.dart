class MyambiiUser {
  MyambiiUser({
    required this.id,
    required this.role,
    this.phone,
    this.email,
  });

  factory MyambiiUser.fromJson(Map<String, dynamic> json) => MyambiiUser(
        id: json['id'] as String,
        role: json['role'] as String? ?? 'CANDIDATE',
        phone: json['phone'] as String?,
        email: json['email'] as String?,
      );

  final String id;
  final String role;
  final String? phone;
  final String? email;

  /// Mirrors the API's own gate exactly — see
  /// candidate-verification-readiness.ts's isCandidateVerified: presence of
  /// both columns is the verified signal, there's no separate flag. A
  /// candidate missing either is blocked from every route except
  /// /users/me and /auth/* (see app.dart's routing off this getter).
  bool get isVerified => phone != null && email != null;
}
