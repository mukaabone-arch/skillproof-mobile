/// Staffing companies — the candidate's side (mirrors apps/web/lib/staffing.ts).
/// Verified staffing companies can find opted-in candidates anonymised; a
/// candidate's name and contact details are shared only with a company whose
/// availability request they accept.

const Map<String, String> workTypeLabels = {
  'PERMANENT': 'Permanent',
  'CONTRACT': 'Contract',
  'CONTRACT_TO_HIRE': 'Contract-to-hire',
};

const Map<String, String> availabilityLabels = {
  'AVAILABLE_NOW': 'Available now',
  'AVAILABLE_FROM': 'Available from a date',
  'NOTICE_PERIOD': 'Serving a notice period',
  'NOT_LOOKING': 'Not looking right now',
};

const Map<String, String> rateUnitLabels = {
  'ANNUAL': 'per year',
  'MONTHLY': 'per month',
  'DAILY': 'per day',
  'HOURLY': 'per hour',
};

const Map<String, String> requestStatusLabels = {
  'PENDING': 'Waiting for your reply',
  'AVAILABLE': 'You said available',
  'CONDITIONAL': 'You said yes, with conditions',
  'NOT_NOW': 'You said not right now',
  'WITHDRAWN': 'Withdrawn by the company',
  'EXPIRED': 'Expired',
};

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;
int? _int(Object? v) => v is num ? v.toInt() : null;

String _inr(int n) {
  // Indian grouping: 12,34,567
  final s = n.toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

String? formatRate(int? min, int? max, String? unit) {
  if (min == null && max == null) return null;
  final range = min != null && max != null
      ? '${_inr(min)}–${_inr(max)}'
      : min != null
          ? 'from ${_inr(min)}'
          : 'up to ${_inr(max!)}';
  return unit != null ? '$range ${rateUnitLabels[unit] ?? ''}'.trim() : range;
}

class StaffingAvailability {
  StaffingAvailability({
    required this.openToStaffing,
    required this.availabilityStatus,
    required this.availableFrom,
    required this.noticePeriodDays,
    required this.workTypes,
    required this.expectedRateMinInr,
    required this.expectedRateMaxInr,
    required this.expectedRateUnit,
    required this.availabilityConfirmedAt,
    required this.fresh,
    required this.freshDays,
  });

  factory StaffingAvailability.fromJson(Map<String, dynamic> json) => StaffingAvailability(
        openToStaffing: json['openToStaffing'] as bool? ?? false,
        availabilityStatus: json['availabilityStatus'] as String?,
        availableFrom: _date(json['availableFrom']),
        noticePeriodDays: _int(json['noticePeriodDays']),
        workTypes: ((json['workTypes'] as List<dynamic>?) ?? const []).cast<String>(),
        expectedRateMinInr: _int(json['expectedRateMinInr']),
        expectedRateMaxInr: _int(json['expectedRateMaxInr']),
        expectedRateUnit: json['expectedRateUnit'] as String?,
        availabilityConfirmedAt: _date(json['availabilityConfirmedAt']),
        fresh: json['fresh'] as bool? ?? false,
        freshDays: _int(json['freshDays']) ?? 30,
      );

  final bool openToStaffing;
  final String? availabilityStatus;
  final DateTime? availableFrom;
  final int? noticePeriodDays;
  final List<String> workTypes;
  final int? expectedRateMinInr;
  final int? expectedRateMaxInr;
  final String? expectedRateUnit;
  final DateTime? availabilityConfirmedAt;

  /// Confirmed within [freshDays] — otherwise staffing companies can't see the candidate.
  final bool fresh;
  final int freshDays;

  /// Opted in but stale: hidden from staffing search until confirmed.
  bool get needsConfirming => openToStaffing && !fresh;

  /// Hidden already, or will be within 4 days — when Home shows "Still available?"
  /// (same lead time as the API's reminder email, REMINDER_LEAD_DAYS).
  bool get confirmSoon => openToStaffing && (!fresh || (daysSinceConfirmed ?? 0) >= freshDays - 4);

  int? get daysSinceConfirmed =>
      availabilityConfirmedAt == null ? null : DateTime.now().difference(availabilityConfirmedAt!).inDays;

  String get availabilityText {
    switch (availabilityStatus) {
      case 'AVAILABLE_NOW':
        return 'Available now';
      case 'AVAILABLE_FROM':
        final d = availableFrom;
        return d == null ? 'Available from a date' : 'Available from ${d.day}/${d.month}/${d.year}';
      case 'NOTICE_PERIOD':
        return noticePeriodDays == null ? 'Notice period' : '$noticePeriodDays-day notice period';
      case 'NOT_LOOKING':
        return 'Not looking right now';
      default:
        return 'Not set';
    }
  }

  /// One line for the collapsed Profile section header.
  String get summary => !openToStaffing ? 'Off' : (needsConfirming ? 'On · needs confirming' : 'On · $availabilityText');
}

class StaffingRequest {
  StaffingRequest({
    required this.id,
    required this.orgId,
    required this.orgName,
    required this.roleTitle,
    required this.summary,
    required this.workType,
    required this.rateMinInr,
    required this.rateMaxInr,
    required this.rateUnit,
    required this.location,
    required this.remote,
    required this.clientName,
    required this.clientIndustry,
    required this.status,
    required this.candidateMessage,
    required this.expiresAt,
  });

  factory StaffingRequest.fromJson(Map<String, dynamic> json) => StaffingRequest(
        id: json['id'] as String,
        orgId: json['orgId'] as String? ?? '',
        orgName: json['orgName'] as String? ?? 'A staffing company',
        roleTitle: json['roleTitle'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        workType: json['workType'] as String? ?? '',
        rateMinInr: _int(json['rateMinInr']),
        rateMaxInr: _int(json['rateMaxInr']),
        rateUnit: json['rateUnit'] as String?,
        location: json['location'] as String?,
        remote: json['remote'] as bool? ?? false,
        clientName: json['clientName'] as String?,
        clientIndustry: json['clientIndustry'] as String?,
        status: json['status'] as String? ?? 'PENDING',
        candidateMessage: json['candidateMessage'] as String?,
        expiresAt: _date(json['expiresAt']) ?? DateTime.now(),
      );

  final String id;
  final String orgId;
  final String orgName;
  final String roleTitle;
  final String summary;
  final String workType;
  final int? rateMinInr;
  final int? rateMaxInr;
  final String? rateUnit;
  final String? location;
  final bool remote;
  final String? clientName;
  final String? clientIndustry;
  final String status;
  final String? candidateMessage;
  final DateTime expiresAt;

  bool get isOpen => status == 'PENDING' && expiresAt.isAfter(DateTime.now());

  String get clientLine =>
      clientName ?? (clientIndustry != null ? 'A client in $clientIndustry' : 'Client not named yet');

  StaffingRequest withStatus(String next, String? message) => StaffingRequest(
        id: id,
        orgId: orgId,
        orgName: orgName,
        roleTitle: roleTitle,
        summary: summary,
        workType: workType,
        rateMinInr: rateMinInr,
        rateMaxInr: rateMaxInr,
        rateUnit: rateUnit,
        location: location,
        remote: remote,
        clientName: clientName,
        clientIndustry: clientIndustry,
        status: next,
        candidateMessage: message,
        expiresAt: expiresAt,
      );
}
