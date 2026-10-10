// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/agent_route.dart';
import 'package:t_matatu/models/route.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/utils/snackbar_service.dart';

class TripFormPage extends StatefulWidget {
  final WaybillTrip? trip;

  const TripFormPage({super.key, this.trip});

  @override
  State<TripFormPage> createState() => _TripFormPageState();
}

class _TripFormPageState extends State<TripFormPage> {
  static const _primaryGreen = Color(0xFF006B3F);
  static const _fieldFill = Color(0xFFF6FBF4);
  static const _pageBg = Color(0xFFEDF3EE);
  static const _mutedText = Color(0xFF6F7A71);

  late final WaybillController _controller;
  final _formKey = GlobalKey<FormState>();
  final RouteService _routeService = RouteService();

  late final TextEditingController _fromCtrl;
  late final TextEditingController _paxCtrl;
  late final TextEditingController _fareCtrl;
  late final TextEditingController _expensesCtrl;
  late final TextEditingController _receivedCtrl;
  late final TextEditingController _commentsCtrl;
  late TextEditingController _startedByCtrl;

  late TimeOfDay _fromTime;
  // Null while a trip is still open — saving an edit must not close it.
  // Create mode starts with the old default (14:00).
  TimeOfDay? _toTime;

  List<RouteModel> _routes = [];

  bool get isEditing => widget.trip != null;

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

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WaybillController>();
    _loadRoutes();

    final t = widget.trip;
    _fromCtrl = TextEditingController(text: t?.From ?? '');
    _paxCtrl = TextEditingController(text: t?.Pax_No?.toString() ?? '');
    _fareCtrl = TextEditingController(text: t?.Fare_Amount?.toString() ?? '');
    _expensesCtrl = TextEditingController(text: t?.Expenses?.toString() ?? '');
    _receivedCtrl = TextEditingController(text: t?.Amount_Received ?? '');
    _commentsCtrl = TextEditingController(text: t?.Comments ?? '');
    // Started By defaults to the logged-in user for new trips.
    final agent = Get.find<MainController>().agent.value;
    final agentLabel = (agent.Name != null && agent.Name!.isNotEmpty)
        ? agent.Name!
        : (agent.Agent_Code ?? '');
    _startedByCtrl = TextEditingController(text: t?.Started_By ?? agentLabel);

