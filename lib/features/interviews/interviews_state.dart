import '../../models/interview.dart';

sealed class InterviewsState {
  const InterviewsState();
}

class InterviewsLoading extends InterviewsState {
  const InterviewsLoading();
}

class InterviewsError extends InterviewsState {
  const InterviewsError(this.message);

  final String message;
}

class InterviewsLoaded extends InterviewsState {
  const InterviewsLoaded(this.interviews, {this.busyId, this.actionError});

  final List<Interview> interviews;

  /// The one interview with an accept/decline/offer-response action
  /// currently in flight — at most one at a time, so its card can show a
  /// busy state and disable its own buttons without touching any other
  /// card.
  final String? busyId;

  /// A message from the last failed action (e.g. the documented 409 when
  /// an offer has already moved past the OFFER stage by the time the
  /// candidate responded) — shown inline rather than replacing the list,
  /// and cleared on the next action attempt.
  final String? actionError;
}
