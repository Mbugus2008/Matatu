// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/models/waybill/waybill.dart';

class WaybillFormPage extends StatefulWidget {
  final Waybill? waybill;

  const WaybillFormPage({super.key, this.waybill});

  @override
  State<WaybillFormPage> createState() => _WaybillFormPageState();
}

class _WaybillFormPageState extends State<WaybillFormPage> {
  late final WaybillController _controller;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fleetCtrl;
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _driverCtrl;
  late final TextEditingController _conductorCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _actualCtrl;
  late final TextEditingController _cashCtrl;
  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _finishTime;
  bool _isSaving = false;

  // Holds the TypeAhead's internal controller so we can read/set text
  TextEditingController? _typeAheadCtrl;

  static const _primaryGreen = Color(0xFF006B3F);
  static const _onPrimary = Color(0xFFFFFFFF);
  static const _surfaceGreen = Color(0xFFF6FBF4);
  static const _targetGrey = Color(0xFF64748B);
  static const _actualGreen = Color(0xFF006B3F);
  static const _shortageRed = Color(0xFFB91C1C);
  static const _outline = Color(0xFF6F7A71);
  static const _surfaceVariant = Color(0xFFDFE4DD);
  static const _summaryBg = Color(0xFFF8FAFC);
  static const _successGreen = Color(0xFF166534);

  bool get isEditing => widget.waybill != null;

  double get _target => double.tryParse(_targetCtrl.text) ?? 0;
  double get _actual => double.tryParse(_actualCtrl.text) ?? 0;
  double get _shortage => _target - _actual;
  bool get _cashMatchesActual =>
      (double.tryParse(_cashCtrl.text) ?? 0) == _actual && _actual > 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WaybillController>();

    final wb = widget.waybill;
    _fleetCtrl = TextEditingController(text: wb?.Fleet_No ?? '');
    _vehicleCtrl = TextEditingController(text: wb?.Vehicle_No ?? '');
    _driverCtrl = TextEditingController(text: wb?.Driver ?? '');
    _conductorCtrl = TextEditingController(text: wb?.Conductor ?? '');
    _targetCtrl =
        TextEditingController(text: wb?.Target_Revenue?.toString() ?? '');
    _actualCtrl =
        TextEditingController(text: wb?.Actual_Revenue?.toString() ?? '');
    _cashCtrl = TextEditingController(text: wb?.Cash?.toString() ?? '');
    _selectedDate = wb?.Date ?? DateTime.now();
    _startTime = wb?.Start_Time != null
        ? TimeOfDay.fromDateTime(wb!.Start_Time!)
        : TimeOfDay.now();
    _finishTime = wb?.Finish_Time != null
        ? TimeOfDay.fromDateTime(wb!.Finish_Time!)
        : const TimeOfDay(hour: 18, minute: 0);

