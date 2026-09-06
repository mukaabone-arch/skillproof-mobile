/// GET /account/status's response — the same "employer-visibility flag, not
/// a lockout" deactivatedAt CandidateProfile carries, exposed as a plain
/// boolean plus the timestamp for display. See AccountService.deactivate's
/// own doc comment on what deactivation does and doesn't affect.
class AccountStatus {
  AccountStatus({required this.deactivated, required this.deactivatedAt});

  factory AccountStatus.fromJson(Map<String, dynamic> json) => AccountStatus(
        deactivated: json['deactivated'] as bool,
        deactivatedAt: json['deactivatedAt'] == null ? null : DateTime.parse(json['deactivatedAt'] as String),
      );

  final bool deactivated;
  final DateTime? deactivatedAt;
}
