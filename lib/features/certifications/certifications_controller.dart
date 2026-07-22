import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import 'certifications_repository.dart';
import 'certifications_state.dart';

final certificationsControllerProvider =
    StateNotifierProvider.autoDispose<CertificationsController, CertificationsState>((ref) {
  return CertificationsController(ref.read(certificationsRepositoryProvider))..load();
});

class CertificationsController extends StateNotifier<CertificationsState> {
  CertificationsController(this._repository) : super(const CertificationsLoading());

  final CertificationsRepository _repository;

  Future<void> load() async {
    state = const CertificationsLoading();
    try {
      final certifications = await _repository.list();
      state = CertificationsLoaded(certifications: certifications);
    } catch (e) {
      state = CertificationsError(_messageOf(e));
    }
  }

  /// Returns true on success so the form knows to close — mirrors
  /// ExternalCredentialsController.add's return-bool contract.
  Future<bool> create({
    required String name,
    required String issuer,
    String? issuerOther,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
    File? file,
  }) async {
    final current = state;
    if (current is! CertificationsLoaded) return false;
    state = current.copyWith(saving: true, clearError: true);
    try {
      final created = await _repository.create(
        name: name,
        issuer: issuer,
        issuerOther: issuerOther,
        issueDate: issueDate,
        expiryDate: expiryDate,
        credentialId: credentialId,
        credentialUrl: credentialUrl,
        file: file,
      );
      state = current.copyWith(
        certifications: [created, ...current.certifications],
        saving: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = current.copyWith(saving: false, error: _messageOf(e));
      return false;
    }
  }

  Future<bool> update(
    String id, {
    required String name,
    required String issuer,
    String? issuerOther,
    required DateTime issueDate,
    DateTime? expiryDate,
    String? credentialId,
    String? credentialUrl,
    File? file,
  }) async {
    final current = state;
    if (current is! CertificationsLoaded) return false;
    state = current.copyWith(saving: true, clearError: true);
    try {
      final updated = await _repository.update(
        id,
        name: name,
        issuer: issuer,
        issuerOther: issuerOther,
        issueDate: issueDate,
        expiryDate: expiryDate,
        credentialId: credentialId,
        credentialUrl: credentialUrl,
        file: file,
      );
      state = current.copyWith(
        certifications: [for (final c in current.certifications) if (c.id == id) updated else c],
        saving: false,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = current.copyWith(saving: false, error: _messageOf(e));
      return false;
    }
  }

  Future<void> remove(String id) async {
    final current = state;
    if (current is! CertificationsLoaded) return;
    state = current.copyWith(deletingId: id, clearError: true);
    try {
      await _repository.remove(id);
      final current2 = state as CertificationsLoaded;
      state = current2.copyWith(
        certifications: current2.certifications.where((c) => c.id != id).toList(),
        clearDeletingId: true,
      );
    } catch (e) {
      final current2 = state as CertificationsLoaded;
      state = current2.copyWith(clearDeletingId: true, error: _messageOf(e));
    }
  }

  String _messageOf(Object e) => e is ApiException ? e.message : e.toString();
}
