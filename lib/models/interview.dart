/// The job this interview pipeline is attached to — always present in
/// practice, but nullable in the API shape, so parsed defensively.
class InterviewJob {
  InterviewJob({required this.id, required this.title});

  factory InterviewJob.fromJson(Map<String, dynamic> json) {
    return InterviewJob(id: json['id'] as String, title: json['title'] as String);
  }

  final String id;
  final String title;
}

/// The candidate's view of only the *latest* round — GET /interviews/mine
/// deliberately never returns round history or a total round count (an
/// employer never commits to a number upfront), so there's nothing here to
/// show "round X of N" with. `status` is left as the API's raw string
/// (not a Dart enum) so an unrecognized value never throws — see the doc
/// on [Interview.stage] for why.
class CurrentRound {
  CurrentRound({required this.roundNumber, required this.status, this.channel, this.scheduledAt});

  factory CurrentRound.fromJson(Map<String, dynamic> json) {
    return CurrentRound(
      roundNumber: json['roundNumber'] as int,
      status: json['status'] as String,
      channel: json['channel'] as String?,
      scheduledAt: json['scheduledAt'] == null ? null : DateTime.parse(json['scheduledAt'] as String),
    );
  }

  final int roundNumber;
  final String status;
  // How to attend — a Zoom/Meet link, a phone number, or free text like
  // "we'll email you" (InterviewsService.present on the API side leaves
  // this unvalidated). The screen makes it tappable when it parses as an
  // http(s) URL; otherwise it's shown as plain text.
  final String? channel;
  final DateTime? scheduledAt;
}

/// One employer's pipeline for this candidate, as returned by
/// GET /interviews/mine. `stage` and `candidateResponse` are kept as the
/// API's raw strings rather than Dart enums: an unrecognized value (a
/// future stage this build doesn't know about yet) should still render —
/// falling back to the raw text — rather than throwing during parse or
/// crashing a switch. See widgets/interview_card.dart's label lookups for
/// the fallback behavior.
class Interview {
  Interview({
    required this.id,
    required this.orgName,
    required this.stage,
    required this.updatedAt,
    this.job,
    this.inviteMessage,
    this.currentRound,
    this.candidateResponse,
  });

  factory Interview.fromJson(Map<String, dynamic> json) {
    return Interview(
      id: json['id'] as String,
      orgName: json['orgName'] as String,
      job: json['job'] == null ? null : InterviewJob.fromJson(json['job'] as Map<String, dynamic>),
      stage: json['stage'] as String,
      inviteMessage: json['inviteMessage'] as String?,
      currentRound:
          json['currentRound'] == null ? null : CurrentRound.fromJson(json['currentRound'] as Map<String, dynamic>),
      candidateResponse: json['candidateResponse'] as String?,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String orgName;
  final InterviewJob? job;
  final String stage;
  final String? inviteMessage;
  final CurrentRound? currentRound;
  final String? candidateResponse;
  final DateTime updatedAt;

  /// The two action endpoints return a small patch, not the full entry —
  /// this applies one locally so the list updates without a full refetch.
  /// Deliberately rebuilds from scratch (not a field-by-field copyWith)
  /// so it's obvious at each call site exactly which field the patch
  /// covers.
  Interview withStage(String newStage) => Interview(
        id: id,
        orgName: orgName,
        job: job,
        stage: newStage,
        inviteMessage: inviteMessage,
        currentRound: currentRound,
        candidateResponse: candidateResponse,
        updatedAt: updatedAt,
      );

  Interview withCandidateResponse(String newResponse) => Interview(
        id: id,
        orgName: orgName,
        job: job,
        stage: stage,
        inviteMessage: inviteMessage,
        currentRound: currentRound,
        candidateResponse: newResponse,
        updatedAt: updatedAt,
      );
}
