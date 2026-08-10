// ignore_for_file: public_member_api_docs, non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/pages/Depot.dart';
import 'package:t_matatu/pages/Fuel.dart';
import 'package:t_matatu/pages/pageloader.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/reports/controller.dart';

/// Dispatch & Fuel Daily Summary model
class DisFuelSummary {
  String? Key;
  DateTime? Date;
  int? Total_Vehicles;
  double? Total_Fuel_ltrs;
  double? Total_Fuels_Amount;
  double? Total_Paid;
  double? Total_Mileage;
  double? Created_By;
  double? Total_Fuel_Arrears;
  double? Total_Collection;
  double? Net_Offload;
  int? Active_Vehicles;
  bool sent = false;

  DisFuelSummary({
    this.Key,
    this.Date,
    this.Total_Vehicles,
    this.Total_Fuel_ltrs,
    this.Total_Fuels_Amount,
    this.Total_Paid,
    this.Total_Mileage,
    this.Created_By,
    this.Total_Fuel_Arrears,
    this.Total_Collection,
    this.Net_Offload,
    this.Active_Vehicles,
    this.sent = false,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
        'Key': Key,
        'Date': Date?.toIso8601String(),
        'Total_Vehicles': Total_Vehicles,
        'Total_Fuel_ltrs': Total_Fuel_ltrs,
        'Total_Fuels_Amount': Total_Fuels_Amount,
        'Total_Paid': Total_Paid,
        'Total_Mileage': Total_Mileage,
        'Total_Fuel_Arrears': Total_Fuel_Arrears,
        'Total_Collection': Total_Collection,
        'Net_Offload': Net_Offload,
      };

  static DisFuelSummary fromMap(Map<String, dynamic> map) => DisFuelSummary(
        Key: map['Key'] as String?,
        Date: _parseDate(map['Date']),
        Total_Vehicles: map['Total_Vehicles'] as int?,
        Total_Fuel_ltrs: (map['Total_Fuel_ltrs'] as num?)?.toDouble(),
        Total_Fuels_Amount: (map['Total_Fuels_Amount'] as num?)?.toDouble(),
        Total_Paid: (map['Total_Paid'] as num?)?.toDouble(),
        Total_Mileage: (map['Total_Mileage'] as num?)?.toDouble(),
        Total_Fuel_Arrears: (map['Total_Fuel_Arrears'] as num?)?.toDouble(),
        Total_Collection: (map['Total_Collection'] as num?)?.toDouble(),
        Net_Offload: (map['Net_Offload'] as num?)?.toDouble(),
        Active_Vehicles: map['Active_Vehicles'] as int?,
      );

  Map<String, dynamic> toMap_fortable() => <String, dynamic>{
        'Key': Key ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'Date': Date?.millisecondsSinceEpoch,
        'Total_Vehicles': Total_Vehicles,
        'Total_Fuel_ltrs': Total_Fuel_ltrs,
        'Total_Fuels_Amount': Total_Fuels_Amount,
        'Total_Paid': Total_Paid,
        'Total_Mileage': Total_Mileage,
        'Total_Fuel_Arrears': Total_Fuel_Arrears,
        'Total_Collection': Total_Collection,
        'Net_Offload': Net_Offload,
        'Active_Vehicles': Active_Vehicles,
        'sent': sent ? 1 : 0,
      };

  static DisFuelSummary fromMap_db(Map<String, dynamic> map) {
    final d = DisFuelSummary.fromMap(map);
    d.sent = (map['sent'] as int?) == 1;
    return d;
  }

  String toJson() => json.encode(toMap());

  /// Parse date from API (MM/dd/yyyy HH:mm:ss) or int milliseconds (DB)
  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      return DateFormat('MM/dd/yyyy HH:mm:ss', 'en_US').tryParse(value) ??
          DateTime.tryParse(value);
    }
    return null;
  }

  // ─── Database ───
  static const String table = 'disfuel_summary';
  static const String createtable = '''
    CREATE TABLE IF NOT EXISTS $table (
      Key TEXT PRIMARY KEY,
      Date INTEGER,
      Total_Vehicles INTEGER,
      Total_Fuel_ltrs REAL,
      Total_Fuels_Amount REAL,
      Total_Paid REAL,
      Total_Mileage REAL,
      Total_Fuel_Arrears REAL,
      Total_Collection REAL,
      Net_Offload REAL,
      sent INTEGER DEFAULT 0
    )
  ''';

  static const List<String> columns = [
    'Key',
    'Date',
    'Total_Vehicles',
    'Total_Fuel_ltrs',
    'Total_Fuels_Amount',
    'Total_Paid',
    'Total_Mileage',
    'Total_Fuel_Arrears',
    'Total_Collection',
    'Net_Offload',
    'sent',
  ];
}

