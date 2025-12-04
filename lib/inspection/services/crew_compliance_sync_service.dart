import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../../network/Apis.dart';
import '../models/crew_compliance_entry.dart';
import 'crew_compliance_repository.dart';

class CrewComplianceSyncService {
  CrewComplianceSyncService(
      {CrewComplianceRepository? repository, ApiClient? apiClient})
      : _repository = repository ?? Get.find<CrewComplianceRepository>(),
        _apiClient = apiClient ?? ApiClient();

  final CrewComplianceRepository _repository;
  final ApiClient _apiClient;

  Future<bool> syncEntry(CrewComplianceEntry entry) async {
    try {
      final http.Response response = await _apiClient.postdata(
        'crewcompliance',
        jsonEncode(entry.toApiPayload()),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _repository.markSynced(entry.id);
        return true;
      }
    } catch (error, stackTrace) {
      debugPrint('CrewCompliance sync failed: $error');
      debugPrint(stackTrace.toString());
    }
    return false;
  }

  Future<void> syncPendingEntries() async {
    final List<CrewComplianceEntry> pending = _repository.getPendingEntries();
    for (final CrewComplianceEntry entry in pending) {
      final bool synced = await syncEntry(entry);
      if (!synced) {
        break;
      }
    }
  }
}
