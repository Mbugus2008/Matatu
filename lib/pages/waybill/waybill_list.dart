// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/pages/setting.dart';
import 'package:t_matatu/pages/waybill/start_trip_sheet.dart';
import 'package:t_matatu/pages/waybill/trip_list.dart';
import 'package:t_matatu/pages/waybill/waybill_form.dart';
import 'package:t_matatu/utils/crew_lookup.dart';
import 'package:t_matatu/utils/snackbar_service.dart';

class WaybillListPage extends StatefulWidget {
  const WaybillListPage({super.key});

  @override
  State<WaybillListPage> createState() => _WaybillListPageState();
}

class _WaybillListPageState extends State<WaybillListPage> {
  late final WaybillController _controller;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Timer? _autoSyncTimer;

  static const _primaryGreen = Color(0xFF006B3F);
  static const _onPrimary = Color(0xFFFFFFFF);
  static const _surfaceGreen = Color(0xFFF6FBF4);
  static const _targetGrey = Color(0xFF64748B);
  static const _actualGreen = Color(0xFF006B3F);
  static const _shortageRed = Color(0xFFB91C1C);
  static const _successGreen = Color(0xFF166534);
  static const _errorRed = Color(0xFFB91C1C);
  static const _outline = Color(0xFF6F7A71);
  static const _surfaceVariant = Color(0xFFDFE4DD);
  static const _summaryBg = Color(0xFFF8FAFC);
  static const _mpesaBlue = Color(0xFF0B5FA5);

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WaybillController>();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toUpperCase());
    });
    // The controller is created at app start, so always reload for the
    // selected date when the screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.reload(silent: true);
      // Full sync on open: pushes pending rows, pulls the day's entries and
      // whatever changed elsewhere (other devices / BC) — entries appear
      // without a manual Sync tap. Silent: no spinner, the list just
      // refreshes when the sync lands.
      _controller.syncFromAPI(silent: true);
      _refreshDailyCollections();

      // Keep the screen live: another device's entry, a trip closed or a
      // receipt settled server-side — refresh quietly every minute.
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        _controller.syncFromAPI(silent: true);
        _refreshDailyCollections();
      });
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Waybill> get _filteredBridges {
    final items = _searchQuery.isEmpty
        ? List<Waybill>.of(_controller.waybills)
        : _controller.waybills.where((wb) {
            return (wb.Fleet_No ?? '').toUpperCase().contains(_searchQuery) ||
                (wb.Vehicle_No ?? '').toUpperCase().contains(_searchQuery);
          }).toList();
    // Vehicles with open trips lead the list — they are the ones still on
    // the road and about to be receipted; the rest keep their order.
    final open = <Waybill>[];
    final rest = <Waybill>[];
    for (final wb in items) {
      (_tripCountsFor(wb).$1 > 0 ? open : rest).add(wb);
    }
    return [...open, ...rest];
  }

  /// Opens the entry form to adjust details (target, crew, cash, ...).
  /// Entries themselves are created silently by Start Trip.
  Future<void> _editEntry(Waybill wb) async {
    // Controller.saveWaybill() already updates the list directly — no need to
    // re-fetch after the edit.
    await Get.to(() => WaybillFormPage(waybill: wb));
  }

  /// Start Trip is the primary action — the day's waybill entry is found or
  /// created silently once the vehicle is picked on the sheet.
  Future<void> _startTrip() async {
    final started = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StartTripSheet(controller: _controller),
    );
    if (started != true || !mounted) return;
    await _controller.reload();
    if (mounted) {
      SnackbarService.showSuccess('Trip started — it will sync automatically');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      _controller.selectedDate.value = picked;
      _controller.reload();
      _refreshDailyCollections();
    }
  }

  /// Pulls the day's per-vehicle collection figures (M-Pesa etc.) shown on
  /// the cards — the same feed the vehicles home screen uses.
  void _refreshDailyCollections() {
    if (!Get.isRegistered<VehiclesController>()) return;
    Vehicles().Daily_Contributions(_controller.selectedDate.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: _onPrimary,
        elevation: 0,
        leading: Builder(
          builder: (ctx) => Navigator.of(ctx).canPop()
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(ctx).pop(),
                )
              : IconButton(
                  // Root (e.g. the Controller's home) — open the drawer.
                  icon: const Icon(Icons.menu),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
        ),
        title: const Text(
          'CityHoppa Waybill',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Pick date',
            onPressed: _selectDate,
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          _buildDateBar(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _controller.syncFromAPI(silent: true);
                _refreshDailyCollections();
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildSummaryGrid()),
                  SliverToBoxAdapter(child: _buildSearchBar()),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startTrip,
        backgroundColor: _primaryGreen,
        foregroundColor: _onPrimary,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Trip'),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Sticky Date Bar ───
  Widget _buildDateBar() {
    return Obx(() {
      final date = _controller.selectedDate.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: _surfaceVariant)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: _primaryGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              DateFormat('EEEE, dd MMM yyyy').format(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF181D19),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _controller.syncFromAPI(silent: true);
                _refreshDailyCollections();
              },
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
      );
    });
  }

  // ─── Summary Bento Grid ───
  Widget _buildSummaryGrid() {
    return Obx(() {
      final entries = _controller.waybills;
      if (entries.isEmpty) return const SizedBox.shrink();

      // Real figures from the day's waybill entries (BC): the totals are
      // exactly the sum of each card's Target / Actual / Shortage.
      final totalTarget =
          entries.fold<double>(0, (s, w) => s + (w.Target_Revenue ?? 0));
      final totalActual =
          entries.fold<double>(0, (s, w) => s + (w.Actual_Revenue ?? 0));
      final totalShortage =
          entries.fold<double>(0, (s, w) => s + (w.Shortage ?? 0));

      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Row(
          children: [
            _summaryTile('TARGET', totalTarget, _targetGrey, _summaryBg,
                _surfaceVariant),
            const SizedBox(width: 8),
            _summaryTile('ACTUAL', totalActual, _primaryGreen,
                const Color(0xFF9DF5BD), _primaryGreen),
            const SizedBox(width: 8),
            _summaryTile('SHORTAGE', totalShortage, _shortageRed,
                const Color(0xFFFFDAD6), _shortageRed),
          ],
        ),
      );
    });
  }

  Widget _summaryTile(
      String label, double value, Color textColor, Color bg, Color border) {
    final display = value >= 1000
        ? '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k'
        : NumberFormat('#,##0').format(value);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
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
            Text(display,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: textColor)),
          ],
        ),
      ),
    );
  }

  // ─── Search Bar ───
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search fleet or plate...',
          prefixIcon: const Icon(Icons.search, color: _outline),
          filled: true,
          isDense: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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

  // ─── Content (list or empty state) ───
  Widget _buildContent() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final items = _filteredBridges;

      if (items.isEmpty && _controller.waybills.isEmpty) {
        return const SliverFillRemaining(child: _EmptyState());
      }

      if (items.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Text('No results for "$_searchQuery"',
                style: const TextStyle(color: _outline)),
          ),
        );
      }

      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildVehicleCard(items[index]),
            childCount: items.length,
          ),
        ),
      );
    });
  }

  // ─── Vehicle Card ───
  Widget _buildVehicleCard(Waybill wb) {
    final hasShortage = (wb.Shortage ?? 0) > 0;
    final borderColor = hasShortage ? _errorRed : _successGreen;

    return GestureDetector(
      onTap: () async {
        _controller.selectedWaybill.value = wb;
        await Get.to(() => const TripListPage());
        // Trips may have been started/closed — refresh the list totals.
        await _controller.reload();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: borderColor, width: 4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF181D19))),
                            ),
                            const SizedBox(width: 8),
                            if (wb.Fleet_No != null)
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
                            const SizedBox(width: 6),
                            _tripChip(wb),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 16, color: _outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                  '${crewLabelFor(wb.Driver)} / ${crewLabelFor(wb.Conductor)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12, color: _outline)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: _outline),
                    onPressed: () => _editEntry(wb),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _summaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _revenueRow('Target', wb.Target_Revenue ?? 0,
                                  _targetGrey),
                              const SizedBox(height: 2),
                              _revenueRow('Actual', wb.Actual_Revenue ?? 0,
                                  _actualGreen),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 30, color: _surfaceVariant),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            children: [
                              _revenueRow('Short', wb.Shortage ?? 0,
                                  hasShortage ? _shortageRed : _outline),
                              const SizedBox(height: 2),
                              _revenueRow('Cash', wb.Cash ?? 0, _targetGrey),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(height: 1, color: _surfaceVariant),
                    const SizedBox(height: 4),
                    _mpesaRow(wb),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// (open, closed) trip counts for the entry — matches by BC entry number
  /// or local key.
  (int, int) _tripCountsFor(Waybill wb) {
    var open = 0;
    var closed = 0;
    for (final t in _controller.allTrips) {
      final byEntry = wb.Entry_No != null &&
          wb.Entry_No! > 0 &&
          t.Weign_Bridge_id == wb.Entry_No;
      final byKey = (wb.Key ?? '').isNotEmpty && t.Waybill_Key == wb.Key;
      if (!byEntry && !byKey) continue;
      if (t.To_Time == null) {
        open++;
      } else {
        closed++;
      }
    }
    return (open, closed);
  }

  Widget _tripChip(Waybill wb) {
    final (open, closed) = _tripCountsFor(wb);
    final parts = <String>[
      if (open > 0) '$open open',
      if (closed > 0) '$closed closed',
    ];
    final label = parts.isEmpty ? '0 trips' : parts.join(' · ');
    final hasOpen = open > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: hasOpen ? const Color(0xFFE8F1EC) : _surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: hasOpen ? _primaryGreen : _outline,
              letterSpacing: 1)),
    );
  }

  /// M-Pesa collected for the vehicle today (same feed the vehicles home
  /// shows) — watched so it fills in as soon as the figures load.
  Widget _mpesaRow(Waybill wb) {
    return Obx(() {
      var mpesa = 0.0;
      if (Get.isRegistered<VehiclesController>()) {
        final list = Get.find<VehiclesController>().vehdailycollections;
        for (final v in list) {
          if (_normVehicle(v.Vehicle_Number) == _normVehicle(wb.Vehicle_No)) {
            mpesa = v.Mpesa ?? 0;
            break;
          }
        }
      }
      return _revenueRow('M-Pesa', mpesa, _mpesaBlue);
    });
  }

  static String _normVehicle(String? value) =>
      (value ?? '').toUpperCase().replaceAll(' ', '').trim();

  Widget _revenueRow(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500, color: _outline)),
        Text(NumberFormat('#,##0').format(value),
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }

  // ─── Bottom Navigation ───
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _surfaceVariant)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _primaryGreen,
        unselectedItemColor: _outline,
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Entries'),
          BottomNavigationBarItem(
              icon: Icon(Icons.analytics), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.sync), label: 'Sync'),
        ],
        onTap: (index) {
          if (index == 2) _controller.syncFromAPI(silent: true);
        },
      ),
    );
  }
}

// ─── Empty State ───
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E9E3),
                borderRadius: BorderRadius.circular(64),
              ),
              child: const Icon(Icons.play_circle_outline,
                  size: 64, color: Color(0xFF6F7A71)),
            ),
            const SizedBox(height: 16),
            const Text('No trips started today',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181D19))),
            const SizedBox(height: 4),
            const Text(
                'Tap Start Trip to begin — the day\'s waybill is created automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF6F7A71))),
          ],
        ),
      ),
    );
  }
}
