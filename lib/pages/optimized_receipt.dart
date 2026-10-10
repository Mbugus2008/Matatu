import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/SettingsController.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/header.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/controllers/waybill_controller.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/models/trantypes.dart';
import 'package:t_matatu/pages/Amount%20dist.dart';
import 'package:t_matatu/pages/crew.dart';
import 'package:t_matatu/pages/waybill/start_trip_sheet.dart';
import 'package:t_matatu/providers/client.dart';
import 'package:t_matatu/reports/controller.dart';

import '../controllers/expenses/expense_controller.dart';
import '../models/Header.dart';
import '../models/Transaction.dart' as tMatatu;
import '../models/expenses/expenses.dart';
import '../models/mpesa_transaction.dart';
import '../models/vehicles/vehicle.dart';
import '../models/waybill/trip_comment.dart';
import '../models/waybill/waybill.dart';
import '../providers/db.dart';
import 'widgets/total_amount_display.dart';
import 'widgets/transaction_list_item.dart';

class Receipt extends StatefulWidget {
  const Receipt({super.key});

  /// Amount the vehicle still has to bring in cash: target minus what was
  /// already paid through M-Pesa and minus the expenses already spent on the
  /// trips (never negative).
  static double expectedCashAmount(
          double target, double paidMpesa, double expenses) =>
      target - paidMpesa - expenses > 0 ? target - paidMpesa - expenses : 0;

  @override
  State<Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  // Controllers - lazy initialized
  late final MainController mainController;
  late final MemberController memberController;
  late final TransTypeController tcontroller;
  late final FocusNode _amountFocusNode;
  late final TextEditingController _vehicleNoController;
  late final TextEditingController _commentsController;

  // CityHoppa metrics: open-trip stats + M-Pesa sum, fetched per vehicle.
  Future<(int, double, double, double?)>? _metricsFuture;
  String? _metricsVehicle;

  /// Context of the blocking print spinner, captured from inside the dialog
  /// route — it is popped via the navigator when the print finishes (see
  /// [_closePrintDialog] for why GetX's back() cannot be used).
  BuildContext? _printDialogContext;

  @override
  void initState() {
    super.initState();
    // Initialize controllers once
    mainController = Get.find<MainController>();
    memberController = Get.find<MemberController>();
    tcontroller = Get.find<TransTypeController>();
    _amountFocusNode = FocusNode();
    _vehicleNoController = TextEditingController();
    _commentsController = TextEditingController();

    // Load initial data if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    // Closing the receipt discards anything that was not committed — pending
    // transaction lines, the typed amount, the vehicle/crew selection and the
    // type selections — so the next time it opens it starts clean.
    _discardUnsavedReceipt();

    // Clean up focus nodes and controllers
    _amountFocusNode.dispose();
    _vehicleNoController.dispose();
    _commentsController.dispose(); // Added dispose for comments controller

    super.dispose();
  }

  /// Resets the in-progress receipt state. Never throws: the page is being torn
  /// down, and a controller may already be unavailable.
  void _discardUnsavedReceipt() {
    try {
      final headerController = Get.find<HeaderController>();
      headerController.amountEditingController.value.text = '';
      headerController.curTran = tMatatu.Trans().obs;
      headerController.currTrans.clear();
      headerController.createheader();

      if (Get.isRegistered<MemberController>()) {
        Get.find<MemberController>().clearcurrentvehicle();
      }
      if (Get.isRegistered<VehiclesController>()) {
        Get.find<VehiclesController>().Currentvehicle = Vehicles().obs;
      }
      if (Get.isRegistered<TransTypeController>()) {
        final types = Get.find<TransTypeController>();
        types.tType.value = TranTypes(Code: ' ');
        types.vehicleTrantypes.clear();
      }
    } catch (e) {
      debugPrint('Receipt close cleanup skipped: $e');
    }
  }

  Future<void> _loadInitialData() async {
    // Load any initial data needed
    Get.find<SettingsController>().fetchWorkingDate();
  }

