import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/auth_controller.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/root/root_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// Navigation is state-driven off [authControllerProvider] rather than a
/// router: the top level only has two destinations (login, the post-login
/// shell), and the auth state already models exactly when each applies.
/// Navigation among Home/Jobs/Profile once signed in lives in [RootScreen].
class SkillProofApp extends ConsumerWidget {
  const SkillProofApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'SkillProof',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: switch (authState) {
        AuthAuthenticated() => const RootScreen(),
        AuthInitial() || AuthLoading() => const _SplashScreen(),
        AuthUnauthenticated() => const LoginScreen(),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
