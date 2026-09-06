import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../auth/auth_controller.dart';
import 'account_repository.dart';
import 'account_status_controller.dart';

/// Shown instead of RootScreen when AccountStatusGate finds the account
/// deactivated — mirrors apps/web/components/ReactivatePrompt.tsx exactly:
/// explicit reactivation, never silent restoration. "Not now" signs back
/// out rather than dropping into a normal session anyway — a deactivated
/// profile is still hidden from search/matching either way, so there's
/// nothing a dashboard would usefully show without reactivating first.
class ReactivateScreen extends ConsumerStatefulWidget {
  const ReactivateScreen({super.key});

  @override
  ConsumerState<ReactivateScreen> createState() => _ReactivateScreenState();
}

class _ReactivateScreenState extends ConsumerState<ReactivateScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _reactivate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).reactivate();
      ref.read(accountStatusControllerProvider.notifier).markReactivated();
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space5),
            child: AppCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Reactivate your account?', style: AppTypography.headlineSmall),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    'Your account is currently deactivated — your profile is hidden from employer search '
                    'and matching, and you\'re not receiving notification emails. Reactivating restores all '
                    'of that immediately. Nothing was lost while you were away.',
                    style: AppTypography.bodyMedium,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.space3),
                    Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
                  ],
                  const SizedBox(height: AppSpacing.space4),
                  AppButton(label: 'Reactivate my account', busy: _busy, onPressed: _busy ? null : _reactivate),
                  const SizedBox(height: AppSpacing.space2),
                  AppButton(
                    label: 'Not now',
                    variant: AppButtonVariant.secondary,
                    onPressed: _busy ? null : _decline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
