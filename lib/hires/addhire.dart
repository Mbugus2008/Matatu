// lib/pages/add_hire_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/hires/Hires.dart';
import 'package:t_matatu/models/enums.dart';

import 'package:t_matatu/models/vehicles/vehicle.dart';




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
  final List<hire_Type> hireTypes = [hire_Type.None, hire_Type.Dropoff, hire_Type.Pick_and_Drop, hire_Type.Full_Day, hire_Type.Half_Day];
  final Rx<vat_Type?> selectedVatType = Rx<vat_Type?>(null);
  final List<vat_Type> vatTypes = [vat_Type.None, vat_Type.Vatable, vat_Type.Non_Vatable];
  final Rx<payment_Methods?> selectedPaymentMethod = Rx<payment_Methods?>(null);
  final List<payment_Methods> paymentMethods = [payment_Methods.Cash, payment_Methods.Bank, payment_Methods.Paybill];
  
  final _formKey = GlobalKey<FormState>();
  
  AddHireScreen({this.hire})
      : vehicleNoController = TextEditingController(text: hire?.Vehicle_No ?? ''),
        amountController = TextEditingController(text: hire?.Amount?.toString() ?? ''),
        startDateController = TextEditingController(text: DateFormat("MM/dd/yyyy").format(hire?.Start_Date ?? DateTime.now())),
        startTimeController = TextEditingController(text: DateFormat("h:mm:ss").format(hire?.Start_Time ?? DateTime.now())),
        returnDateController = TextEditingController(text: DateFormat("MM/dd/yyyy").format(hire?.Return_Date ?? DateTime.now())),
        returnTimeController = TextEditingController(text: DateFormat("h:mm:ss").format(hire?.Return_Time ?? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59))),
        fleetNoController = TextEditingController(text: hire?.Fleet_No ?? ''),
        destinationController = TextEditingController(text: hire?.Destination ?? ''),
        clientNameController = TextEditingController(text: hire?.Client_Name ?? ''),
        inchargeController = TextEditingController(text: hire?.Incharge ?? ''),
        departmentController = TextEditingController(text: hire?.Department ?? ''),
        driverController = TextEditingController(text: hire?.Driver ?? '')
      {
        selectedClient.value = clients.firstWhereOrNull((client c) => c == hire?.Client);
    selectedHireType.value = hireTypes.firstWhereOrNull((hire_Type h) => h == hire?.Hire_Type);
    selectedVatType.value = vatTypes.firstWhereOrNull((vat_Type v) => v == hire?.Vat_Type);
    selectedPaymentMethod.value = paymentMethods.firstWhereOrNull((payment_Methods p) => p == hire?.Payment_Methods);
  }

