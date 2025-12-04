import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';

import '../models/waybill_revenue_entry.dart';
import '../services/waybill_revenue_repository.dart';
import '../services/waybill_revenue_sync_service.dart';

class WaybillRevenueController extends GetxController {
  WaybillRevenueController({
    WaybillRevenueRepository? repository,
    WaybillRevenueSyncService? syncService,
  })  : _repository = repository ?? Get.find<WaybillRevenueRepository>(),
        _syncService = syncService ?? Get.find<WaybillRevenueSyncService>();

  final WaybillRevenueRepository _repository;
  final WaybillRevenueSyncService _syncService;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController targetController = TextEditingController();
  final TextEditingController offloadController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  final RxString targetText = ''.obs;
  final Rx<Vehicles?> selectedVehicle = Rx<Vehicles?>(null);
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxDouble actualRevenue = 0.0.obs;
  final RxBool waybillEndorsed = false.obs;
  final RxBool feesPaid = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool isSyncing = false.obs;

  List<Vehicles> get vehicles => Get.find<VehiclesController>().allVehicles;

  @override
  void onInit() {
    super.onInit();
    targetController.addListener(() {
      targetText.value = targetController.text;
    });
    final VehiclesController vehiclesController =
        Get.find<VehiclesController>();
    ever<List<Vehicles>>(vehiclesController.allVehicles, (List<Vehicles> list) {
      if (selectedVehicle.value == null && list.isNotEmpty) {
        setVehicle(list.first);
      }
    });
    if (vehiclesController.allVehicles.isNotEmpty) {
      setVehicle(vehiclesController.allVehicles.first);
    }
  }

  void setVehicle(Vehicles? vehicle) {
    selectedVehicle.value = vehicle;
    if (vehicle == null) {
      targetController.clear();
      offloadController.clear();
      targetText.value = '0';
      actualRevenue.value = 0;
      return;
    }
    final double target = vehicle.Daily_Contribution ?? vehicle.total;
    targetController.text = target.toStringAsFixed(2);
    targetText.value = targetController.text;
    final double offload = vehicle.Offload ?? 0;
    offloadController.text = offload.toStringAsFixed(2);
    _recalculateActual();
  }

  Future<void> pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedDate.value = picked;
      _recalculateActual();
    }
  }

  Future<void> _recalculateActual() async {
    final Vehicles? vehicle = selectedVehicle.value;
    if (vehicle == null) {
      actualRevenue.value = 0;
      return;
    }
    final String code = _vehicleCode(vehicle);
    if (code.isEmpty) {
      actualRevenue.value = 0;
      return;
    }
    actualRevenue.value =
        await _repository.calculateActualRevenue(code, selectedDate.value);
  }

  String _vehicleCode(Vehicles vehicle) {
    if (vehicle.Code != null && vehicle.Code!.isNotEmpty) {
      return vehicle.Code!;
    }
    if (vehicle.Vehicle_Number != null && vehicle.Vehicle_Number!.isNotEmpty) {
      return vehicle.Vehicle_Number!;
    }
    if (vehicle.Fleet_No != null && vehicle.Fleet_No!.isNotEmpty) {
      return vehicle.Fleet_No!;
    }
    return '';
  }

  double get targetValue => double.tryParse(targetText.value.trim()) ?? 0;

  double get offloadValue =>
      double.tryParse(offloadController.text.trim()) ?? 0;

  double get variance => actualRevenue.value - targetValue;

  Future<void> saveEntry() async {
    if (isSaving.value) {
      return;
    }
    if (selectedVehicle.value == null) {
      Get.snackbar(
        'Missing data',
        'Please select a vehicle.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }
    isSaving.value = true;
    try {
      await _recalculateActual();
      final DateTime now = DateTime.now();
      final Vehicles vehicle = selectedVehicle.value!;
      final WaybillRevenueEntry entry = WaybillRevenueEntry(
        id: const Uuid().v4(),
        vehicleCode: _vehicleCode(vehicle),
        vehicleNumber: vehicle.Vehicle_Number ?? '',
        date: selectedDate.value,
        targetRevenue: targetValue,
        actualRevenue: actualRevenue.value,
        offloadPerTrip: offloadValue,
        waybillEndorsed: waybillEndorsed.value,
        feesPaid: feesPaid.value,
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await _repository.saveEntry(entry);
      await _syncService.syncEntry(entry);
      Get.snackbar(
        'Saved',
        'Waybill & revenue entry recorded.',
        snackPosition: SnackPosition.BOTTOM,
      );
      _resetForm();
    } finally {
      isSaving.value = false;
    }
    await syncPendingEntries();
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
    waybillEndorsed.value = false;
    feesPaid.value = false;
    notesController.clear();
    _recalculateActual();
  }

  @override
  void onClose() {
    targetController.dispose();
    offloadController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
