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

  final Rx<client?> selectedClient = Rx<client?>(null);
  final List<client> clients = [client.Corporate, client.Private];
  final Rx<hire_Type?> selectedHireType = Rx<hire_Type?>(null);
  final List<hire_Type> hireTypes = [
    hire_Type.None,
    hire_Type.Dropoff,
    hire_Type.Pick_and_Drop,
    hire_Type.Full_Day,
    hire_Type.Half_Day
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
        driverController = TextEditingController(text: hire?.Driver ?? '') {
    selectedClient.value =
        clients.firstWhereOrNull((client c) => c == hire?.Client);
    selectedHireType.value =
        hireTypes.firstWhereOrNull((hire_Type h) => h == hire?.Hire_Type);
    selectedVatType.value =
        vatTypes.firstWhereOrNull((vat_Type v) => v == hire?.Vat_Type);
    selectedPaymentMethod.value = paymentMethods
        .firstWhereOrNull((payment_Methods p) => p == hire?.Payment_Methods);
  }

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

  Future<void> _submitForm() async {
    _log('BUTTON PRESSED mode=${hire == null ? 'CREATE' : 'UPDATE'} '
        'Key=${hire?.Key} Code=${hire?.Code}');
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
        'fleet=$fleetNo');

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
        final DateTime now = DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day); // DateTime.now();
        final DateTime returnDateTime = DateTime(returnDateParsed.year,
            returnDateParsed.month, returnDateParsed.day);
        // A return date in the past only blocks CREATING a new hire.
        // When editing an existing hire, allow the update through so the
        // record can still reach BC.
        final bool returnInPast = returnDateTime.isBefore(now);
        _log('return date check: past=$returnInPast creating=${hire == null}');
        if (!returnInPast || hire != null) {
          Hires newHire = Hires(
            Key: hire?.Key,
            Vehicle_No: vehicleNo,
            Amount: amount,
            Code: hire?.Code ?? await generateCustomCode(),
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
                  'Could not ${hire == null ? 'create' : 'update'} the hire. '
                      'Please check your connection and try again.',
                  backgroundColor: Colors.red,
                  snackPosition: SnackPosition.BOTTOM,
                  colorText: Colors.white);
              return;
            }
            Get.back(); // Navigate back after saving
            Get.snackbar(
                'Success',
                hire == null
                    ? 'New hire added successfully'
                    : 'Hire updated successfully');
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
          _log('validation failed: return date is in the past');
          Get.snackbar('Error', 'Return date and time must be in the future');
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
        title: Text(hire == null ? 'New Hire' : 'Edit Hire',
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
                  _buildSection(
                    'Vehicle Information',
                    VehicleNumberInput(
                      controller: vehicleNoController,
                      fleetNoController: fleetNoController,
                      hintText: 'Vehicle Number *',
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
                            onDateSelected: (selectedDate) {
                              startDateController.text =
                                  DateFormat('MM/dd/yyyy').format(selectedDate);
                            },
                          ),
                          time: TimeInput(
                            controller: startTimeController,
                            labelText: 'Start Time',
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
                            onDateSelected: (selectedDate) {
                              returnDateController.text =
                                  DateFormat('MM/dd/yyyy').format(selectedDate);
                            },
                          ),
                          time: TimeInput(
                            controller: returnTimeController,
                            labelText: 'Return Time',
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
                        ),
                        if (selectedClient.value == null)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 12.0, top: 4.0),
                            child: Text(
                              'Client Type is required',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: clientNameController,
                          hintText: 'Client Name',
                          prefixIcon: Icons.person,
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: inchargeController,
                          hintText: 'In Charge',
                          prefixIcon: Icons.badge,
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: departmentController,
                          hintText: 'Department',
                          prefixIcon: Icons.domain,
                        ),
                        const SizedBox(height: 12),
                        TextInput(
                          controller: destinationController,
                          hintText: 'Destination',
                          prefixIcon: Icons.pin_drop,
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
                              child: TextFormField(
                                controller: amountController,
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  border: const OutlineInputBorder(
                                    borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(12)),
                                    borderSide:
                                        BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  enabledBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(12)),
                                    borderSide:
                                        BorderSide(color: Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: const OutlineInputBorder(
                                    borderRadius: BorderRadius.horizontal(
                                        right: Radius.circular(12)),
                                    borderSide: BorderSide(
                                        color: Color(0xFF006B3F), width: 1.5),
                                  ),
                                  errorText: amountController.text.isEmpty
                                      ? 'Amount is required'
                                      : null,
                                ),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
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
                                  ),
                                  if (selectedHireType.value == null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 12.0, top: 4.0),
                                      child: Text(
                                        'Hire Type is required',
                                        style: TextStyle(
                                            color: Colors.red, fontSize: 12),
                                      ),
                                    ),
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
                        ),
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
                      onPressed: saving.value ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006B3F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF006B3F),
                        disabledForegroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      child: saving.value
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
                              hire == null ? 'Create Hire' : 'Update Hire',
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

  const CustomDropdown({
    required this.selectedValue,
    required this.items,
    required this.displayText,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          decoration: BoxDecoration(
            color: Colors.white,
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
            onChanged: (T? newValue) {
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

  const VehicleNumberInput({
    required this.controller,
    required this.fleetNoController,
    this.hintText,
    this.onSelected,
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
          onTap: () {
            // Keep the existing text on focus; just select it so the user
            // can quickly type over it to search another vehicle.
            if (fieldTextEditingController.text.isNotEmpty) {
              fieldTextEditingController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: fieldTextEditingController.text.length,
              );
            }
          },
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

  const TextInput({
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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

  const DateInput({
    required this.controller,
    required this.labelText,
    this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
      onTap: () async {
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
      },
      readOnly: true,
    );
  }
}

class TimeInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final ValueChanged<DateTime>? onTimeSelected;

  const TimeInput({
    required this.controller,
    required this.labelText,
    this.onTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
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
      onTap: () async {
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
      },
      readOnly: true,
    );
  }
}
