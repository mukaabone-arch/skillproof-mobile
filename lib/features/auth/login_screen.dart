import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'auth_controller.dart';

/// Apple guideline 4.8: an iOS app that offers third-party sign-in must also
/// offer Sign in with Apple, at least as prominently. Both are on for 1.1
/// (Apple first, then Google). Android shows Google only.
const bool kSocialSignInOnIOS = true;

bool get _showSocialSignIn => !Platform.isIOS || kSocialSignInOnIOS;

/// What the one sign-in field holds. Exposed for tests.
sealed class LoginIdentifier {
  const LoginIdentifier();
}

class EmailIdentifier extends LoginIdentifier {
  const EmailIdentifier(this.email);
  final String email;
}

class PhoneIdentifier extends LoginIdentifier {
  const PhoneIdentifier(this.e164);
  final String e164;
}

/// Default country for a mobile number typed without one. MyAmbii's
/// candidates are in India today; a Gulf build changes this one constant
/// (see the web app's per-region settings).
const String kDefaultDialCode = '+91';

/// One field, two kinds of sign-in: anything with an "@" is an email;
/// otherwise digits (spaces, dashes and brackets ignored) are a mobile
/// number — a bare 10-digit number gets [kDefaultDialCode]. Returns null
/// when it is neither, so the screen can say so before calling the API.
LoginIdentifier? parseLoginIdentifier(String raw) {
  final input = raw.trim();
  if (input.isEmpty) return null;
  if (input.contains('@')) {
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input);
    return ok ? EmailIdentifier(input) : null;
  }
  final compact = input.replaceAll(RegExp(r'[\s\-().]'), '');
  if (RegExp(r'^\+\d{8,15}$').hasMatch(compact)) return PhoneIdentifier(compact);
  if (RegExp(r'^0?\d{10}$').hasMatch(compact)) {
    return PhoneIdentifier('$kDefaultDialCode${compact.substring(compact.length - 10)}');
  }
  return null;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController();
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  /// The identifier the code was sent to — locked once sent, so a code is
  /// never verified against a different address than it went to.
  LoginIdentifier? _sentTo;
  bool _submitting = false;
  bool _googleSubmitting = false;
  bool _appleSubmitting = false;
  String? _error;

  bool get _anySubmitting => _submitting || _googleSubmitting || _appleSubmitting;
  bool get _codeSent => _sentTo != null;

  @override
  void dispose() {
    _idController.dispose();
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final id = parseLoginIdentifier(_idController.text);
    if (id == null) {
      setState(() => _error = 'Enter your email address or mobile number.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final controller = ref.read(authControllerProvider.notifier);
      switch (id) {
        case EmailIdentifier(:final email):
          await controller.requestCandidateEmailOtp(email);
        case PhoneIdentifier(:final e164):
          await controller.requestOtp(e164);
      }
      if (!mounted) return;
      setState(() => _sentTo = id);
      _codeFocus.requestFocus();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _verifyCode() async {
    final id = _sentTo;
    final code = _codeController.text.trim();
    if (id == null || code.length != 6 || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final controller = ref.read(authControllerProvider.notifier);
      switch (id) {
        case EmailIdentifier(:final email):
          await controller.verifyCandidateEmailOtp(email: email, otp: code);
        case PhoneIdentifier(:final e164):
          await controller.verifyOtp(phone: e164, otp: code);
      }
      // Success flips global auth state; MyambiiApp swaps to RootScreen.
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _changeIdentifier() {
    setState(() {
      _sentTo = null;
      _error = null;
      _codeController.clear();
    });
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _appleSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithApple();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _appleSubmitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _googleSubmitting = false);
    }
  }

  String get _sentToLabel => switch (_sentTo) {
        EmailIdentifier(:final email) => email,
        PhoneIdentifier(:final e164) => e164,
        null => '',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.space6),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Center(
                      child: Image(image: AssetImage('assets/images/myambii-logo.png'), width: 72, height: 72),
                    ),
                    const SizedBox(height: AppSpacing.space5),
                    Text('Welcome to MyAmbii', style: AppTypography.headlineMedium, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      'Prove your AI skills. Get hired on proof.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppSpacing.space7),
                    if (!_codeSent)
                      TextField(
                        controller: _idController,
                        // Email keyboard: has "@" and ".", and digits one tap away.
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email, AutofillHints.telephoneNumber],
                        autocorrect: false,
                        enabled: !_anySubmitting,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendCode(),
                        style: AppTypography.bodyLarge,
                        decoration: const InputDecoration(labelText: 'Email or mobile number'),
                      )
                    else ...[
                      Text.rich(
                        TextSpan(
                          text: 'We sent a code to ',
                          children: [TextSpan(text: _sentToLabel, style: const TextStyle(fontWeight: FontWeight.w600))],
                        ),
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.space4),
                      TextField(
                        controller: _codeController,
                        focusNode: _codeFocus,
                        keyboardType: TextInputType.number,
                        // iOS offers the code from Messages/Mail above the
                        // keyboard; Android keyboards that read SMS do too.
                        autofillHints: const [AutofillHints.oneTimeCode],
                        maxLength: 6,
                        enabled: !_googleSubmitting && !_appleSubmitting,
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(letterSpacing: 8),
                        decoration: const InputDecoration(labelText: '6-digit code', counterText: ''),
                        // Filled (typed or autofilled) -> verify, no extra tap.
                        onChanged: (v) {
                          if (v.trim().length == 6) _verifyCode();
                        },
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Text(
                        'Your keyboard can fill the code in for you.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space4),
                    AppButton(
                      label: _codeSent ? 'Verify' : 'Send code',
                      busy: _submitting,
                      expand: true,
                      onPressed: (_googleSubmitting || _appleSubmitting) ? null : (_codeSent ? _verifyCode : _sendCode),
                    ),
                    if (_codeSent) ...[
                      const SizedBox(height: AppSpacing.space2),
                      TextButton(
                        onPressed: _anySubmitting ? null : _changeIdentifier,
                        child: const Text('Use a different email or number'),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.space3),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright),
                      ),
                    ],
                    if (_showSocialSignIn && !_codeSent) ...[
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
                      // Apple first and at least as prominent (guideline 4.8);
                      // Apple's own widget keeps its required look.
                      if (Platform.isIOS) ...[
                        SizedBox(
                          height: 48,
                          child: AbsorbPointer(
                            absorbing: _anySubmitting,
                            child: Opacity(
                              opacity: _anySubmitting ? 0.6 : 1,
                              child: SignInWithAppleButton(
                                onPressed: _signInWithApple,
                                style: SignInWithAppleButtonStyle.white,
                                text: 'Sign in with Apple',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                      ],
                      AppButton(
                        label: 'Sign in with Google',
                        variant: AppButtonVariant.secondary,
                        icon: const _GoogleGlyph(),
                        busy: _googleSubmitting,
                        expand: true,
                        onPressed: (_submitting || _appleSubmitting) ? null : _signInWithGoogle,
                      ),
                    ],
                    // GitHub sign-in stays hidden (AuthController.signInWithGithub
                    // is intact) — see git history for the rollout reasoning.
                  ],
                ),
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
