// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/route.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/pages/waybill/trip_form.dart';
import 'package:t_matatu/utils/crew_lookup.dart';

class TripListPage extends StatefulWidget {
  const TripListPage({super.key});

  @override
  State<TripListPage> createState() => _TripListPageState();
}

class _TripListPageState extends State<TripListPage> {
  late final WaybillController _controller;

  /// Page-local loading flag. The controller's isLoading is shared with the
  /// other waybill screens, so watching it here made this page's Obx rebuild
  /// while another screen was mid-build.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WaybillController>();
    // initState runs during the build phase, and _reload() flips isLoading on
    // the shared controller. Doing that here marks the still-mounted Obx of the
    // previous screen dirty mid-build ("setState() called during build") and
    // aborts this page's build, leaving it stuck on the spinner.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  /// Reloads the trips of the selected waybill plus the waybill-level totals
  /// shown on the list screen. The two reads run one after the other — firing
  /// them together made the trip read stall on the shared SQLite connection.
  Future<void> _reload() async {
    if (mounted) setState(() => _loading = true);
    final wb = _controller.selectedWaybill.value;
    await _controller.fetchTrips(wb?.Entry_No, waybillKey: wb?.Key);
    await _controller.loadTripTotals();
    if (mounted) setState(() => _loading = false);
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
                  'Driver: ${crewLabelFor(wb.Driver)} | Cond: ${crewLabelFor(wb.Conductor)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Target = sum of all trip totals; Actual = received on closed trips.
          Obx(() {
            final trips = _controller.trips;
            final target =
                trips.fold<double>(0, (sum, t) => sum + (t.Total ?? 0));
            final actual = trips.where((t) => t.To_Time != null).fold<double>(
                0, (sum, t) => sum + _receivedValue(t.Amount_Received));
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Target: ${NumberFormat('#,##0').format(target)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Actual: ${NumberFormat('#,##0').format(actual)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  /// Numeric value of Amount_Received (stored as text).
  double _receivedValue(String? value) {
    if (value == null || value.trim().isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0;
  }

  Widget _buildList() {
    return Obx(() {
      final trips = _controller.trips;
      // Reading length subscribes this Obx to the list — referencing the RxList
      // field alone does not, and returning without a subscription makes GetX
      // throw "[Get] the improper use of a GetX has been detected".
      final count = trips.length;

      if (_loading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (count == 0) {
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
        itemCount: count,
        padding: const EdgeInsets.only(bottom: 80),
        itemBuilder: (context, index) => _buildTripCard(trips[index]),
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
                if (trip.To_Time == null)
                  IconButton(
                    tooltip: 'Edit Trip',
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => _navigateToTripForm(trip: trip),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'CLOSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
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
                  'Received',
                  _formatReceived(trip.Amount_Received),
                  Icons.payments,
                ),
                _statItem(
                  'Exp.',
                  NumberFormat('#,##0').format(trip.Expenses ?? 0),
                  Icons.money_off,
                ),
              ],
            ),
            if (trip.To_Time == null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006B3F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.flag, size: 20),
                    label: const Text(
                      'Close Trip',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    onPressed: () => _closeTrip(trip),
                  ),
                ),
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

  /// Amount received is stored as text; format it when it is numeric.
  String _formatReceived(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final parsed = double.tryParse(value.replaceAll(',', '').trim());
    if (parsed == null) return value;
    return NumberFormat('#,##0').format(parsed);
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
    Get.to(() => TripFormPage(trip: trip))?.then((_) => _reload());
  }

  /// Opens the close-trip popup (same style as Start Trip).
  void _closeTrip(WaybillTrip trip) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CloseTripSheet(
        controller: _controller,
        trip: trip,
      ),
    ).then((closed) {
      if (closed == true) {
        _reload();
        _showInfoDialog(
            'Close Trip', 'Trip closed. It will sync automatically.');
      }
    });
  }

  // ─── Start Trip popup ────────────────────────────────
  void _showStartTripSheet() {
    final wb = _controller.selectedWaybill.value;
    if (wb == null) {
      _showInfoDialog('Waybill', 'Select a waybill entry first');
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
        vehicleNo: wb.Vehicle_No,
        waybillKey: wb.Key,
      ),
    ).then((started) {
      if (started == true) {
        _reload();
        _showInfoDialog(
            'Start Trip',
            'Trip saved locally — it will sync once '
                'the waybill is synced.');
      }
    });
  }

  void _showInfoDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}

/// Popup form used to start a new trip quickly.
class _StartTripSheet extends StatefulWidget {
  final WaybillController controller;
  final int? entryNo;
  final String? vehicleNo;
  final String? waybillKey;

  const _StartTripSheet({
    required this.controller,
    required this.entryNo,
    this.vehicleNo,
    this.waybillKey,
  });

  @override
  State<_StartTripSheet> createState() => _StartTripSheetState();
}

class _StartTripSheetState extends State<_StartTripSheet> {
  static const _primaryGreen = Color(0xFF006B3F);

  final RouteService _routeService = RouteService();
  List<RouteModel> _routes = [];

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _paxCtrl = TextEditingController(text: '1');
  final _fareCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  TimeOfDay _departure = TimeOfDay.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefillCapacity();
    _loadRoutes();
  }

  /// Prefills passengers from the vehicle's capacity (derived from its type,
  /// e.g. "33 Seater" -> 33).
  void _prefillCapacity() {
    final vehicleNo = widget.vehicleNo;
    if (vehicleNo == null || vehicleNo.isEmpty) return;
    if (!Get.isRegistered<VehiclesController>()) return;

    try {
      Vehicles? vehicle;
      for (final v in Get.find<VehiclesController>().allVehicles) {
        if (v.Vehicle_Number == vehicleNo) {
          vehicle = v;
          break;
        }
      }
      if (vehicle == null) return;

      final desc = vehicle_type_desc.desc[vehicle.Vehicle_Type] ?? '';
      final digits = RegExp(r'\d+').firstMatch(desc)?.group(0);
      if (digits != null && digits.isNotEmpty) {
        _paxCtrl.text = digits;
      }
    } catch (_) {
      // Capacity prefill is a convenience only.
    }
  }

  /// Load routes from local DB, syncing from BC when empty.
  Future<void> _loadRoutes() async {
    final routes = await _routeService.loadFromLocalDB();
    if (routes.isEmpty) {
      await _routeService.syncRoutes();
      final refreshed = await _routeService.loadFromLocalDB();
      if (mounted) setState(() => _routes = refreshed);
    } else {
      if (mounted) setState(() => _routes = routes);
    }
  }

  Widget _buildRouteField(TextEditingController ctrl, String label,
      {TextEditingController? other}) {
    return InkWell(
      onTap: () => _pickRoute(ctrl, label, exclude: other?.text),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Tap to select route',
          prefixIcon:
              Icon(label == 'From' ? Icons.trip_origin : Icons.location_on),
          suffixIcon: const Icon(Icons.arrow_drop_down),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          ctrl.text.isEmpty ? 'Select route' : ctrl.text,
          style: TextStyle(color: ctrl.text.isEmpty ? Colors.grey : null),
        ),
      ),
    );
  }

  /// Opens a searchable list of routes and stores the picked one.
  /// Any route already chosen in the other field is hidden.
  Future<void> _pickRoute(TextEditingController ctrl, String label,
      {String? exclude}) async {
    if (_routes.isEmpty) {
      await _loadRoutes();
    }
    if (!mounted) return;
    if (_routes.isEmpty) {
      _showDialog('Route',
          'No routes available. Check the connection, then try again.');
      return;
    }

    var query = '';
    final selected = await showDialog<RouteModel>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final excluded = (exclude ?? '').trim().toLowerCase();
          final available = excluded.isEmpty
              ? _routes
              : _routes
                  .where((r) =>
                      (r.Description ?? r.Code ?? '').trim().toLowerCase() !=
                      excluded)
                  .toList();
          final filtered = query.isEmpty
              ? available
              : available
                  .where((r) =>
                      (r.Code ?? '')
                          .toLowerCase()
                          .contains(query.toLowerCase()) ||
                      (r.Description ?? '')
                          .toLowerCase()
                          .contains(query.toLowerCase()))
                  .toList();
          return AlertDialog(
            title: Text('Select $label Route'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search route...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setDialogState(() => query = value.trim()),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('No matching routes'),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, index) {
                              final route = filtered[index];
                              return ListTile(
                                dense: true,
                                leading:
                                    const Icon(Icons.route_outlined, size: 20),
                                title:
                                    Text(route.Description ?? route.Code ?? ''),
                                subtitle: route.Code != null
                                    ? Text(route.Code!,
                                        style: const TextStyle(fontSize: 12))
                                    : null,
                                onTap: () =>
                                    Navigator.pop(dialogContext, route),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );

    if (selected != null && mounted) {
      setState(() => ctrl.text = selected.Description ?? selected.Code ?? '');
    }
  }

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
    if (_fromCtrl.text.trim().isEmpty || _toCtrl.text.trim().isEmpty) {
      _showDialog('Start Trip', 'Enter From and To routes');
      return;
    }
    if (_pax <= 0) {
      _showDialog('Start Trip', 'Passengers must be at least 1');
      return;
    }

    setState(() => _saving = true);

    var nextNo = 1;
    for (final t in widget.controller.trips) {
      if ((t.Trip_No ?? 0) >= nextNo) nextNo = (t.Trip_No ?? 0) + 1;
    }

    final now = DateTime.now();
    final trip = WaybillTrip(
      // Null when the waybill is not synced yet — the trip is saved locally
      // and linked by Waybill_Key until BC assigns its entry number.
      Weign_Bridge_id: entryNo,
      Waybill_Key: widget.waybillKey,
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
      _showDialog('Start Trip', 'Failed to start trip');
    }
  }

  Future<WaybillTrip?> _saveSafely(WaybillTrip trip) async {
    try {
      return await widget.controller.saveTrip(trip);
    } catch (_) {
      return null;
    }
  }

  void _showDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
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
          _buildRouteField(_fromCtrl, 'From', other: _toCtrl),
          const SizedBox(height: 10),
          _buildRouteField(_toCtrl, 'To', other: _fromCtrl),
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

/// Popup used to close an open trip (mirrors the Start Trip sheet).
class _CloseTripSheet extends StatefulWidget {
  final WaybillController controller;
  final WaybillTrip trip;

  const _CloseTripSheet({required this.controller, required this.trip});

  @override
  State<_CloseTripSheet> createState() => _CloseTripSheetState();
}

class _CloseTripSheetState extends State<_CloseTripSheet> {
  static const _primaryGreen = Color(0xFF006B3F);

  late TimeOfDay _endTime;
  late final TextEditingController _commentsCtrl;
  late final TextEditingController _receivedCtrl;
  late final TextEditingController _expensesCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endTime = TimeOfDay(hour: now.hour, minute: now.minute);
    _commentsCtrl = TextEditingController(text: widget.trip.Comments ?? '');
    _receivedCtrl =
        TextEditingController(text: widget.trip.Amount_Received ?? '');
    _expensesCtrl =
        TextEditingController(text: widget.trip.Expenses?.toString() ?? '');
  }

  @override
  void dispose() {
    _commentsCtrl.dispose();
    _receivedCtrl.dispose();
    _expensesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickEndTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _endTime);
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _close() async {
    setState(() => _saving = true);

    final now = DateTime.now();
    final trip = widget.trip;
    trip.To_Time =
        DateTime(now.year, now.month, now.day, _endTime.hour, _endTime.minute);
    trip.Ended_by = Get.find<MainController>().agent.value.Agent_Code;
    trip.Amount_Received =
        _receivedCtrl.text.trim().isEmpty ? null : _receivedCtrl.text.trim();
    trip.Expenses =
        double.tryParse(_expensesCtrl.text.trim()) ?? widget.trip.Expenses ?? 0;
    trip.Comments =
        _commentsCtrl.text.trim().isEmpty ? null : _commentsCtrl.text.trim();

    WaybillTrip? saved;
    try {
      saved = await widget.controller.saveTrip(trip);
    } catch (_) {
      saved = null;
    }
    if (!mounted) return;
    setState(() => _saving = false);

    if (saved != null) {
      Navigator.pop(context, true);
    } else {
      _showError('Failed to close the trip');
    }
  }

  void _showError(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Close Trip'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
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
          const Text('Close Trip',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FBF4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${trip.From ?? '?'} → ${trip.To ?? '?'}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Trip #${trip.Trip_No ?? '-'} · Pax ${trip.Pax_No ?? 0} · '
                  'Total ${NumberFormat('#,##0').format(trip.Total ?? 0)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickEndTime,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'End Time',
                prefixIcon: Icon(Icons.schedule),
                border: OutlineInputBorder(),
              ),
              child: Text(_endTime.format(context)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _receivedCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Amount Received',
                    prefixIcon: Icon(Icons.payments),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _expensesCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Expenses',
                    prefixIcon: Icon(Icons.money_off),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
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
                      : const Icon(Icons.flag),
                  label: const Text('Close Trip'),
                  onPressed: _saving ? null : _close,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
