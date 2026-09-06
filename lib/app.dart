import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/account/account_status_gate.dart';
import 'features/auth/auth_controller.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/verify_screen.dart';
import 'features/entitlements/widgets/limit_reached_listener.dart';
import 'features/root/root_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Navigation is state-driven off [authControllerProvider] rather than a
/// router: the top level only has two destinations (login, the post-login
/// shell), and the auth state already models exactly when each applies.
/// Navigation among Home/Jobs/Profile once signed in lives in [RootScreen].
class MyambiiApp extends ConsumerWidget {
  const MyambiiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'MyAmbii',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: switch (authState) {
        // A hard gate, not a nag: every route except /users/me and
        // /auth/* 400s with CANDIDATE_VERIFICATION_INCOMPLETE for an
        // unverified candidate (see candidate-verification.guard.ts), so
        // there's nothing in RootScreen worth letting them reach yet.
        AuthAuthenticated(:final user) when !user.isVerified => const VerifyScreen(),
        AuthAuthenticated() => const LimitReachedListener(
            child: AccountStatusGate(child: RootScreen()),
          ),
        AuthInitial() || AuthLoading() => const _SplashScreen(),
        AuthUnauthenticated() => const LoginScreen(),
      },
    );
  }
}

/// Shown while [AuthController._restoreSession] decides where next (see
/// auth_controller.dart) — the only "where do we go next" logic in the app,
/// this widget just renders whatever that decision is currently loading
/// toward. Deliberately pixel-matched to the generated native splash
/// (flutter_native_splash config in pubspec.yaml: same #161826 background,
/// same assets/icon/splash_logo_1024.png image — transparent background, so
/// it composites onto AppColors.background with no baked-in square — same
/// 256x256 logical size) so the native-to-Flutter handoff has no visible seam.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image(
          image: AssetImage('assets/icon/splash_logo_1024.png'),
          width: 256,
          height: 256,
        ),
      ),
    );
  }
}
