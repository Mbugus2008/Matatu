// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/wbridge_controller.dart';
import 'package:t_matatu/models/route.dart';
import 'package:t_matatu/models/weighbridge/wbridge.dart';

class TripFormPage extends StatefulWidget {
  final WbridgeTrip? trip;

  const TripFormPage({super.key, this.trip});

  @override
  State<TripFormPage> createState() => _TripFormPageState();
}

class _TripFormPageState extends State<TripFormPage> {
  late final WBridgeController _controller;
  final _formKey = GlobalKey<FormState>();
  final RouteService _routeService = RouteService();

  late final TextEditingController _fromCtrl;
  late final TextEditingController _toCtrl;
  late final TextEditingController _paxCtrl;
  late final TextEditingController _fareCtrl;
  late final TextEditingController _expensesCtrl;
  late final TextEditingController _receivedCtrl;
  late final TextEditingController _commentsCtrl;
  late TextEditingController _startedByCtrl;

  late TimeOfDay _fromTime;
  late TimeOfDay _toTime;

  List<RouteModel> _routes = [];

  bool get isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WBridgeController>();
    _loadRoutes();

    final t = widget.trip;
    _fromCtrl = TextEditingController(text: t?.From ?? '');
    _toCtrl = TextEditingController(text: t?.To ?? '');
    _paxCtrl = TextEditingController(text: t?.Pax_No?.toString() ?? '');
    _fareCtrl = TextEditingController(text: t?.Fare_Amount?.toString() ?? '');
    _expensesCtrl = TextEditingController(text: t?.Expenses?.toString() ?? '');
    _receivedCtrl = TextEditingController(text: t?.Amount_Received ?? '');
    _commentsCtrl = TextEditingController(text: t?.Comments ?? '');
    _startedByCtrl = TextEditingController(text: t?.Started_By ?? '');

    _fromTime = t?.From_Time != null
        ? TimeOfDay.fromDateTime(t!.From_Time!)
        : const TimeOfDay(hour: 8, minute: 0);
    _toTime = t?.To_Time != null
        ? TimeOfDay.fromDateTime(t!.To_Time!)
        : const TimeOfDay(hour: 14, minute: 0);
  }

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

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
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
      initialTime: isFrom ? _fromTime : _toTime,
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

    final wb = _controller.selectedWBridge.value;
    final now = DateTime.now();

    final trip = WbridgeTrip(
      Key: widget.trip?.Key,
      Weign_Bridge_id: widget.trip?.Weign_Bridge_id ?? wb?.Entry_No,
      Trip_No: widget.trip?.Trip_No,
      From: _fromCtrl.text.trim(),
      From_Time: DateTime(
          now.year, now.month, now.day, _fromTime.hour, _fromTime.minute),
      To: _toCtrl.text.trim(),
      To_Time:
          DateTime(now.year, now.month, now.day, _toTime.hour, _toTime.minute),
      Pax_No: int.tryParse(_paxCtrl.text) ?? 0,
      Fare_Amount: double.tryParse(_fareCtrl.text) ?? 0,
      Total: (int.tryParse(_paxCtrl.text) ?? 0) *
          (double.tryParse(_fareCtrl.text) ?? 0),
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
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Trip' : 'New Trip'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Route'),
              const SizedBox(height: 8),
              _buildRouteAutocomplete(_fromCtrl, 'From'),
              const SizedBox(height: 12),
              _buildRouteAutocomplete(_toCtrl, 'To'),
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
              const SizedBox(height: 16),
              _buildSectionHeader('Passenger & Fare'),
              const SizedBox(height: 8),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('Total: ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        NumberFormat('#,##0.00').format(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              _buildSectionHeader('Other Details'),
              const SizedBox(height: 8),
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
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: Obx(() => ElevatedButton(
                      onPressed: _controller.isLoading.value ? null : _save,
                      child: _controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing ? 'Update Trip' : 'Save Trip',
                              style: const TextStyle(fontSize: 16),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.blue[700],
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
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: required
          ? (value) => (value == null || value.trim().isEmpty)
              ? '$label is required'
              : null
          : null,
    );
  }

  Widget _buildRouteAutocomplete(TextEditingController ctrl, String label) {
    return TypeAheadField<RouteModel>(
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) return _routes;
        final query = pattern.toLowerCase();
        return _routes
            .where((r) =>
                (r.Code ?? '').toLowerCase().contains(query) ||
                (r.Description ?? '').toLowerCase().contains(query))
            .toList();
      },
      itemBuilder: (context, route) => ListTile(
        leading: const Icon(Icons.route_outlined, size: 20),
        title: Text(route.Description ?? route.Code ?? ''),
        subtitle: route.Code != null
            ? Text(route.Code!, style: const TextStyle(fontSize: 12))
            : null,
        dense: true,
      ),
      onSelected: (route) {
        ctrl.text = route.Description ?? route.Code ?? '';
      },
      builder: (context, controller, focusNode) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: '$label *',
            hintText: 'Search route...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.search, size: 20),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? '$label is required'
              : null,
        );
      },
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isFrom) {
    return InkWell(
      onTap: () => _selectTime(isFrom),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(time.format(context)),
      ),
    );
  }
}