DateTime parseTime(String timeString) {
  DateFormat format = DateFormat("h:mm a");
  try {
    DateTime dateTime = format.parse(timeString);
      return dateTime;
  } on FormatException catch (e) {
    print("Failed to parse time: $e");
    return DateTime.now();
  }
}
  Future<void> _submitForm() async {
    // Validate required fields
    if (vehicleNoController.text.isEmpty) {
      Get.snackbar('Error', 'Please select a vehicle',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    
    if (selectedClient.value == null) {
      Get.snackbar('Error', 'Please select a client type',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    
    if (amountController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter an amount',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    
    if (selectedHireType.value == null) {
      Get.snackbar('Error', 'Please select a hire type',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    final String vehicleNo = vehicleNoController.text;
    final String amountText = amountController.text;
    final String startDate = startDateController.text.isEmpty ? DateFormat("MM/dd/yyyy").format(DateTime.now()) : startDateController.text;
    final String startTime = startTimeController.text;
    final String returnDate = returnDateController.text;
    final String returnTime = returnTimeController.text;
    final String fleetNo = fleetNoController.text;

    if (vehicleNo.isNotEmpty && amountText.isNotEmpty && startDate.isNotEmpty && startTime.isNotEmpty && returnDate.isNotEmpty && returnTime.isNotEmpty) {
      final double? amount = double.tryParse(amountText);
      if (amount != null) {
        final DateTime startDateParsed = DateFormat("MM/dd/yyyy").parse(startDate);
        final DateTime startTimeParsed = parseTime(startTime);
        final DateTime returnDateParsed = DateFormat("MM/dd/yyyy").parse(returnDate);
        final DateTime returnTimeParsed = DateFormat("h:mm:ss").parse(returnTime);

        // Check if return date and time are in the future
if (selectedVatType.value == null) {
  Get.snackbar('Error', 'Please select a Vat Type', backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
  return;
}
if (selectedPaymentMethod.value == null) {
  Get.snackbar('Error', 'Please select a Payment Method', backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
  return;
} 
if (selectedHireType.value == null) {
  Get.snackbar('Error', 'Please select a Hire Type', backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
  return;
}
if (selectedClient.value == null) {
  Get.snackbar('Error', 'Please select a Client', backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
  return;
}
        final DateTime now =DateTime(DateTime.now().year, DateTime.now().month,  DateTime.now().day);// DateTime.now();
        final DateTime returnDateTime = DateTime(returnDateParsed.year, returnDateParsed.month, 
        returnDateParsed.day);
        if (!returnDateTime.isBefore(now)) {
          Hires  newHire = Hires(
            Vehicle_No: vehicleNo,
            Amount: amount,
            Code: await generateCustomCode(),
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

          // Save the new hire
          Hires().savetires(newHire);

          Get.back(); // Navigate back after adding
          Get.snackbar('Success', 'New hire added successfully');
        } else {
          Get.snackbar('Error', 'Return date and time must be in the future');
        }
      } else {
        Get.snackbar('Error', 'Please enter a valid amount');
      }
    } else {
      Get.snackbar('Error', 'Please fill in all fields', backgroundColor: Colors.red, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.blue[800],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(hire == null ? 'Add New Hire' : 'Edit Hire', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 90, // Add padding at the bottom for the floating button
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('Vehicle Information'),
                  SizedBox(height: 8),
                  VehicleNumberInput(
                    controller: vehicleNoController,
                    fleetNoController: fleetNoController,
                    hintText: 'Enter fleet number/vehicle number *',
                    onSelected: (Vehicles? selection) {
                      if (selection != null) {
                        vehicleNoController.text = selection.Vehicle_Number ?? '';
                        fleetNoController.text = selection.Fleet_No ?? '';
                      }
                    },
                  ),
              
                  _buildSectionHeader('Hire Period'),
                  SizedBox(height: 8),
                  // Start and End Dates
                  Row(
                    children: [
                      Expanded(
                        child: DateInput(
                          controller: startDateController,
                          labelText: 'Start Date',
                          onDateSelected: (selectedDate) {
                            startDateController.text = DateFormat('MM/dd/yyyy').format(selectedDate);
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DateInput(
                          controller: returnDateController,
                          labelText: 'Return Date',
                          onDateSelected: (selectedDate) {
                            returnDateController.text = DateFormat('MM/dd/yyyy').format(selectedDate);
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Start and End Times
                  Row(
                    children: [
                      Expanded(
                        child: TimeInput(
                          controller: startTimeController,
                          labelText: 'Start Time',
                          onTimeSelected: (selectedTime) {
                            startTimeController.text = DateFormat('HH:mm').format(selectedTime);
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TimeInput(
                          controller: returnTimeController,
                          labelText: 'Return Time',
                          onTimeSelected: (selectedTime) {
                            returnTimeController.text = DateFormat('HH:mm').format(selectedTime);
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  _buildSectionHeader('Client Information'),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomDropdown<client>(
                              selectedValue: selectedClient,
                              items: clients,
                              displayText: (client c) => c.toString().split('.').last,
                              hintText: 'Client Type *',
                            ),
                            if (selectedClient.value == null)
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                                child: Text(
                                  'This field is required',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: TextInput(
                          controller: clientNameController,
                          hintText: 'Client Name',
                          prefixIcon: Icons.person_outline,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  TextInput(
                    controller: inchargeController,
                    hintText: 'In Charge',
                    prefixIcon: Icons.supervisor_account,
                  ),
                  SizedBox(height: 12),
                  TextInput(
                    controller: departmentController,
                    hintText: 'Department',
                  ),
                  SizedBox(height: 12),
                  TextInput(
                    controller: destinationController,
                    hintText: 'Destination',
                  ),
                  
                  _buildSectionHeader('Hire Details'),
                  SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          hintText: 'Amount *',
                          prefixText: 'Kshs. ',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          errorText: amountController.text.isEmpty ? 'This field is required' : null,
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'\d+\.?\d{0,2}')), // Allows numbers and up to 2 decimal places
                        ],
                      ),
                      if (amountController.text.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                          child: Text(
                            'This field is required',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropdown<hire_Type>(
                        selectedValue: selectedHireType,
                        items: hireTypes,
                        displayText: (hire_Type h) => h.toString().split('.').last.replaceAll('_', ' '),
                        hintText: 'Select Hire Type *',
                      ),
                      if (selectedHireType.value == null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, top: 4.0),
                          child: Text(
                            'This field is required',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CustomDropdown<vat_Type>(
                          selectedValue: selectedVatType,
                          items: vatTypes,
                          displayText: (vat_Type v) => v.toString().split('.').last.replaceAll('_', ' '),
                          hintText: 'VAT Type',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CustomDropdown<payment_Methods>(
                          selectedValue: selectedPaymentMethod,
                          items: paymentMethods,
                          displayText: (payment_Methods p) => p.toString().split('.').last,
                          hintText: 'Payment Method',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 90), // Add extra space at the bottom for the floating button
                ],
              ),
            ),
          ),
          // Floating button at the bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  hire == null ? 'CREATE HIRE' : 'UPDATE HIRE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
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
        border: Border.all(
          color: selectedValue.value == null ? Colors.red : Colors.grey,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<T>(
        isExpanded: true,
        value: selectedValue.value,
        hint: Text(
          hintText,
          style: TextStyle(
            color: selectedValue.value == null ? Colors.red : Colors.black,
          ),
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
      fieldViewBuilder: (context, fieldTextEditingController, fieldFocusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldTextEditingController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            hintText: hintText ?? 'Enter fleet number/vehicle number',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          onTap: () {
            fieldTextEditingController.clear();
            onFieldSubmitted();
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
                                vehicle_type_desc.desc[option.Vehicle_Type] ?? '',
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
          return await VehiclesController().VehicleSuggestions(textEditingValue.text);
        } catch (e) {
          debugPrint('Error fetching vehicle suggestions: $e');
          return const Iterable<Vehicles>.empty();
        }
      },
      displayStringForOption: (option) => option.Vehicle_Number ?? '',
      onSelected: (selection) {
        controller.text = selection.Vehicle_Number ?? '';
        fleetNoController.text = selection.Fleet_No ?? '';
        onSelected?.call(selection);
      },
    );
  }

  IconData _getVehicleIcon(int? vehicleType) {
    switch (vehicleType) {
      case 1: return Icons.directions_bus;
      case 2: return Icons.directions_car;
      case 3: return Icons.directions_bike;
      default: return Icons.directions_bus;
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.blue,
            width: 1.5,
          ),
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.blue,
            width: 1.5,
          ),
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
        suffixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.blue,
            width: 1.5,
          ),
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
        suffixIcon: const Icon(Icons.access_time),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.black,
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: controller.text.isEmpty ? Colors.red : Colors.blue,
            width: 1.5,
          ),
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