/// API service for DisFuelSummary
class DisFuelSummaryService {
  final ApiClient _api = ApiClient();
  static const int pageSize = 20;

  /// Fetch a page of summaries using NAV bookmark-based pagination.
  /// [bookmark] is the Key of the last record from the previous page.
  /// Pass null for the first page.
  Future<ResultsDisFuel> fetchPage({String? bookmark}) async {
    final body = <String, dynamic>{
      'size': pageSize,
    };
    if (bookmark != null && bookmark.isNotEmpty) {
      body['bookmark'] = bookmark;
    }
    final response = await _api.postdata('disFuelSummary', json.encode(body));
    return ResultsDisFuel.fromJson(response.body);
  }

  Future<DisFuelSummary?> save(DisFuelSummary summary) async {
    final db = db_Provider();
    summary.sent = false;
    if (summary.Key == null || summary.Key!.isEmpty) {
      summary.Key = DateTime.now().millisecondsSinceEpoch.toString();
    }
    final database = await db.database;
    await database.insert(
      DisFuelSummary.table,
      summary.toMap_fortable(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return summary;
  }

  Future<List<DisFuelSummary>> loadFromLocalDB(DateTime date) async {
    try {
      final db = db_Provider();
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final rows = await db.getdata(
          DisFuelSummary.table,
          DisFuelSummary.columns,
          'Date >= ? AND Date < ?',
          [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch]);
      return rows.map((m) => DisFuelSummary.fromMap_db(m)).toList();
    } catch (_) {
      return [];
    }
  }
}

/// Typed Results wrapper for DisFuelSummary
class ResultsDisFuel {
  int? Code;
  String? Desc;
  List<DisFuelSummary>? Contents;

  ResultsDisFuel({this.Code, this.Desc, this.Contents});

  factory ResultsDisFuel.fromJson(String source) {
    final map = json.decode(source) as Map<String, dynamic>;
    return ResultsDisFuel(
      Code: map['Code'] as int?,
      Desc: map['Desc'] as String?,
      Contents: map['Contents'] != null
          ? (map['Contents'] as List)
              .map((e) => DisFuelSummary.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// UI Screen
// ═══════════════════════════════════════════════════════════

/// Self-contained screen with its own AppBar — no PageLoader needed.
class DisFuelSummaryScreen extends StatelessWidget {
  const DisFuelSummaryScreen({super.key});

  static const _green = Color(0xFF006B3F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispatch & Fuel Summary',
            style: TextStyle(fontSize: 16)),
        centerTitle: true,
        toolbarHeight: 44,
        backgroundColor: _green,
        foregroundColor: Colors.white,
      ),
      body: const DisFuelSummaryPage(),
      floatingActionButton: const _SummaryFABs(),
    );
  }
}

class _SummaryFABs extends StatelessWidget {
  const _SummaryFABs();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'new_fuel',
          backgroundColor: Colors.orange,
          onPressed: () {
            Get.find<ReportController>().selectedDate?.value = null;
            Get.find<DepotController>().depottrans.clear();
            Get.find<DepotController>().depottrans1.clear();
            Get.to(() => const FuelScreen());
          },
          child: const Icon(Icons.local_gas_station, color: Colors.white),
        ),
        const SizedBox(height: 10),
        FloatingActionButton.small(
          heroTag: 'new_dispatch',
          backgroundColor: const Color(0xFF006B3F),
          onPressed: () {
            Get.to(() => const PageLoader(page: Depot(), title: "Dispatch"));
          },
          child: const Icon(Icons.local_shipping, color: Colors.white),
        ),
      ],
    );
  }
}

class DisFuelSummaryPage extends StatefulWidget {
  const DisFuelSummaryPage({super.key});

  @override
  State<DisFuelSummaryPage> createState() => _DisFuelSummaryPageState();
}

