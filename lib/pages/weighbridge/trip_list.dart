// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/wbridge_controller.dart';
import 'package:t_matatu/models/weighbridge/wbridge.dart';
import 'package:t_matatu/pages/weighbridge/trip_form.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  late final WBridgeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WBridgeController>();
    final wb = _controller.selectedWBridge.value;
    if (wb?.Entry_No != null) {
      _controller.fetchTrips(wb!.Entry_No!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _controller.selectedWBridge.value?.Vehicle_No != null
              ? 'Trips — ${_controller.selectedWBridge.value!.Vehicle_No}'
              : 'Trips',
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToTripForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Trip'),
      ),
    );
  }

  Widget _buildHeader() {
    final wb = _controller.selectedWBridge.value;
    if (wb == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${wb.Vehicle_No} — ${wb.Fleet_No}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Driver: ${wb.Driver ?? '-'} | Cond: ${wb.Conductor ?? '-'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Target: ${NumberFormat('#,##0').format(wb.Target_Revenue ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Actual: ${NumberFormat('#,##0').format(wb.Actual_Revenue ?? 0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (_controller.trips.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.route_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No trips recorded',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: _controller.trips.length,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) {
          final trip = _controller.trips[index];
          return _buildTripCard(trip);
        },
      );
    });
  }

  Widget _buildTripCard(WbridgeTrip trip) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Trip #${trip.Trip_No ?? '-'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip.From ?? '?'} → ${trip.To ?? '?'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (trip.From_Time != null || trip.To_Time != null)
                        Text(
                          '${trip.From_Time != null ? DateFormat('HH:mm').format(trip.From_Time!) : '?'} — ${trip.To_Time != null ? DateFormat('HH:mm').format(trip.To_Time!) : '?'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _navigateToTripForm(trip: trip),
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Pax', '${trip.Pax_No ?? 0}', Icons.people),
                _statItem(
                  'Fare',
                  NumberFormat('#,##0').format(trip.Fare_Amount ?? 0),
                  Icons.money,
                ),
                _statItem(
                  'Total',
                  NumberFormat('#,##0').format(trip.Total ?? 0),
                  Icons.receipt_long,
                ),
                _statItem(
                  'Exp.',
                  NumberFormat('#,##0').format(trip.Expenses ?? 0),
                  Icons.money_off,
                ),
              ],
            ),
            if (trip.Comments != null && trip.Comments!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.comment, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        trip.Comments!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.blue[400]),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ],
    );
  }

  void _navigateToTripForm({WbridgeTrip? trip}) {
    Get.to(() => TripFormPage(trip: trip))?.then((_) {
      final wb = _controller.selectedWBridge.value;
      if (wb?.Entry_No != null) {
        _controller.fetchTrips(wb!.Entry_No!);
      }
    });
  }
}
