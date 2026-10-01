// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/agent_route.dart';
import 'package:t_matatu/models/route.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/utils/crew_lookup.dart';

/// Start Trip popup — the app's primary waybill action.
///
/// Opened from the waybill list without [waybill]: the user picks the vehicle
/// and the day's entry is found — or created silently — behind the scenes.
/// Opened from an entry's trip list with [waybill] set: the trip joins it.
class StartTripSheet extends StatefulWidget {
  final WaybillController controller;
  final Waybill? waybill;

  const StartTripSheet({super.key, required this.controller, this.waybill});

  @override
  State<StartTripSheet> createState() => _StartTripSheetState();
}

class _StartTripSheetState extends State<StartTripSheet> {
  static const _primaryGreen = Color(0xFF006B3F);
  static const _outline = Color(0xFF6F7A71);

  final RouteService _routeService = RouteService();
  List<RouteModel> _routes = [];

  // Vehicle picked when the sheet starts a fresh day (no entry yet).
  Vehicles? _vehicle;
  TextEditingController? _typeAheadCtrl;
  String? _driverNo;
  String? _conductorNo;

  final _fromCtrl = TextEditingController();
  final _paxCtrl = TextEditingController(text: '1');
  final _fareCtrl = TextEditingController();
  final _commentsCtrl = TextEditingController();
  TimeOfDay _departure = TimeOfDay.now();
  bool _saving = false;

  bool get _freshStart => widget.waybill == null;

  @override
  void initState() {
    super.initState();
    if (!_freshStart) {
      // The trip joins the entry the user already opened.
      _adoptVehicle(widget.waybill!.Vehicle_No, prefillPax: true);
    }
    _loadRoutes();
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _paxCtrl.dispose();
    _fareCtrl.dispose();
    _commentsCtrl.dispose();
    super.dispose();
  }

  // ─── Vehicle ─────────────────────────────────────────

  /// Crew attached to [vehicleNo], plus optional passenger prefill.
  void _adoptVehicle(String? vehicleNo, {bool prefillPax = false}) {
    if (vehicleNo == null || vehicleNo.isEmpty) return;
    final (driverNo, conductorNo) = crewNumbersForVehicle(vehicleNo);
    _driverNo = driverNo;
    _conductorNo = conductorNo;
    if (prefillPax) _prefillCapacity(vehicleNo);
  }

