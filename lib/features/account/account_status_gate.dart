import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'account_status_controller.dart';
import 'account_status_state.dart';
import 'reactivate_screen.dart';

/// Sits between app.dart's AuthAuthenticated branch and RootScreen — the
/// mobile equivalent of apps/web/app/candidate/page.tsx's own
/// GET /account/status check, just moved from the web app's login-landing
/// route to this app's single post-auth gate point (the same slot the
/// `!user.isVerified` check already occupies one line above in app.dart).
/// Deliberately independent of authControllerProvider/AuthState — those
/// files carry unrelated, still-unverified-on-device auth work, and this
/// gate's own check (a plain GET, not part of the login response) doesn't
/// need to live there.
///
/// Fails open: [AccountStatusLoading]/[AccountStatusError] both render
/// [child] rather than blocking on this check — a slow or failed status
/// fetch must never lock a candidate out of an app they're already
/// authenticated into.
class AccountStatusGate extends ConsumerWidget {
  const AccountStatusGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(accountStatusControllerProvider);
    return switch (status) {
      AccountStatusLoaded(:final deactivated) when deactivated => const ReactivateScreen(),
      AccountStatusLoaded() || AccountStatusLoading() || AccountStatusError() => child,
    };
  }
}
