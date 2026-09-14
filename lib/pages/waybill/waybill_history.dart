// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/pages/waybill/trip_list.dart';
import 'package:t_matatu/utils/crew_lookup.dart';

/// Waybill History — every waybill entry on the device, newest first,
/// grouped by day. Read-only view: tap an entry to open its trips.
class WaybillHistoryPage extends StatefulWidget {
  const WaybillHistoryPage({super.key});

  @override
  State<WaybillHistoryPage> createState() => _WaybillHistoryPageState();
}

class _WaybillHistoryPageState extends State<WaybillHistoryPage> {
  late final WaybillController _controller;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _primaryGreen = Color(0xFF006B3F);
  static const _surfaceGreen = Color(0xFFF6FBF4);
  static const _targetGrey = Color(0xFF64748B);
  static const _shortageRed = Color(0xFFB91C1C);
  static const _outline = Color(0xFF6F7A71);
  static const _surfaceVariant = Color(0xFFDFE4DD);
  static const _summaryBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WaybillController>();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toUpperCase());
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _controller.reloadAll());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Filtering ───

  List<Waybill> get _filtered {
    final all = _controller.allWaybills;
    if (_searchQuery.isEmpty) return all;
    return all.where((wb) {
      return (wb.Fleet_No ?? '').toUpperCase().contains(_searchQuery) ||
          (wb.Vehicle_No ?? '').toUpperCase().contains(_searchQuery) ||
          (wb.Driver ?? '').toUpperCase().contains(_searchQuery);
    }).toList();
  }

  /// Groups entries by day, preserving the newest-first order.
  Map<String, List<Waybill>> _grouped(List<Waybill> entries) {
    final groups = <String, List<Waybill>>{};
    for (final wb in entries) {
      final d = wb.Date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final key = DateFormat('yyyy-MM-dd').format(d);
      groups.putIfAbsent(key, () => <Waybill>[]).add(wb);
    }
    return groups;
  }

  String _groupLabel(String key) {
    final date = DateTime.parse(key);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    final formatted = DateFormat('EEE, dd MMM yyyy').format(date);

    if (diff == 0) return 'Today · $formatted';
    if (diff == 1) return 'Yesterday · $formatted';
    return formatted;
  }

  // ─── Totals ───

  /// Target/Actual/Shortage for one entry — computed from its trips when it has
  /// any, otherwise from the values stored on the entry.
  _EntryTotals _totalsFor(Waybill wb) {
    final trips = _controller.tripsFor(wb);
    if (trips.isEmpty) {
      final target = wb.Target_Revenue ?? 0;
      final actual = wb.Actual_Revenue ?? 0;
      return _EntryTotals(target, actual, target - actual);
    }
    final target = trips.fold<double>(0, (s, t) => s + (t.Total ?? 0));
    final actual = trips
        .where((t) => t.To_Time != null)
        .fold<double>(0, (s, t) => s + _receivedValue(t.Amount_Received));
    return _EntryTotals(target, actual, target - actual);
  }

  /// Numeric value of Amount_Received (stored as text, may contain commas).
  double _receivedValue(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  void _openEntry(Waybill wb) async {
    _controller.selectedWaybill.value = wb;
    await Get.to(() => const TripListPage());
    // Trips may have been started/closed — refresh history totals.
    await _controller.reloadAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Waybill History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          _buildTotalsHeader(),
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _controller.syncFromAPI(),
              child: CustomScrollView(
                slivers: [
                  _buildGroupedList(),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header: entry count + grand totals ───
  Widget _buildTotalsHeader() {
    return Obx(() {
      final entries = _filtered;
      var target = 0.0;
      var actual = 0.0;
      for (final wb in entries) {
        final t = _totalsFor(wb);
        target += t.target;
        actual += t.actual;
      }
      final shortage = target - actual;

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _surfaceVariant)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history, color: _primaryGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  entries.length == 1 ? '1 entry' : '${entries.length} entries',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181D19),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _controller.syncFromAPI(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, color: _primaryGreen, size: 18),
                      SizedBox(width: 4),
                      Text('Sync',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _primaryGreen)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _totalTile(
                    'TARGET', target, _targetGrey, _summaryBg, _surfaceVariant),
                const SizedBox(width: 8),
                _totalTile('ACTUAL', actual, _primaryGreen,
                    const Color(0xFF9DF5BD), _primaryGreen),
                const SizedBox(width: 8),
                _totalTile('SHORTAGE', shortage, _shortageRed,
                    const Color(0xFFFFDAD6), _shortageRed),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _totalTile(
      String label, double value, Color textColor, Color bg, Color border) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: textColor)),
            const SizedBox(height: 2),
            Text(NumberFormat('#,##0').format(value),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  // ─── Search ───
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search fleet, plate or crew...',
          prefixIcon: const Icon(Icons.search, color: _outline),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _surfaceVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _surfaceVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryGreen, width: 2),
          ),
        ),
      ),
    );
  }

  // ─── Grouped list ───
  Widget _buildGroupedList() {
    return Obx(() {
      if (_controller.isLoading.value && _controller.allWaybills.isEmpty) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final entries = _filtered;
      if (entries.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history, size: 56, color: _outline),
                  const SizedBox(height: 12),
                  Text(
                    _controller.allWaybills.isEmpty
                        ? 'No waybills yet'
                        : 'No results for "$_searchQuery"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF181D19)),
                  ),
                  const SizedBox(height: 4),
                  const Text('Create entries from the Waybill screen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _outline)),
                ],
              ),
            ),
          ),
        );
      }

      final groups = _grouped(entries);
      final slivers = <Widget>[];

      groups.forEach((key, items) {
        slivers.add(SliverToBoxAdapter(child: _buildGroupHeader(key, items)));
        slivers.add(SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _buildEntryCard(items[index]),
            ),
            childCount: items.length,
          ),
        ));
      });

      return SliverMainAxisGroup(slivers: slivers);
    });
  }

  Widget _buildGroupHeader(String key, List<Waybill> items) {
    var target = 0.0;
    var actual = 0.0;
    for (final wb in items) {
      final t = _totalsFor(wb);
      target += t.target;
      actual += t.actual;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _groupLabel(key),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF181D19)),
            ),
          ),
          Text(
            'T ${NumberFormat('#,##0').format(target)}  ·  '
            'A ${NumberFormat('#,##0').format(actual)}',
            style: const TextStyle(fontSize: 11, color: _outline),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryCard(Waybill wb) {
    final totals = _totalsFor(wb);
    final hasShortage = totals.shortage > 0;
    final synced = wb.Entry_No != null || wb.sent;

    return GestureDetector(
      onTap: () => _openEntry(wb),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(
              left: BorderSide(
                  color: hasShortage ? _shortageRed : _primaryGreen, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(wb.Vehicle_No ?? 'N/A',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF181D19))),
                  ),
                  const SizedBox(width: 8),
                  if (wb.Fleet_No != null && wb.Fleet_No!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Fleet ${wb.Fleet_No}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _outline,
                              letterSpacing: 1)),
                    ),
                  const Spacer(),
                  Icon(
                    synced ? Icons.cloud_done : Icons.cloud_off,
                    size: 16,
                    color: synced ? _primaryGreen : _shortageRed,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.group, size: 15, color: _outline),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${crewLabelFor(wb.Driver)} / ${crewLabelFor(wb.Conductor)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: _outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _summaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _revenueRow('Target', totals.target, _targetGrey),
                          const SizedBox(height: 4),
                          _revenueRow('Actual', totals.actual, _primaryGreen),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 34, color: _surfaceVariant),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          _revenueRow('Short', totals.shortage,
                              hasShortage ? _shortageRed : _outline),
                          const SizedBox(height: 4),
                          _revenueRow('Cash', wb.Cash ?? 0, _targetGrey),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _revenueRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _outline)),
        Text(NumberFormat('#,##0').format(value),
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// Computed totals for one waybill entry.
class _EntryTotals {
  const _EntryTotals(this.target, this.actual, this.shortage);

  final double target;
  final double actual;
  final double shortage;
}
