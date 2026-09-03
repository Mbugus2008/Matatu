// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/pages/waybill/trip_form.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  late final WaybillController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WaybillController>();
    final wb = _controller.selectedWaybill.value;
    if (wb?.Entry_No != null) {
      _controller.fetchTrips(wb!.Entry_No!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _controller.selectedWaybill.value?.Vehicle_No != null
              ? 'Trips — ${_controller.selectedWaybill.value!.Vehicle_No}'
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
        onPressed: _showStartTripSheet,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start Trip'),
      ),
    );
  }

  Widget _buildHeader() {
    final wb = _controller.selectedWaybill.value;
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

  Widget _buildTripCard(WaybillTrip trip) {
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

  void _navigateToTripForm({WaybillTrip? trip}) {
    Get.to(() => TripFormPage(trip: trip))?.then((_) {
      final wb = _controller.selectedWaybill.value;
      if (wb?.Entry_No != null) {
        _controller.fetchTrips(wb!.Entry_No!);
      }
    });
  }

  // ─── Start Trip popup ────────────────────────────────
  void _showStartTripSheet() {
    final wb = _controller.selectedWaybill.value;
    if (wb == null) {
      Get.snackbar('Waybill', 'Select a waybill entry first');
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _StartTripSheet(
        controller: _controller,
        entryNo: wb.Entry_No,
      ),
    ).then((started) {
      if (started == true) {
        final entryNo = _controller.selectedWaybill.value?.Entry_No;
        if (entryNo != null) {
          _controller.fetchTrips(entryNo);
        }
        Get.snackbar('Start Trip', 'Trip started successfully');
      }
    });
  }
}

/// Popup form used to start a new trip quickly.
class _StartTripSheet extends StatefulWidget {
  final WaybillController controller;
  final int? entryNo;

  const _StartTripSheet({required this.controller, required this.entryNo});

  @override
  State<_StartTripSheet> createState() => _StartTripSheetState();
}

class _StartTripSheetState extends State<_StartTripSheet> {
  static const _primaryGreen = Color(0xFF006B3F);

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _paxCtrl = TextEditingController(text: '1');
  final _fareCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  TimeOfDay _departure = TimeOfDay.now();
  bool _saving = false;

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _paxCtrl.dispose();
    _fareCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  int get _pax => int.tryParse(_paxCtrl.text.trim()) ?? 0;
  double get _fare => double.tryParse(_fareCtrl.text.trim()) ?? 0;
  double get _total => _pax * _fare;

  Future<void> _pickDeparture() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departure,
    );
    if (picked != null) setState(() => _departure = picked);
  }

  Future<void> _start() async {
    final entryNo = widget.entryNo;
    if (entryNo == null) {
      Get.snackbar('Start Trip',
          'This waybill is not synced yet. Tap Sync on the waybill page and try again.');
      return;
    }
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      Get.snackbar('Start Trip', 'Enter From and To routes');
      return;
    }
    if (_pax <= 0) {
      Get.snackbar('Start Trip', 'Passengers must be at least 1');
      return;
    }

    setState(() => _saving = true);

    var nextNo = 1;
    for (final t in widget.controller.trips) {
      if ((t.Trip_No ?? 0) >= nextNo) nextNo = (t.Trip_No ?? 0) + 1;
    }

    final now = DateTime.now();
    final trip = WaybillTrip(
      Weign_Bridge_id: entryNo,
      Trip_No: nextNo,
      From: _fromCtrl.text.trim(),
      From_Time: DateTime(
          now.year, now.month, now.day, _departure.hour, _departure.minute),
      To: _toCtrl.text.trim(),
      Pax_No: _pax,
      Fare_Amount: _fare,
      Total: _total,
      Comments:
          _commentsCtrl.text.trim().isEmpty ? null : _commentsCtrl.text.trim(),
    );

    final saved = await _saveSafely(trip);
    if (!mounted) return;
    setState(() => _saving = false);

    if (saved != null) {
      Navigator.pop(context, true);
    } else {
      Get.snackbar('Start Trip', 'Failed to start trip');
    }
  }

  Future<WaybillTrip?> _saveSafely(WaybillTrip trip) async {
    try {
      return await widget.controller.saveTrip(trip);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Start Trip',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen)),
          const SizedBox(height: 12),
          TextField(
            controller: _fromCtrl,
            decoration: const InputDecoration(
              labelText: 'From',
              prefixIcon: Icon(Icons.trip_origin),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _toCtrl,
            decoration: const InputDecoration(
              labelText: 'To',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickDeparture,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Departure',
                prefixIcon: Icon(Icons.schedule),
                border: OutlineInputBorder(),
              ),
              child: Text(_departure.format(context)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _paxCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Passengers',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _fareCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Fare Amount',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Total',
              prefixIcon: Icon(Icons.receipt_long),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Color(0xFFF6FBF4),
            ),
            child: Text(NumberFormat('#,##0').format(_total)),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _commentsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Comments',
              prefixIcon: Icon(Icons.comment),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                  onPressed: _saving ? null : _start,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
