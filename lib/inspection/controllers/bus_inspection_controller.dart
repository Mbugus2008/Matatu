import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/bus_inspection.dart';
import '../services/bus_inspection_repository.dart';
import '../services/bus_inspection_sync_service.dart';
import '../services/inspection_photo_service.dart';

class BusInspectionController extends GetxController {
  BusInspectionController({
    BusInspectionRepository? repository,
    InspectionPhotoService? photoService,
    BusInspectionSyncService? syncService,
  })  : _repository =
            repository ?? BusInspectionRepository(),
        _photoService = photoService ?? InspectionPhotoService(),
        _syncService = syncService ?? BusInspectionSyncService();

  final BusInspectionRepository _repository;
  final InspectionPhotoService _photoService;
  final BusInspectionSyncService _syncService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController busIdentifierController = TextEditingController();
  final TextEditingController inspectorNameController = TextEditingController();
  final Map<String, TextEditingController> notesControllers =
      <String, TextEditingController>{};

  final Rx<DateTime> inspectionDate = DateTime.now().obs;

  final RxMap<String, InspectionItemData> _items =
      <String, InspectionItemData>{}.obs;

  final RxBool isSaving = false.obs;
  final RxBool isSubmitting = false.obs;

  BusInspection? _currentInspection;

  List<String> get ratingOptions => const <String>[
        'Excellent',
        'Good',
        'Fair',
        'Poor',
        'Needs Attention',
      ];

  Map<String, InspectionItemData> get items =>
      Map<String, InspectionItemData>.unmodifiable(_items);

  @override
  void onInit() {
    super.onInit();
    _initialiseItems();
  }

  void _initialiseItems() {
    final List<InspectionItemData> definitions = <InspectionItemData>[
      InspectionItemData(key: 'body', label: 'Body'),
      InspectionItemData(key: 'branding', label: 'Branding'),
      InspectionItemData(key: 'painting', label: 'Painting'),
      InspectionItemData(key: 'cleanliness', label: 'Cleanliness'),
      InspectionItemData(key: 'interior', label: 'Interior'),
      InspectionItemData(key: 'seats', label: 'Seats'),
      InspectionItemData(key: 'stickers', label: 'Stickers'),
      InspectionItemData(key: 'fire_extinguisher', label: 'Fire Extinguisher'),
      InspectionItemData(key: 'first_aid_kit', label: 'First Aid Kit'),
      InspectionItemData(key: 'insurance', label: 'Insurance'),
      InspectionItemData(key: 'speed_governor', label: 'Speed Governor'),
      InspectionItemData(key: 'uniforms', label: 'Uniforms'),
      InspectionItemData(key: 'waybill_status', label: 'Waybill Status'),
    ];
    _items.assignAll({
      for (final InspectionItemData item in definitions) item.key: item,
    });
    for (final InspectionItemData item in definitions) {
      notesControllers[item.key] = TextEditingController(text: item.notes);
    }
  }

  void setInspectionDate(DateTime date) {
    inspectionDate.value = date;
  }

  void toggleCompliance(String key, bool isCompliant) {
    final InspectionItemData? item = _items[key];
    if (item == null) return;
    _items[key] = item.copyWith(isCompliant: isCompliant);
  }

  void setRating(String key, String rating) {
    final InspectionItemData? item = _items[key];
    if (item == null) return;
    _items[key] = item.copyWith(rating: rating);
  }

  void setNotes(String key, String notes) {
    final InspectionItemData? item = _items[key];
    if (item == null) return;
    _items[key] = item.copyWith(notes: notes);
  }

  Future<void> addPhoto(
    String key, {
    ImageSource source = ImageSource.camera,
  }) async {
    final InspectionItemData? item = _items[key];
    if (item == null) return;
    final String storageKey = _currentInspection?.id?.toString() ?? key;
    final String? path = await _photoService.capturePhoto(
      source: source,
      storageKey: storageKey,
    );
    if (path == null) {
      return;
    }
    final List<String> updated = List<String>.from(item.photoPaths)..add(path);
    _items[key] = item.copyWith(photoPaths: updated);
  }

  Future<void> removePhoto(String key, String path) async {
    final InspectionItemData? item = _items[key];
    if (item == null) return;
    await _photoService.deletePhoto(path);
    final List<String> updated = List<String>.from(item.photoPaths)
      ..remove(path);
    _items[key] = item.copyWith(photoPaths: updated);
  }

  Future<BusInspection?> saveLocally() async {
    if (!formKey.currentState!.validate()) {
      return null;
    }
    isSaving.value = true;
    try {
      for (final MapEntry<String, TextEditingController> entry
          in notesControllers.entries) {
        final InspectionItemData? item = _items[entry.key];
        if (item != null && item.notes != entry.value.text) {
          _items[entry.key] = item.copyWith(notes: entry.value.text);
        }
      }
      final DateTime now = DateTime.now();
      final DateTime createdAt = _currentInspection?.createdAt ?? now;
      final BusInspection payload = BusInspection(
        id: _currentInspection?.id,
        busIdentifier: busIdentifierController.text.trim(),
        inspectorName: inspectorNameController.text.trim().isEmpty
            ? null
            : inspectorNameController.text.trim(),
        inspectionDate: inspectionDate.value,
        items: Map<String, InspectionItemData>.from(_items),
        isSynced: _currentInspection?.isSynced ?? false,
        createdAt: createdAt,
        updatedAt: now,
      );
      final BusInspection saved = await _repository.saveInspection(payload);
      _currentInspection = saved;
      return saved;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> submitInspection() async {
    if (isSubmitting.value) return;
    final BusInspection? saved = await saveLocally();
    if (saved == null) {
      return;
    }
    isSubmitting.value = true;
    try {
      final bool success = await _syncService.syncInspection(saved);
      if (success && saved.id != null) {
        await _repository.markInspectionSynced(saved.id!);
        _currentInspection = saved.copyWith(isSynced: true);
        Get.snackbar(
          'Inspection Submitted',
          'The inspection was synced with the backend successfully.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Offline',
          'Inspection saved locally. It will sync when online.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    busIdentifierController.dispose();
    inspectorNameController.dispose();
    for (final TextEditingController controller in notesControllers.values) {
      controller.dispose();
    }
    _syncService.dispose();
    super.onClose();
  }
}

