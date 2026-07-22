import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'profile_repository.dart';
import 'profile_viewers_state.dart';

final profileViewersControllerProvider =
    StateNotifierProvider.autoDispose<ProfileViewersController, ProfileViewersState>((ref) {
  return ProfileViewersController(ref.read(profileRepositoryProvider))..load();
});

class ProfileViewersController extends StateNotifier<ProfileViewersState> {
  ProfileViewersController(this._repository) : super(const ProfileViewersLoading());

  final ProfileRepository _repository;

  Future<void> load() async {
    state = const ProfileViewersLoading();
    try {
      state = ProfileViewersLoaded(await _repository.getViewers());
    } catch (e) {
      state = ProfileViewersError(e is ApiException ? e.message : e.toString());
    }
  }
}
