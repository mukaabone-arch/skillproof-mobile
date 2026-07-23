import '../../models/profile_viewers.dart';

sealed class ProfileViewersState {
  const ProfileViewersState();
}

class ProfileViewersLoading extends ProfileViewersState {
  const ProfileViewersLoading();
}

class ProfileViewersError extends ProfileViewersState {
  const ProfileViewersError(this.message);

  final String message;
}

class ProfileViewersLoaded extends ProfileViewersState {
  const ProfileViewersLoaded(this.result);

  final ProfileViewersResult result;
}
