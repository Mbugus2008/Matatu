// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/expenses/vehicle_expenses.dart';
import 'package:t_matatu/models/waybill/waybill.dart';
import 'package:t_matatu/pages/waybill/start_trip_sheet.dart';
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

  /// Supervisors and admins can record expenses (fuel, police, ...) on an
  /// open trip — see Agent.canAddTripExpenses.
  bool get _canAddExpenses =>
      Get.find<MainController>().agent.value.canAddTripExpenses;

  /// "From — description" for the trip card, keeping "→ To" for older trips
  /// that still carry a To route.
  String _routeLine(WaybillTrip trip) {
    final from = (trip.From ?? '?').trim();
    final description = (trip.Description ?? '').trim();
    final base =
        (description.isEmpty || description.toUpperCase() == from.toUpperCase())
            ? from
            : '$from — $description';
    final to = (trip.To ?? '').trim();
    return to.isEmpty ? base : '$base → $to';
  }

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
                        _routeLine(trip),
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
            if (_canAddExpenses && trip.isOpen)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF006B3F),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.post_add, size: 18),
                  label: const Text('Add Expense'),
                  onPressed: () => _addExpense(trip),
                ),
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

  /// Supervisor/admin action: money spent on a trip (fuel, police, ...) while
  /// it is open. The amount adds to whatever is already on the trip; the
  /// reason is kept in the comments and on the vehicle-expenses journal.
  Future<void> _addExpense(WaybillTrip trip) async {
    final result = await showDialog<_ExpenseEntry>(
      context: context,
      builder: (_) => _AddExpenseDialog(trip: trip),
    );
    if (result == null || !mounted) return;

    trip.Expenses = (trip.Expenses ?? 0) + result.amount;
    if (result.note.isNotEmpty) {
      final line = 'Expense: ${result.note} '
          '(KSh ${NumberFormat('#,##0').format(result.amount)})';
      final existing = (trip.Comments ?? '').trim();
      trip.Comments = existing.isEmpty ? line : '$existing\n$line';
    }

    final saved = await _controller.saveTrip(trip);
    if (!mounted) return;
    if (saved != null) {
      await _storeVehicleExpense(trip, result);
      await _reload();
      _showInfoDialog(
          'Add Expense', 'Expense added — it will sync automatically.');
    } else {
      _showInfoDialog('Add Expense', 'Could not save the expense. Try again.');
    }
  }

  /// Mirrors the trip expense onto the vehicle-expenses journal so the depot
  /// reports see it too. The trip's code goes in Vehicle_No — that is how the
  /// office links a vehicle expense back to the trip it was spent on.
  Future<void> _storeVehicleExpense(
      WaybillTrip trip, _ExpenseEntry entry) async {
    final wb = _controller.selectedWaybill.value;
    final row = Vehicle_Expenses(
      Code: Vehicle_Expenses.newCode(),
      Vehicle_No: trip.Key,
      Date: DateTime.now(),
      DateSpecified: true,
      Description: entry.note.isEmpty ? null : entry.note,
      Created_By: Get.find<MainController>().agent.value.Agent_Code,
      Amount: entry.amount,
      AmountSpecified: true,
      Fleet_No: wb?.Fleet_No,
    );

    try {
      await row.saveLocal();
      // Best effort push — a row BC does not take stays pending for Post All.
      await Vehicle_Expenses.postRows([row]);
    } catch (_) {
      // Offline or page unavailable: the expense still reached the trip.
    }
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
      builder: (_) => StartTripSheet(
        controller: _controller,
        waybill: wb,
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

/// Dialog that captures an expense to add to a trip. Owns its controllers so
/// they are disposed with the dialog — disposing them right after showDialog
/// returns crashes while the route is still animating out.
class _AddExpenseDialog extends StatefulWidget {
  final WaybillTrip trip;

  const _AddExpenseDialog({required this.trip});

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountCtrl.text.trim()) ?? 0;
  String get _reason => _noteCtrl.text.trim();

  /// Both the amount and the reason are required — the reason is what the
  /// office reads on the vehicle-expenses record.
  bool get _valid => _amount > 0 && _reason.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final current = trip.Expenses ?? 0;

    return AlertDialog(
      title: const Text('Add Expense'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip #${trip.Trip_No ?? '-'} · '
            '${trip.From ?? '?'} → ${trip.To ?? '?'}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Current expenses: KSh ${NumberFormat('#,##0').format(current)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Amount to add',
              prefixText: 'KSh ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Reason *',
              hintText: 'e.g. fuel, police',
              border: OutlineInputBorder(),
            ),
          ),
          if (_amount > 0) ...[
            const SizedBox(height: 12),
            Text(
              'New total: KSh '
              '${NumberFormat('#,##0').format(current + _amount)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF006B3F)),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.pop(context, _ExpenseEntry(_amount, _reason))
              : null,
          child: const Text('Add'),
        ),
      ],
    );
  }
}

/// Values captured by the Add Expense dialog.
class _ExpenseEntry {
  final double amount;
  final String note;

  const _ExpenseEntry(this.amount, this.note);
}
