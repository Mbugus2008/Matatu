import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/crew_compliance_entry.dart';
import '../services/crew_compliance_repository.dart';
import '../services/crew_compliance_sync_service.dart';

class CrewComplianceController extends GetxController {
  CrewComplianceController({
    CrewComplianceRepository? repository,
    CrewComplianceSyncService? syncService,
  })  : _repository = repository ?? Get.find<CrewComplianceRepository>(),
        _syncService =
            syncService ?? CrewComplianceSyncService(repository: repository);

  final CrewComplianceRepository _repository;
  final CrewComplianceSyncService _syncService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController notesController = TextEditingController();

  final RxnString grooming = RxnString();
  final RxnString behaviour = RxnString();
  final RxMap<String, ComplianceDocument> documents =
      <String, ComplianceDocument>{}.obs;
  final RxBool isSaving = false.obs;
  final RxBool isSyncing = false.obs;

  List<String> get groomingOptions =>
      const <String>['Excellent', 'Good', 'Fair', 'Poor'];
  List<String> get behaviourOptions =>
      const <String>['Professional', 'Satisfactory', 'Needs Improvement'];
  List<String> get documentKeys => CrewComplianceDocumentKeys.ordered;

  @override
  void onInit() {
    super.onInit();
    syncPendingEntries();
  }

  Future<void> pickDocument(String key) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final PlatformFile file = result.files.single;
    if (file.path == null) {
      return;
    }
    final File source = File(file.path!);
    final String storedPath = await _repository.persistAttachment(source);
    documents[key] = ComplianceDocument(
      path: storedPath,
      name: file.name.isNotEmpty ? file.name : p.basename(storedPath),
    );
  }

  void removeDocument(String key) {
    documents.remove(key);
  }

  String? documentLabel(String key) {
    return documents[key]?.name;
  }

  Future<void> saveEntry() async {
    if (isSaving.value) {
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    isSaving.value = true;
    try {
      final DateTime now = DateTime.now();
      final CrewComplianceEntry entry = CrewComplianceEntry(
        id: const Uuid().v4(),
        createdAt: now,
        updatedAt: now,
        documentPaths: documents.map((String key, ComplianceDocument value) =>
            MapEntry<String, String>(key, value.path)),
        grooming: grooming.value,
        behavior: behaviour.value,
        notes: notesController.text.trim(),
        isSynced: false,
      );
      await _repository.saveEntry(entry);
      await _syncService.syncEntry(entry);
      _resetForm();
      Get.snackbar(
        'Saved',
        'Crew compliance entry saved locally.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
    syncPendingEntries();
  }

  Future<void> syncPendingEntries() async {
    if (isSyncing.value) {
      return;
    }
    isSyncing.value = true;
    try {
      await _syncService.syncPendingEntries();
    } finally {
      isSyncing.value = false;
    }
  }

  void _resetForm() {
    grooming.value = null;
    behaviour.value = null;
    notesController.clear();
    documents.clear();
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }
}
