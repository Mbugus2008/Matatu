import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/providers/db.dart';

class VehicleContributionsReport extends StatefulWidget {
  const VehicleContributionsReport({super.key});

  @override
  State<VehicleContributionsReport> createState() =>
      _VehicleContributionsReportState();
}

class _VehicleContributionsReportState
    extends State<VehicleContributionsReport> {
  late DateTimeRange _dateRange;
  bool _isLoading = false;
  bool _singleDateMode = true;
  final NumberFormat _amountFormat = NumberFormat('#,##0.00', 'en_US');

  List<_VehicleContribution> _rows = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final DateTime today = getdate();
    _dateRange = DateTimeRange(start: today, end: today);
    _loadData();
  }

  Future<void> _loadData({bool showLoader = true}) async {
    if (showLoader && mounted) setState(() => _isLoading = true);

    final db = Get.find<db_Provider>();
    final DateTime startDate = getdates(_dateRange.start);
    final DateTime endDate = getdates(_dateRange.end);
    final int startMs = startDate.millisecondsSinceEpoch;
    final int endMs =
        endDate.add(const Duration(days: 1)).millisecondsSinceEpoch - 1;

    List<_VehicleContribution> updated = [];

    try {
      final String sql = '''
        SELECT
          COALESCE(${Header.col_Vehicle}, '') AS vehicle,
          COALESCE(${Header.col_Fleet}, '') AS fleet,
          SUM(COALESCE(${Header.col_Total_Amount}, 0)) AS totalAmount,
          COUNT(${Header.col_Receipt_No}) AS transactionCount
        FROM ${Header.table}
        WHERE ${Header.col_Date} BETWEEN $startMs AND $endMs
        GROUP BY vehicle, fleet
        HAVING vehicle <> '' OR fleet <> ''
        ORDER BY totalAmount DESC
      ''';

      final List<Map<String, dynamic>> groups = await db.rawquery(sql);

      for (final g in groups) {
        final String vehicle = (g['vehicle'] as String?)?.trim() ?? '';
        final String fleet = (g['fleet'] as String?)?.trim() ?? '';
        final double totalAmount = g['totalAmount'] is num
            ? (g['totalAmount'] as num).toDouble()
            : double.tryParse(g['totalAmount']?.toString() ?? '') ?? 0.0;
        final int txCount = g['transactionCount'] is int
            ? g['transactionCount'] as int
            : int.tryParse(g['transactionCount']?.toString() ?? '0') ?? 0;

        final String txSql = '''
          SELECT * FROM ${tmatatu.Trans.tabletrans}
          WHERE (
            ${tmatatu.Trans.col_Loan_No} = '${_escapeSql(vehicle)}'
            OR ${tmatatu.Trans.col_Account_No} = '${_escapeSql(vehicle)}'
            OR ${tmatatu.Trans.col_OTTN} IN (SELECT ${Header.col_Receipt_No} FROM ${Header.table} WHERE ${Header.col_Vehicle} = '${_escapeSql(vehicle)}' AND ${Header.col_Date} BETWEEN $startMs AND $endMs)
          )
          AND ${tmatatu.Trans.col_Transaction_Date} BETWEEN $startMs AND $endMs
          ORDER BY ${tmatatu.Trans.col_Transaction_Time} DESC
        ''';

        final List<Map<String, dynamic>> txrows = await db.rawquery(txSql);
        final List<tmatatu.Trans> transactions =
            txrows.map((r) => tmatatu.Trans.fromMap_d(r)).toList();

        updated.add(_VehicleContribution(
          vehicle: vehicle,
          fleet: fleet,
          totalAmount: totalAmount,
          transactionCount: txCount,
          transactions: transactions,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load vehicle contributions: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _rows = updated;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateRange() async {
    final DateTime firstDate = DateTime(2020);
    final DateTime lastDate = DateTime.now();
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _dateRange,
    );

    if (pickedRange != null) {
      setState(() {
        _dateRange = DateTimeRange(
            start: getdates(pickedRange.start), end: getdates(pickedRange.end));
        _singleDateMode = pickedRange.start == pickedRange.end;
      });
      await _loadData();
    }
  }

  Future<void> _pickSingleDate() async {
    final DateTime firstDate = DateTime(2020);
    final DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateRange.start,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      final DateTime d = getdates(picked);
      setState(() {
        _dateRange = DateTimeRange(start: d, end: d);
        _singleDateMode = true;
      });
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String rangeLabel =
        '${formattedDate2.format(_dateRange.start)} - ${formattedDate2.format(_dateRange.end)}';
    final double grandTotal = _rows.fold(0.0, (s, r) => s + r.totalAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Collections')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 12),
                          ),
                          onPressed: () async {
                            if (_singleDateMode) {
                              await _pickSingleDate();
                            } else {
                              await _pickDateRange();
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              _singleDateMode = !_singleDateMode;
                            });
                          },
                          child: Center(
                            child: Text(rangeLabel,
                                style: theme.textTheme.titleMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by vehicle or fleet',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  _searchQuery = v.trim();
                });
              },
            ),
          ),
          Expanded(
            child: Builder(builder: (context) {
              if (_isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_rows.isEmpty) {
                return const Center(
                    child: Text(
                        'No vehicle contributions for the selected range'));
              }

              final q = _searchQuery.toLowerCase();
              final List<_VehicleContribution> filtered = q.isEmpty
                  ? _rows
                  : _rows.where((r) {
                      return r.vehicle.toLowerCase().contains(q) ||
                          r.fleet.toLowerCase().contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return const Center(
                    child: Text('No vehicle contributions match your search'));
              }

              return RefreshIndicator(
                onRefresh: () => _loadData(showLoader: false),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = filtered[index];
                    final title = r.vehicle.isNotEmpty
                        ? r.vehicle
                        : (r.fleet.isNotEmpty ? r.fleet : 'Unknown');

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        key: ValueKey('vehicle_${title}_$index'),
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(title),
                        subtitle: Text(
                            '${r.transactionCount} transaction${r.transactionCount == 1 ? '' : 's'}'),
                        trailing: Text(_amountFormat.format(r.totalAmount),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: r.transactions.isEmpty
                                ? const Text('No transactions')
                                : Column(
                                    children: r.transactions.map((t) {
                                      final when = t.Transaction_Time != null
                                          ? formattedTime
                                              .format(t.Transaction_Time!)
                                          : (t.Transaction_Date != null
                                              ? formattedDate
                                                  .format(t.Transaction_Date!)
                                              : '');
                                      return ListTile(
                                        dense: true,
                                        title: Text(t.Description ??
                                            t.Account_Name ??
                                            t.Document_No ??
                                            ''),
                                        subtitle: Text(
                                            '${t.Account_No ?? ''} • ${when}'),
                                        trailing: Text(_amountFormat
                                            .format(t.Amount ?? 0)),
                                      );
                                    }).toList(),
                                  ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _VehicleContribution {
  final String vehicle;
  final String fleet;
  final double totalAmount;
  final int transactionCount;
  final List<tmatatu.Trans> transactions;

  _VehicleContribution({
    required this.vehicle,
    required this.fleet,
    required this.totalAmount,
    required this.transactionCount,
    required this.transactions,
  });
}

String _escapeSql(String s) {
  return s.replaceAll("'", "''");
}
