import 'package:flutter/material.dart';

import '../../../core/external_link.dart';
import '../../../models/interview.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';

/// One employer's pipeline. Deliberately calmer than a job/badge card — no
/// tap-through to a detail screen, since there is no detail endpoint (see
/// InterviewsRepository doc); everything the candidate needs is already
/// here. Stage-specific content mirrors apps/web/components/
/// CandidateInterviews.tsx section-for-section: an INVITED card leads with
/// Accept/Decline, INTERVIEWING shows the current (and only the current)
/// round, OFFER shows the response actions once, and terminal stages
/// (HIRED/DECLINED/REJECTED/CLOSED) just state the outcome.
class InterviewCard extends StatelessWidget {
  const InterviewCard({
    required this.interview,
    required this.busy,
    required this.onRespondInvite,
    required this.onRespondOffer,
    super.key,
  });

  final Interview interview;
  final bool busy;
  final void Function(String response) onRespondInvite;
  final void Function(String response) onRespondOffer;

  @override
  Widget build(BuildContext context) {
    final stagePill = _stagePillStyle(interview.stage);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(interview.orgName, style: AppTypography.titleMedium)),
              const SizedBox(width: AppSpacing.space2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3, vertical: AppSpacing.space1),
                decoration: BoxDecoration(
                  color: stagePill.background,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(_stageLabel(interview.stage), style: AppTypography.metaLabel(color: stagePill.foreground)),
              ),
            ],
          ),
          if (interview.job != null) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(interview.job!.title, style: AppTypography.bodySmall),
          ],
          ..._stageBody(context),
        ],
      ),
    );
  }

  List<Widget> _stageBody(BuildContext context) {
    switch (interview.stage) {
      case 'INVITED':
        return [
          const SizedBox(height: AppSpacing.space3),
          if (interview.inviteMessage != null && interview.inviteMessage!.isNotEmpty) ...[
            Text('"${interview.inviteMessage}"', style: AppTypography.bodyMedium),
            const SizedBox(height: AppSpacing.space3),
          ],
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Accept',
                  busy: busy,
                  onPressed: busy ? null : () => onRespondInvite('ACCEPT'),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: AppButton(
                  label: 'Decline',
                  variant: AppButtonVariant.secondary,
                  busy: busy,
                  onPressed: busy ? null : () => _confirmDecline(context),
                ),
              ),
            ],
          ),
        ];

      case 'INTERVIEWING':
        final round = interview.currentRound;
        return [
          const SizedBox(height: AppSpacing.space3),
          if (round == null)
            Text(
              "You're in — the employer will schedule your first round soon.",
              style: AppTypography.bodyMedium,
            )
          else
            _RoundDetails(round: round),
        ];

      case 'OFFER':
        if (interview.candidateResponse != null) {
          return [
            const SizedBox(height: AppSpacing.space3),
            Text(
              'Your response: ${_responseLabel(interview.candidateResponse!)}',
              style: AppTypography.bodyMedium,
            ),
          ];
        }
        return [
          const SizedBox(height: AppSpacing.space3),
          Text("You've received an offer. Let them know where you stand:", style: AppTypography.bodyMedium),
          const SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Accept',
                  busy: busy,
                  onPressed: busy ? null : () => onRespondOffer('ACCEPTED'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Still deciding',
                  variant: AppButtonVariant.secondary,
                  busy: busy,
                  onPressed: busy ? null : () => onRespondOffer('NEGOTIATING'),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: AppButton(
                  label: 'Decline',
                  variant: AppButtonVariant.secondary,
                  busy: busy,
                  onPressed: busy ? null : () => onRespondOffer('DECLINED'),
                ),
              ),
            ],
          ),
        ];

      case 'HIRED':
      case 'CLOSED':
        if (interview.candidateResponse == null) return const [];
        return [
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Your response was: ${_responseLabel(interview.candidateResponse!)}',
            style: AppTypography.bodyMedium,
          ),
        ];

      // SHORTLISTED, DECLINED, REJECTED, and any stage this build doesn't
      // recognize yet — the stage pill above already says everything
      // there is to say.
      default:
        return const [];
    }
  }

  Future<void> _confirmDecline(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Decline this invite?'),
        content: const Text('This ends the pipeline with this employer.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Decline')),
        ],
      ),
    );
    if (confirmed == true) onRespondInvite('DECLINE');
  }
}