  // Optimized print function
  Future<void> _printReceipt(HeaderController headerController) async {
    final header = headerController.currHeader.value;

    // Cache Get.find instances
    final dbProvider = Get.find<db_Provider>();
    final reportController = Get.find<ReportController>();
    final mainControllerInstance = Get.find<MainController>();
    final bluetoothManager = Get.find<BluetoothManager>();
    final settingsController = Get.find<SettingsController>();

    Get.dialog(
      Builder(builder: (dialogContext) {
        _printDialogContext = dialogContext;
        return const Center(child: CircularProgressIndicator());
      }),
      barrierDismissible: false,
    );
    try {
      if (headerController.currTrans.isEmpty) {
        throw "No transactions to print";
      }
      header.Total_Amount = headerController.currTrans
          .fold<double>(0.0, (sum, item) => sum + (item.Amount ?? 0));
      await dbProvider.insert(Header.table, header);

      final batch = dbProvider.batch();
      for (final element in headerController.currTrans) {
        await dbProvider.insert(tMatatu.Trans.tabletrans, element);
      }
      await batch.commit();
      headerController.trans.insert(0, header);
      reportController.daystrans.insert(0, header);
      headerController.filteredTrans.value = headerController.trans;

      settingsController.fetchWorkingDate();

      final client = mainControllerInstance.CurrentClient?.value;
      if (client != null) {
        final bytes = await client.printReceipt(header);
        if (bytes != null) {
          bluetoothManager.printReceip(bytes);
        } else {
          throw "Failed to generate receipt bytes";
        }
      } else {
        throw "Client not available";
      }
      headerController.clearAllTransactions();
      _vehicleNoController.clear();
      // The receipt has collected the vehicle's day: reset the "Todays
      // Transactions" figure so it cannot keep reading as money still due.
      // Both reload when the next vehicle is selected.
      mainControllerInstance.vehtrans.clear();
      mainControllerInstance.vehsummary.clear();
      // CityHoppa: the printed receipt settles the vehicle — close whatever is
      // still open and update the M-Pesa transactions it covers.
      _settleVehicleAfterPrint(header);
      upload();
      _closePrintDialog();
      _showSnackbarDeferred('Success', 'Receipt printed successfully',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      _closePrintDialog();

      _showSnackbarDeferred('Print Error', e.toString(),
          backgroundColor: Colors.red, colorText: Colors.white);

      debugPrint("Print error: $e");
    }
  }

  /// Closes the blocking print spinner. The dialog is popped through the
  /// navigator with its own context — GetX's back() is NOT used because it
  /// is swallowed whenever a snackbar is open: it closes the snackbar and
  /// returns without popping the dialog, and clearing the snackbars first
  /// does not help (their state only clears after the closing animation,
  /// which still leaves back() swallowed and the spinner up "forever").
  void _closePrintDialog() {
    final dialogContext = _printDialogContext;
    _printDialogContext = null;
    if (dialogContext == null || !dialogContext.mounted) return;
    Navigator.of(dialogContext).pop();
  }

  void _clearTransactionData() {
    Get.find<HeaderController>().amountEditingController.value.text = '';
    _vehicleNoController.clear();
    Get.find<HeaderController>().currTrans.clear();
    Get.find<HeaderController>().createheader();
    Get.find<MemberController>().clearcurrentvehicle();
  }

  /// Fire-and-forget settlement run right after a CityHoppa receipt prints:
  ///
  /// 1. Every un-receipted M-Pesa transaction for the vehicle since the
  ///    *previous* receipt is stamped with this receipt's number
  ///    (Receipt_No / Receipted_At / Receipted_By) in BC, so it is never
  ///    counted by the next receipt.
  /// 2. Every open trip of the vehicle is closed — what was on the road was
  ///    handed in with this receipt. Each closed trip records the receipt's
  ///    total as its Amount_Received (split across trips when several are
  ///    open) — closes go through the normal dirty/push lifecycle, so they
  ///    sync even while offline.
  /// 3. The entries whose trips were closed are stamped with the receipt
  ///    number too, keeping trip → entry → receipt traceable.
  void _settleVehicleAfterPrint(Header header) {
    if (!_isCityHoppa) return;
    final vehicleNo = (header.Vehicle ?? '').trim();
    if (vehicleNo.isEmpty) return;

    Future<void>(() async {
      try {
        final service = MpesaTransactionService();
        final receiptNo = (header.Receipt_No ?? '').trim();
        final since = await service.lastReceiptTime(vehicleNo,
                excludeReceiptNo: receiptNo) ??
            MpesaTransactionService.startOfToday();
        final vehicle = _findVehicle(vehicleNo);
        final transactions = await service.fetchSince(
          vehicleNo: vehicleNo,
          paybill: vehicle?.Till_No,
          since: since,
        );
        final pending = transactions.where((t) => !t.isReceipted).toList();
        final updated = await service.markReceipted(
          pending,
          receiptNo: receiptNo,
          agent: header.Agent,
        );
        // Pull the vehicle's trips live before closing: anything started on
        // another device (or still unsynced here) must close with this
        // receipt too — that is what makes a two-or-more-trip close complete.
        try {
          await WaybillService()
              .refreshVehicleTrips(vehicleNo: vehicleNo)
              .timeout(const Duration(seconds: 12));
        } catch (_) {}
        final closed = await WaybillService().closeOpenTrips(
          vehicleNo: vehicleNo,
          receiptNo: receiptNo,
          amountReceived: header.Total_Amount,
        );
        debugPrint('[CITYHOPPA] receipt $receiptNo: '
            '$updated mpesa transaction(s) updated, $closed trip(s) closed');
      } catch (e) {
        debugPrint('[CITYHOPPA] post-print settlement failed: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Receipt'),
            _buildWorkingDateText(),
          ],
        ),
      ),
      body: _buildBody(),
      // Print/Reprint are pinned to the bottom bar so they stay reachable
      // while the keyboard is open (they used to sit at the end of the
      // scroll content where the keyboard hid them). The keyboard pushes
      // this bar up instead of covering it.
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 4.0, 4.0, 8.0),
          child: _buildPrintButtons(),
        ),
      ),
    );
  }

  Widget _buildWorkingDateText() {
    return GetBuilder<SettingsController>(
      builder: (controller) => Text(
        DateFormat('MMM-dd-yyyy').format(controller.workingDate),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // NOTE: never switch between different widget-tree branches based on
        // MediaQuery.viewInsets - opening the keyboard changes those insets,
        // which would recreate the vehicle Autocomplete field and lose focus
        // (keyboard flicker). Keep ONE stable layout branch.
        final double transactionsHeight =
            (constraints.maxHeight * 0.4).clamp(220.0, 420.0);

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            2.0,
            2.0,
            2.0,
            MediaQuery.of(context).viewInsets.bottom + 8.0,
          ),
          child: Column(
            children: [
              _buildVehicleMemberSection(),
              const SizedBox(height: 1.0),
              if (_isCityHoppa) _buildCityHoppaMetrics(),
              _buildTodayTransactionsButton(),
              const SizedBox(height: 1.0),
              _buildNewEntrySection(),
              const SizedBox(height: 1.0),
              SizedBox(
                height: transactionsHeight,
                child: _buildCurrentTransactions(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentsSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildComments(),
          ],
        ),
      ),
    );
  }

  Widget _buildComments() {
    return TextFormField(
      controller: _commentsController,
      decoration: const InputDecoration(
        labelText: 'Comments',
        border: OutlineInputBorder(),
      ),
    );
  }

  // ─── CityHoppa metrics ───────────────────────────────

  /// CityHoppa officers watch the day's trip flow here: open trips, the money
  /// still on the road (target = totals of all open trips), M-Pesa paid, the
  /// expenses spent on those trips, and the cash still expected (target minus
  /// M-Pesa minus expenses).
  bool get _isCityHoppa =>
      Get.find<MainController>().config?.value.clientId == 'CITYHOPPER';

  Future<(int, double, double, double?)> _metricsFutureFor(String vehicleNo) {
    if (_metricsVehicle != vehicleNo || _metricsFuture == null) {
      _metricsVehicle = vehicleNo;
      _metricsFuture = _loadMetrics(vehicleNo);
    }
    return _metricsFuture!;
  }

  Future<(int, double, double, double?)> _loadMetrics(String vehicleNo) async {
    // Live first (bounded): trips started on other devices must count too.
    // Offline or slow networks quietly fall back to the local copy.
    try {
      await WaybillService()
          .refreshVehicleTrips(vehicleNo: vehicleNo)
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
    final open =
        await WaybillService().openTripsSummaryForVehicle(vehicleNo: vehicleNo);
    final vehicle = _findVehicle(vehicleNo);
    final mpesa = await MpesaTransactionService().paidSinceLastReceipt(
      vehicleNo: vehicleNo,
      paybill: vehicle?.Till_No,
    );
    return (open.$1, open.$2, open.$3, mpesa);
  }

  /// Local vehicle row — carries the M-Pesa till (paybill) its transactions
  /// land on.
  Vehicles? _findVehicle(String vehicleNo) {
    final target = vehicleNo.trim().toUpperCase();
    if (target.isEmpty) return null;
    try {
      for (final v in Get.find<VehiclesController>().allVehicles) {
        if ((v.Vehicle_Number ?? '').trim().toUpperCase() == target) return v;
      }
    } catch (_) {}
    return null;
  }

  Widget _buildCityHoppaMetrics() {
    final vehicleCtrl = Get.find<VehiclesController>();
    // Reactive: the card must reload when the officer picks another vehicle.
    return Obx(() {
      final vehicle = vehicleCtrl.Currentvehicle.value;

      var mpesa = vehicle?.Mpesa;
      if (mpesa == null && vehicle?.Vehicle_Number != null) {
        for (final v in vehicleCtrl.vehdailycollections) {
          if (v.Vehicle_Number == vehicle!.Vehicle_Number) {
            mpesa = v.Mpesa;
            break;
          }
        }
      }
      final money = NumberFormat('#,##0');

      return FutureBuilder<(int, double, double, double?)>(
        future: _metricsFutureFor(vehicle?.Vehicle_Number ?? ''),
        builder: (context, snapshot) {
          final waiting = snapshot.connectionState == ConnectionState.waiting;
          final openCount = snapshot.data?.$1 ?? 0;
          // Target = the money still on the road: totals of all open trips.
          final target = snapshot.data?.$2 ?? 0;
          // Expenses already spent on those open trips.
          final expenses = snapshot.data?.$3 ?? 0;
          // Paid M-Pesa: live sum of the vehicle's M-Pesa transactions since
          // its last receipt. Falls back to the daily-collection figure when
          // the feed is unreachable, so the receipt still works offline.
          final paidMpesa = snapshot.data?.$4 ?? mpesa ?? 0;
          final expectedCash =
              Receipt.expectedCashAmount(target, paidMpesa, expenses);
          final vehicleNo = (vehicle?.Vehicle_Number ?? '').trim();

          return Card(
            elevation: 4,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showVehicleTripsSheet(vehicleNo),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetric('Open Trips',
                              waiting ? '—' : '$openCount', Icons.timelapse),
                        ),
                        Expanded(
                          child: _buildMetric(
                              'Target',
                              waiting ? '—' : money.format(target),
                              Icons.flag_outlined),
                        ),
                        Expanded(
                          child: _buildMetric(
                              'Paid M-Pesa',
                              waiting ? '—' : money.format(paidMpesa),
                              Icons.phone_android),
                        ),
                        Expanded(
                          child: _buildMetric(
                              'Expenses',
                              waiting ? '—' : money.format(expenses),
                              Icons.money_off),
                        ),
                        Expanded(
                          child: _buildMetric(
                              'Expected Cash',
                              waiting ? '—' : money.format(expectedCash),
                              Icons.payments_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined,
                            size: 13, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to view trips & comments',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }

  Widget _buildMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF006B3F)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF5B5F61)),
            textAlign: TextAlign.center),
      ],
    );
  }

  /// Opens the trips popup for the selected vehicle: today's trips — open
  /// first — with their stats, M-Pesa / cash split and comments. The
  /// CityHoppa metrics card (the trips widget) brings this up on touch.
  void _showVehicleTripsSheet(String vehicleNo) {
    final vehicle = vehicleNo.trim();
    if (vehicle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a vehicle first')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _VehicleTripsSheet(
        vehicleNo: vehicle,
        // A new trip changes the money on the road — re-fetch the card's
        // metrics when the trip sheet closes back onto the receipt.
        onTripAdded: () {
          if (!mounted) return;
          setState(() {
            _metricsVehicle = null;
            _metricsFuture = null;
          });
        },
      ),
    );
  }

  Widget _buildVehicleMemberSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          children: [
            _buildVehicleSearch(),
            if (Get.find<MainController>().CurrentClient?.value.Attach_crew ==
                true)
              _buildCrewInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSearch() {
    return Autocomplete<Suggestion>(
      initialValue: TextEditingValue.empty,
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty)
          return const Iterable<Suggestion>.empty();
        return memberController.getVehicleSuggestions(textEditingValue.text);
      },
      displayStringForOption: (option) => option.displayText,
      onSelected: (selection) => _handleVehicleSelection(selection),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'Enter vehicle number or member name',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                onPressed: () => controller.clear(),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ));
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return _buildSuggestionItem(option, onSelected);
              },
            ),
          ),
        );
      },
    );
  }

  void _handleVehicleSelection(Suggestion selection) {
    final headerController = Get.find<HeaderController>();
    headerController.createheader();
    headerController.currTrans.clear();
    mainController.vehsummary.clear();
    headerController.currHeader.value.Account = selection.account;
    _vehicleNoController.text = selection.displayText;

    if (selection.isVehicle) {
      if (selection.id.isNotEmpty) {
        _vehicleNoController.text = selection.id;
        headerController.currHeader.value.Fleet = selection.id;
      }
      memberController.getcurrentcrew(selection.displayText);
      headerController.currHeader.value.Vehicle = selection.displayText;
      // Pull the vehicle's trips live right away: the metrics card, the
      // trips sheet and the post-print close join this same refresh.
      WaybillService().refreshVehicleTrips(vehicleNo: selection.displayText);
      Get.find<VehiclesController>()
          .getvehtrans(selection.displayText, DateTime.now());
      // The officer's next step is typing the amount — move the focus there
      // once the selection settles (the autocomplete also fiddles with focus
      // during the tap, so wait for the next frame).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        FocusScope.of(context).requestFocus(_amountFocusNode);
      });
    }
  }

  Widget _buildSuggestionItem(
      Suggestion option, AutocompleteOnSelected<Suggestion> onSelected) {
    final title = option.id.isEmpty
        ? option.displayText
        : '${option.id}-${option.displayText}';

    return ListTile(
      leading: option.isVehicle
          ? const Icon(Icons.directions_bus, color: Colors.blue, size: 24)
          : const Icon(Icons.person, color: Colors.green, size: 24),
      title: Text(option.isVehicle ? title : option.displayText),
      subtitle: Text(option.details),
      trailing: option.loan > 0
          ? Text(NumberFormat("#,##0.00").format(option.loan),
              style: const TextStyle(fontSize: 12, color: Colors.red))
          : null,
      onTap: () => onSelected(option),
    );
  }

  Widget _buildCrewInfoSection() {
    return GetBuilder<MemberController>(
      builder: (controller) => Row(
        children: [
          if (_shouldShowDriver())
            Expanded(
                child:
                    _buildCrewInfo("Driver", controller.currentdriver.value)),
          if (_shouldShowConductor())
            Expanded(
                child: _buildCrewInfo(
                    "Conductor", controller.currentcunductor.value)),
          Expanded(
            child: IconButton(
              icon: const Icon(Icons.edit, size: 30),
              onPressed: () async {
                final vehiclesController = Get.find<VehiclesController>();
                final currentVehicle = vehiclesController.Currentvehicle.value;
                // Crew rows and the vehicles table are keyed by the vehicle
                // number (plate). _vehicleNoController can hold the fleet
                // number, and refreshing with that key erased the crew below
                // the vehicle and unloaded the current vehicle entirely.
                final vehicleNo = (currentVehicle?.Vehicle_Number ??
                        _vehicleNoController.text)
                    .trim();
                await Get.to(() => CrewAssignment(vehicle: currentVehicle));
                if (vehicleNo.isEmpty) return;
                // Re-read the vehicle's crew after the assignment so new
                // receipt lines stop picking the old driver/conductor: the
                // header crew feeds the account on crew-savings lines.
                // Post-frame: the pop is still settling and getcurrentcrew()
                // notifies listeners.
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  if (!mounted) return;
                  Get.find<MemberController>().getcurrentcrew(vehicleNo);
                  await vehiclesController.getcurrvehicle(vehicleNo);
                });
              },
            ),
          )
        ],
      ),
    );
  }

  bool _shouldShowDriver() {
    final client = Get.find<MainController>().CurrentClient?.value;
    return client?.Crew_to_attach == CrewToattach.Both ||
        client?.Crew_to_attach == CrewToattach.Driver;
  }

  bool _shouldShowConductor() {
    final client = Get.find<MainController>().CurrentClient?.value;
    return client?.Crew_to_attach == CrewToattach.Both ||
        client?.Crew_to_attach == CrewToattach.Condutor;
  }

  Widget _buildCrewInfo(String title, Member? member) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((255 * 0.2).round()),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2.0),
          Text(
            member?.Name ?? "Not Assigned",
            style: TextStyle(
                fontSize: 10,
                color: member != null ? Colors.black : Colors.red,
                overflow: TextOverflow.ellipsis),
          ),
          if (member != null) ...[
            const SizedBox(height: 2.0),
            Text(
              member.No ?? 'N/A',
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTodayTransactionsButton() {
    return Obx(
      () {
        final total = Get.find<MainController>()
            .vehtrans
            .fold<double>(0, (sum, item) => sum + (item.Amount ?? 0));

        return ElevatedButton(
          onPressed: () => _showTodayTransactions(),
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                const TextSpan(
                    text: 'Todays Transactions : ',
                    style: TextStyle(fontSize: 12, color: Colors.black87)),
                TextSpan(
                  text: NumberFormat.currency(symbol: 'KSh ').format(total),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: total >= 0 ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTodayTransactions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vehicle Transactions'),
        content: SizedBox(
          width: double.maxFinite,
          child: _buildVehicleTransactionsList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTransactionsList() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: GetBuilder<MainController>(
          builder: (controller) {
            return DataTable(
              columnSpacing: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              columns: [
                DataColumn(label: Text('Type', style: TextStyle(fontSize: 14))),
                DataColumn(
                    label: Text('Agent', style: TextStyle(fontSize: 14))),
                DataColumn(
                  label: Container(
                    alignment: Alignment.centerRight,
                    child: Text('Amount', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
              rows: [
                ...controller.vehsummary.map((tr) => DataRow(
                      cells: [
                        DataCell(Text(tr.Type.toString(),
                            style: const TextStyle(fontSize: 14))),
                        DataCell(Text(tr.agents.join(', '),
                            style: const TextStyle(fontSize: 14))),
                        DataCell(
                          Container(
                            alignment: Alignment.centerRight,
                            child: Text(
                                NumberFormat("#,##0.00").format(tr.Amount),
                                style: VehiclesController().summaryAmount()),
                          ),
                        ),
                      ],
                    )),
                DataRow(
                  cells: [
                    const DataCell(Text('Total',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold))),
                    const DataCell(Text('')),
                    DataCell(
                      Text(
                          NumberFormat("#,##0.00").format(controller.vehsummary
                              .fold<double>(0.0,
                                  (sum, item) => sum + (item.Amount ?? 0))),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewEntrySection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildTransactionTypeDropdown(),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextFormField(
                    focusNode: _amountFocusNode,
                    controller: Get.find<HeaderController>()
                        .amountEditingController
                        .value,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (Get.find<MainController>().CurrentClient?.value.Show_comments ??
                false) ...[
              const SizedBox(height: 1.0),
              _buildCommentsSection(),
            ],
            //     const SizedBox(height: 1.0),
            // _buildCommentsSection(),
            _buildExpenseDropdownIfNeeded(),
            const SizedBox(height: 16.0),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeDropdown() {
    return GetBuilder<TransTypeController>(
      builder: (controller) {
        final ttypes = List.from(controller.alltrantypes);
        if (ttypes.firstWhereOrNull((e) => e.Code == " ") == null) {
          ttypes.insert(0, TranTypes(Order: -1, Code: " "));
        }

        return DropdownButtonFormField<TranTypes>(
          onChanged: (newValue) => _handleTransactionTypeChange(newValue),
          items: ttypes
              .map((value) => DropdownMenuItem<TranTypes>(
                    value: value,
                    child: SizedBox(
                      child: Text(
                        value.Order! >= 0
                            ? '${value.Name} (${value.VehicleAmount})'
                            : value.Name ?? "",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  void _handleTransactionTypeChange(TranTypes? newValue) {
    if (newValue == null) return;

    final headerController = Get.find<HeaderController>();
    headerController.curTran.value.Type = newValue.Code;
    headerController.curTran.value.Description = newValue.Name;

    Get.find<TransTypeController>().tType.value = newValue;
    headerController.amountEditingController.value.text =
        newValue.VehicleAmount.toString();

    FocusScope.of(context).requestFocus(_amountFocusNode);
    headerController.amountEditingController.value.selection = TextSelection(
      baseOffset: 0,
      extentOffset: headerController.amountEditingController.value.text.length,
    );
  }

  Widget _buildExpenseDropdownIfNeeded() {
    return GetBuilder<TransTypeController>(
      builder: (controller) {
        return Visibility(
          visible: controller.tType.value.Code == "EXPENSES",
          child: GetBuilder<ExpenseController>(
            builder: (expController) {
              return DropdownButtonFormField<Expenses>(
                onChanged: (newValue) {
                  if (newValue != null) {
                    Get.find<HeaderController>().curTran.value.Constituency =
                        newValue.Code;
                  }
                },
                items: expController.all
                    .map((value) => DropdownMenuItem<Expenses>(
                          value: value,
                          child: Text(value.Description ?? ''),
                        ))
                    .toList(),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleAddEntry,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        if (_shouldShowDistributeButton()) ...[
          const SizedBox(width: 16.0),
          ElevatedButton.icon(
            onPressed: () => Get.to(() => Distribute()), // Added const
            icon: const Icon(Icons.more_horiz, size: 20),
            label: const Text('Distribute', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }

  bool _shouldShowDistributeButton() {
    return Get.find<MainController>().CurrentClient?.value.Auto_Assign == true;
  }

  void _handleAddEntry() {
    final headerController = Get.find<HeaderController>();
    final amount = headerController.amountEditingController.value.text;

    if (_vehicleNoController.text.isEmpty) {
      _showErrorSnackbar("No Vehicle/Account entered");
      return;
    }
    if (amount.isEmpty) {
      _showErrorSnackbar("Amount cannot be empty");
      return;
    }
    if (Get.find<TransTypeController>().tType.value.Code?.trim().isEmpty ??
        true) {
      _showErrorSnackbar("No Type Selected");
      return;
    }
    if (_isExpenseWithoutConstituency()) {
      _showErrorSnackbar("Kindly select the Expenses");
      return;
    }

    _createTransactionLine();
    _clearTransactionLines();
  }

  bool _isExpenseWithoutConstituency() {
    final transType = Get.find<TransTypeController>().tType.value.Code;
    final constituency =
        Get.find<HeaderController>().curTran.value.Constituency;
    return transType == "EXPENSES" &&
        (constituency == null || constituency.isEmpty);
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Receipt',
      message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Shows a snackbar after navigation settles. Calling Get.snackbar in the
  /// same frame as Get.back() can leave an unshown snackbar in GetX's queue,
  /// which later crashes with a LateInitializationError.
  void _showSnackbarDeferred(String title, String message,
      {Color? backgroundColor, Color? colorText}) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (Get.isSnackbarOpen) return;
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: backgroundColor,
        colorText: colorText,
      );
    });
  }

  void _createTransactionLine() {
    final headerController = Get.find<HeaderController>();
    final currentHeader = headerController.currHeader.value;
    final currentTran = headerController.curTran.value;
    currentTran.Document_No = DateTime.now().microsecondsSinceEpoch.toString();
    currentTran.OTTN = currentHeader.Receipt_No;
    currentTran.Account_No = currentHeader.Account;

    if (currentTran.Type == TranTypes.savingsCrewCode &&
        (currentHeader.Crew != null && currentHeader.Crew!.isNotEmpty)) {
      currentTran.Account_No = currentHeader.Crew;
    } else if (currentTran.Type == TranTypes.savingsCrew2Code &&
        (currentHeader.Crew2 != null && currentHeader.Crew2!.isNotEmpty)) {
      currentTran.Account_No = currentHeader.Crew2;
    }
    // Crew savings carry the driver's / conductor's number in brackets,
    // e.g. "Crew Savings(Dr)(B098)" - the same way older receipts wrote it.
    currentTran.Description = TranTypes.crewSavingsDescription(
        currentTran.Description,
        TranTypes.crewNoFor(
            currentTran.Type, currentHeader.Crew, currentHeader.Crew2));
    currentTran.Messages = _commentsController.value.text;
    currentTran.Loan_No = currentHeader.Vehicle;
    currentTran.Transaction_Date = currentHeader.Date;
    currentTran.Amount =
        double.tryParse(headerController.amountEditingController.value.text) ??
            0;

    if (currentTran.Type == "EXPENSES") {
      currentTran.Amount = currentTran.Amount! * -1;
    }

    currentTran.Transaction_Time = DateTime.now();
    currentTran.Agent_Code = currentHeader.Agent;
    currentTran.sent = false;

    headerController.currTrans.add(currentTran);
    headerController.currHeader.value.transtions?.add(currentTran);
  }

  void _clearTransactionLines() {
    Get.find<HeaderController>().amountEditingController.value.text = '';
    Get.find<TransTypeController>().tType.value = TranTypes(Code: " ");
    Get.find<HeaderController>().curTran = tMatatu.Trans().obs;
    Get.find<VehiclesController>().Currentvehicle = Vehicles().obs;
  }

  Widget _buildCurrentTransactions() {
    return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Card(
          elevation: 4,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 200),
            child: Obx(
              () => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Transactions List
                  Expanded(
                    child: Get.find<HeaderController>().currTrans.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('No transactions yet'),
                            ),
                          )
                        : ListView.builder(
                            itemCount:
                                Get.find<HeaderController>().currTrans.length,
                            itemExtent: 60, // Fixed height for each item
                            cacheExtent:
                                500, // Cache more items for smooth scrolling
                            addAutomaticKeepAlives: true,
                            addRepaintBoundaries: true,
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final tr =
                                  Get.find<HeaderController>().currTrans[index];
                              return TransactionListItem(
                                transaction: tr,
                                onDelete: () => Get.find<HeaderController>()
                                    .removetrans(tr),
                                key: ValueKey(tr.Document_No),
                              );
                            },
                          ),
                  ),
                  // Total Amount Display
                  const TotalAmountDisplay(),
                ],
              ),
            ),
          ),
        ));
  }

  // Transaction list item has been moved to a separate widget file

  Widget _buildPrintButtons() {
    final headerController = Get.find<HeaderController>();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Implement reprint functionality
              Get.snackbar(
                'Info',
                'Reprint functionality will be implemented here',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Reprint'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
          ),
        ),
        const SizedBox(width: 2.0),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _printReceipt(headerController),
            icon: const Icon(Icons.print),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet listing a vehicle's trips (today's, open ones first) with
/// their details, M-Pesa / cash split and comments — opened by touching the
/// CityHoppa metrics card on the receipt page.
class _VehicleTripsSheet extends StatefulWidget {
  final String vehicleNo;

  /// Called after a trip was added from this sheet — the receipt uses it to
  /// refresh the vehicle's order-book metrics.
  final VoidCallback? onTripAdded;

  const _VehicleTripsSheet({required this.vehicleNo, this.onTripAdded});

  @override
  State<_VehicleTripsSheet> createState() => _VehicleTripsSheetState();
}

class _VehicleTripsSheetState extends State<_VehicleTripsSheet> {
  static const _startGreen = Color(0xFF006B3F);

  List<WaybillTrip>? _trips;
  Map<int, TripComment> _comments = {};
  bool _loading = true;
  bool _error = false;

  /// Guards the New Trip action against a double tap opening two sheets.
  bool _addingTrip = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }
    try {
      // Live first (bounded) so the sheet shows trips started on other
      // devices; offline falls back to whatever is stored locally.
      try {
        await WaybillService()
            .refreshVehicleTrips(vehicleNo: widget.vehicleNo)
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
      final trips = List<WaybillTrip>.of(await WaybillService()
          .tripsForVehicle(
              vehicleNo: widget.vehicleNo, onDate: DateTime.now()));
      // Open trips on top — they are what the officer still expects back —
      // then the rest by start time. Today only: earlier days are history.
      trips.sort((a, b) {
        if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
        final af = a.From_Time;
        final bf = b.From_Time;
        if (af != null && bf != null) {
          final c = af.compareTo(bf);
          if (c != 0) return c;
        } else if (af != null) {
          return -1;
        } else if (bf != null) {
          return 1;
        }
        return (a.Trip_No ?? 0).compareTo(b.Trip_No ?? 0);
      });
      final comments = await TripComment.forTrips(
          trips.map((t) => t.Trip_No ?? 0).where((n) => n > 0).toList());
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _comments = comments;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  /// "From — description" line, keeping "→ To" for trips that carry a To
  /// route (same shape as the trip list cards).
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

  double _received(WaybillTrip trip) {
    final value = (trip.Amount_Received ?? '').trim();
    if (value.isEmpty) return 0;
    return double.tryParse(value.replaceAll(',', '')) ?? 0;
  }

  /// Local vehicle row for [widget.vehicleNo] — the day's waybill entry is
  /// found or created from it.
  Vehicles? _vehicleRow() {
    try {
      for (final v in Get.find<VehiclesController>().allVehicles) {
        if ((v.Vehicle_Number ?? '').trim().toUpperCase() ==
            widget.vehicleNo.trim().toUpperCase()) {
          return v;
        }
      }
    } catch (_) {
      // Controller not ready — treated as "not found".
    }
    return null;
  }

  /// Adds a new trip for this vehicle: reuses (or silently creates) the
  /// day's waybill entry, then opens the standard Start Trip sheet on it.
  Future<void> _startTrip() async {
    if (_addingTrip) return;
    final vehicle = _vehicleRow();
    if (vehicle == null) {
      _snack('Vehicle ${widget.vehicleNo} was not found on this device');
      return;
    }

    setState(() => _addingTrip = true);
    final controller = Get.find<WaybillController>();
    Waybill? entry;
    try {
      entry = await controller.ensureEntryForVehicle(
          vehicle: vehicle, date: DateTime.now());
    } catch (_) {
      entry = null;
    }
    if (!mounted) return;
    final target = entry;
    if (target == null) {
      setState(() => _addingTrip = false);
      _snack('Could not open the day\'s waybill for ${widget.vehicleNo}');
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => StartTripSheet(controller: controller, waybill: target),
    );
    if (!mounted) return;
    setState(() => _addingTrip = false);

    if (saved == true) {
      widget.onTripAdded?.call();
      await _load();
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trips = _trips ?? const <WaybillTrip>[];
    final openCount = trips.where((t) => t.isOpen).length;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.78,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trips — ${widget.vehicleNo}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _loading
                            ? 'Loading…'
                            : '${trips.length} trip(s) today · $openCount open',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: (_loading || _addingTrip) ? null : _startTrip,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Trip'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _startGreen,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: _loading ? null : _load,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody(trips)),
        ],
      ),
    );
  }

  Widget _buildBody(List<WaybillTrip> trips) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            const Text('Could not load the trips.'),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No trips recorded for this vehicle',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _addingTrip ? null : _startTrip,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Start a trip'),
              style: FilledButton.styleFrom(
                backgroundColor: _startGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: trips.length,
      itemBuilder: (context, index) => _tripCard(trips[index]),
    );
  }

  Widget _tripCard(WaybillTrip trip) {
    final money = NumberFormat('#,##0');
    final comment = _comments[trip.Trip_No ?? 0];
    final commentText = (comment?.Comments ?? '').trim();
    final received = _received(trip);
    final mpesaAmount = trip.Mpesa_Amount ?? 0;
    final cashAmount = trip.Cash_amount ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Open trips stand out — light green, matching the OPEN chip.
        color: trip.isOpen ? const Color(0xFFF1F8E9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              trip.isOpen ? const Color(0xFFA5D6A7) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Trip #${trip.Trip_No ?? '-'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trip.isOpen
                      ? const Color(0xFFE8F5E9)
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  trip.isOpen ? 'OPEN' : 'CLOSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: trip.isOpen ? const Color(0xFF2E7D32) : Colors.grey,
                  ),
                ),
              ),
              const Spacer(),
              if (trip.From_Time != null || trip.To_Time != null)
                Text(
                  '${trip.From_Time != null ? DateFormat('HH:mm').format(trip.From_Time!) : '?'} — ${trip.To_Time != null ? DateFormat('HH:mm').format(trip.To_Time!) : '?'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _routeLine(trip),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _tripStat('Pax', '${trip.Pax_No ?? 0}'),
              _tripStat('Fare', money.format(trip.Fare_Amount ?? 0)),
              _tripStat('Total', money.format(trip.Total ?? 0)),
              _tripStat(
                'Received',
                received > 0 ? money.format(received) : '-',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _tripStat(
                'M-Pesa',
                mpesaAmount > 0 ? money.format(mpesaAmount) : '-',
              ),
              const SizedBox(width: 32),
              _tripStat(
                'Cash',
                cashAmount > 0 ? money.format(cashAmount) : '-',
              ),
              const Spacer(),
            ],
          ),
          if (commentText.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                    children: [
                      const Icon(Icons.mode_comment_outlined,
                          size: 14, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(commentText, style: const TextStyle(fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tripStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
