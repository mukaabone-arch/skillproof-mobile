import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'help_models.dart';
import 'help_repository.dart';

const int maxQuestionChars = 1000;

/// Earlier turns sent with a new question — even, so the slice starts with a question.
const int _historyTurns = 18;

class HelpChatState {
  const HelpChatState({this.turns = const [], this.sending = false, this.error, this.consented});

  final List<HelpTurn> turns;
  final bool sending;
  final String? error;

  /// null while the stored answer is still loading.
  final bool? consented;

  HelpChatState copyWith({List<HelpTurn>? turns, bool? sending, String? error, bool clearError = false, bool? consented}) =>
      HelpChatState(
        turns: turns ?? this.turns,
        sending: sending ?? this.sending,
        error: clearError ? null : (error ?? this.error),
        consented: consented ?? this.consented,
      );
}

/// One conversation with the help assistant. autoDispose: leaving the Help
/// screen ends the conversation, so nothing carries over to another account
/// signed in on the same phone.
class HelpController extends StateNotifier<HelpChatState> {
  HelpController(this._repository, this._consent) : super(const HelpChatState()) {
    _loadConsent();
  }

  final HelpRepository _repository;
  final HelpConsentStore _consent;

  Future<void> _loadConsent() async {
    final ok = await _consent.hasConsented();
    if (mounted) state = state.copyWith(consented: ok);
  }

  Future<void> agree() async {
    state = state.copyWith(consented: true);
    await _consent.recordConsent();
  }

  /// Returns false when the question wasn't sent (empty, too long, or busy).
  Future<bool> ask(String question) async {
    final q = question.trim();
    if (q.isEmpty || state.sending) return false;
    if (q.length > maxQuestionChars) {
      state = state.copyWith(error: 'Please keep your question under $maxQuestionChars characters.');
      return false;
    }
    final before = state.turns;
    final withQuestion = [...before, HelpTurn.user(q)];
    state = state.copyWith(turns: withQuestion, sending: true, clearError: true);
    try {
      final sendable = withQuestion.length > _historyTurns + 1
          ? withQuestion.sublist(withQuestion.length - (_historyTurns + 1))
          : withQuestion;
      final answer = await _repository.ask(sendable);
      if (mounted) state = state.copyWith(turns: [...withQuestion, HelpTurn.assistant(answer)], sending: false);
      return true;
    } catch (e) {
      // Drop the unanswered question so the conversation keeps alternating.
      if (mounted) {
        state = state.copyWith(
          turns: before,
          sending: false,
          error: e is ApiException ? e.message : 'Something went wrong. Please try again.',
        );
      }
      return false;
    }
  }

  void startOver() => state = state.copyWith(turns: const [], clearError: true);
}

final helpControllerProvider = StateNotifierProvider.autoDispose<HelpController, HelpChatState>(
  (ref) => HelpController(ref.read(helpRepositoryProvider), ref.read(helpConsentStoreProvider)),
);
