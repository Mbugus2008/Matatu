import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../network/Apis.dart';
import '../models/waybill_revenue_entry.dart';
import 'waybill_revenue_repository.dart';

class WaybillRevenueSyncService {
  WaybillRevenueSyncService(
      {WaybillRevenueRepository? repository, ApiClient? apiClient})
      : _repository = repository ?? Get.find<WaybillRevenueRepository>(),
        _apiClient = apiClient ?? ApiClient();

  final WaybillRevenueRepository _repository;
  final ApiClient _apiClient;

  Future<bool> syncEntry(WaybillRevenueEntry entry) async {
    try {
      final http.Response response = await _apiClient.postdata(
        'waybillrevenue',
        jsonEncode(entry.toApiPayload()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _repository.markSynced(entry.id);
        return true;
      }
    } catch (error, stackTrace) {
      debugPrint('Waybill sync failed: $error');
      debugPrint(stackTrace.toString());
    }
    return false;
  }

  Future<void> syncPendingEntries() async {
    final List<WaybillRevenueEntry> pending = _repository.getPendingEntries();
    for (final WaybillRevenueEntry entry in pending) {
      final bool synced = await syncEntry(entry);
      if (!synced) {
        break;
      }
    }
  }
}