String _stageLabel(String stage) {
  switch (stage) {
    case 'SHORTLISTED':
      return 'On their shortlist';
    case 'INVITED':
      return 'Invited to interview';
    case 'INTERVIEWING':
      return 'Interviewing';
    case 'OFFER':
      return 'Offer extended';
    case 'HIRED':
      return 'Hired';
    case 'DECLINED':
      return 'You declined';
    case 'REJECTED':
      return 'Not moving forward';
    case 'CLOSED':
      return 'Closed';
    default:
      // A stage this build doesn't recognize yet — show it as-is rather
      // than throwing or hiding the card.
      return stage;
  }
}

String _responseLabel(String response) {
  switch (response) {
    case 'ACCEPTED':
      return 'Accepted';
    case 'DECLINED':
      return 'Declined';
    case 'NEGOTIATING':
      return 'Still deciding';
    default:
      return response;
  }
}

/// Stage pill color, following the same rule already used for application
/// status pills (jobs_screen.dart's `_statusPillStyle`): brand for
/// still-moving-forward-or-positive stages, error for a closed-out
/// rejection, neutral for a plain close. Never coral or success-green —
/// both are rationed elsewhere (earned badges only; see AppColors' class
/// doc) and an interview stage is neither.
({Color background, Color foreground}) _stagePillStyle(String stage) {
  switch (stage) {
    case 'DECLINED':
    case 'REJECTED':
      return (background: AppColors.errorSoft, foreground: AppColors.errorBright);
    case 'CLOSED':
      return (background: AppColors.surfaceElevated, foreground: AppColors.textSecondary);
    default: // SHORTLISTED, INVITED, INTERVIEWING, OFFER, HIRED, and unknown stages
      return (background: AppColors.primarySoft, foreground: AppColors.primary);
  }
}

class _RoundDetails extends StatelessWidget {
  const _RoundDetails({required this.round});

  final CurrentRound round;

  @override
  Widget build(BuildContext context) {
    final channelUri = round.channel == null ? null : Uri.tryParse(round.channel!);
    final channelIsLink = channelUri != null && (channelUri.scheme == 'http' || channelUri.scheme == 'https');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Round ${round.roundNumber}', style: AppTypography.titleSmall),
          const SizedBox(height: AppSpacing.space1),
          Text(_roundStatusLabel(round.status), style: AppTypography.bodySmall),
          if (round.channel != null && round.channel!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            channelIsLink
                ? InkWell(
                    onTap: () => _openChannel(context, round.channel!),
                    child: Text(
                      'How to attend: ${round.channel}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text('How to attend: ${round.channel}', style: AppTypography.bodySmall),
          ],
          if (round.scheduledAt != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(_formatDateTime(round.scheduledAt!), style: AppTypography.bodySmall),
          ],
        ],
      ),
    );
  }

  Future<void> _openChannel(BuildContext context, String url) async {
    try {
      await openInBrowser(url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open that link. Please try again.')),
        );
      }
    }
  }

  String _roundStatusLabel(String status) {
    switch (status) {
      case 'SCHEDULED':
        return 'Scheduled';
      case 'COMPLETED':
        return 'Completed';
      case 'PASSED':
        return 'Passed';
      case 'FAILED':
        return 'Did not pass';
      default:
        return status;
    }
  }

  // Same y-m-d style as BadgeCard._formatDate / card_state's
  // _formatLocalDate, extended with a 24h time since this is a specific
  // meeting slot, not just a day. Converts from the API's UTC to local
  // time, same as the assessments cooldown date.
  String _formatDateTime(DateTime utc) {
    final local = utc.toLocal();
    final date = '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final time = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
