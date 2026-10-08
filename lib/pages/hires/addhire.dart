// lib/pages/add_hire_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/Hires.dart';
import 'package:t_matatu/models/enums.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/providers/logger.dart';

class AddHireScreen extends StatelessWidget {
  final Hires? hire;
  final TextEditingController vehicleNoController;
  final TextEditingController amountController;
  final TextEditingController startDateController;
  final TextEditingController startTimeController;
  final TextEditingController returnDateController;
  final TextEditingController returnTimeController;
  final TextEditingController fleetNoController;
  final TextEditingController destinationController;
  final TextEditingController clientNameController;
  final TextEditingController inchargeController;
  final TextEditingController departmentController;
  final TextEditingController driverController;
  final TextEditingController kmController;

  final Rx<client?> selectedClient = Rx<client?>(null);
  final List<client> clients = [client.Corporate, client.Private];
  final Rx<hire_Type?> selectedHireType = Rx<hire_Type?>(null);
  final List<hire_Type> hireTypes = [
    hire_Type.None,
    hire_Type.Dropoff,
    hire_Type.Pick_and_Drop,
    hire_Type.Full_Day,
    hire_Type.Half_Day,
    hire_Type.Several_Days,
  ];
  final Rx<vat_Type?> selectedVatType = Rx<vat_Type?>(null);
  final List<vat_Type> vatTypes = [
    vat_Type.None,
    vat_Type.Vatable,
    vat_Type.Non_Vatable
  ];
  final Rx<payment_Methods?> selectedPaymentMethod = Rx<payment_Methods?>(null);
  final List<payment_Methods> paymentMethods = [
    payment_Methods.Cash,
    payment_Methods.Bank,
    payment_Methods.Paybill
  ];

  final _formKey = GlobalKey<FormState>();
  final RxBool saving = false.obs;
  final RxBool isPaid = false.obs;

  /// Debug helper - prints to the VS Code debug console AND the app log
  /// file (/storage/emulated/0/Documents/Mbranch/yyyy-MM-dd.log)
  void _log(String message) {
    debugPrint('[AddHire] $message');
    Get.find<LoggerService>().info('[AddHire] $message');
  }

  AddHireScreen({this.hire})
      : vehicleNoController =
            TextEditingController(text: hire?.Vehicle_No ?? ''),
        amountController =
            TextEditingController(text: hire?.Amount?.toString() ?? ''),
        startDateController = TextEditingController(
            text: DateFormat("MM/dd/yyyy")
                .format(hire?.Start_Date ?? DateTime.now())),
        startTimeController = TextEditingController(
            text: DateFormat("h:mm:ss")
                .format(hire?.Start_Time ?? DateTime.now())),
        returnDateController = TextEditingController(
            text: DateFormat("MM/dd/yyyy")
                .format(hire?.Return_Date ?? DateTime.now())),
        returnTimeController = TextEditingController(
            text: DateFormat("h:mm:ss").format(hire?.Return_Time ??
                DateTime(DateTime.now().year, DateTime.now().month,
                    DateTime.now().day, 23, 59, 59))),
        fleetNoController = TextEditingController(text: hire?.Fleet_No ?? ''),
        destinationController =
            TextEditingController(text: hire?.Destination ?? ''),
        clientNameController =
            TextEditingController(text: hire?.Client_Name ?? ''),
        inchargeController = TextEditingController(text: hire?.Incharge ?? ''),
        departmentController =
            TextEditingController(text: hire?.Department ?? ''),
        driverController = TextEditingController(text: hire?.Driver ?? ''),
        kmController = TextEditingController(
            text: (hire?.Km ?? 0) == 0 ? '' : hire!.Km!.toString()) {
    selectedClient.value =
        clients.firstWhereOrNull((client c) => c == hire?.Client);
    selectedHireType.value =
        hireTypes.firstWhereOrNull((hire_Type h) => h == hire?.Hire_Type);
    selectedVatType.value =
        vatTypes.firstWhereOrNull((vat_Type v) => v == hire?.Vat_Type);
    selectedPaymentMethod.value = paymentMethods
        .firstWhereOrNull((payment_Methods p) => p == hire?.Payment_Methods);
    isPaid.value = hire?.Paid ?? false;
  }

