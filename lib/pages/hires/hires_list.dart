import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/components/shimmer_loading.dart';
import 'package:t_matatu/models/Hires.dart';
import 'package:t_matatu/models/enums.dart';
import 'package:t_matatu/pages/hires/addhire.dart';
import 'package:t_matatu/utils/snackbar_service.dart';

class HiresListScreen extends StatelessWidget {
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString searchQuery = ''.obs;
  final TextEditingController searchController = TextEditingController();

  /// Group keys the user has opened; every other group renders collapsed.
  final RxSet<String> expandedGroups = <String>{}.obs;

  /// Set once a header is tapped, so the initial "first group open" default
  /// does not creep back on the next rebuild.
  final RxBool _headersTouched = false.obs;

  HiresListScreen() {
    fetchHires();
  }

  Future<void> fetchHires() async {
    try {
      hasError.value = false;
      isLoading.value = true;
      await Hires().getthires();
      // Assuming getthires updates a global or singleton list of Hires
      // Replace with actual data fetching logic
    } catch (e) {
      hasError.value = true;
      SnackbarService.showError('Failed to load hires: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiresController = Get.put(HiresController());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hires', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        toolbarHeight: 44,
        backgroundColor: const Color(0xFF006B3F),
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (isLoading.value) return ShimmerLoading();
        if (hasError.value) return _buildErrorState();
        return Column(
          children: [
            _buildSearchBar(),
            Expanded(child: _buildHiresList(hiresController)),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Get.to(() => AddHireScreen(hire: Hires())),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: searchController,
        onChanged: (v) => searchQuery.value = v,
        decoration: InputDecoration(
          hintText: 'Search vehicle, fleet or code...',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF8A9296)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF006B3F)),
          suffixIcon: Obx(() => searchQuery.value.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF8A9296)),
                  onPressed: () {
                    searchController.clear();
                    searchQuery.value = '';
                  },
                )),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF006B3F), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildHiresList(HiresController hiresController) {
    final query = searchQuery.value.trim().toLowerCase();
    final filtered = query.isEmpty
        ? hiresController.hires.toList()
        : hiresController.hires.where((h) {
            return (h.Vehicle_No ?? '').toLowerCase().contains(query) ||
                (h.Fleet_No ?? '').toLowerCase().contains(query) ||
                (h.Code ?? '').toLowerCase().contains(query);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty ? 'No hires yet' : 'No hires match "$query"',
          style: const TextStyle(color: Color(0xFF8A9296)),
        ),
      );
    }

    // Group by start date, newest group first, fleet number inside a group.
    final byDate = <DateTime, List<Hires>>{};
    final undated = <Hires>[];
    for (final hire in filtered) {
      final date = hire.Start_Date;
      if (date == null) {
        undated.add(hire);
        continue;
      }
      byDate
          .putIfAbsent(DateTime(date.year, date.month, date.day), () => [])
          .add(hire);
    }

    final ordered = <MapEntry<DateTime?, List<Hires>>>[];
    for (final date in byDate.keys.toList()..sort((a, b) => b.compareTo(a))) {
      ordered.add(MapEntry(date, byDate[date]!..sort(_byFleet)));
    }
    if (undated.isNotEmpty) {
      ordered.add(MapEntry(null, undated..sort(_byFleet)));
    }

    final items = <Widget>[];
    for (var i = 0; i < ordered.length; i++) {
      final entry = ordered[i];
      final key = _groupKey(entry.key);
      // The newest group starts open, every other group starts collapsed.
      final isExpanded =
          expandedGroups.contains(key) || (!_headersTouched.value && i == 0);
      items.add(_groupHeader(entry.key, entry.value, key, isExpanded));
      if (isExpanded) {
        items.addAll(entry.value.map(_hireCard));
      }
    }

    return SizedBox(
      width: MediaQuery.of(Get.context!).size.width,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      ),
    );
  }

  /// Fleet 99 must come before fleet 100, so numeric fleets compare as numbers.
  int _byFleet(Hires a, Hires b) {
    final fa = int.tryParse((a.Fleet_No ?? '').trim());
    final fb = int.tryParse((b.Fleet_No ?? '').trim());
    if (fa != null && fb != null && fa != fb) return fa.compareTo(fb);
    if (fa != null && fb == null) return -1;
    if (fa == null && fb != null) return 1;
    return (a.Fleet_No ?? '')
        .toLowerCase()
        .compareTo((b.Fleet_No ?? '').toLowerCase());
  }

  /// "Today" and "Yesterday" read better than the date on a fresh group.
  String _groupLabel(DateTime? date) {
    if (date == null) return 'No date';
    final now = DateTime.now();
    final days = DateTime(now.year, now.month, now.day).difference(date).inDays;
    if (days == 0) return 'Today';
    if (days == 1) return 'Yesterday';
    return DateFormat('EEE, dd MMM yyyy').format(date);
  }

  /// A stable key per group: the day, or a sentinel for hires with no date.
  String _groupKey(DateTime? date) =>
      date == null ? 'undated' : DateFormat('yyyy-MM-dd').format(date);

  void _toggleGroup(String key, bool isExpanded) {
    _headersTouched.value = true;
    if (isExpanded) {
      expandedGroups.remove(key);
    } else {
      expandedGroups.add(key);
    }
  }

  Widget _groupHeader(
      DateTime? date, List<Hires> group, String key, bool isExpanded) {
    final total = group.fold<double>(0, (sum, h) => sum + (h.Amount ?? 0));
    return InkWell(
      onTap: () => _toggleGroup(key, isExpanded),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 14, 6),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 20,
              color: const Color(0xFF006B3F),
            ),
            const SizedBox(width: 4),
            Text(
              _groupLabel(date),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF161D1F)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1EC),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${group.length} ${group.length == 1 ? 'hire' : 'hires'}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF006B3F)),
              ),
            ),
            const Spacer(),
            Text(
              NumberFormat.simpleCurrency(name: "KES").format(total),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF006B3F)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hireCard(Hires hire) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      color: hire.Key == null
          ? const Color(0xFFF2F2F2)
          : (hire.Paid == true ? const Color(0xFFF1F8F2) : Colors.white),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.to(() => AddHireScreen(hire: hire));
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF006B3F).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.directions_bus, color: Color(0xFF006B3F)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            hire.Vehicle_No ?? '-',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF161D1F)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hire.Fleet_No != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F1EC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Fleet ${hire.Fleet_No}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF006B3F)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Code: ${hire.Code ?? '-'}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5B5F61),
                          fontFamily: 'monospace'),
                    ),
                    if ((hire.Destination ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.pin_drop,
                                size: 14, color: Color(0xFF8A9296)),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hire.Destination!.trim(),
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF5B5F61)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    _dateLine(
                        Icons.play_circle, hire.Start_Date, hire.Start_Time),
                    const SizedBox(height: 2),
                    _dateLine(
                        Icons.stop_circle, hire.Return_Date, hire.Return_Time),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _chip(
                          hire_type_desc.desc.values
                              .elementAt(hire.Hire_Type?.index ?? 0),
                          const Color(0xFF006B3F),
                        ),
                        _chip(
                          client_desc.desc.values
                              .elementAt(hire.Client?.index ?? 0),
                          const Color(0xFF1B6CA8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hire.Amount != null
                        ? NumberFormat.simpleCurrency(name: "KES")
                            .format(hire.Amount)
                        : 'KES 0.00',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006B3F)),
                  ),
                  const Text('Amount',
                      style: TextStyle(fontSize: 10, color: Color(0xFF5B5F61))),
                  const SizedBox(height: 6),
                  _paidPill(hire.Paid == true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  /// Payment status pill — green when paid, red while still pending.
  Widget _paidPill(bool paid) {
    final color = paid ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        paid ? 'PAID' : 'UNPAID',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: color),
      ),
    );
  }

  Widget _dateLine(IconData icon, DateTime? date, DateTime? time) {
    if (date == null) return const SizedBox.shrink();
    final fmt = DateFormat('dd-MMM-yyyy HH:mm');
    final dt = DateTime(date.year, date.month, date.day, time?.hour ?? 0,
        time?.minute ?? 0, time?.second ?? 0);
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A9296)),
        const SizedBox(width: 4),
        Text(fmt.format(dt),
            style: const TextStyle(fontSize: 12, color: Color(0xFF5B5F61))),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Failed to load hires', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          ElevatedButton(
            child: Text('Retry'),
            onPressed: fetchHires,
          ),
        ],
      ),
    );
  }
}
