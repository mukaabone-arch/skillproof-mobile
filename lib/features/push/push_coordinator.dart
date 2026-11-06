import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../root/root_tab_provider.dart';
import 'push_messaging.dart';
import 'push_providers.dart';
import 'push_routes.dart';

/// Global key for MaterialApp.scaffoldMessengerKey, so a foreground
/// notification can show a banner from outside any Scaffold.
final pushMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Wires push into the app's lifecycle. Mounted once, around the whole
/// MaterialApp content (see app.dart), so it sees every auth transition and
/// every notification in all three app states:
///  - terminated: [PushMessaging.initialMessage] on start;
///  - background: [PushMessaging.onOpened];
///  - foreground: [PushMessaging.onForeground] -> an in-app banner with
///    "View" (the OS shows nothing while the app is open).
/// A tap becomes a bottom-nav tab ([tabForPushRoute]); it waits in
/// [pendingPushRouteProvider] until the candidate is signed in and verified.
class PushCoordinator extends ConsumerStatefulWidget {
  const PushCoordinator({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<PushCoordinator> createState() => _PushCoordinatorState();
}

class _PushCoordinatorState extends ConsumerState<PushCoordinator> {
  final _subs = <StreamSubscription<PushOpened>>[];

  @override
  void initState() {
    super.initState();
    final messaging = ref.read(pushMessagingProvider);
    messaging.initialMessage().then((m) {
      if (m != null && mounted) _open(m.route);
    }).catchError((_) {});
    _subs.add(messaging.onOpened.listen((m) => _open(m.route)));
    _subs.add(messaging.onForeground.listen(_showBanner));
    // A session restored at startup is already authenticated by the time
    // ref.listen below could see a transition.
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncAuth(ref.read(authControllerProvider)));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  void _syncAuth(AuthState state) {
    if (state is AuthAuthenticated) {
      ref.read(pushServiceProvider).onSignedIn();
      if (state.user.isVerified) _applyPending();
    }
  }

  void _open(String? route) {
    ref.read(pendingPushRouteProvider.notifier).state = route ?? 'home';
    final auth = ref.read(authControllerProvider);
    if (auth is AuthAuthenticated && auth.user.isVerified) _applyPending();
  }

  void _applyPending() {
    final route = ref.read(pendingPushRouteProvider);
    if (route == null) return;
    ref.read(pendingPushRouteProvider.notifier).state = null;
    ref.read(rootTabIndexProvider.notifier).state = tabForPushRoute(route);
  }

  void _showBanner(PushOpened m) {
    final text = [m.title, m.body].whereType<String>().where((s) => s.isNotEmpty).join(' — ');
    if (text.isEmpty) return;
    pushMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'View', onPressed: () => _open(m.route)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) => _syncAuth(next));
    return widget.child;
  }
}
