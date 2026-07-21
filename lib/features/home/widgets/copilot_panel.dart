import 'package:flutter/material.dart';

import '../../../models/matched_job.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/score_bar.dart';

/// Which part of the app a [CopilotMessage]'s CTA should open — the same
/// tab-index navigation the old NextStepCard already did, plus one new
/// destination (a specific job) now that the message can name one.
enum CopilotAction { profileTab, badgesTab, jobsTab, jobDetail }

class CopilotMessage {
  const CopilotMessage({
    required this.eyebrow,
    required this.message,
    required this.ctaLabel,
    required this.action,
    this.jobId,
    this.skillId,
  });

  final String eyebrow;
  final String message;
  final String ctaLabel;
  final CopilotAction action;
  /// Set only when [action] is [CopilotAction.jobDetail].
  final String? jobId;
  /// Set only on the "Close the gap" message (the [RecurringGap] branch of
  /// [buildCopilotMessage]) — the specific skill the CTA should land on in
  /// Badges, so the message and the card it opens always agree. See
  /// HeroSection._handleCopilotAction.
  final String? skillId;
}

/// A missing skill that recurs across enough of the candidate's top matches
/// to be worth calling out as a bottleneck, rather than one job's
/// idiosyncratic requirement.
class RecurringGap {
  const RecurringGap({required this.skillId, required this.skillName, required this.count});
  final String skillId;
  final String skillName;
  final int count;
}

/// A missing skill only becomes the co-pilot's headline suggestion once it
/// blocks at least this many of the candidate's top matches.
const int kRecurringGapMinCount = 2;

/// The dashboard's hero message: one contextual suggestion, computed from
/// data the rest of Home is already loading (profile, badges, external
/// credentials, matched jobs, applications) — no separate AI backend call.
/// Priority order mirrors buildCopilotMessage in
/// apps/web/components/Dashboard.tsx; keep the two in sync if either
/// changes.
CopilotMessage buildCopilotMessage({
  required bool hasProfile,
  required bool hasVerifiedSkill,
  required MatchedJob? bestUnapplied,
  required RecurringGap? recurringGap,
  required bool hasApplied,
  required int applicationCount,
}) {
  if (!hasProfile) {
    return const CopilotMessage(
      eyebrow: "Let's get started",
      message: "Complete your profile so employers know who they're looking at.",
      ctaLabel: 'Complete your profile',
      action: CopilotAction.profileTab,
    );
  }

  if (!hasVerifiedSkill) {
    return const CopilotMessage(
      eyebrow: 'Your next move',
      message: 'Earn a badge or add a credential to prove your skills.',
      ctaLabel: 'Earn a badge or add a credential',
      action: CopilotAction.badgesTab,
    );
  }

  if (bestUnapplied != null && bestUnapplied.score >= kMatchStrongThreshold) {
    return CopilotMessage(
      eyebrow: 'Strong match found',
      message: "${bestUnapplied.job.title} at ${bestUnapplied.job.orgName} is a "
          "${bestUnapplied.score}% match with your verified skills — this one's worth a look.",
      ctaLabel: 'View ${bestUnapplied.job.title}',
      action: CopilotAction.jobDetail,
      jobId: bestUnapplied.job.id,
    );
  }

  if (recurringGap != null) {
    return CopilotMessage(
      eyebrow: 'Close the gap',
      message: "You're one skill away from more matches — ${recurringGap.skillName} shows up "
          "as a requirement on ${recurringGap.count} roles you're close to.",
      ctaLabel: 'Explore ways to verify',
      action: CopilotAction.badgesTab,
      skillId: recurringGap.skillId,
    );
  }

  if (bestUnapplied != null) {
    return CopilotMessage(
      eyebrow: 'Keep going',
      message: 'Your best match right now is ${bestUnapplied.score}% — still developing. '
          'Verifying more skills will move the needle.',
      ctaLabel: 'View matches',
      action: CopilotAction.jobsTab,
    );
  }

  if (hasApplied) {
    return CopilotMessage(
      eyebrow: "You're on your way",
      message: "You've applied to $applicationCount role${applicationCount == 1 ? '' : 's'}. "
          "I'll keep watching for new ones that fit your verified skills.",
      ctaLabel: 'View applications',
      action: CopilotAction.jobsTab,
    );
  }

  return const CopilotMessage(
    eyebrow: 'Keep going',
    message: 'Earn another verified skill to unlock more job matches.',
    ctaLabel: 'Take another assessment',
    action: CopilotAction.badgesTab,
  );
}

/// The dashboard's hero panel — one AI co-pilot message with a single CTA.
/// Visually the most prominent element on Home, but a confident insight
/// rather than a banner: heading-sized type (not [AppTypography.headlineSmall]
/// at full size), elevated card, brand eyebrow dot. Mirrors web's
/// `.copilot-panel` — same one-accent (brand) treatment, just phone-native.
class CopilotPanel extends StatelessWidget {
  const CopilotPanel({required this.message, required this.onTap, super.key});

  final CopilotMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(message.eyebrow.toUpperCase(), style: AppTypography.metaLabel(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            message.message,
            style: AppTypography.headlineSmall.copyWith(fontSize: 18, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.space4),
          AppButton(label: message.ctaLabel, onPressed: onTap),
        ],
      ),
    );
  }
}
