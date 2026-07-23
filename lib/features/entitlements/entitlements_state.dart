import '../../models/entitlements.dart';

sealed class EntitlementsState {
  const EntitlementsState();
}

class EntitlementsLoading extends EntitlementsState {
  const EntitlementsLoading();
}

class EntitlementsError extends EntitlementsState {
  const EntitlementsError(this.message);

  final String message;
}

class EntitlementsLoaded extends EntitlementsState {
  const EntitlementsLoaded(this.entitlements);

  final Entitlements entitlements;
}
