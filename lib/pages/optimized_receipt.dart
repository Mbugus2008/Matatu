import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/Clients/Amount%20dist.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/SettingsController.dart';
import 'package:t_matatu/controllers/TypesController.dart';
import 'package:t_matatu/controllers/header.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/models/trantypes.dart';
import 'package:t_matatu/pages/crew.dart';
import 'package:t_matatu/providers/client.dart';
import 'package:t_matatu/reports/controller.dart';

import '../controllers/expenses.dart';
import '../models/Header.dart';
import '../models/Transaction.dart' as tMatatu;
import '../models/expences.dart';
import '../models/vehicles/vehicle.dart';
import '../providers/db.dart';
import 'widgets/total_amount_display.dart';
import 'widgets/transaction_list_item.dart';

class Receipt extends StatefulWidget {
  const Receipt({super.key});
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
    // Clean up focus nodes and controllers
    _amountFocusNode.dispose();
    _vehicleNoController.dispose();
    _commentsController.dispose(); // Added dispose for comments controller

    super.dispose();
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
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    try {
      if (headerController.currTrans.isEmpty) {
        throw "No transactions to print";
      }
      header.Total_Amount = headerController.currTrans
          .fold<double>(0.0, (sum, item) => sum + (item.Amount ?? 0));

      final batch = dbProvider.batch();
      batch.insert(Header.table, header.toMap_fortable());
      for (final element in headerController.currTrans) {
        batch.insert(tMatatu.Trans.tabletrans, element.toMap_fortable());
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
      upload();
      Get.back();
      Get.snackbar(
        "Success",
        "Receipt printed successfully",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      if (Get.isDialogOpen!) Get.back();

      Get.snackbar(
        "Print Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      debugPrint("Print error: $e");
    }
  }

  void _clearTransactionData() {
    Get.find<HeaderController>().amountEditingController.value.text = '';
    _vehicleNoController.clear();
    Get.find<HeaderController>().currTrans.clear();
    Get.find<HeaderController>().createheader();
    Get.find<MemberController>().clearcurrentvehicle();
    Get.find<MainController>().vehtrans.clear();
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
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        children: [
          _buildVehicleMemberSection(),
          const SizedBox(height: 1.0),
          _buildTodayTransactionsButton(),
          const SizedBox(height: 1.0),
          _buildNewEntrySection(),
          const SizedBox(height: 1.0),
          Expanded(child: _buildCurrentTransactions()),
          const SizedBox(height: 1.0),
          _buildPrintButtons(),
        ],
      ),
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
      Get.find<VehiclesController>()
          .getvehtrans(selection.displayText, DateTime.now());
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
              onPressed: () => Get.to(() => CrewAssignment(
                  vehicle:
                      Get.find<VehiclesController>().Currentvehicle.value)),
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

        return Container(
          child: ElevatedButton(
            onPressed: () => _showTodayTransactions(),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
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
          ),
        );
      },
    );
  }

  void _showTodayTransactions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog.fullscreen(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Vehicle Transactions',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildVehicleTransactionsList(expanded: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTransactionsList({bool expanded = false}) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: GetBuilder<MainController>(
        builder: (controller) {
          final summary = controller.vehsummary;
          if (summary.isEmpty) {
            if (expanded) {
              return const SizedBox.expand(
                child: Center(
                  child: Text('No vehicle transactions available'),
                ),
              );
            }
            return const SizedBox(
              height: 160,
              child: Center(
                child: Text('No vehicle transactions available'),
              ),
            );
          }

          final numberFormat = NumberFormat('#,##0.00');
          final totalAmount = summary.fold<double>(
            0.0,
            (double sum, element) => sum + (element.Amount ?? 0),
          );
          final amountStyle = Get.find<VehiclesController>().summaryAmount();

          final content = Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(10)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                        child: Text(
                          'Type',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Amount',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: summary.length,
                    itemBuilder: (BuildContext context, int index) {
                      final tr = summary[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tr.Type?.toString() ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              numberFormat.format(tr.Amount ?? 0),
                              style: amountStyle,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const Divider(height: 1),
                  ),
                ),
                const Divider(height: 1),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(10)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        numberFormat.format(totalAmount),
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          if (expanded) {
            return content;
          }

          return SizedBox(
            height: 320,
            child: content,
          );
        },
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

  void _createTransactionLine() {
    final headerController = Get.find<HeaderController>();
    final currentHeader = headerController.currHeader.value;
    final currentTran = headerController.curTran.value;
    currentTran.Document_No = DateTime.now().microsecondsSinceEpoch.toString();
    currentTran.OTTN = currentHeader.Receipt_No;
    currentTran.Account_No = currentHeader.Account;

    if (currentTran.Type == "SAVINGSCREW" &&
        (currentHeader.Crew != null && currentHeader.Crew!.isNotEmpty)) {
      currentTran.Account_No = currentHeader.Crew;
    }
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
    Get.find<VehiclesController>().Currentvehicle.value = Vehicles();
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
                              padding: EdgeInsets.all(2.0),
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