  /// True when this screen edits an existing BC hire. The + button opens a
  /// NEW hire as `AddHireScreen(hire: Hires())`, so `hire == null` alone
  /// cannot tell a new hire apart from an edit.
  bool get _isEdit =>
      hire != null &&
      ((hire?.Code ?? '').trim().isNotEmpty ||
          (hire?.Entry ?? 0) > 0 ||
          (hire?.Key ?? '').isNotEmpty);

  /// A hire that has been marked Paid can no longer be edited.
  bool get _locked => hire?.Paid == true;

  DateTime parseTime(String timeString) {
    // Accept every format this screen can produce:
    // - initial value: DateFormat("h:mm:ss")  -> e.g. "10:15:00"
    // - TimeInput picker: "HH:mm" or locale 12h "10:15 AM"
    final text = timeString.trim();
    const formats = [
      'h:mm a',
      'h:mm:ss a',
      'HH:mm',
      'HH:mm:ss',
      'H:mm',
      'h:mm',
      'h:mm:ss',
    ];
    for (final format in formats) {
      try {
        return DateFormat(format).parse(text);
      } on FormatException {
        continue;
      }
    }
    throw FormatException('Invalid time format: "$timeString"');
  }

  /// Turning Paid on locks the hire from further edits - confirm first.
  Future<void> _confirmPaidToggle(bool value) async {
    if (!value || isPaid.value) {
      isPaid.value = value;
      return;
    }
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Mark as Paid?'),
        content: const Text(
            'Once a hire is marked as Paid it can no longer be edited.\n\n'
            'Continue?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    if (confirm == true) {
      isPaid.value = true;
      _log('paid confirmed - the hire will lock after saving');
    }
  }