    // Rebuild on text changes for auto-calc
    _targetCtrl.addListener(() => setState(() {}));
    _actualCtrl.addListener(() => setState(() {}));
    _cashCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _fleetCtrl.dispose();
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    _conductorCtrl.dispose();
    _targetCtrl.dispose();
    _actualCtrl.dispose();
    _cashCtrl.dispose();
    super.dispose();
  }

  void _onFleetSelected(Vehicles vehicle) {
    setState(() {
      _fleetCtrl.text = vehicle.Fleet_No ?? '';
      _typeAheadCtrl?.text = vehicle.Fleet_No ?? '';
      _vehicleCtrl.text = vehicle.Vehicle_Number ?? '';
      _targetCtrl.text = (vehicle.Daily_Contribution ?? 0).toStringAsFixed(0);
      _loadCrewForVehicle(vehicle.Vehicle_Number);
    });
  }

  /// Load driver and conductor using MemberController (same as receipts page).
  void _loadCrewForVehicle(String? vehicleNo) {
    if (vehicleNo == null || vehicleNo.isEmpty) return;
    final memberCtrl = Get.find<MemberController>();
    memberCtrl.getcurrentcrew(vehicleNo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _driverCtrl.text = memberCtrl.currentdriver.value?.Name ?? '';
          _conductorCtrl.text = memberCtrl.currentcunductor.value?.Name ?? '';
        });
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _finishTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _finishTime = picked;
        }
      });
    }
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final waybill = Waybill(
      Key: widget.waybill?.Key,
      Vehicle_No: _vehicleCtrl.text.trim(),
      Fleet_No: _fleetCtrl.text.trim(),
      Driver: _driverCtrl.text.trim(),
      Conductor: _conductorCtrl.text.trim(),
      Date: _selectedDate,
      Start_Time: _combineDateAndTime(_selectedDate, _startTime),
      Finish_Time: _combineDateAndTime(_selectedDate, _finishTime),
      Target_Revenue: _target,
      Actual_Revenue: _actual,
      Shortage: _shortage,
      Cash: double.tryParse(_cashCtrl.text) ?? 0,
    );

    final saved = await _controller.saveWaybill(waybill);
    if (mounted) {
      setState(() => _isSaving = false);
      if (saved != null) Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceGreen,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: _onPrimary,
        elevation: 0,
        title: const Text('CityHoppa Waybill',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Page header ──
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isEditing ? 'Edit Entry' : 'New Entry',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen)),
                    const SizedBox(height: 4),
                    const Text(
                        'Fill in the daily trip and revenue details below.',
                        style: TextStyle(fontSize: 14, color: _outline)),
                  ],
                ),
              ),

              // ── Section 1: Vehicle ──
              _buildSectionCard(
                icon: Icons.directions_bus,
                title: 'Vehicle',
                child: Row(
                  children: [
                    Expanded(child: _buildFleetAutocomplete()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(_vehicleCtrl, 'Vehicle No',
                          enabled: false,
                          fillColor: _surfaceVariant.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 2: Crew ──
              _buildSectionCard(
                icon: Icons.group,
                title: 'Crew',
                child: Row(
                  children: [
                    Expanded(
                        child: _buildTextField(_driverCtrl, 'Driver',
                            hint: 'Driver Name')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTextField(_conductorCtrl, 'Conductor',
                            hint: 'Conductor Name')),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 3: Date & Time ──
              _buildSectionCard(
                icon: Icons.schedule,
                title: 'Date & Time',
                child: Column(
                  children: [
                    _buildDatePicker(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                            child: _buildTimePicker(
                                'Start Time', _startTime, true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _buildTimePicker(
                                'Finish Time', _finishTime, false)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 4: Revenue Metrics ──
              _buildSectionCard(
                icon: Icons.payments,
                title: 'Revenue Metrics',
                child: Column(
                  children: [
                    // Summary bar
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _summaryBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _surfaceVariant),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _summaryStat('Target', _target, _targetGrey),
                          ),
                          Container(
                              width: 1, height: 40, color: _surfaceVariant),
                          Expanded(
                            child:
                                _summaryStat('Actual', _actual, _actualGreen),
                          ),
                          Container(
                              width: 1, height: 40, color: _surfaceVariant),
                          Expanded(
                            child: _summaryStat('Shortage', _shortage,
                                _shortage > 0 ? _shortageRed : _outline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                                _targetCtrl, 'Target Revenue',
                                keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                                _actualCtrl, 'Actual Revenue',
                                keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              TextEditingController(
                                  text: _shortage.toStringAsFixed(2)),
                              'Shortage (Auto)',
                              enabled: false,
                              fillColor: _summaryBg,
                              textColor:
                                  _shortage > 0 ? _shortageRed : _outline,
                              bold: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Section 5: Payment ──
              _buildSectionCard(
                icon: Icons.account_balance_wallet,
                title: 'Payment Collection',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      _cashCtrl,
                      'Cash Input',
                      keyboardType: TextInputType.number,
                      prefix: 'KSh',
                    ),
                    if (_actual > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              _cashMatchesActual
                                  ? Icons.check_circle
                                  : Icons.warning_amber_rounded,
                              size: 14,
                              color: _cashMatchesActual
                                  ? _successGreen
                                  : _shortageRed,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _cashMatchesActual
                                  ? 'Matches Actual Revenue'
                                  : 'Does not match Actual Revenue (${NumberFormat('#,##0').format(_actual)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _cashMatchesActual
                                    ? _successGreen
                                    : _shortageRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      // ── Bottom Save Bar ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _surfaceVariant)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _onPrimary))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Save Entry',
                  style: const TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: _onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════ Section Card ═══════════════

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _primaryGreen)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ═══════════════ Summary Stat ═══════════════

  Widget _summaryStat(String label, double value, Color color) {
    final display = NumberFormat('#,##0').format(value);
    return Column(
      children: [
        Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: color)),
        const SizedBox(height: 2),
        Text(display,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: color)),
      ],
    );
  }

  // ═══════════════ Date Picker ═══════════════

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date',
          border: OutlineInputBorder(),
          filled: true,
        ),
        child: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
      ),
    );
  }

  // ═══════════════ Time Picker ═══════════════

  Widget _buildTimePicker(String label, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(isStart),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
        ),
        child: Text(time.format(context)),
      ),
    );
  }

  // ═══════════════ Text Field ═══════════════

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    Color? fillColor,
    Color? textColor,
    String? hint,
    String? prefix,
    bool bold = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: enabled,
      style: TextStyle(
        fontSize: 14,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: enabled
            ? (textColor ?? const Color(0xFF181D19))
            : const Color(0xFF6F7A71),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefix: prefix != null
            ? Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(prefix,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _outline)),
              )
            : null,
        filled: true,
        fillColor: fillColor ?? Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _surfaceVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryGreen, width: 2),
        ),
      ),
    );
  }

  // ═══════════════ Fleet Autocomplete ═══════════════

  Widget _buildFleetAutocomplete() {
    return TypeAheadField<Vehicles>(
      suggestionsCallback: (pattern) {
        if (pattern.isEmpty) return [];
        final query = pattern.toUpperCase();
        final vehicles = Get.find<VehiclesController>().allVehicles;
        return vehicles
            .where((v) =>
                (v.Fleet_No ?? '').toUpperCase().contains(query) ||
                (v.Vehicle_Number ?? '').toUpperCase().contains(query))
            .toList();
      },
      itemBuilder: (context, vehicle) {
        return ListTile(
          leading: const Icon(Icons.directions_bus, color: _primaryGreen),
          title: Text(vehicle.Fleet_No ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '${vehicle.Vehicle_Number ?? ''}  •  '
            '${vehicle_type_desc.desc[vehicle.Vehicle_Type] ?? ''}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        );
      },
      onSelected: _onFleetSelected,
      builder: (context, controller, focusNode) {
        _typeAheadCtrl = controller;
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Fleet No',
            hintText: 'Search Fleet No...',
            filled: true,
            prefixIcon: const Icon(Icons.search, color: _outline),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _surfaceVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _primaryGreen, width: 2),
            ),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Fleet No is required'
              : null,
        );
      },
    );
  }
}