  /// Prefills passengers from the vehicle's capacity (derived from its type,
  /// e.g. "33 Seater" -> 33).
  void _prefillCapacity(String vehicleNo) {
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

  void _onVehicleSelected(Vehicles vehicle) {
    setState(() {
      _vehicle = vehicle;
      final fleet = (vehicle.Fleet_No ?? '').trim();
      final plate = (vehicle.Vehicle_Number ?? '').trim();
      // Show the vehicle number (plate) in the field the user searched with.
      _typeAheadCtrl?.text = plate.isNotEmpty ? plate : fleet;
      _adoptVehicle(plate, prefillPax: true);
    });
  }

  bool get _crewKnown =>
      (_driverNo ?? '').trim().isNotEmpty &&
      (_conductorNo ?? '').trim().isNotEmpty;

  Widget _buildVehiclePicker() {
    return TypeAheadField<Vehicles>(
      suggestionsCallback: (pattern) {
        final query = pattern.trim().toUpperCase();
        final vehicles = Get.find<VehiclesController>().allVehicles;
        if (query.isEmpty) return vehicles.take(8).toList();
        return vehicles
            .where((v) =>
                (v.Fleet_No ?? '').toUpperCase().contains(query) ||
                (v.Vehicle_Number ?? '').toUpperCase().contains(query))
            .take(12)
            .toList();
      },
      itemBuilder: (context, vehicle) => ListTile(
        dense: true,
        leading:
            const Icon(Icons.directions_bus, size: 20, color: _primaryGreen),
        title: Text(
          'Fleet ${vehicle.Fleet_No ?? ''} — ${vehicle.Vehicle_Number ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          vehicle_type_desc.desc[vehicle.Vehicle_Type] ?? '',
          style: const TextStyle(fontSize: 12),
        ),
      ),
      onSelected: _onVehicleSelected,
      builder: (context, controller, focusNode) {
        _typeAheadCtrl = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Vehicle',
            hintText: 'Search fleet or plate...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        );
      },
    );
  }

  Widget _buildCrewLine() {
    final attached = _crewKnown;
    final driver = crewNameFor(_driverNo) ?? _driverNo;
    final conductor = crewNameFor(_conductorNo) ?? _conductorNo;

    return Row(
      children: [
        Icon(
          attached ? Icons.check_circle_outline : Icons.info_outline,
          size: 16,
          color: attached ? _primaryGreen : const Color(0xFFB45309),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            attached
                ? 'Crew: $driver / $conductor'
                : 'No crew attached yet — attach a driver and conductor on '
                    'the Crew screen so the waybill can sync.',
            style: TextStyle(
              fontSize: 12,
              color: attached ? _outline : const Color(0xFFB45309),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Routes ──────────────────────────────────────────

  /// Load routes from local DB, refreshing from BC first so the codes match
  /// what NAV's trip table accepts.
  Future<void> _loadRoutes() async {
    // Push anything captured offline before pulling the list.
    await _routeService.syncPendingRoutes();
    // Always refresh: NAV validates From/To against its current route codes.
    await _routeService.syncRoutes();
    // Agent-route assignments decide which routes this agent may pick.
    await AgentRouteService().syncAgentRoutes();

    final loaded = await _routeService.loadFromLocalDB();
    final agentCode = Get.find<MainController>().agent.value.Agent_Code;
    final allowed = await AgentRouteService().routeCodesForAgent(agentCode);
    final routes = AgentRouteService.allowedRoutes(loaded, allowed);
    if (mounted) setState(() => _routes = routes);
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
      // NAV's trip From/To fields are route codes (with a table relation to the
      // Route table), so the code is stored — never the description.
      setState(() => ctrl.text = selected.Code ?? selected.Description ?? '');
    }
  }

  // ─── Trip details ────────────────────────────────────

  int get _pax => int.tryParse(_paxCtrl.text.trim()) ?? 0;
  double get _fare => double.tryParse(_fareCtrl.text.trim()) ?? 0;
  double get _total => _pax * _fare;

  /// Description of the route stored in [fromText] (a code), from the local
  /// route list. NAV stores it on the trip for reporting.
  String? _routeDescription(String? fromText) {
    final target = (fromText ?? '').trim().toUpperCase();
    if (target.isEmpty) return null;
    for (final r in _routes) {
      if ((r.Code ?? '').trim().toUpperCase() == target) return r.Description;
    }
    return null;
  }

  Future<void> _pickDeparture() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _departure,
    );
    if (picked != null) setState(() => _departure = picked);
  }

  Future<void> _start() async {
    if (_freshStart && _vehicle == null) {
      _showDialog('Start Trip', 'Select the vehicle from the list');
      return;
    }
    if (_fromCtrl.text.trim().isEmpty) {
      _showDialog('Start Trip', 'Select the From route');
      return;
    }
    if (_pax <= 0) {
      _showDialog('Start Trip', 'Passengers must be at least 1');
      return;
    }
    if (_fare <= 0) {
      _showDialog('Start Trip', 'Enter the fare amount');
      return;
    }

    setState(() => _saving = true);

    // Silent entry: the day's waybill for the vehicle is reused or created
    // now — the user only ever sees Start Trip.
    Waybill? entry = widget.waybill;
    if (entry == null) {
      final vehicle = _vehicle!;
      entry = await widget.controller.ensureEntryForVehicle(vehicle: vehicle);
      if (entry == null) {
        if (!mounted) return;
        setState(() => _saving = false);
        _showDialog(
            'Start Trip',
            'Could not create the day\'s waybill for '
                '${vehicle.Vehicle_Number}. Try again.');
        return;
      }
    }

    final nextNo = await widget.controller.nextTripNo(entry);

    final now = DateTime.now();
    final day = entry.Date ?? now;
    final trip = WaybillTrip(
      // Null when the waybill is not synced yet — the trip is saved locally
      // and linked by Waybill_Key until BC assigns its entry number.
      Weign_Bridge_id: entry.Entry_No,
      Waybill_Key: entry.Key,
      Trip_No: nextNo,
      From: _fromCtrl.text.trim(),
      Description: _routeDescription(_fromCtrl.text),
      From_Time: DateTime(
          day.year, day.month, day.day, _departure.hour, _departure.minute),
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Start Trip',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen)),
            const SizedBox(height: 4),
            Text(
              _freshStart
                  ? 'Pick the vehicle — the day\'s waybill is created '
                      'automatically.'
                  : 'Vehicle: ${widget.waybill?.Vehicle_No ?? ''} — the trip '
                      'is added to this entry.',
              style: const TextStyle(fontSize: 12, color: _outline),
            ),
            const SizedBox(height: 12),
            if (_freshStart) ...[
              _buildVehiclePicker(),
              const SizedBox(height: 8),
              _buildCrewLine(),
              const SizedBox(height: 12),
            ],
            _buildRouteField(_fromCtrl, 'From'),
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
      ),
    );
  }
}
