import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _submitting = false;
  bool _googleSubmitting = false;
  String? _error;

  bool get _anySubmitting => _submitting || _googleSubmitting;

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
      await ref
          .read(authControllerProvider.notifier)
          .requestOtp(_phoneController.text.trim());
      setState(() => _otpSent = true);
    } catch (e) {
      setState(() => _error = e.toString());
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
      await ref.read(authControllerProvider.notifier).verifyOtp(
            phone: _phoneController.text.trim(),
            otp: _otpController.text.trim(),
          );
      // A successful verify flips global auth state to Authenticated;
      // SkillProofApp swaps to RootScreen on its own.
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
      // Same routing as _verifyOtp: a successful sign-in flips global auth
      // state to Authenticated and SkillProofApp swaps to RootScreen on its
      // own. A cancelled native chooser resolves normally (no throw) —
      // AuthController absorbs that case, so there's nothing to show here.
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _googleSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Global AI Talent Hub',
                    style: AppTypography.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.space7),
                  AppCard(
                    elevated: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'SkillProof',
                          style: AppTypography.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          'Verify your AI skills. Get hired on proof.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.space5),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_otpSent && !_anySubmitting,
                          style: AppTypography.bodyLarge,
                          decoration: const InputDecoration(labelText: 'Phone number'),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: AppSpacing.space4),
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            enabled: !_googleSubmitting,
                            style: AppTypography.bodyLarge,
                            decoration: const InputDecoration(
                              labelText: 'OTP (dev: 123456)',
                              counterText: '',
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.space4),
                        AppButton(
                          label: _otpSent ? 'Verify OTP' : 'Send OTP',
                          busy: _submitting,
                          expand: true,
                          onPressed: _googleSubmitting ? null : (_otpSent ? _verifyOtp : _sendOtp),
                        ),
                        if (_otpSent) ...[
                          const SizedBox(height: AppSpacing.space2),
                          TextButton(
                            onPressed: _anySubmitting
                                ? null
                                : () => setState(() {
                                      _otpSent = false;
                                      _error = null;
                                    }),
                            child: const Text('Change number'),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.space5),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: AppColors.border)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
                              child: Text('or', style: AppTypography.bodySmall),
                            ),
                            const Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space5),
                        AppButton(
                          label: 'Sign in with Google',
                          variant: AppButtonVariant.secondary,
                          icon: const _GoogleGlyph(),
                          busy: _googleSubmitting,
                          expand: true,
                          onPressed: _submitting ? null : _signInWithGoogle,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: AppSpacing.space3),
                          Text(
                            _error!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright),
                          ),
                        ],
                      ],
                    ),
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

/// Minimal "G" mark — no image asset/package required. Sized to sit
/// comfortably next to the button label at the same visual weight as a
/// real Google logo glyph would.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      child: const Text(
        'G',
        style: TextStyle(
          color: AppColors.googleBrandBlue,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          height: 1,
        ),
      ),
    );
  }
}