  Future<void> _submitForm() async {
    if (_locked) return;
    _log('BUTTON PRESSED mode=${hire == null ? 'CREATE' : 'UPDATE'} '
        'Key=${hire?.Key} Code=${hire?.Code}');
    // A hire is an edit when the row already carries an identity from BC - a
    // code, an entry number or a key. The new-hire screen is opened with an
    // empty Hires(), so `hire == null` alone cannot tell the two apart.
    final String? existingCode = hire?.Code?.trim();
    final bool isEdit = _isEdit;
    // Validate required fields
    if (vehicleNoController.text.isEmpty) {
      _log('validation failed: vehicle is empty');
      Get.snackbar('Error', 'Please select a vehicle',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (selectedClient.value == null) {
      _log('validation failed: client is null');
      Get.snackbar('Error', 'Please select a client type',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (amountController.text.isEmpty) {
      _log('validation failed: amount is empty');
      Get.snackbar('Error', 'Please enter an amount',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    if (selectedHireType.value == null) {
      _log('validation failed: hire type is null');
      Get.snackbar('Error', 'Please select a hire type',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    final String vehicleNo = vehicleNoController.text;
    final String amountText = amountController.text;
    final String startDate = startDateController.text.isEmpty
        ? DateFormat("MM/dd/yyyy").format(DateTime.now())
        : startDateController.text;
    final String startTime = startTimeController.text;
    final String returnDate = returnDateController.text;
    final String returnTime = returnTimeController.text;
    final String fleetNo = fleetNoController.text;
    _log('fields: vehicle=$vehicleNo amount=$amountText '
        'start=$startDate $startTime return=$returnDate $returnTime '
        'fleet=$fleetNo km=${kmController.text} paid=${isPaid.value}');

    if (vehicleNo.isNotEmpty &&
        amountText.isNotEmpty &&
        startDate.isNotEmpty &&
        startTime.isNotEmpty &&
        returnDate.isNotEmpty &&
        returnTime.isNotEmpty) {
      final double? amount = double.tryParse(amountText);
      if (amount != null) {
        late final DateTime startDateParsed;
        late final DateTime startTimeParsed;
        late final DateTime returnDateParsed;
        late final DateTime returnTimeParsed;
        try {
          startDateParsed = DateFormat("MM/dd/yyyy").parse(startDate);
          startTimeParsed = parseTime(startTime);
          returnDateParsed = DateFormat("MM/dd/yyyy").parse(returnDate);
          returnTimeParsed = parseTime(returnTime);
          _log('parsed: start=$startDateParsed $startTimeParsed '
              'return=$returnDateParsed $returnTimeParsed');
        } catch (e) {
          _log('parse error: $e');
          Get.snackbar('Error', 'Invalid date or time: $e',
              backgroundColor: Colors.red,
              snackPosition: SnackPosition.BOTTOM,
              colorText: Colors.white);
          return;
        }

        // Check if return date and time are in the future
        if (selectedVatType.value == null) {
          _log('validation failed: vat type is null');
          Get.snackbar('Error', 'Please select a Vat Type',
              backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        if (selectedPaymentMethod.value == null) {
          _log('validation failed: payment method is null');
          Get.snackbar('Error', 'Please select a Payment Method',
              backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        if (selectedHireType.value == null) {
          _log('validation failed: hire type is null (second check)');
          Get.snackbar('Error', 'Please select a Hire Type',
              backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        if (selectedClient.value == null) {
          _log('validation failed: client is null (second check)');
          Get.snackbar('Error', 'Please select a Client',
              backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
          return;
        }
        final DateTime startDay = DateTime(startDateParsed.year,
            startDateParsed.month, startDateParsed.day);
        final DateTime returnDateTime = DateTime(returnDateParsed.year,
            returnDateParsed.month, returnDateParsed.day);
        // Back-dated hires are legitimate (recording yesterday's trip), so a
        // past return date does not block the save any more. Only an interval
        // that ends before it starts is rejected.
        final bool returnBeforeStart = returnDateTime.isBefore(startDay);
        _log('return/start check: returnBeforeStart=$returnBeforeStart');
        if (!returnBeforeStart) {
          Hires newHire = Hires(
            Key: hire?.Key,
            Entry: hire?.Entry,
            Vehicle_No: vehicleNo,
            Amount: amount,
            // An edit keeps the code BC knows the hire by; when the local row
            // has lost it, the entry number above identifies the record so
            // the server updates instead of adding a second hire.
            Code: isEdit ? existingCode : await generateCustomCode(),
            Start_Date: startDateParsed,
            Start_Time: startTimeParsed,
            Return_Date: returnDateParsed,
            Created_by: Get.find<MainController>().agent.value.Agent_Code,
            Return_Time: returnTimeParsed,
            Client: selectedClient.value,
            Hire_Type: selectedHireType.value,
            Vat_Type: selectedVatType.value,
            Payment_Methods: selectedPaymentMethod.value,
            Fleet_No: fleetNo,
            Destination: destinationController.text,
            Client_Name: clientNameController.text,
            Incharge: inchargeController.text,
            Department: departmentController.text,
            Driver: driverController.text,
            Paid: isPaid.value,
            Km: double.tryParse(kmController.text.trim()) ?? 0,
          );

          // Save the hire (button shows updating state meanwhile)
          _log('sending to API (addHires): ${newHire.toJson()}');
          saving.value = true;
          try {
            final success = await Hires().savetires(newHire);
            _log('savetires returned: $success');
            if (!success) {
              Get.snackbar(
                  'Error',
                  'Could not ${isEdit ? 'update' : 'create'} the hire. '
                      'Please check your connection and try again.',
                  backgroundColor: Colors.red,
                  snackPosition: SnackPosition.BOTTOM,
                  colorText: Colors.white);
              return;
            }
            Get.back(); // Navigate back after saving
            final hireMsg = isEdit
                ? 'Hire updated successfully'
                : 'New hire added successfully';
            Future.delayed(const Duration(milliseconds: 350), () {
              if (!Get.isSnackbarOpen) {
                Get.snackbar('Success', hireMsg);
              }
            });
          } catch (e) {
            _log('exception during save: $e');
            Get.snackbar('Error', 'Something went wrong: $e',
                backgroundColor: Colors.red,
                snackPosition: SnackPosition.BOTTOM,
                colorText: Colors.white);
          } finally {
            saving.value = false;
          }
        } else {
          _log('validation failed: return date is before the start date');
          Get.snackbar(
              'Error', 'Return date must be on or after the start date');
        }
      } else {
        _log('validation failed: amount is not a number');
        Get.snackbar('Error', 'Please enter a valid amount');
      }
    } else {
      _log('validation failed: some required fields are empty '
          '(vehicle=$vehicleNo amount=$amountText start=$startDate/$startTime '
          'return=$returnDate/$returnTime)');
      Get.snackbar('Error', 'Please fill in all fields',
          backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _buildSection(String title, Widget child, {bool tinted = false}) {
    return Container(
      color: tinted ? const Color(0xFFF4FAFD) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF161D1F),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  /// Shown when the hire is locked (already marked Paid in BC).
  Widget _buildPaidBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: Color(0xFF2E7D32)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'This hire is marked as Paid — it can no longer be edited.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodCard({
    required IconData icon,
    required String label,
    required Widget date,
    required Widget time,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDDE4E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF006B3F)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF161D1F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: date),
              const SizedBox(width: 12),
              Expanded(child: time),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Hire' : 'New Hire',
            style: const TextStyle(
                color: Color(0xFF161D1F), fontWeight: FontWeight.w600)),
        centerTitle: true,
        toolbarHeight: 56,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF161D1F)),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: 8, bottom: 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_locked) _buildPaidBanner(),
                  _buildSection(
                    'Vehicle Information',
                    VehicleNumberInput(
                      controller: vehicleNoController,
                      fleetNoController: fleetNoController,
                      hintText: 'Vehicle Number *',
                      enabled: !_locked,
                      onSelected: (Vehicles? selection) {
                        if (selection != null) {
                          vehicleNoController.text =
                              selection.Vehicle_Number ?? '';
                          fleetNoController.text = selection.Fleet_No ?? '';
                        }
                      },
                    ),
                  ),
                  _buildSection(
                    'Hire Period',
                    Column(
                      children: [
                        _buildPeriodCard(
                          icon: Icons.play_circle,
                          label: 'PICKUP',
                          date: DateInput(
                            controller: startDateController,
                            labelText: 'Start Date',
                            enabled: !_locked,
                            onDateSelected: (selectedDate) {
                              startDateController.text =
                                  DateFormat('MM/dd/yyyy').format(selectedDate);
                            },
                          ),
                          time: TimeInput(
                            controller: startTimeController,
                            labelText: 'Start Time',
                            enabled: !_locked,
                            onTimeSelected: (selectedTime) {
                              startTimeController.text =
                                  DateFormat('HH:mm').format(selectedTime);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPeriodCard(
                          icon: Icons.stop_circle,
                          label: 'RETURN',
                          date: DateInput(
                            controller: returnDateController,
                            labelText: 'Return Date',
                            enabled: !_locked,
                            onDateSelected: (selectedDate) {
                              returnDateController.text =
                                  DateFormat('MM/dd/yyyy').format(selectedDate);
                            },
                          ),
                          time: TimeInput(
                            controller: returnTimeController,
                            labelText: 'Return Time',
                            enabled: !_locked,
                            onTimeSelected: (selectedTime) {
                              returnTimeController.text =
                                  DateFormat('HH:mm').format(selectedTime);
                            },
                          ),
                        ),
                      ],
                    ),
                    tinted: true,
                  ),
                  _buildSection(
                    'Client Information',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomDropdown<client>(
                          selectedValue: selectedClient,
                          items: clients,
                          displayText: (client c) =>
                              c.toString().split('.').last,
                          hintText: 'Select Client Type *',
                          enabled: !_locked,
                        ),
                        Obx(() => selectedClient.value == null
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    left: 12.0, top: 4.0),
                                child: Text(
                                  'Client Type is required',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink()),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: clientNameController,
                          hintText: 'Client Name',
                          prefixIcon: Icons.person,
                          enabled: !_locked,
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: inchargeController,
                          hintText: 'In Charge',
                          prefixIcon: Icons.badge,
                          enabled: !_locked,
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: departmentController,
                          hintText: 'Department',
                          prefixIcon: Icons.domain,
                          enabled: !_locked,
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: destinationController,
                          hintText: 'Destination',
                          prefixIcon: Icons.pin_drop,
                          enabled: !_locked,
                        ),
                      ],
                    ),
                  ),
                  _buildSection(
                    'Hire Details',
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 46,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EFF1),
                                border:
                                    Border.all(color: const Color(0xFFE0E0E0)),
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(12)),
                              ),
                              alignment: Alignment.center,
                              child: const Text('Kshs',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3F4941))),
                            ),
                            Expanded(
                              child:
                                  ValueListenableBuilder<TextEditingValue>(
                                valueListenable: amountController,
                                builder: (context, value, _) => TextFormField(
                                  controller: amountController,
                                  enabled: !_locked,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                    border: const OutlineInputBorder(
                                      borderRadius: BorderRadius.horizontal(
                                          right: Radius.circular(12)),
                                      borderSide: BorderSide(
                                          color: Color(0xFFE0E0E0)),
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.horizontal(
                                          right: Radius.circular(12)),
                                      borderSide: BorderSide(
                                          color: Color(0xFFE0E0E0)),
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                      borderRadius: BorderRadius.horizontal(
                                          right: Radius.circular(12)),
                                      borderSide: BorderSide(
                                          color: Color(0xFF006B3F),
                                          width: 1.5),
                                    ),
                                    errorText: value.text.isEmpty
                                        ? 'Amount is required'
                                        : null,
                                  ),
                                  keyboardType:
                                      TextInputType.numberWithOptions(
                                          decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'\d+\.?\d{0,2}')),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: kmController,
                          hintText: 'Distance (Km)',
                          prefixIcon: Icons.route,
                          enabled: !_locked,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'\d+\.?\d{0,2}')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CustomDropdown<hire_Type>(
                                    selectedValue: selectedHireType,
                                    items: hireTypes,
                                    displayText: (hire_Type h) => h
                                        .toString()
                                        .split('.')
                                        .last
                                        .replaceAll('_', ' '),
                                    hintText: 'Select Hire Type *',
                                    enabled: !_locked,
                                  ),
                                  Obx(() => selectedHireType.value == null
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                              left: 12.0, top: 4.0),
                                          child: Text(
                                            'Hire Type is required',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12),
                                          ),
                                        )
                                      : const SizedBox.shrink()),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomDropdown<vat_Type>(
                                selectedValue: selectedVatType,
                                items: vatTypes,
                                displayText: (vat_Type v) => v
                                    .toString()
                                    .split('.')
                                    .last
                                    .replaceAll('_', ' '),
                                hintText: 'VAT Type',
                                enabled: !_locked,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomDropdown<payment_Methods>(
                          selectedValue: selectedPaymentMethod,
                          items: paymentMethods,
                          displayText: (payment_Methods p) =>
                              p.toString().split('.').last,
                          hintText: 'Payment Method',
                          enabled: !_locked,
                        ),
                        const SizedBox(height: 12),
                        Obx(() => Container(
                              padding: const EdgeInsets.only(left: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE0E0E0)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.payments_outlined,
                                      size: 20, color: Color(0xFF3F4941)),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text('Paid',
                                        style: TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF161D1F))),
                                  ),
                                  Switch(
                                    value: isPaid.value,
                                    onChanged:
                                        _locked ? null : _confirmPaidToggle,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor:
                                        const Color(0xFF006B3F),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                    tinted: true,
                  ),
                ],
              ),
            ),
          ),
          // Floating button at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0),
                    Colors.white,
                    Colors.white,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF006B3F).withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Obx(() => ElevatedButton(
                      onPressed: _locked
                          ? () => Get.back()
                          : (saving.value ? null : _submitForm),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B3F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF006B3F),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: _locked
                          ? const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            )
                          : saving.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white),
                                ),
                                SizedBox(width: 10),
                                Text('UPDATING...',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                        color: Colors.white)),
                              ],
                            )
                          : Text(
                              _isEdit ? 'Update Hire' : 'Create Hire',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                    )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CustomDropdown<T> extends StatelessWidget {
  final Rx<T?> selectedValue;
  final List<T> items;
  final String Function(T) displayText;
  final String hintText;
  final bool enabled;

  const CustomDropdown({
    required this.selectedValue,
    required this.items,
    required this.displayText,
    required this.hintText,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF2F2F2),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButton<T>(
            isExpanded: true,
            isDense: true,
            value: selectedValue.value,
            icon: const Icon(Icons.expand_more, color: Color(0xFF5B5F61)),
            hint: Text(
              hintText,
              style: const TextStyle(color: Color(0xFF5B5F61)),
            ),
            onChanged: !enabled
                ? null
                : (T? newValue) {
                    if (newValue != null) {
                      selectedValue.value = newValue;
                    }
                  },
            underline: const SizedBox(),
            items: items.map((T item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(displayText(item)),
              );
            }).toList(),
          ),
        ));
  }
}

