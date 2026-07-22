/// Tiny pub-sub so [ApiClient] (a plain Dart class, no widget tree access)
/// can notify a widget-rendered upgrade prompt without depending on
/// Flutter/Riverpod itself. Mirrors apps/web/lib/limitReachedBus.ts:
/// api_client.dart publishes here the instant it decodes a 402
/// { code: 'LIMIT_REACHED' } response, from any call site — LimitReachedListener
/// (mounted once, wrapping RootScreen) is the sole subscriber and is what
/// actually shows the upgrade sheet. This is what "handle 402 centrally"
/// means in practice: no individual repository/controller ever needs to
/// special-case this shape itself.
class LimitReachedPayload {
  const LimitReachedPayload({required this.metric, required this.limit, required this.resetsAt});

  /// 'assessments' | 'applications' | 'retakeCooldownDays' | 'retakesPerSkillLifetime'.
  final String metric;
  final int? limit;
  /// null for a lifetime-cap breach (retakesPerSkillLifetime) — there is no reset.
  final DateTime? resetsAt;
}

typedef LimitReachedListenerFn = void Function(LimitReachedPayload payload);

class LimitReachedBus {
  LimitReachedBus._();
  static final LimitReachedBus instance = LimitReachedBus._();

  final Set<LimitReachedListenerFn> _listeners = {};

  /// Returns an unsubscribe callback.
  void Function() addListener(LimitReachedListenerFn listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void emit(LimitReachedPayload payload) {
    for (final listener in Set.of(_listeners)) {
      listener(payload);
    }
  }
}
