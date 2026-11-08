import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../core/external_link.dart';
import '../../core/store_policy.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import 'help_controller.dart';
import 'help_models.dart';
import 'help_repository.dart';

const _starters = [
  'How do I get my first verified badge?',
  'How does the live discussion work?',
  'What do I need before I can apply for jobs?',
  'How do I let recruiters find me?',
];

/// "Ask MyAmbii" — the signed-in help assistant, replacing the old Help
/// tile's trip to the web guide. Mirrors apps/web/components/help/
/// HelpAssistant.tsx: first-use AI notice, starter questions, answers with
/// the guide sections they came from, and Report on every answer.
///
/// iOS shows no links out to the web guide: those pages talk about the
/// paid plan, which the iOS app must not (see store_policy.dart). The API
/// also strips that topic from the guide it answers iOS questions from.
class HelpAssistantScreen extends ConsumerStatefulWidget {
  const HelpAssistantScreen({super.key});

  @override
  ConsumerState<HelpAssistantScreen> createState() => _HelpAssistantScreenState();
}

class _HelpAssistantScreenState extends ConsumerState<HelpAssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? text]) async {
    final question = text ?? _input.text;
    if (question.trim().isEmpty) return;
    _input.clear();
    final sent = await ref.read(helpControllerProvider.notifier).ask(question);
    if (!sent && mounted && _input.text.isEmpty) _input.text = question;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(helpControllerProvider);
    ref.listen(helpControllerProvider, (prev, next) {
      if (prev?.turns.length != next.turns.length || prev?.sending != next.sending) _scrollToEnd();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask MyAmbii'),
        actions: [
          if (state.turns.isNotEmpty)
            TextButton(
              onPressed: state.sending ? null : () => ref.read(helpControllerProvider.notifier).startOver(),
              child: const Text('New chat'),
            ),
        ],
      ),
      body: switch (state.consented) {
        null => const Center(child: CircularProgressIndicator()),
        false => _ConsentView(onAgree: () => ref.read(helpControllerProvider.notifier).agree()),
        true => SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    children: [
                      if (state.turns.isEmpty) _Welcome(onPick: state.sending ? null : _send),
                      for (final t in state.turns)
                        t.isUser ? _UserBubble(text: t.content) : _AnswerBubble(answer: t.answer!),
                      if (state.sending) const _Typing(),
                    ],
                  ),
                ),
                _Composer(
                  controller: _input,
                  sending: state.sending,
                  error: state.error,
                  onSend: () => _send(),
                ),
              ],
            ),
          ),
      },
    );
  }
}

class _ConsentView extends StatelessWidget {
  const _ConsentView({required this.onAgree});

  final VoidCallback onAgree;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space5),
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
          child: const Icon(Icons.support_agent_outlined, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text('Before you start', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.space3),
        Text(
          'Your questions are sent to our AI provider, Anthropic, to write an answer from the MyAmbii '
          "guides. Please don't include personal details such as phone numbers, passwords or one-time codes.",
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.space3),
        Text(
          'Answers are AI-generated and can be wrong. You can report any answer that looks wrong or harmful.',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.space5),
        AppButton(label: 'Agree and continue', onPressed: onAgree, expand: true),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});

  final ValueChanged<String>? onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Hi! Ask anything about using MyAmbii, or start with one of these:', style: AppTypography.bodyMedium),
        const SizedBox(height: AppSpacing.space3),
        for (final s in _starters)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: Material(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: onPick == null ? null : () => onPick!(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space3),
                  child: Text(s, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3, left: AppSpacing.space7),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space2 + 2),
        decoration: const BoxDecoration(
          color: AppColors.primaryFill,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text, style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
      ),
    );
  }
}

class _AnswerBubble extends StatelessWidget {
  const _AnswerBubble({required this.answer});

  final HelpAnswer answer;

  Future<void> _openSource(BuildContext context, HelpSource s) async {
    try {
      await openInBrowser('${ApiConfig.webBaseUrl}${answer.guidePath}#${s.id}');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the guide. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space3, right: AppSpacing.space5),
        padding: const EdgeInsets.fromLTRB(AppSpacing.space3, AppSpacing.space3, AppSpacing.space3, AppSpacing.space1),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(answer.answer, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
            if (mentionPaidPlans && answer.sources.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space3),
              Text('From the guide:', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.space1),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: AppSpacing.space1,
                children: [
                  for (final s in answer.sources)
                    ActionChip(
                      label: Text(s.label),
                      labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.primaryMuted),
                      side: const BorderSide(color: AppColors.border),
                      backgroundColor: Colors.transparent,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _openSource(context, s),
                    ),
                ],
              ),
            ],
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => showReportHelpAnswerSheet(context, answer.id),
                icon: const Icon(Icons.outlined_flag, size: 16),
                label: const Text('Report'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  textStyle: AppTypography.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: 'Writing an answer',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4, vertical: AppSpacing.space3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.sending, required this.error, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final String? error;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space3, AppSpacing.space4, AppSpacing.space3),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null) ...[
            Text(error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
            const SizedBox(height: AppSpacing.space2),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: maxQuestionChars,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(hintText: 'Ask a question…', counterText: ''),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) => IconButton.filled(
                  tooltip: 'Send',
                  onPressed: sending || controller.text.trim().isEmpty ? null : onSend,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          Text('AI answers can be wrong.', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}

const _reasons = [
  ('OFFENSIVE', 'Offensive or harmful'),
  ('HATEFUL', 'Hateful or discriminatory'),
  ('SEXUAL', 'Sexual or inappropriate'),
  ('DANGEROUS', 'Dangerous or illegal'),
  ('MISLEADING', 'Misleading or wrong'),
  ('OTHER', 'Something else'),
];

/// Report one assistant answer — same reasons as the web's ReportAiContent.
Future<void> showReportHelpAnswerSheet(BuildContext context, String answerId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReportSheet(answerId: answerId),
  );
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.answerId});

  final String answerId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  String? _reason;
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      setState(() => _error = "Choose what's wrong with this answer.");
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(helpRepositoryProvider).report(answerId: widget.answerId, reason: _reason!, note: _note.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Thanks — reported. Our team will review it.')));
    } catch (e) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space4,
        0,
        AppSpacing.space4,
        AppSpacing.space4 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text("What's wrong with this answer?", style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.space2),
            for (final (value, label) in _reasons)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  _reason == value ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: _reason == value ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                onTap: _sending ? null : () => setState(() => _reason = value),
              ),
            const SizedBox(height: AppSpacing.space2),
            TextField(
              controller: _note,
              maxLength: 1000,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Anything else we should know? (optional)', counterText: ''),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
            ],
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: 'Send report', onPressed: _submit, busy: _sending, expand: true),
          ],
        ),
      ),
    );
  }
}
