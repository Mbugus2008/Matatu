import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/enums.dart';
import 'package:t_matatu/models/Hires.dart';

class HiresController extends GetxController {
  // Form key
  final formKey = GlobalKey<FormState>();

  // Text controllers - will be initialized in the UI
  late TextEditingController vehicleNoController;
  late TextEditingController amountController;
  late TextEditingController startDateController;
  late TextEditingController startTimeController;
  late TextEditingController returnDateController;
  late TextEditingController returnTimeController;
  late TextEditingController fleetNoController;
  late TextEditingController destinationController;
  late TextEditingController clientNameController;
  late TextEditingController inchargeController;
  late TextEditingController departmentController;
  late TextEditingController driverController;

  // Dropdown values
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

  // Initialize controller with optional hire data
  void initController(Hires? hire) {
    // Initialize controllers
    vehicleNoController = TextEditingController(text: hire?.Vehicle_No ?? '');
    amountController = TextEditingController(text: hire?.Amount?.toString() ?? '');
    startDateController = TextEditingController(
      text: DateFormat("MM/dd/yyyy").format(hire?.Start_Date ?? DateTime.now())
    );
    startTimeController = TextEditingController(
      text: DateFormat("h:mm:ss").format(hire?.Start_Time ?? DateTime.now())
    );
    returnDateController = TextEditingController(
      text: DateFormat("MM/dd/yyyy").format(hire?.Return_Date ?? DateTime.now())
    );
    returnTimeController = TextEditingController(
      text: DateFormat("h:mm:ss").format(
        hire?.Return_Time ?? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59, 59)
      )
    );
    fleetNoController = TextEditingController(text: hire?.Fleet_No ?? '');
    destinationController = TextEditingController(text: hire?.Destination ?? '');
    clientNameController = TextEditingController(text: hire?.Client_Name ?? '');
    inchargeController = TextEditingController(text: hire?.Incharge ?? '');
    departmentController = TextEditingController(text: hire?.Department ?? '');
    driverController = TextEditingController(text: hire?.Driver ?? '');

    // Set selected values
    selectedClient.value = hire?.Client;
    selectedHireType.value = hire?.Hire_Type;
    selectedVatType.value = hire?.Vat_Type;
    selectedPaymentMethod.value = hire?.Payment_Methods;
  }

  // Parse time string to DateTime
  DateTime parseTime(String timeString) {
    DateFormat format = DateFormat("h:mm a");
    try {
      return format.parse(timeString);
    } on FormatException catch (e) {
      print("Failed to parse time: $e");
      return DateTime.now();
    }
  }

  // Validate and submit form
  Future<void> submitForm() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Get form values
    final hire = Hires(
      Vehicle_No: vehicleNoController.text,
      Amount: double.tryParse(amountController.text) ?? 0,
      Start_Date: DateFormat("MM/dd/yyyy").parse(startDateController.text),
      Start_Time: parseTime(startTimeController.text),
      Return_Date: DateFormat("MM/dd/yyyy").parse(returnDateController.text),
      Return_Time: parseTime(returnTimeController.text),
      Fleet_No: fleetNoController.text,
      Destination: destinationController.text,
      Client_Name: clientNameController.text,
      Incharge: inchargeController.text,
      Department: departmentController.text,
      Driver: driverController.text,
      Client: selectedClient.value,
      Hire_Type: selectedHireType.value,
      Vat_Type: selectedVatType.value,
      Payment_Methods: selectedPaymentMethod.value,
      // Add other required fields here
    );

    // TODO: Save the hire to your database/API
    // For example: await hireService.saveHire(hire);
    
    // Show success message
    Get.snackbar('Success', 'Hire saved successfully', 
      backgroundColor: Colors.green, 
      snackPosition: SnackPosition.BOTTOM
    );
    
    // Navigate back
    Get.back(result: true);
  }

  // Clean up controllers when done
  @override
  void onClose() {
    vehicleNoController.dispose();
    amountController.dispose();
    startDateController.dispose();
    startTimeController.dispose();
    returnDateController.dispose();
    returnTimeController.dispose();
    fleetNoController.dispose();
    destinationController.dispose();
    clientNameController.dispose();
    inchargeController.dispose();
    departmentController.dispose();
    driverController.dispose();
    super.onClose();
  }
}
