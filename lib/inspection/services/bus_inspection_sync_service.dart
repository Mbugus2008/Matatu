import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bus_inspection.dart';

class BusInspectionSyncService {
  BusInspectionSyncService({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const String _defaultBaseUrl = 'https://api.example.com';

  final http.Client _httpClient;
  final String _baseUrl;

  Future<bool> syncInspection(BusInspection inspection) async {
    final Uri uri = Uri.parse('$_baseUrl/inspections');
    try {
      final http.Response response = await _httpClient.post(
        uri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(inspection.toJson()),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