class VehicleNumberInput extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController fleetNoController;
  final String? hintText;
  final ValueChanged<Vehicles>? onSelected;
  final bool enabled;

  const VehicleNumberInput({
    required this.controller,
    required this.fleetNoController,
    this.hintText,
    this.onSelected,
    this.enabled = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Autocomplete<Vehicles>(
      // Prefill with the existing vehicle number when editing a hire.
      initialValue: TextEditingValue(text: controller.text),
      displayStringForOption: (option) => option.Vehicle_Number ?? '',
      fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode,
          onFieldSubmitted) {
        return TextField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          enabled: enabled,
          onChanged: (text) {
            // Mirror what is typed into the form's controller. Without this
            // the outer controller only ever changed when a suggestion was
            // tapped, so a typed-but-not-selected vehicle failed validation
            // with "Please select a vehicle" and the save never ran.
            controller.text = text;
          },
          decoration: InputDecoration(
            hintText: hintText ?? 'Enter fleet number/vehicle number',
            prefixIcon: const Icon(Icons.directions_car),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: Color(0xFF006B3F), width: 1.5),
            ),
          ),
          onTap: enabled
              ? () {
                  // Keep the existing text on focus; just select it so the
                  // user can quickly type over it to search another vehicle.
                  if (fieldTextEditingController.text.isNotEmpty) {
                    fieldTextEditingController.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: fieldTextEditingController.text.length,
                    );
                  }
                }
              : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          option.Fleet_No ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(option.Vehicle_Number ?? ''),
                            if (option.Vehicle_Type != null)
                              Text(
                                vehicle_type_desc.desc[option.Vehicle_Type] ??
                                    '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        leading: Icon(
                          _getVehicleIcon(6),
                          color: Theme.of(context).primaryColor,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      optionsBuilder: (textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Vehicles>.empty();
        }
        try {
          return await VehiclesController()
              .VehicleSuggestions(textEditingValue.text);
        } catch (e) {
          debugPrint('Error fetching vehicle suggestions: $e');
          return const Iterable<Vehicles>.empty();
        }
      },
      onSelected: (selection) {
        controller.text = selection.Vehicle_Number ?? '';
        fleetNoController.text = selection.Fleet_No ?? '';
        onSelected?.call(selection);
      },
    );
  }

  IconData _getVehicleIcon(int? vehicleType) {
    switch (vehicleType) {
      case 1:
        return Icons.directions_bus;
      case 2:
        return Icons.directions_car;
      case 3:
        return Icons.directions_bike;
      default:
        return Icons.directions_bus;
    }
  }
}

class TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;

  const TextInput({
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF006B3F), width: 1.5),
        ),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: (_) {
        // This forces the widget to rebuild when text changes
        (context as Element).markNeedsBuild();
      },
    );
  }
}

class AmountInput extends StatelessWidget {
  final TextEditingController controller;
  AmountInput({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: 'Amount',
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF006B3F), width: 1.5),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) {
        (context as Element).markNeedsBuild();
      },
    );
  }
}

class DateInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final ValueChanged<DateTime>? onDateSelected;
  final bool enabled;

  const DateInput({
    required this.controller,
    required this.labelText,
    this.onDateSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF006B3F), width: 1.5),
        ),
      ),
      onTap: enabled
          ? () async {
              final DateTime? picked = await showDatePicker(
                fieldLabelText: labelText,
                helpText: labelText,
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                controller.text = DateFormat("MM/dd/yyyy").format(picked);
                onDateSelected?.call(picked);
              }
            }
          : null,
      readOnly: true,
    );
  }
}

class TimeInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final ValueChanged<DateTime>? onTimeSelected;
  final bool enabled;

  const TimeInput({
    required this.controller,
    required this.labelText,
    this.onTimeSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        suffixIcon: const Icon(Icons.access_time),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: Color(0xFF006B3F), width: 1.5),
        ),
      ),
      onTap: enabled
          ? () async {
              final TimeOfDay? pickedTime = await showTimePicker(
                helpText: labelText,
                context: context,
                initialEntryMode: TimePickerEntryMode.input,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null && context.mounted) {
                controller.text = pickedTime.format(context);
                onTimeSelected?.call(DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  pickedTime.hour,
                  pickedTime.minute,
                ));
              }
            }
          : null,
      readOnly: true,
    );
  }
}
