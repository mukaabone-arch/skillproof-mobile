import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/certification.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../certifications_controller.dart';
import '../certifications_state.dart';

const int _maxFileBytes = 5 * 1024 * 1024;

/// Add/edit form for a [Certification] — shared between both flows exactly
/// like web's CertificationsPanel does (one form component, [editing] null
/// for add). Field set and validation mirror web's form 1:1 except for
/// skill tags, which this app doesn't expose (see Certification's doc
/// comment), and file type: only PNG/JPG are picked (via image_picker,
/// gallery only) since PDF requires file_picker, which is blocked on this
/// project's Android toolchain — see profile_repository.dart's resume
/// upload TODO for the same constraint.
class CertificationForm extends ConsumerStatefulWidget {
  const CertificationForm({this.editing, required this.onDone, super.key});

  final Certification? editing;
  final VoidCallback onDone;

  @override
  ConsumerState<CertificationForm> createState() => _CertificationFormState();
}

class _CertificationFormState extends ConsumerState<CertificationForm> {
  late final _nameController = TextEditingController(text: widget.editing?.name ?? '');
  late String? _issuer = widget.editing?.issuer;
  late final _issuerOtherController = TextEditingController(text: widget.editing?.issuerOther ?? '');
  late DateTime? _issueDate = widget.editing?.issueDate;
  late DateTime? _expiryDate = widget.editing?.expiryDate;
  late final _credentialIdController = TextEditingController(text: widget.editing?.credentialId ?? '');
  late final _credentialUrlController = TextEditingController(text: widget.editing?.credentialUrl ?? '');
  File? _file;
  String? _fileError;
  bool _touchedSubmit = false;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerOtherController.dispose();
    _credentialIdController.dispose();
    _credentialUrlController.dispose();
    super.dispose();
  }

  bool get _keepsExistingProof {
    final editing = widget.editing;
    if (editing == null || _file != null) return false;
    return (editing.credentialUrl?.isNotEmpty ?? false) || editing.fileUrl != null;
  }

  String? get _nameError => _nameController.text.trim().isEmpty ? 'Required.' : null;

  String? get _issuerError => _issuer == null ? 'Required.' : null;

  String? get _issuerOtherError =>
      _issuer == 'OTHER' && _issuerOtherController.text.trim().isEmpty ? 'Required when issuer is Other.' : null;

  String? get _issueDateError => _issueDate == null ? 'Required.' : null;

  String? get _expiryOrderError {
    if (_expiryDate == null || _issueDate == null) return null;
    return !_expiryDate!.isAfter(_issueDate!) ? 'Expiry date must be after the issue date.' : null;
  }

  String? get _proofError {
    if (_credentialUrlController.text.trim().isNotEmpty || _file != null || _keepsExistingProof) return null;
    return 'Provide either a credential URL or an upload (PNG/JPG).';
  }

  bool get _formValid =>
      _nameError == null &&
      _issuerError == null &&
      _issuerOtherError == null &&
      _issueDateError == null &&
      _expiryOrderError == null &&
      _proofError == null &&
      _fileError == null;

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    XFile? picked;
    try {
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open your photo gallery. Please try again.')),
        );
      }
      return;
    }
    if (picked == null) return; // candidate cancelled the picker
    final file = File(picked.path);
    final size = await file.length();
    if (size > _maxFileBytes) {
      setState(() => _fileError = 'File is too large — the limit is 5MB.');
      return;
    }
    setState(() {
      _file = file;
      _fileError = null;
    });
  }

  Future<void> _pickDate({required bool isExpiry}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isExpiry ? _expiryDate : _issueDate) ?? now,
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 30),
    );
    if (picked == null) return;
    setState(() {
      if (isExpiry) {
        _expiryDate = picked;
      } else {
        _issueDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _touchedSubmit = true);
    if (!_formValid) return;

    final notifier = ref.read(certificationsControllerProvider.notifier);
    final issuer = _issuer!;
    final issuerOther = issuer == 'OTHER' ? _issuerOtherController.text.trim() : null;
    final credentialId = _credentialIdController.text.trim();
    final credentialUrl = _credentialUrlController.text.trim();

    final ok = widget.editing == null
        ? await notifier.create(
            name: _nameController.text.trim(),
            issuer: issuer,
            issuerOther: issuerOther,
            issueDate: _issueDate!,
            expiryDate: _expiryDate,
            credentialId: credentialId,
            credentialUrl: credentialUrl,
            file: _file,
          )
        : await notifier.update(
            widget.editing!.id,
            name: _nameController.text.trim(),
            issuer: issuer,
            issuerOther: issuerOther,
            issueDate: _issueDate!,
            expiryDate: _expiryDate,
            credentialId: credentialId,
            credentialUrl: credentialUrl,
            file: _file,
          );
    if (ok && mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(certificationsControllerProvider);
    final saving = state is CertificationsLoaded && state.saving;
    final submitError = state is CertificationsLoaded ? state.error : null;
    // Only show field errors once the candidate has tried to submit once —
    // same "don't yell at an empty form" contract ProfileEditForm's
    // AutovalidateMode.onUserInteraction gives, done manually here since
    // this form mixes plain TextEditingControllers with non-text fields
    // (dropdown, dates, file) that a Form/validator pass doesn't cover.
    final showErrors = _touchedSubmit;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Project Management Professional (PMP)',
              counterText: '',
              errorText: showErrors ? _nameError : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.space3),
          DropdownButtonFormField<String>(
            initialValue: _issuer,
            // isExpanded: without it, DropdownButtonFormField sizes its
            // selected-item Text at intrinsic width — the longer labels
            // here ("LinkedIn Learning", "Scrum Alliance") overflow the
            // field at a ~375-wide viewport. Confirmed by
            // certifications_widgets_test.dart's 375-width render.
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Issuer', errorText: showErrors ? _issuerError : null),
            items: certIssuerOptions
                .map((i) => DropdownMenuItem(
                      value: i,
                      child: Text(certIssuerLabels[i]!, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _issuer = value),
          ),
          if (_issuer == 'OTHER') ...[
            const SizedBox(height: AppSpacing.space3),
            TextFormField(
              controller: _issuerOtherController,
              maxLength: 120,
              decoration: InputDecoration(
                labelText: 'Issuer name',
                counterText: '',
                errorText: showErrors ? _issuerOtherError : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          _DateField(
            label: 'Issue date',
            value: _issueDate,
            onTap: () => _pickDate(isExpiry: false),
            errorText: showErrors ? _issueDateError : null,
          ),
          const SizedBox(height: AppSpacing.space3),
          _DateField(
            label: 'Expiry date (optional)',
            value: _expiryDate,
            onTap: () => _pickDate(isExpiry: true),
            onClear: _expiryDate == null ? null : () => setState(() => _expiryDate = null),
            errorText: showErrors ? _expiryOrderError : null,
          ),
          const SizedBox(height: AppSpacing.space3),
          TextFormField(
            controller: _credentialIdController,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Credential ID (optional)', counterText: ''),
          ),
          const SizedBox(height: AppSpacing.space3),
          TextFormField(
            controller: _credentialUrlController,
            keyboardType: TextInputType.url,
            autocorrect: false,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Credential URL (optional)',
              hintText: 'https://...',
              counterText: '',
              helperText: _issuer == 'CREDLY'
                  ? 'A public Credly badge URL is verified automatically — paste the badge page URL, not your profile URL.'
                  : null,
              helperMaxLines: 3,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.space3),
          _FilePickerField(
            file: _file,
            hasExistingFile: widget.editing?.fileUrl != null,
            fileError: _fileError,
            onPick: _pickFile,
            onClear: _file == null ? null : () => setState(() => _file = null),
          ),
          if (showErrors && _proofError != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(_proofError!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
          ],
          if (submitError != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(submitError, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
          ],
          const SizedBox(height: AppSpacing.space2),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: widget.editing == null ? 'Add certification' : 'Save changes',
                  busy: saving,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              AppButton(
                label: 'Cancel',
                variant: AppButtonVariant.secondary,
                onPressed: saving ? null : widget.onDone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onTap, this.onClear, this.errorText});

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          suffixIcon: onClear != null
              ? IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(
          value == null ? 'Select a date' : _formatDate(value!),
          style: value == null
              ? AppTypography.bodyLarge.copyWith(color: AppColors.textTertiary)
              : AppTypography.bodyLarge,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _FilePickerField extends StatelessWidget {
  const _FilePickerField({
    required this.file,
    required this.hasExistingFile,
    required this.fileError,
    required this.onPick,
    this.onClear,
  });

  final File? file;
  final bool hasExistingFile;
  final String? fileError;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload (PNG/JPG, max 5MB)', style: AppTypography.titleSmall),
        const SizedBox(height: AppSpacing.space2),
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AppButton(
              label: file == null ? 'Choose photo' : 'Change photo',
              variant: AppButtonVariant.secondary,
              onPressed: onPick,
            ),
            if (file != null)
              AppButton(label: 'Remove', variant: AppButtonVariant.secondary, onPressed: onClear),
          ],
        ),
        const SizedBox(height: AppSpacing.space1),
        if (file != null)
          Text('Selected: ${file!.path.split('/').last}', style: AppTypography.bodySmall)
        else if (hasExistingFile)
          Text(
            'A file is already on record — choose a new one only to replace it.',
            style: AppTypography.bodySmall,
          )
        else
          Text(
            'PDF is not supported on mobile yet — upload a photo of the certificate instead.',
            style: AppTypography.bodySmall,
          ),
        if (fileError != null) ...[
          const SizedBox(height: AppSpacing.space1),
          Text(fileError!, style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright)),
        ],
      ],
    );
  }
}
