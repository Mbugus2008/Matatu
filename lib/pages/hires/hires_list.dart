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

    return filtered.isEmpty
        ? Center(
            child: Text(
              query.isEmpty ? 'No hires yet' : 'No hires match "$query"',
              style: const TextStyle(color: Color(0xFF8A9296)),
            ),
          )
        : SizedBox(
            width: MediaQuery.of(Get.context!).size.width,
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final hire = filtered[index];

                return Card(
                  elevation: 2,
                  shadowColor: Colors.black26,
                  color:
                      hire.Key != null ? Colors.white : const Color(0xFFF2F2F2),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
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
                            child: const Icon(Icons.directions_bus,
                                color: Color(0xFF006B3F)),
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
                                          borderRadius:
                                              BorderRadius.circular(20),
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
                                const SizedBox(height: 6),
                                _dateLine(Icons.play_circle, hire.Start_Date,
                                    hire.Start_Time),
                                const SizedBox(height: 2),
                                _dateLine(Icons.stop_circle, hire.Return_Date,
                                    hire.Return_Time),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _chip(
                                      hire_type_desc.desc.values.elementAt(
                                          hire.Hire_Type?.index ?? 0),
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
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xFF5B5F61))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ));
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
