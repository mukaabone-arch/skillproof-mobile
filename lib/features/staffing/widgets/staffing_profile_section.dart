import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/staffing.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/collapsible_section.dart';
import '../staffing_controller.dart';

/// Profile → "Staffing companies": opt in, availability, work types and
/// optional expected pay. Mirrors apps/web/components/StaffingAvailabilityPanel.tsx.
class StaffingProfileSection extends ConsumerWidget {
  const StaffingProfileSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(staffingAvailabilityProvider);
    return CollapsibleSection(
      title: 'Staffing companies',
      summary: state.valueOrNull?.summary,
      child: switch (state) {
        AsyncData(:final value) => _StaffingForm(availability: value),
        AsyncError() => Text(
            "Couldn't load your staffing settings. Pull to refresh.",
            style: AppTypography.bodySmall.copyWith(color: AppColors.errorBright),
          ),
        _ => const Padding(
            padding: EdgeInsets.all(AppSpacing.space3),
            child: Center(child: CircularProgressIndicator()),
          ),
      },
    );
  }
}

class _StaffingForm extends ConsumerStatefulWidget {
  const _StaffingForm({required this.availability});

  final StaffingAvailability availability;

  @override
  ConsumerState<_StaffingForm> createState() => _StaffingFormState();
}

class _StaffingFormState extends ConsumerState<_StaffingForm> {
  late bool _open = widget.availability.openToStaffing;
  late String? _status = widget.availability.availabilityStatus;
  late DateTime? _from = widget.availability.availableFrom;
  late final _notice = TextEditingController(text: widget.availability.noticePeriodDays?.toString() ?? '');
  late final Set<String> _workTypes = {...widget.availability.workTypes};
  late final _rateMin = TextEditingController(text: widget.availability.expectedRateMinInr?.toString() ?? '');
  late final _rateMax = TextEditingController(text: widget.availability.expectedRateMaxInr?.toString() ?? '');
  late String? _rateUnit = widget.availability.expectedRateUnit;
  bool _saving = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _notice.dispose();
    _rateMin.dispose();
    _rateMax.dispose();
    super.dispose();
  }

  int? _num(TextEditingController c) => int.tryParse(c.text.trim());

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _message = null;
    });
    final error = await ref.read(staffingAvailabilityProvider.notifier).save({
      'openToStaffing': _open,
      if (_status != null) 'availabilityStatus': _status,
      if (_status == 'AVAILABLE_FROM' && _from != null) 'availableFrom': _from!.toIso8601String().substring(0, 10),
      if (_status == 'NOTICE_PERIOD' && _num(_notice) != null) 'noticePeriodDays': _num(_notice),
      'workTypes': _workTypes.toList(),
      if (_num(_rateMin) != null) 'expectedRateMinInr': _num(_rateMin),
      if (_num(_rateMax) != null) 'expectedRateMaxInr': _num(_rateMax),
      if (_rateUnit != null) 'expectedRateUnit': _rateUnit,
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      _message = error ?? 'Saved';
      _messageIsError = error != null;
    });
  }

  Future<void> _confirm() async {
    final error = await ref.read(staffingAvailabilityProvider.notifier).confirm();
    if (!mounted) return;
    setState(() {
      _message = error ?? 'Confirmed — staffing companies can see you again.';
      _messageIsError = error != null;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _from ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _from = picked);
  }

  @override
  Widget build(BuildContext context) {
    final a = ref.watch(staffingAvailabilityProvider).valueOrNull ?? widget.availability;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Let verified staffing and recruitment companies find you for client roles. They see your verified skills, '
          'experience, city and availability — not your name, photo or contact details. Those are shared only with a '
          'company whose request you accept.',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        if (a.needsConfirming) ...[
          const SizedBox(height: AppSpacing.space3),
          Text(
            'Last confirmed ${a.daysSinceConfirmed ?? '–'} days ago, so staffing companies can\'t see you right now.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space2),
          AppButton(label: 'Still accurate — confirm', onPressed: _confirm),
        ],
        const SizedBox(height: AppSpacing.space2),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Open to staffing companies'),
          value: _open,
          onChanged: (v) => setState(() => _open = v),
        ),
        if (_open) ...[
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(labelText: 'Availability'),
            items: [
              for (final e in availabilityLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _status = v),
          ),
          if (_status == 'AVAILABLE_FROM') ...[
            const SizedBox(height: AppSpacing.space2),
            OutlinedButton.icon(
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(_from == null ? 'Choose start date' : 'From ${_from!.day}/${_from!.month}/${_from!.year}'),
              onPressed: _pickDate,
            ),
          ],
          if (_status == 'NOTICE_PERIOD') ...[
            const SizedBox(height: AppSpacing.space2),
            TextField(
              controller: _notice,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Notice period (days)'),
            ),
          ],
          const SizedBox(height: AppSpacing.space3),
          Text('Type of work', style: AppTypography.labelSmall),
          const SizedBox(height: AppSpacing.space1),
          Wrap(
            spacing: AppSpacing.space2,
            children: [
              for (final e in workTypeLabels.entries)
                FilterChip(
                  label: Text(e.value),
                  selected: _workTypes.contains(e.key),
                  onSelected: (on) => setState(() => on ? _workTypes.add(e.key) : _workTypes.remove(e.key)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text('Expected pay (optional, ₹)', style: AppTypography.labelSmall),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _rateMin,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min'),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Expanded(
                child: TextField(
                  controller: _rateMax,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max'),
                ),
              ),
            ],
          ),
          DropdownButtonFormField<String>(
            value: _rateUnit,
            decoration: const InputDecoration(labelText: 'Per'),
            items: [
              for (final e in rateUnitLabels.entries) DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _rateUnit = v),
          ),
        ],
        const SizedBox(height: AppSpacing.space3),
        AppButton(label: 'Save', busy: _saving, onPressed: _saving ? null : _save, expand: true),
        if (_message != null) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            _message!,
            style: AppTypography.bodySmall.copyWith(color: _messageIsError ? AppColors.errorBright : AppColors.textSecondary),
          ),
        ],
        if (_open) ...[
          const SizedBox(height: AppSpacing.space2),
          Text(
            "We'll ask you to confirm this every ${a.freshDays} days so companies only see people who are really available.",
            style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ],
    );
  }
}
