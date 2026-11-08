/// Shapes for POST /help/ask — see apps/api src/modules/help-assistant.
class HelpSource {
  const HelpSource({required this.id, required this.label});

  factory HelpSource.fromJson(Map<String, dynamic> json) =>
      HelpSource(id: json['id'] as String, label: json['label'] as String);

  final String id;
  final String label;
}

class HelpAnswer {
  const HelpAnswer({
    required this.id,
    required this.answer,
    required this.covered,
    required this.sources,
    required this.guidePath,
  });

  factory HelpAnswer.fromJson(Map<String, dynamic> json) => HelpAnswer(
        id: json['id'] as String,
        answer: json['answer'] as String,
        covered: json['covered'] as bool,
        sources: [
          for (final s in (json['sources'] as List<dynamic>? ?? const [])) HelpSource.fromJson(s as Map<String, dynamic>),
        ],
        guidePath: json['guidePath'] as String? ?? '/help/candidate',
      );

  /// HelpQuestion id — what a report of this answer points at.
  final String id;
  final String answer;

  /// False when the guide didn't cover the question.
  final bool covered;
  final List<HelpSource> sources;
  final String guidePath;
}

/// One message in the conversation. [answer] is set on assistant turns.
class HelpTurn {
  const HelpTurn.user(this.content)
      : isUser = true,
        answer = null;

  HelpTurn.assistant(HelpAnswer this.answer)
      : isUser = false,
        content = answer.answer;

  final bool isUser;
  final String content;
  final HelpAnswer? answer;

  Map<String, dynamic> toJson() => {'role': isUser ? 'user' : 'assistant', 'content': content};
}
