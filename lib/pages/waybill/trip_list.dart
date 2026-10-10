// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/models/expenses/vehicle_expenses.dart';
import 'package:t_matatu/models/waybill/trip_comment.dart';
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

  /// Comment records for the trips on screen, keyed by Trip_No — shown on
  /// the cards and refreshed after the comments dialog closes.
  Map<int, TripComment> _tripComments = {};

  /// Supervisors, admins and controllers can record expenses (fuel,
  /// police, ...) on an open trip — see Agent.canAddTripExpenses.
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
    await _loadTripComments();
    if (mounted) setState(() => _loading = false);
  }

  /// Loads the comment records for the trips currently on screen.
  Future<void> _loadTripComments() async {
    try {
      final ids = _controller.trips
          .map((t) => t.Trip_No ?? 0)
          .where((n) => n > 0)
          .toList();
      final map = await TripComment.forTrips(ids);
      if (mounted) setState(() => _tripComments = map);
    } catch (_) {
      // The cards simply show no comments when the local read fails.
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
    final wb = _controller.selectedWaybill.value;
    final comment = _tripComments[trip.Trip_No ?? 0];
    final commentText = (comment?.Comments ?? '').trim();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Touching anywhere on the card opens the trip's full details.
        onTap: () => _showTripDetails(trip, wb),
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
                        // Closed trips name the receipt that settled them.
                        if (trip.To_Time != null &&
                            (wb?.Receipt_No ?? '').trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Closed by receipt ${wb!.Receipt_No!.trim()}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B5FA5),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Comments are logged while the trip is OPEN. Closed trips
                  // show no card actions — the trip is done.
                  if (trip.To_Time == null) ...[
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0B5FA5),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        minimumSize: const Size(0, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.mode_comment_outlined, size: 16),
                      label: const Text(
                        'Add comments',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () => _addComment(trip),
                    ),
                  ],
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
              // The trip's comment record (BC TripComments) — the same text the
              // "Add comments" dialog writes. Full text shows in the popup.
              if (commentText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFFECB3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.mode_comment_outlined,
                            size: 14, color: Color(0xFFB45309)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            commentText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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

  // The card's edit pencil was removed (2026-10-07) — kept so the trip form
  // can be re-entered from another spot if needed.
  // ignore: unused_element
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
  /// reports see it too. BC caps the journal's Vehicle No at 10 characters,
  /// so it carries the trip's id — its auto-incrementing trip number, e.g.
  /// "59" — which the office uses to link an expense back to its trip.
  /// Until the number is known the trip key is stored instead and
  /// [Vehicle_Expenses.repairLegacyTripKeys] rewrites it at sign-in.
  Future<void> _storeVehicleExpense(
      WaybillTrip trip, _ExpenseEntry entry) async {
    final wb = _controller.selectedWaybill.value;
    final row = Vehicle_Expenses(
      Code: Vehicle_Expenses.newCode(),
      Vehicle_No:
          Vehicle_Expenses.tripLabel(tripNo: trip.Trip_No, fallback: trip.Key),
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

  /// Opens the close-trip popup (same style as Start Trip) — reached from
  /// the trip details popup on an open trip.
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

  /// Comments are logged on OPEN trips: the text is kept on the device per
  /// trip and mirrored to BC's TripComments page (one record per Trip_Id).
  Future<void> _addComment(WaybillTrip trip) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TripCommentsDialog(trip: trip),
    );
    // The cards show the comment text, so pick up whatever was added.
    _loadTripComments();
  }

  /// Tap-a-trip popup: everything recorded for the trip in one place.
  void _showTripDetails(WaybillTrip trip, Waybill? wb) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _TripDetailsSheet(
        trip: trip,
        routeLine: _routeLine(trip),
        receivedLabel: _formatReceived(trip.Amount_Received),
        receiptNo: (wb?.Receipt_No ?? '').trim(),
        comment: _tripComments[trip.Trip_No ?? 0],
        // Closing moved off the card (too easy to hit by accident) — open
        // trips can still be closed deliberately from their details popup.
        onCloseTrip: trip.To_Time == null ? () => _closeTrip(trip) : null,
      ),
    );
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

/// Dialog behind "Add comments" on a trip.
///
/// BC's TripComments page keeps ONE record per trip (keyed by Trip_Id), so
/// every comment the user adds is appended to that record's text as a
/// stamped block — who wrote it and when stays visible in the text itself.
class _TripCommentsDialog extends StatefulWidget {
  final WaybillTrip trip;

  const _TripCommentsDialog({required this.trip});

  @override
  State<_TripCommentsDialog> createState() => _TripCommentsDialogState();
}

class _TripCommentsDialogState extends State<_TripCommentsDialog> {
  final TextEditingController _inputCtrl = TextEditingController();
  TripComment? _existing;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    TripComment? row;
    try {
      row = await TripComment.forTrip(widget.trip.Trip_No);
    } catch (_) {
      row = null;
    }
    if (!mounted) return;
    setState(() {
      _existing = row;
      _loading = false;
    });
  }

  String get _agentCode {
    try {
      return Get.find<MainController>().agent.value.Agent_Code ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _save() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final row = _existing ??
          TripComment(
            Code: TripComment.newCode(),
            Trip_Id: widget.trip.Trip_No,
          );
      row.Trip_Id ??= widget.trip.Trip_No;
      row.Comments = TripComment.appendBlock(
        existing: _existing?.Comments,
        text: text,
        user: _agentCode,
        at: now,
      );
      row.User = _agentCode;
      row.Date_time = now;
      // Edited locally — BC still needs the update.
      row.sent = false;
      await row.saveLocal();
      _existing = row;
      _inputCtrl.clear();
      // Best effort push — a row BC does not take stays pending for the next
      // upload/retry cycle.
      TripComment.postPending().catchError((_) => 0);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment saved — it will sync automatically.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripNo = widget.trip.Trip_No;
    final existingText = (_existing?.Comments ?? '').trim();

    return AlertDialog(
      title: Text('Trip #${tripNo ?? '-'} comments'),
      content: SizedBox(
        width: double.maxFinite,
        child: _loading
            ? const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (existingText.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        existingText,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(
                      'No comments on this trip yet.',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _inputCtrl,
                    maxLines: 3,
                    minLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'New comment',
                      hintText: 'e.g. breakdown, accident, police...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

/// Details for one trip — opened by touching a trip card. Open trips can be
/// closed from here.
class _TripDetailsSheet extends StatelessWidget {
  final WaybillTrip trip;
  final String routeLine;
  final String receivedLabel;
  final String receiptNo;
  final TripComment? comment;

  /// Present for open trips — closes the trip, then refreshes the list.
  final VoidCallback? onCloseTrip;

  const _TripDetailsSheet({
    required this.trip,
    required this.routeLine,
    required this.receivedLabel,
    required this.receiptNo,
    this.comment,
    this.onCloseTrip,
  });

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0');
    final commentText = (comment?.Comments ?? '').trim();
    final notes = (trip.Comments ?? '').trim();
    final closed = trip.To_Time != null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
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
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        closed ? Colors.grey.shade200 : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    closed ? 'CLOSED' : 'OPEN',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color:
                          closed ? Colors.grey[700] : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(routeLine,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (trip.From_Time != null || trip.To_Time != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${trip.From_Time != null ? DateFormat('HH:mm').format(trip.From_Time!) : '?'} — ${trip.To_Time != null ? DateFormat('HH:mm').format(trip.To_Time!) : 'not closed'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ),
            if (closed && receiptNo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_outlined,
                        size: 15, color: Color(0xFF0B5FA5)),
                    const SizedBox(width: 4),
                    Text(
                      'Closed by receipt $receiptNo',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B5FA5),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 24),
            _detailRow('Pax', '${trip.Pax_No ?? 0}'),
            _detailRow('Fare', money.format(trip.Fare_Amount ?? 0)),
            _detailRow('Total', money.format(trip.Total ?? 0)),
            _detailRow('Received', receivedLabel),
            _detailRow('Expenses', money.format(trip.Expenses ?? 0)),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Notes',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(notes,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontStyle: FontStyle.italic)),
            ],
            if (commentText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFECB3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.mode_comment_outlined,
                            size: 14, color: Color(0xFFB45309)),
                        SizedBox(width: 4),
                        Text(
                          'Comments',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB45309)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(commentText, style: const TextStyle(fontSize: 12.5)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (onCloseTrip != null) ...[
              SizedBox(
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onCloseTrip!();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(onCloseTrip != null ? 'Back' : 'Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
