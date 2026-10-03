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

enum _LoginMode { email, phone }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Email first, matching the web app — most existing candidates signed up
  // with an email, so this is the path that signs them straight back in.
  _LoginMode _mode = _LoginMode.email;
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91');
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _submitting = false;
  bool _googleSubmitting = false;
  String? _error;

  bool get _anySubmitting => _submitting || _googleSubmitting;

  bool get _isEmail => _mode == _LoginMode.email;

  TextEditingController get _activeController => _isEmail ? _emailController : _phoneController;

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Switching tabs drops any OTP already in flight. Otherwise a code sent
  /// to a phone could be submitted against an email address — the verify
  /// fails with a confusing message and the OTP is burned.
  void _selectMode(_LoginMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      _otpSent = false;
      _error = null;
      _otpController.clear();
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final controller = ref.read(authControllerProvider.notifier);
      final input = _activeController.text.trim();
      // Trim only. The server lowercases and normalises the email, so the
      // same address resolves to one OTP entry however it was typed.
      if (_isEmail) {
        await controller.requestCandidateEmailOtp(input);
      } else {
        await controller.requestOtp(input);
      }
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
      final controller = ref.read(authControllerProvider.notifier);
      final input = _activeController.text.trim();
      final otp = _otpController.text.trim();
      if (_isEmail) {
        await controller.verifyCandidateEmailOtp(email: input, otp: otp);
      } else {
        await controller.verifyOtp(phone: input, otp: otp);
      }
      // A successful verify flips global auth state to Authenticated;
      // MyambiiApp swaps to RootScreen on its own.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
      // state to Authenticated and MyambiiApp swaps to RootScreen on its
      // own. A cancelled native chooser resolves normally (no throw) —
      // AuthController absorbs that case, so there's nothing to show here.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
                          'MyAmbii',
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
                        SegmentedButton<_LoginMode>(
                          segments: const [
                            ButtonSegment(value: _LoginMode.email, label: Text('Email')),
                            ButtonSegment(value: _LoginMode.phone, label: Text('Phone')),
                          ],
                          selected: {_mode},
                          showSelectedIcon: false,
                          onSelectionChanged: _anySubmitting
                              ? null
                              : (selection) => _selectMode(selection.first),
                        ),
                        const SizedBox(height: AppSpacing.space4),
                        TextField(
                          controller: _activeController,
                          keyboardType: _isEmail ? TextInputType.emailAddress : TextInputType.phone,
                          enabled: !_otpSent && !_anySubmitting,
                          style: AppTypography.bodyLarge,
                          decoration: InputDecoration(
                            labelText: _isEmail ? 'Email' : 'Phone number',
                          ),
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
                            child: Text(_isEmail ? 'Change email' : 'Change number'),
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
                        // GitHub sign-in is temporarily hidden, not removed.
                        // Like Google, it only ever returns an email (no
                        // phone) — that's why VerifyScreen exists, and a
                        // GitHub signup would be caught by the same gate and
                        // land on the same phone-linking screen as Google
                        // does today. Hidden anyway as a deliberate, narrower
                        // rollout: prove the gate + VerifyScreen out on the
                        // Google path first before adding a second OAuth
                        // provider through it. AuthController.signInWithGithub
                        // and AuthRepository.signInWithGithub are untouched —
                        // re-adding this button is the only step needed once
                        // that's confirmed working.
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

// _GithubGlyph/_OctocatPainter (the GitHub button's icon) were removed here
// along with the button itself — see the "temporarily hidden" comment above
// the Google button. Recoverable from git history if/when the button comes
// back.
