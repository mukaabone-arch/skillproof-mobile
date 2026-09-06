import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'account_controller.dart';
import 'account_state.dart';
import 'widgets/reason_picker.dart';

/// Deactivate (reversible) and delete (permanent) — mirrors
/// apps/web/app/profile/account/page.tsx's deactivate/delete cards exactly,
/// including their copy. Reactivation deliberately has NO button here, same
/// as web: it only happens via ReactivateScreen at the next sign-in (see
/// AccountStatusGate) — the status card below just says so.
///
/// "Download my data" is deliberately not on this screen: web hides it
/// behind SHOW_DATA_EXPORT_UI = false (dormant, backend fully live, not
/// public yet) — this app matches that current behaviour rather than
/// exposing something web itself keeps hidden.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  bool _deactivateOpen = false;
  String? _deactivateReason;
  final _deactivateReasonTextController = TextEditingController();

  bool _deleteOpen = false;
  String? _deleteReason;
  final _deleteReasonTextController = TextEditingController();
  final _confirmationController = TextEditingController();

  @override
  void dispose() {
    _deactivateReasonTextController.dispose();
    _deleteReasonTextController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: switch (state) {
        AccountLoading() => const Center(child: CircularProgressIndicator()),
        AccountError(:final message) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space5),
              child: Text(message, style: AppTypography.bodyMedium.copyWith(color: AppColors.errorBright)),
            ),
          ),
        AccountLoaded(:final status) when status.deactivated => Padding(
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: AppCard(
              child: Text(
                'Your account is currently deactivated. Reactivate it from the sign-in screen any time — '
                'just sign back in and you\'ll be offered the option.',
                style: AppTypography.bodyMedium,
              ),
            ),
          ),
        AccountLoaded() => ListView(
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              _DeactivateCard(
                state: state,
                open: _deactivateOpen,
                reason: _deactivateReason,
                reasonTextController: _deactivateReasonTextController,
                onOpen: () => setState(() => _deactivateOpen = true),
                onCancel: () => setState(() => _deactivateOpen = false),
                onReasonChanged: (r) => setState(() => _deactivateReason = r),
                onConfirm: () => ref.read(accountControllerProvider.notifier).deactivate(
                      reasonCategory: _deactivateReason,
                      reasonText: _deactivateReasonTextController.text.trim().isEmpty
                          ? null
                          : _deactivateReasonTextController.text.trim(),
                    ),
              ),
              const SizedBox(height: AppSpacing.space4),
              _DeleteCard(
                state: state,
                open: _deleteOpen,
                reason: _deleteReason,
                reasonTextController: _deleteReasonTextController,
                confirmationController: _confirmationController,
                onOpen: () => setState(() => _deleteOpen = true),
                onCancel: () => setState(() => _deleteOpen = false),
                onReasonChanged: (r) => setState(() => _deleteReason = r),
                onConfirm: () => ref.read(accountControllerProvider.notifier).delete(
                      confirmation: _confirmationController.text,
                      reasonCategory: _deleteReason,
                      reasonText: _deleteReasonTextController.text.trim().isEmpty
                          ? null
                          : _deleteReasonTextController.text.trim(),
                    ),
              ),
            ],
          ),
      },
    );
  }
}

class _DeactivateCard extends StatelessWidget {
  const _DeactivateCard({
    required this.state,
    required this.open,
    required this.reason,
    required this.reasonTextController,
    required this.onOpen,
    required this.onCancel,
    required this.onReasonChanged,
    required this.onConfirm,
  });

  final AccountLoaded state;
  final bool open;
  final String? reason;
  final TextEditingController reasonTextController;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final ValueChanged<String?> onReasonChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Deactivate my account', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Your profile is hidden from employer search and matching, you won\'t appear in new match '
            'results or get newly shortlisted or invited, and all notification emails stop. Everything '
            'else about your account — your profile, badges, applications, and history — is kept exactly '
            'as it is. Sign back in any time to reactivate.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.space4),
          if (!open)
            AppButton(label: 'Deactivate account', onPressed: onOpen)
          else ...[
            ReasonPicker(reason: reason, onReasonChanged: onReasonChanged, reasonTextController: reasonTextController),
            if (state.deactivateError != null) ...[
              const SizedBox(height: AppSpacing.space3),
              Text(state.deactivateError!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
            ],
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Confirm deactivation',
                    busy: state.deactivating,
                    onPressed: state.deactivating ? null : onConfirm,
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.secondary,
                  onPressed: state.deactivating ? null : onCancel,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DeleteCard extends StatelessWidget {
  const _DeleteCard({
    required this.state,
    required this.open,
    required this.reason,
    required this.reasonTextController,
    required this.confirmationController,
    required this.onOpen,
    required this.onCancel,
    required this.onReasonChanged,
    required this.onConfirm,
  });

  final AccountLoaded state;
  final bool open;
  final String? reason;
  final TextEditingController reasonTextController;
  final TextEditingController confirmationController;
  final VoidCallback onOpen;
  final VoidCallback onCancel;
  final ValueChanged<String?> onReasonChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.errorBright, width: 1.5),
      ),
      child: AppCard(
        child: StatefulBuilder(
          builder: (context, setLocalState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Delete my account', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  'This permanently removes your personal data — name, email, phone, photo, resume, and '
                  'profile details. It cannot be undone. Any verified skill badge you\'ve earned stays '
                  'independently verifiable to anyone who already has the certificate link, shown without '
                  'your name attached. Employer records that legitimately belong to them (that you applied, '
                  'were shortlisted, or interviewed) are kept, anonymised — deleting your account doesn\'t '
                  'create holes in someone else\'s hiring history.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.space4),
                if (!open)
                  AppButton(label: 'Delete account', variant: AppButtonVariant.secondary, onPressed: onOpen)
                else ...[
                  ReasonPicker(reason: reason, onReasonChanged: onReasonChanged, reasonTextController: reasonTextController),
                  const SizedBox(height: AppSpacing.space3),
                  Text.rich(
                    TextSpan(
                      style: AppTypography.bodyMedium,
                      children: [
                        const TextSpan(text: "This can't be undone. Type "),
                        TextSpan(text: 'DELETE', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                        const TextSpan(text: ' to confirm.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
                  TextField(
                    controller: confirmationController,
                    autocorrect: false,
                    decoration: const InputDecoration(hintText: 'DELETE'),
                    // Rebuilds just this card so the confirm button's
                    // enabled state tracks the typed text live, without
                    // lifting confirmation text into the parent screen's
                    // own setState for a value nothing else needs.
                    onChanged: (_) => setLocalState(() {}),
                  ),
                  if (state.deleteError != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Text(state.deleteError!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
                  ],
                  const SizedBox(height: AppSpacing.space3),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Permanently delete my account',
                          variant: AppButtonVariant.secondary,
                          busy: state.deleting,
                          onPressed: (state.deleting || confirmationController.text != 'DELETE') ? null : onConfirm,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      AppButton(
                        label: 'Cancel',
                        variant: AppButtonVariant.secondary,
                        onPressed: state.deleting ? null : onCancel,
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
