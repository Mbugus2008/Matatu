// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/wbridge_controller.dart';
import 'package:t_matatu/models/weighbridge/wbridge.dart';
import 'package:t_matatu/pages/setting.dart';
import 'package:t_matatu/pages/weighbridge/trip_list.dart';
import 'package:t_matatu/pages/weighbridge/wbridge_form.dart';

class WBridgeListPage extends StatefulWidget {
  const WBridgeListPage({super.key});

  @override
  State<WBridgeListPage> createState() => _WBridgeListPageState();
}

class _WBridgeListPageState extends State<WBridgeListPage> {
  late final WBridgeController _controller;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

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

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WBridgeController>();
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toUpperCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WBridge> get _filteredBridges {
    if (_searchQuery.isEmpty) return _controller.wbridges;
    return _controller.wbridges.where((wb) {
      return (wb.Fleet_No ?? '').toUpperCase().contains(_searchQuery) ||
          (wb.Vehicle_No ?? '').toUpperCase().contains(_searchQuery);
    }).toList();
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
      _controller.loadFromLocalDB();
    }
  }

  void _navigateToForm({WBridge? wb}) {
    // Controller.saveWBridge() already updates the list directly — no need to re-fetch
    Get.to(() => WBridgeFormPage(wbridge: wb));
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
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text(
          'CityHoppa WeighBridge',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
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
              onRefresh: () => _controller.syncFromAPI(),
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
        onPressed: () => _navigateToForm(),
        backgroundColor: _primaryGreen,
        foregroundColor: _onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New Entry'),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ─── Sticky Date Bar ───
  Widget _buildDateBar() {
    return Obx(() {
      final date = _controller.selectedDate.value;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      );
    });
  }

  // ─── Summary Bento Grid ───
  Widget _buildSummaryGrid() {
    return Obx(() {
      final bridges = _controller.wbridges;
      if (bridges.isEmpty) return const SizedBox.shrink();

      final totalTarget =
          bridges.fold<double>(0, (s, b) => s + (b.Target_Revenue ?? 0));
      final totalActual =
          bridges.fold<double>(0, (s, b) => s + (b.Actual_Revenue ?? 0));
      final totalShortage =
          bridges.fold<double>(0, (s, b) => s + (b.Shortage ?? 0));

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            _summaryTile('TARGET', totalTarget, _targetGrey, _summaryBg,
                _surfaceVariant),
            const SizedBox(width: 12),
            _summaryTile('ACTUAL', totalActual, _primaryGreen,
                const Color(0xFF9DF5BD), _primaryGreen),
            const SizedBox(width: 12),
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
        padding: const EdgeInsets.all(12),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: textColor)),
            const SizedBox(height: 4),
            Text(display,
                style: TextStyle(
                    fontSize: 22,
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search fleet or plate...',
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

  // ─── Content (list or empty state) ───
  Widget _buildContent() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final items = _filteredBridges;

      if (items.isEmpty && _controller.wbridges.isEmpty) {
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
  Widget _buildVehicleCard(WBridge wb) {
    final hasShortage = (wb.Shortage ?? 0) > 0;
    final borderColor = hasShortage ? _errorRed : _successGreen;

    return GestureDetector(
      onTap: () {
        _controller.selectedWBridge.value = wb;
        Get.to(() => const TripListPage());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          padding: const EdgeInsets.all(16),
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
                                      fontSize: 18,
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
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.group, size: 16, color: _outline),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                  '${wb.Driver ?? '-'} / ${wb.Conductor ?? '-'}',
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
                    onPressed: () => _navigateToForm(wb: wb),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _summaryBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _revenueRow(
                              'Target', wb.Target_Revenue ?? 0, _targetGrey),
                          const SizedBox(height: 4),
                          _revenueRow(
                              'Actual', wb.Actual_Revenue ?? 0, _actualGreen),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: _surfaceVariant),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _revenueRow('Short', wb.Shortage ?? 0,
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
          if (index == 2) _controller.syncFromAPI();
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
            child:
                const Icon(Icons.list_alt, size: 64, color: Color(0xFF6F7A71)),
          ),
          const SizedBox(height: 16),
          const Text('No entries yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181D19))),
          const SizedBox(height: 4),
          const Text('Start by adding a new vehicle\nweighing entry for today.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6F7A71))),
        ],
      ),
    );
  }
}
