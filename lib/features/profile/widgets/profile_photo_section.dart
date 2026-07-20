import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/profile.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../profile_controller.dart';
import '../profile_state.dart';

/// Photo + upload/remove, at the top of the Profile screen. Mirrors
/// apps/web/app/profile/page.tsx's photo block: a circular avatar (the
/// fetched bytes, or an initials placeholder), a picker button, and a
/// remove action shown only once a photo exists. Picking always goes
/// through the gallery, not the camera — same "select an existing file"
/// scope as the (currently dead) resume-upload path this mirrors, not a
/// new capture flow.
class ProfilePhotoSection extends ConsumerWidget {
  const ProfilePhotoSection({required this.profile, super.key});

  final CandidateProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileControllerProvider);
    final loaded = state is ProfileLoaded ? state : null;
    final uploadingPhoto = loaded?.uploadingPhoto ?? false;
    final removingPhoto = loaded?.removingPhoto ?? false;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(bytes: loaded?.photoBytes, fullName: profile.fullName),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    AppButton(
                      label: profile.hasPhoto ? 'Change photo' : 'Add photo',
                      variant: AppButtonVariant.secondary,
                      busy: uploadingPhoto,
                      onPressed: (uploadingPhoto || removingPhoto) ? null : () => _pickAndUpload(context, ref),
                    ),
                    if (profile.hasPhoto) ...[
                      const SizedBox(width: AppSpacing.space2),
                      AppButton(
                        label: 'Remove',
                        variant: AppButtonVariant.secondary,
                        busy: removingPhoto,
                        onPressed: (uploadingPhoto || removingPhoto)
                            ? null
                            : () => ref.read(profileControllerProvider.notifier).removePhoto(),
                      ),
                    ],
                  ],
                ),
                if (loaded?.uploadPhotoError != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    loaded!.uploadPhotoError!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright),
                  ),
                ],
                if (loaded?.removePhotoError != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    loaded!.removePhotoError!,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(profileControllerProvider.notifier);
    final ImagePicker picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your photo gallery. Please try again.')),
        );
      }
      return;
    }
    if (picked == null) return; // candidate cancelled the picker
    await notifier.uploadPhoto(File(picked.path));
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.bytes, required this.fullName});

  final Uint8List? bytes;
  final String? fullName;

  static const double _size = 64;

  @override
  Widget build(BuildContext context) {
    if (bytes != null) {
      return ClipOval(
        child: Image.memory(bytes!, width: _size, height: _size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: _size,
      height: _size,
      decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials(fullName),
        style: AppTypography.mono(size: 20, weight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }

  String _initials(String? fullName) {
    final parts = (fullName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