class _DisFuelSummaryPageState extends State<DisFuelSummaryPage> {
  final _service = DisFuelSummaryService();
  final Rx<DateTime> _date = DateTime.now().obs;
  final RxList<DisFuelSummary> _summaries = <DisFuelSummary>[].obs;
  final RxBool _loading = false.obs;
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasMore = true.obs;
  String? _bookmark;
  final ScrollController _scrollController = ScrollController();

  static const _green = Color(0xFF006B3F);
  static const _outline = Color(0xFF6F7A71);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore.value &&
        _hasMore.value) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    _loading.value = true;
    _hasMore.value = true;
    _bookmark = null;
    try {
      final result = await _service.fetchPage();
      final apiData = result.Contents ?? [];
      _hasMore.value = apiData.length >= DisFuelSummaryService.pageSize;
      if (apiData.isNotEmpty) {
        _bookmark = apiData.last.Key;
      }

      if (apiData.isNotEmpty) {
        for (final s in apiData) {
          await _service.save(s);
        }
        apiData.sort((a, b) =>
            (b.Date ?? DateTime(2000)).compareTo(a.Date ?? DateTime(2000)));
        _summaries.assignAll(apiData);
        _loading.value = false;
        return;
      }
    } catch (_) {}
    final data = await _service.loadFromLocalDB(_date.value);
    data.sort((a, b) =>
        (b.Date ?? DateTime(2000)).compareTo(a.Date ?? DateTime(2000)));
    _summaries.assignAll(data);
    _hasMore.value = false;
    _loading.value = false;
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore.value || !_hasMore.value) return;
    _isLoadingMore.value = true;
    try {
      final result = await _service.fetchPage(bookmark: _bookmark);
      final apiData = result.Contents ?? [];
      _hasMore.value = apiData.length >= DisFuelSummaryService.pageSize;
      if (apiData.isNotEmpty) {
        _bookmark = apiData.last.Key;
      }

      if (apiData.isNotEmpty) {
        for (final s in apiData) {
          await _service.save(s);
        }
        _summaries.addAll(apiData);
      }
    } catch (_) {}
    _isLoadingMore.value = false;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      _date.value = picked;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateBar(),
        _buildSummaryHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => _load(),
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildDateBar() {
    return Obx(() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, color: _green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEE, dd MMM yyyy').format(_date.value),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _green),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _selectDate,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.calendar_month, color: _green, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: _green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _load,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: _green, size: 16),
                        SizedBox(width: 4),
                        Text('Refresh',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _green)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildSummaryHeader() {
    return Obx(() {
      if (_summaries.isEmpty) return const SizedBox.shrink();
      final totalVehicles =
          _summaries.fold<int>(0, (s, r) => s + (r.Total_Vehicles ?? 0));
      final totalFuel =
          _summaries.fold<double>(0, (s, r) => s + (r.Total_Fuel_ltrs ?? 0));
      final totalAmount =
          _summaries.fold<double>(0, (s, r) => s + (r.Total_Fuels_Amount ?? 0));
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _green.withValues(alpha: 0.08),
              _green.withValues(alpha: 0.02)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _green.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            _statChip(Icons.directions_bus, '$totalVehicles', 'Vehicles'),
            const SizedBox(width: 4),
            _statChip(Icons.local_gas_station,
                NumberFormat('#,##0').format(totalFuel), 'Litres'),
            const SizedBox(width: 4),
            _statChip(Icons.payments,
                NumberFormat('#,##0.00').format(totalAmount), 'Total'),
            const Spacer(),
            Text('${_summaries.length} days',
                style: TextStyle(
                    fontSize: 11,
                    color: _green.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    });
  }

  Widget _buildContent() {
    return Obx(() {
      if (_loading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_summaries.isEmpty) {
        return ListView(
          children: [
            const SizedBox(height: 80),
            Icon(Icons.auto_graph, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('No summaries yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _outline)),
            const SizedBox(height: 4),
            Text('Tap + to add a new dispatch or fuel entry',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
        );
      }
      return ListView.builder(
        controller: _scrollController,
        padding:
            const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80),
        itemCount: _summaries.length + (_hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _summaries.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final s = _summaries[index];
          if (s.Date == null) return const SizedBox.shrink();
          final dateStr = DateFormat('dd MMM yyyy').format(s.Date!);
          final dayOfWeek = DateFormat('EEEE').format(s.Date!);
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            elevation: 1,
            shadowColor: Colors.black26,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (s.Date != null) {
                  Get.find<ReportController>().selectedDate?.value = s.Date!;
                  DepotFuel().getdata(s.Date!);
                  Get.to(() => const FuelScreen());
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 13, color: _green),
                              const SizedBox(width: 6),
                              Text(dateStr,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _green)),
                              const SizedBox(width: 6),
                              Text(dayOfWeek,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _green.withValues(alpha: 0.7))),
                            ],
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            final text = '$dayOfWeek, $dateStr\n'
                                'Collection: ${NumberFormat('#,##0.00').format(s.Total_Collection ?? 0)}\n'
                                'Vehicles: ${s.Total_Vehicles ?? 0}\n'
                                'Fuel: ${NumberFormat('#,##0.0').format(s.Total_Fuel_ltrs ?? 0)} L\n'
                                'Amount: ${NumberFormat('#,##0.00').format(s.Total_Fuels_Amount ?? 0)}\n'
                                'Paid: ${NumberFormat('#,##0.00').format(s.Total_Paid ?? 0)}\n'
                                'Mileage: ${NumberFormat('#,##0').format(s.Total_Mileage ?? 0)}\n'
                                'Arrears: ${NumberFormat('#,##0.00').format(s.Total_Fuel_Arrears ?? 0)}\n'
                                'Net Offload: ${NumberFormat('#,##0.00').format(s.Net_Offload ?? 0)}\n'
                                'Active Vehicles: ${s.Active_Vehicles ?? 0}\n'
                                '---\n'
                                'View Dashboard: https://services.trimline.co.ke:8094/fuelsummary/${DateFormat('yyyy-MM-dd').format(s.Date!)}';
                            SharePlus.instance.share(ShareParams(text: text));
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Icon(Icons.share,
                                size: 18, color: Colors.grey.shade500),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 20, color: Colors.grey.shade400),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _tile(
                                'Collection',
                                NumberFormat('#,##0.00')
                                    .format(s.Total_Collection ?? 0),
                                Icons.monetization_on,
                                Colors.teal)),
                        Container(
                            width: 1, height: 36, color: Colors.grey.shade200),
                        Expanded(
                            child: _tile('Vehicles', '${s.Total_Vehicles ?? 0}',
                                Icons.directions_bus, _green)),
                        Container(
                            width: 1, height: 36, color: Colors.grey.shade200),
                        Expanded(
                            child: _tile(
                                'Fuel (L)',
                                NumberFormat('#,##0.0')
                                    .format(s.Total_Fuel_ltrs ?? 0),
                                Icons.local_gas_station,
                                Colors.orange)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _tile(
                                'Amount',
                                NumberFormat('#,##0.00')
                                    .format(s.Total_Fuels_Amount ?? 0),
                                Icons.payments,
                                Colors.blue)),
                        Container(
                            width: 1, height: 36, color: Colors.grey.shade200),
                        Expanded(
                            child: _tile(
                                'Paid',
                                NumberFormat('#,##0.00')
                                    .format(s.Total_Paid ?? 0),
                                Icons.check_circle_outline,
                                Colors.green)),
                        Container(
                            width: 1, height: 36, color: Colors.grey.shade200),
                        Expanded(
                            child: _tile(
                                'Mileage',
                                NumberFormat('#,##0')
                                    .format(s.Total_Mileage ?? 0),
                                Icons.speed,
                                Colors.purple)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _tile(
                                'Arrears',
                                NumberFormat('#,##0.00')
                                    .format(s.Total_Fuel_Arrears ?? 0),
                                Icons.warning_amber_rounded,
                                (s.Total_Fuel_Arrears ?? 0) > 0
                                    ? Colors.red
                                    : _outline)),
                        Container(
                            width: 1, height: 36, color: Colors.grey.shade200),
                        Expanded(
                            child: _tile(
                                'Net Offload',
                                NumberFormat('#,##0.00')
                                    .format(s.Net_Offload ?? 0),
                                Icons.local_shipping,
                                Colors.brown)),
                        Container(
                            width: 1, height: 36, color: Colors.grey.shade200),
                        Expanded(
                            child: _tile('Active', '${s.Active_Vehicles ?? 0}',
                                Icons.directions_bus, Colors.indigo)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: _green.withValues(alpha: 0.7)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _green)),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: _green.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _tile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
