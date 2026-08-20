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
  bool _githubSubmitting = false;
  String? _error;

  bool get _anySubmitting => _submitting || _googleSubmitting || _githubSubmitting;

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
      await ref.read(authControllerProvider.notifier).verifyOtp(
            phone: _phoneController.text.trim(),
            otp: _otpController.text.trim(),
          );
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

  Future<void> _signInWithGithub() async {
    setState(() {
      _githubSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithGithub();
      // Same routing as _signInWithGoogle — a cancelled browser tab or a
      // decline on GitHub's consent screen both resolve normally (no
      // throw); AuthController absorbs GithubSignInCancelled.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _githubSubmitting = false);
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
                          onPressed: (_googleSubmitting || _githubSubmitting)
                              ? null
                              : (_otpSent ? _verifyOtp : _sendOtp),
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
                          onPressed: (_submitting || _githubSubmitting) ? null : _signInWithGoogle,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        AppButton(
                          label: 'Sign in with GitHub',
                          variant: AppButtonVariant.secondary,
                          icon: const _GithubGlyph(),
                          busy: _githubSubmitting,
                          expand: true,
                          onPressed: (_submitting || _googleSubmitting) ? null : _signInWithGithub,
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

/// Minimal Octocat-silhouette mark — same "no image asset/package required"
/// approach as [_GoogleGlyph], at the same 18x18 size/weight. A simplified
/// head-with-ears shape rather than a single letter (unlike Google's "G",
/// GitHub's own mark has no letter to fall back on).
class _GithubGlyph extends StatelessWidget {
  const _GithubGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.githubBrandBlack, shape: BoxShape.circle),
      child: const CustomPaint(size: Size(11, 11), painter: _OctocatPainter()),
    );
  }
}

class _OctocatPainter extends CustomPainter {
  const _OctocatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Ears — two small triangles peeking above the head circle.
    final earWidth = size.width * 0.28;
    final earHeight = size.height * 0.32;
    for (final dx in [0.0, size.width - earWidth]) {
      final ear = Path()
        ..moveTo(dx, earHeight)
        ..lineTo(dx + earWidth / 2, 0)
        ..lineTo(dx + earWidth, earHeight)
        ..close();
      canvas.drawPath(ear, paint);
    }

    // Head — a rounded blob covering the lower ~80% of the glyph, overlapping
    // the ears' base so the two shapes read as one silhouette, not two
    // disconnected pieces.
    final headRect = Rect.fromLTWH(0, size.height * 0.22, size.width, size.height * 0.78);
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(size.width * 0.42)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
