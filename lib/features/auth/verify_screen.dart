import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

/// Shown by app.dart in place of RootScreen whenever the signed-in user
/// isn't verified (MyambiiUser.isVerified) — the app's hard equivalent of the web's
/// /verify page. A candidate lands here straight out of Google/GitHub sign-in
/// (email, no phone) or, in principle, straight after phone OTP if a future
/// signup path ever leaves email unset. There's no back button and no way to
/// reach RootScreen except finishing both sections that apply — every other
/// route in the app 400s with CANDIDATE_VERIFICATION_INCOMPLETE until this
/// is done, so a soft/dismissible prompt would just delay hitting that wall
/// instead of preventing it.
///
/// Only depends on /users/me and /auth/link/* (via AuthController) — see
/// skip-verification-gate.decorator.ts: AuthController is exempt class-wide
/// and UsersController.me method-wide, specifically so this screen isn't
/// itself locked out by the gate it exists to satisfy.
class VerifyScreen extends ConsumerWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'One more step',
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  Text(
                    'Add and verify both a phone number and an email address '
                    'to continue — this keeps every account reachable and '
                    'reduces duplicate/fraudulent signups.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.space7),
                  if (user?.phone == null) ...[
                    const _LinkPhoneCard(),
                    const SizedBox(height: AppSpacing.space5),
                  ],
                  if (user?.email == null) const _LinkEmailCard(),
                  const SizedBox(height: AppSpacing.space5),
                  TextButton(
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    child: const Text('Log out'),
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

class _LinkPhoneCard extends ConsumerStatefulWidget {
  const _LinkPhoneCard();

  @override
  ConsumerState<_LinkPhoneCard> createState() => _LinkPhoneCardState();
}

class _LinkPhoneCardState extends ConsumerState<_LinkPhoneCard> {
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).requestLinkPhoneOtp(_phoneController.text.trim());
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).verifyLinkPhoneOtp(
            phone: _phoneController.text.trim(),
            otp: _otpController.text.trim(),
          );
      // A successful link flips AuthController's user to phone != null;
      // if email is already set too, app.dart swaps to RootScreen on its
      // own — this widget just stops needing to do anything further.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verify your phone number', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_otpSent && !_submitting,
            style: AppTypography.bodyLarge,
            decoration: const InputDecoration(labelText: 'Phone number'),
          ),
          if (_otpSent) ...[
            const SizedBox(height: AppSpacing.space4),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(labelText: 'OTP', counterText: ''),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: _otpSent ? 'Verify OTP' : 'Send OTP',
            busy: _submitting,
            expand: true,
            onPressed: _otpSent ? _verifyOtp : _sendOtp,
          ),
          if (_otpSent) ...[
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => setState(() {
                        _otpSent = false;
                        _error = null;
                      }),
              child: const Text('Change number'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
          ],
        ],
      ),
    );
  }
}

class _LinkEmailCard extends ConsumerStatefulWidget {
  const _LinkEmailCard();

  @override
  ConsumerState<_LinkEmailCard> createState() => _LinkEmailCardState();
}

class _LinkEmailCardState extends ConsumerState<_LinkEmailCard> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).requestLinkEmailOtp(_emailController.text.trim());
      if (mounted) setState(() => _otpSent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).verifyLinkEmailOtp(
            email: _emailController.text.trim(),
            otp: _otpController.text.trim(),
          );
      // Same reasoning as _LinkPhoneCardState._verifyOtp above.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Verify your email address', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.space4),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !_otpSent && !_submitting,
            style: AppTypography.bodyLarge,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          if (_otpSent) ...[
            const SizedBox(height: AppSpacing.space4),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(labelText: 'OTP', counterText: ''),
            ),
          ],
          const SizedBox(height: AppSpacing.space4),
          AppButton(
            label: _otpSent ? 'Verify OTP' : 'Send OTP',
            busy: _submitting,
            expand: true,
            onPressed: _otpSent ? _verifyOtp : _sendOtp,
          ),
          if (_otpSent) ...[
            const SizedBox(height: AppSpacing.space2),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () => setState(() {
                        _otpSent = false;
                        _error = null;
                      }),
              child: const Text('Change email'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.space3),
            Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
          ],
        ],
      ),
    );
  }
}
