import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../credly_url_validator.dart';
import '../external_credentials_controller.dart';
import '../external_credentials_state.dart';

/// Paste-a-Credly-URL form. Client-side format validation
/// ([validateCredlyBadgeUrl]) runs before the network call ever fires —
/// same "reject a doomed PENDING record before it's created" contract as
/// the web profile page — plus a concise, tap-to-expand "How do I find
/// this?" hint instead of a permanent wall of text.
class AddCredentialForm extends ConsumerStatefulWidget {
  const AddCredentialForm({super.key});

  @override
  ConsumerState<AddCredentialForm> createState() => _AddCredentialFormState();
}

class _AddCredentialFormState extends ConsumerState<AddCredentialForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  bool _hintExpanded = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(externalCredentialsControllerProvider.notifier).add(url);
    if (ok && mounted) {
      _urlController.clear();
      _formKey.currentState?.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(externalCredentialsControllerProvider);
    final adding = state is ExternalCredentialsLoaded && state.adding;
    final error = state is ExternalCredentialsLoaded ? state.error : null;

    return AppCard(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text('Credly badge URL', style: AppTypography.titleSmall)),
                InkWell(
                  onTap: () => setState(() => _hintExpanded = !_hintExpanded),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'How do I find this?',
                          style: AppTypography.labelMedium.copyWith(color: AppColors.indigoLight),
                        ),
                        Icon(
                          _hintExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                          size: 18,
                          color: AppColors.indigoLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_hintExpanded) ...[
              const SizedBox(height: AppSpacing.space2),
              const _CredlyHint(),
            ],
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              validator: (value) => validateCredlyBadgeUrl(value?.trim() ?? ''),
              decoration: const InputDecoration(hintText: 'https://www.credly.com/badges/...'),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppButton(
              label: adding ? 'Adding…' : 'Add credential',
              busy: adding,
              expand: true,
              onPressed: _submit,
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.space2),
              Text(error, style: AppTypography.bodySmall.copyWith(color: AppColors.dangerBright)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Concise guidance, not a wall of text: paste one badge's URL (not the
/// profile), what it looks like, and how to find it. Indigo-tinted — this
/// is neutral info, not a warning/error.
class _CredlyHint extends StatelessWidget {
  const _CredlyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space3),
      decoration: BoxDecoration(
        color: AppColors.indigoSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        'Paste the URL of one specific badge, not your Credly profile — it '
        "looks like credly.com/badges/<id>. Open your Credly profile, tap a "
        "badge, then copy that page's link. Make sure the badge is set to Public.",
        style: AppTypography.bodySmall,
      ),
    );
  }
}
