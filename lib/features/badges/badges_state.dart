import '../../models/badge.dart';

sealed class BadgesState {
  const BadgesState();
}

class BadgesLoading extends BadgesState {
  const BadgesLoading();
}

class BadgesLoaded extends BadgesState {
  const BadgesLoaded(this.badges);

  final List<VerifiedBadge> badges;
}

class BadgesError extends BadgesState {
  const BadgesError(this.message);

  final String message;
}