    _fromTime = t?.From_Time != null
        ? TimeOfDay.fromDateTime(t!.From_Time!)
        : const TimeOfDay(hour: 8, minute: 0);
    // Open trip: leave the arrival unset so an edit keeps it open. New trips
    // and closed trips keep the previous default/actual time.
    if (t == null) {
      _toTime = const TimeOfDay(hour: 14, minute: 0);
    } else if (t.To_Time != null) {
      _toTime = TimeOfDay.fromDateTime(t.To_Time!);
    } else {
      _toTime = null;
    }
  }

  Future<void> _loadRoutes() async {
    // Push anything captured offline before pulling the list, so a route added
    // on this device (or another one) shows up here and in BC.
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

  /// Creates a route from what the user typed in a From/To box and fills the
  /// field with it. The route is stored locally first, so this works offline;
  /// the push to Business Central happens straight away and is retried later
  /// if it does not get through.
  Future<void> _createRoute(
      TextEditingController ctrl, String description) async {
    final created = await _routeService.createRoute(description);
    await _loadRoutes();

    if (ctrl.text.trim().toLowerCase() == description.trim().toLowerCase()) {
      // Store the route code — NAV validates From/To against route codes.
      ctrl.text = created.Code ?? created.Description ?? description;
    }

    if (!mounted) return;
    setState(() {});
    SnackbarService.showSuccess(created.sent
        ? 'Route "${created.Description}" added and sent to Business Central'
        : 'Route "${created.Description}" saved - it will sync when online');
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _paxCtrl.dispose();
    _fareCtrl.dispose();
    _expensesCtrl.dispose();
    _receivedCtrl.dispose();
    _commentsCtrl.dispose();
    _startedByCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : (_toTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pax = int.tryParse(_paxCtrl.text) ?? 0;
    final fare = double.tryParse(_fareCtrl.text) ?? 0;
    if (pax <= 0) {
      Get.snackbar('Trip', 'Passengers must be at least 1');
      return;
    }
    if (fare <= 0) {
      Get.snackbar('Trip', 'Enter the fare amount');
      return;
    }

    final wb = _controller.selectedWaybill.value;
    final now = DateTime.now();
    // New trips take the next auto-incremented trip number; edits keep theirs.
    final tripNo = widget.trip?.Trip_No ??
        (wb == null ? null : await _controller.nextTripNo(wb));

    final trip = WaybillTrip(
      Key: widget.trip?.Key,
      Weign_Bridge_id: widget.trip?.Weign_Bridge_id ?? wb?.Entry_No,
      Trip_No: tripNo,
      From: _fromCtrl.text.trim(),
      Description: _routeDescription(_fromCtrl.text),
      From_Time: DateTime(
          now.year, now.month, now.day, _fromTime.hour, _fromTime.minute),
      To: widget.trip?.To,
      To_Time: _toTime == null
          ? null
          : DateTime(
              now.year, now.month, now.day, _toTime!.hour, _toTime!.minute),
      Pax_No: pax,
      Fare_Amount: fare,
      Total: pax * fare,
      Started_By: _startedByCtrl.text.trim(),
      Amount_Received: _receivedCtrl.text.trim(),
      Expenses: double.tryParse(_expensesCtrl.text) ?? 0,
      Comments: _commentsCtrl.text.trim(),
    );

    final saved = await _controller.saveTrip(trip);
    if (saved != null && mounted) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Trip' : 'New Trip',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(),
              _sectionCard(
                title: 'Route',
                icon: Icons.route_outlined,
                children: [
                  _buildRouteAutocomplete(_fromCtrl, 'From'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePicker('Departure', _fromTime, true),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimePicker('Arrival', _toTime, false),
                      ),
                    ],
                  ),
                ],
              ),
              _sectionCard(
                title: 'Passenger & Fare',
                icon: Icons.people_outline,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          _paxCtrl,
                          'Passengers',
                          required: true,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          _fareCtrl,
                          'Fare Amount',
                          required: true,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(builder: (context) {
                    final pax = int.tryParse(_paxCtrl.text) ?? 0;
                    final fare = double.tryParse(_fareCtrl.text) ?? 0;
                    final total = pax * fare;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _fieldFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long,
                              size: 18, color: _primaryGreen),
                          const SizedBox(width: 8),
                          const Text('Total',
                              style:
                                  TextStyle(fontSize: 13, color: _mutedText)),
                          const Spacer(),
                          Text(
                            NumberFormat('#,##0.00').format(total),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
              _sectionCard(
                title: 'Other Details',
                icon: Icons.notes_outlined,
                children: [
                  _buildTextField(_startedByCtrl, 'Started By'),
                  const SizedBox(height: 12),
                  _buildTextField(_receivedCtrl, 'Amount Received'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _expensesCtrl,
                    'Expenses',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _commentsCtrl,
                    'Comments',
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: Obx(() => ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _controller.isLoading.value ? null : _save,
                      child: _controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              isEditing ? 'Update Trip' : 'Save Trip',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    )),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Dark-green summary card: trip number, open/closed state and the running
  /// total — mirrors the card style used across the waybill screens.
  Widget _buildHeaderCard() {
    final total = (int.tryParse(_paxCtrl.text) ?? 0) *
        (double.tryParse(_fareCtrl.text) ?? 0);
    final open = !isEditing || (widget.trip?.isOpen ?? false);
    final status = !isEditing ? 'New' : (open ? 'Open' : 'Closed');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: Color(0x33FFFFFF),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.directions_bus, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Trip #${widget.trip?.Trip_No ?? '-'}' : 'Trip',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total',
                  style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 11)),
              Text(
                NumberFormat('#,##0').format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// White rounded card with a small green section header.
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _primaryGreen),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// Shared look for every input on this page.
  InputDecoration _fieldDecoration(String label,
      {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
          icon == null ? null : Icon(icon, size: 20, color: _primaryGreen),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: _fieldDecoration(label + (required ? ' *' : '')),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
              ? '$label is required'
              : null
          : null,
    );
  }

  Widget _buildRouteAutocomplete(TextEditingController ctrl, String label) {
    return TypeAheadField<_RouteSuggestion>(
      controller: ctrl,
      suggestionsCallback: (pattern) {
        final query = pattern.trim().toLowerCase();
        final matches = _routes
            .where((r) =>
                (r.Code ?? '').toLowerCase().contains(query) ||
                (r.Description ?? '').toLowerCase().contains(query))
            .map(_RouteSuggestion.existing)
            .toList();

        // Nothing matches what was typed, so offer to create it rather than
        // making the user leave the trip to go and add the route elsewhere.
        final alreadyExists = _routes.any((r) =>
            (r.Description ?? '').trim().toLowerCase() == query &&
            query.isNotEmpty);
        if (query.isNotEmpty && !alreadyExists) {
          matches.insert(0, _RouteSuggestion.create(pattern.trim()));
        }
        return matches;
      },
      itemBuilder: (context, suggestion) {
        if (suggestion.newDescription != null) {
          return ListTile(
            leading: const Icon(Icons.add_circle_outline,
                size: 20, color: Color(0xFF2E7D32)),
            title: Text('Add "${suggestion.newDescription}"'),
            subtitle: const Text('New route - saved here and sent to BC',
                style: TextStyle(fontSize: 12)),
            dense: true,
          );
        }

        final route = suggestion.route!;
        return ListTile(
          leading: const Icon(Icons.route_outlined, size: 20),
          title: Text(route.Description ?? route.Code ?? ''),
          subtitle: route.Code != null
              ? Text(route.Code!, style: const TextStyle(fontSize: 12))
              : null,
          dense: true,
        );
      },
      onSelected: (suggestion) async {
        if (suggestion.newDescription != null) {
          await _createRoute(ctrl, suggestion.newDescription!);
          return;
        }
        // NAV's trip From/To fields are route codes (with a table relation to
        // the Route table), so the code is stored — never the description.
        ctrl.text =
            suggestion.route!.Code ?? suggestion.route!.Description ?? '';
        setState(() {});
      },
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: _fieldDecoration('$label *',
              hint: 'Search route...', icon: Icons.search),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? '$label is required'
              : null,
        );
      },
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? time, bool isFrom) {
    return InkWell(
      onTap: () => _selectTime(isFrom),
      child: InputDecorator(
        decoration: _fieldDecoration(label, icon: Icons.access_time),
        child: Text(time?.format(context) ?? 'Not closed'),
      ),
    );
  }
}

/// A row in the From/To suggestion list: an existing route, or the offer to
/// create the route the user has just typed.
class _RouteSuggestion {
  const _RouteSuggestion.existing(RouteModel this.route)
      : newDescription = null;

  const _RouteSuggestion.create(String this.newDescription) : route = null;

  final RouteModel? route;
  final String? newDescription;
}
