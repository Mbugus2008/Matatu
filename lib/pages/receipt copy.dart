// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:t_matatu/controllers/Members.dart';
// import 'package:t_matatu/controllers/SettingsController.dart';
// import 'package:t_matatu/controllers/TypesController.dart';
// import 'package:t_matatu/controllers/header.dart';
// import 'package:t_matatu/controllers/main.dart';
// import 'package:t_matatu/controllers/vehicles/vehicles.dart';
// import 'package:t_matatu/init.dart';
// import 'package:t_matatu/models/TransSummary.dart';
// import 'package:t_matatu/models/trantypes.dart';
// import 'package:t_matatu/pages/Amount%20dist.dart';
// import 'package:t_matatu/pages/crew.dart';
// import 'package:t_matatu/pages/widgets/bluetoothManager.dart';
// import 'package:t_matatu/providers/client.dart';
// import 'package:t_matatu/providers/colors.dart';
// import 'package:t_matatu/reports/controller.dart';
// import 'package:t_matatu/models/member.dart';

// import '../controllers/expenses.dart';

// import '../models/Header.dart';
// import '../models/Transaction.dart' as tMatatu;
// import '../models/expences.dart';
// import '../models/vehicles/vehicle.dart';
// import '../providers/db.dart';

// class Receipt extends StatefulWidget {
//   Receipt({super.key});

//   @override
//   State<Receipt> createState() => _ReceiptState();
// }

// class _ReceiptState extends State<Receipt> {
//   MainController mainController = Get.find<MainController>();

//   MemberController memberController = Get.find<MemberController>();

//   TextEditingController vehicleno = TextEditingController();

//   TextEditingController recamount = TextEditingController();

//   TransTypeController tcontroller = Get.find<TransTypeController>();

//   final FocusNode _myFocusNode = FocusNode();

//   // Add this line to define _vehicleSuggestions
//   List<VehicleSuggestion> _vehicleSuggestions = [];

 


//   Future<void> Print(Header header) async {
//      Get.dialog(
//     Center(child: CircularProgressIndicator()),
//     barrierDismissible: false,
//   );
//     await Future.delayed(Duration.zero, () async {  
//     try{
//    if (header.Vehicle == null || header.Vehicle!.isEmpty || header.Account == null || header.Account!.isEmpty) {
//       Get.snackbar("Error", "Vehicle or Account is empty.");
//       return;
//    }
//    if (header.transtions == null || header.transtions!.isEmpty) {
//       Get.snackbar("Error", "Transactions is empty.");
//       return;
//    }
//     header.Total_Amount = header.transtions!.fold<double>(
//         0.0,
//         (double currentSum, item) =>
//             currentSum + num.tryParse(item.Amount.toString())!);
//     await Get.find<db_Provider>().insert(Header.table, header);
//     if (header.transtions != null) {
//       for (var element in header.transtions!.toList()) {
//         await Get.find<db_Provider>().insert(tMatatu.Trans.tabletrans, element);
//       }
//     }
//  SettingsController().fetchWorkingDate();
//     Get.find<HeaderController>().trans.insert(0, header);
//     Get.find<ReportController>().daystrans.insert(0, header);
//     Get.find<HeaderController>().filteredTrans.value =
//         Get.find<HeaderController>().trans;
//     List<int>? bytes = await Get.find<MainController>()
//         .CurrentClient
//         ?.value
//         .printReceipt(header);
//     if (bytes != null) Get.find<BluetoothManager>().printReceip(bytes);
//     cleartrans();
//     clearlines();
//     upload();
//        } catch (e) {
//       debugPrint("Print failed: $e");
//       Get.snackbar("Error", "Something went wrong during printing.");
//     } finally {
//       Get.back(); // close loading dialog
//       } });

  
//   Get.snackbar("Success", "Receipt saved and printed");
//   }

//   void createline() {
//     Get.find<HeaderController>().currHeader.value.Customer_Posting_Group =
//         Get.find<TransTypeController>().tType.value.Customer_Posting_Group;
//     Get.find<HeaderController>().curTran.value.Document_No =
//         DateTime.now().microsecondsSinceEpoch.toString();
//     Get.find<HeaderController>().curTran.value.OTTN =
//         Get.find<HeaderController>().currHeader.value.Receipt_No;
//     Get.find<HeaderController>().curTran.value.Account_No =
//         Get.find<HeaderController>().currHeader.value.Account;
//     if ((Get.find<HeaderController>().curTran.value.Type == "SAVINGSCREW") &&
//         (Get.find<HeaderController>().currHeader.value.Crew != null ||
//             Get.find<HeaderController>().currHeader.value.Crew != "")) {
//       Get.find<HeaderController>().curTran.value.Account_No =
//           Get.find<HeaderController>().currHeader.value.Crew;
//     }
//     Get.find<HeaderController>().curTran.value.Loan_No =
//         Get.find<HeaderController>().currHeader.value.Vehicle;
//     Get.find<HeaderController>().curTran.value.Transaction_Date =
//         Get.find<HeaderController>().currHeader.value.Date;
//     Get.find<HeaderController>().curTran.value.Amount = double.tryParse(
//         Get.find<HeaderController>().amountEditingController.value.text);
//     Get.find<HeaderController>().curTran.value.Type =
//         Get.find<TransTypeController>().tType.value.Code;
//     if (Get.find<HeaderController>().curTran.value.Type == "EXPENSES") {
//       Get.find<HeaderController>().curTran.value.Amount = double.tryParse(
//               Get.find<HeaderController>()
//                   .amountEditingController
//                   .value
//                   .text)! *
//           -1;
//     }
//     Get.find<HeaderController>().curTran.value.Description =
//         Get.find<TransTypeController>().tType.value.Name;
//     Get.find<HeaderController>().curTran.value.Transaction_Time =
//         DateTime.now();
//     Get.find<HeaderController>().curTran.value.Agent_Code =
//         Get.find<HeaderController>().currHeader.value.Agent;
//     Get.find<HeaderController>().curTran.value.sent = false;
//     Get.find<HeaderController>()
//         .currTrans
//         .add(Get.find<HeaderController>().curTran.value);
//     Get.find<HeaderController>()
//         .currHeader
//         .value
//         .transtions!
//         .add(Get.find<HeaderController>().curTran.value);
//   }

//   void clearlines() {
//     Get.find<HeaderController>().amountEditingController.value.text = '';
//     Get.find<TransTypeController>().tType.value = TranTypes(Code: " ");
//     Get.find<HeaderController>().curTran = tMatatu.Trans().obs;
//     Get.find<VehiclesController>().Currentvehicle = Vehicles().obs;
//   }

//   cleartrans() {
//     clearlines();
//     vehicleno.clear();
//     Get.find<HeaderController>().curTran = tMatatu.Trans().obs;
//     mainController.vehsummary.clear();
//     Get.find<HeaderController>().currTrans.clear();
//     Get.find<HeaderController>().createheader();
//     Get.find<MemberController>().clearcurrentvehicle();
//     Get.find<TransTypeController>().vehicleTrantypes.forEach((element) {
//       element.Checked = false;
//     });
//     Get.find<VehiclesController>().Currentvehicle = Vehicles().obs;
//     vehicleno.clear();
//   }

//   @override
//   Widget build(BuildContext context) {

//     return Scaffold(
//       appBar: AppBar(
     
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.start,
//           children: [
//             const Text('Receipt'),
//            Obx(() => Text(
//                     'Working Date: ${DateFormat('MMM-dd-yyyy').format(Get.find<SettingsController>().workingDate)}',
//                     style: TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),),
          
//           ],
//         ),
//         elevation: 0,
//         centerTitle: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(2.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             veh_memb(context),
//             const SizedBox(height: 1),
//             Obx(() {
//               double total = 0;
//               for (var element in Get.find<MainController>().vehtrans) {
//                 total += element.Amount!;
//               }
//               return ElevatedButton(
//                 onPressed: () {
//                   showDialog(
//                     context: context,
//                     builder: (context) => AlertDialog(
//                       title: Text('Vehicle Transactions'),
//                       content: SizedBox(
//                         width: double.maxFinite,
//                         child: veh_trans(),
//                       ),
//                       actions: [
//                         TextButton(
//                           onPressed: () => Navigator.pop(context),
//                           child: Text('Close'),
//                         ),
//                       ],
//                     ),
//                   );
//                 },
//                 child: RichText(
//                   text: TextSpan(
//                     style: DefaultTextStyle.of(context).style,
//                     children: [
//                       TextSpan(
//                         text: 'Todays Transactions : ',
//                         style: TextStyle(fontSize: 12, color: Colors.black87),
//                       ),
//                       TextSpan(
//                         text:
//                             '${NumberFormat.currency(locale: 'en_US', symbol: 'KSh ').format(total)}',
//                         style: TextStyle(
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           color:
//                               total >= 0 ? Colors.green[800] : Colors.red[800],
//                         ),
//                       ),
                     
//                     ],
//                   ),
//                 ),
//               );
//             }),
//             const SizedBox(height: 1),
//             newentry(context),
//             const SizedBox(height: 1),
//             Expanded(child: curr_trans()),
//             const SizedBox(height: 1),
//             _print(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _print() {
//     return Row(
//       children: [
//         Expanded(
//           child: ElevatedButton.icon(
//             onPressed: () {},
//             icon: const Icon(Icons.print),
//             label: const Text('Reprint'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//             ),
//           ),
//         ),
//         const SizedBox(width: 2),
//         Expanded(
//           child: ElevatedButton.icon(
//             onPressed: _handlePrint,
//             icon: const Icon(Icons.print),
//             label: const Text('Print'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   void _handlePrint() {
//     Print(Get.find<HeaderController>().currHeader.value);
//   }

//   SizedBox curr_trans() {
//     return SizedBox(
//       height: 150,
//       child: Card(
//         elevation: 20,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12), // Adjust the border radius
//           side: const BorderSide(
//               color: Color.fromARGB(255, 19, 158, 82),
//               width: 2), // Border color and width
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.vertical,
//             child: Obx(
//               () => DataTable(
                
//                 dataTextStyle: const TextStyle(
//                   fontWeight: FontWeight.w400,
//                   color: AppColors.textColor,
//                 ),
//                 headingTextStyle: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: AppColors.textColor,
//                     fontSize: 12),
//                 columnSpacing: 60.0, // Set global column spacing
//                 dataRowMinHeight: 30,
//                 dataRowMaxHeight: 50,
//                 headingRowHeight: 20,
//                 columns: [
//                   DataColumn(
//                     label: Container(
//                         alignment: Alignment.centerLeft, child: const Text('')),
//                   ),
//                   DataColumn(
//                     label: Container(
//                         alignment: Alignment.centerLeft,
//                         child: const Text('Desc')),
//                   ),
//                   DataColumn(
//                       label: Container(
//                           alignment: Alignment.centerRight,
//                           child: const Text('Amount'))),
//                 ],
//                 rows: [
//                   for (var tr in Get.find<HeaderController>().currTrans)
//                     DataRow(
//                       cells: [
//                         DataCell(
//                           Container(
//                               padding: const EdgeInsets.all(0.0),
//                               margin: const EdgeInsets.all(
//                                   0.0), // Set margin for the cell content

//                               child: IconButton(
//                                 icon: const Icon(
//                                   Icons.delete,
//                                   size: 40,
//                                   color: Colors.red,
//                                 ),
//                                 onPressed: () {
//                                   Get.find<HeaderController>().removetrans(tr);
//                                 },
//                               )),
//                         ),
//                         DataCell(
//                           Container(
//                               padding: const EdgeInsets.all(0.0),
//                               margin: const EdgeInsets.all(
//                                   0.0), // Set margin for the cell content

//                               child: tr.Type == "SAVINGSCREW"
//                                   ? Text('${tr.Description}(${tr.Account_No})',
//                                       style: const TextStyle(fontSize: 10))
//                                   : Text('${tr.Description}',
//                                       style: const TextStyle(fontSize: 10))),
//                         ),
//                         DataCell(Container(
//                             padding: const EdgeInsets.all(0.0),
//                             margin: const EdgeInsets.all(0.0), //
//                             alignment: Alignment
//                                 .centerRight, // // Set padding for the cell content
//                             child: Text(
//                                 NumberFormat("#,##0.00", "en_US")
//                                     .format(tr.Amount),
//                                 style:
//                                     VehiclesController().summaryexpected()))),
//                       ],
//                     ),
//                   DataRow(
//                     color: MaterialStateProperty.resolveWith<Color?>(
//                       (Set<MaterialState> states) {
//                         // Set color based on the button's state
//                         if (states.contains(MaterialState.pressed)) {
//                           return Colors.red; // Color for pressed state
//                         }
//                         return Colors.lightGreen; // Default color
//                       },
//                     ),
//                     cells: [
//                       DataCell(Container(
//                         padding: const EdgeInsets.all(0.0),
//                         margin: const EdgeInsets.all(0.0),
//                         alignment: Alignment
//                             .centerLeft, // // Set padding for the cell content
//                         child: const Text(
//                           '',
//                           style: TextStyle(
//                               fontSize: 15, fontWeight: FontWeight.bold),
//                         ),
//                       )),
//                       DataCell(Container(
//                         padding: const EdgeInsets.all(0.0),
//                         margin: const EdgeInsets.all(0.0),
//                         alignment: Alignment
//                             .centerLeft, // // Set padding for the cell content
//                         child: const Text(
//                           'Total',
//                           style: TextStyle(
//                               fontSize: 15, fontWeight: FontWeight.bold),
//                         ),
//                       )),
//                       DataCell(
//                         Text(
//                             NumberFormat("#,##0.00", "en_US").format(
//                                 Get.find<HeaderController>().currTrans.fold<
//                                         double>(
//                                     0.0,
//                                     (double currentSum, tMatatu.Trans item) =>
//                                         currentSum +
//                                         num.tryParse(item.Amount.toString())!)),
//                             style: const TextStyle(
//                                 fontSize: 15, fontWeight: FontWeight.bold)),
//                         // Set padding directly to remove row margins
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget newentry(BuildContext context) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(2.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: GetBuilder<TransTypeController>(
//                     builder: (controller) =>
//                         _buildTransTypeDropdown(controller),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: TextFormField(
//                     focusNode: _myFocusNode,
//                     controller: Get.find<HeaderController>()
//                         .amountEditingController
//                         .value,
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(
//                       hintText: 'Amount',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             Visibility(
//               visible: Get.find<TransTypeController>().tType.value.Code ==
//                   "EXPENSES",
//               child: GetBuilder<ExpenseController>(
//                 builder: (controller) => _buildexpensesDropdown(controller),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       padding: EdgeInsets.symmetric(vertical: 12),
//                       backgroundColor: Colors.green[600],
//                       foregroundColor: Colors.white,
//                     ),
//                     onPressed: _handleAddEntry,
//                     icon: Icon(Icons.add, size: 20),
//                     label: Text('Add', style: TextStyle(fontSize: 14)),
//                   ),
//                 ),
//                 if (Get.find<MainController>()
//                         .CurrentClient!
//                         .value
//                         .Auto_Assign ==
//                     true) ...[
//                   SizedBox(width: 16),
//                   ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       padding:
//                           EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                       backgroundColor: Colors.blue[600],
//                       foregroundColor: Colors.white,
//                     ),
//                     onPressed: () {
//                       Get.find<TransTypeController>()
//                           .vehicleTrantypes
//                           .forEach((element) {
//                         print(element.toString());
//                       });
//                       Get.to(() => Distribute());
//                     },
//                     icon: Icon(Icons.more_horiz, size: 20),
//                     label: Text('Distribute', style: TextStyle(fontSize: 14)),
//                   ),
//                 ],
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildexpensesDropdown(ExpenseController controller) {
//     List<Expenses> exps = List.from(Get.find<ExpenseController>().all);

//     return exps.isNotEmpty
//         ? DropdownButtonFormField<Expenses>(
//             //value: Get.find<TransTypeController>().tType.value,
//             onChanged: (Expenses? newValue) {
//               Get.find<HeaderController>().curTran.value.Constituency =
//                   newValue!.Code;
//             },
//             style: const TextStyle(fontSize: 10),
//             items: exps.map<DropdownMenuItem<Expenses>>((Expenses? value) {
//               return DropdownMenuItem<Expenses>(
//                 value: value,
//                 child: Container(
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       Text(
//                         '${value?.Description ?? ''}',
//                         style: const TextStyle(
//                           fontSize: 14,
//                           color: Colors.black,
//                         ),
//                       )

//                       // Checkbox(
//                       //     value: false, onChanged: (bool? value) {})
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//             // decoration: const InputDecoration(
//             //     prefixIcon: Icon(
//             //       Icons.settings_ethernet,
//             //       color: Colors.blue,
//             //     ),
//             //     labelText: 'Select an item',
//             //     labelStyle: TextStyle(fontSize: 12)),
//           )
//         : const CircularProgressIndicator();
//   }

//   Widget _buildTransTypeDropdown(TransTypeController controller) {
//     List<TranTypes> ttypes =
//         List.from(Get.find<TransTypeController>().alltrantypes);

//     final first = ttypes.firstWhereOrNull((element) => element.Code == " ");
//     if (first == null) {
//       ttypes.insert(0, TranTypes(Order: -1, Code: " "));
//     }
//     return ttypes.isNotEmpty
//         ? DropdownButtonFormField<TranTypes>(
//             //value: Get.find<TransTypeController>().tType.value,
//             onChanged: (TranTypes? newValue) {
//               Get.find<HeaderController>().curTran.value.Type = newValue!.Code;
//               Get.find<HeaderController>().curTran.value.Description =
//                   newValue.Name;

//               Get.find<TransTypeController>().tType.value = newValue;
//               Get.find<HeaderController>().amountEditingController.value.text =
//                   newValue.VehicleAmount.toString();
//               FocusScope.of(context).requestFocus(_myFocusNode);
//               Get.find<HeaderController>()
//                   .amountEditingController
//                   .value
//                   .selection = TextSelection(
//                 baseOffset: 0,
//                 extentOffset: Get.find<HeaderController>()
//                     .amountEditingController
//                     .value
//                     .text
//                     .length,
//               );
//             }, 
//             style: const TextStyle(fontSize: 10),
//             items: ttypes.map<DropdownMenuItem<TranTypes>>((TranTypes? value) {
//               return DropdownMenuItem<TranTypes>(
//                 value: value,
//                 child: Container(
//                   constraints: BoxConstraints(
//                     minWidth: 200,
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.start,
//                     children: [
//                       if (value!.Order! >= 0)
//                         value.Name != null
//                             ? Text(
//                                 '${value.Name} (${value.VehicleAmount})',
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.black,
//                                 ),
//                               )
//                             : Text(
//                                 value.Name ?? "",
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//             // decoration: const InputDecoration(
//             //     prefixIcon: Icon(
//             //       Icons.settings_ethernet,
//             //       color: Colors.blue,
//             //     ),
//             //     labelText: 'Select an item',
//             //     labelStyle: TextStyle(fontSize: 12)),
//           )
//         : const CircularProgressIndicator();
//   }

//   void _handleAddEntry() {
//     if (vehicleno.text.isEmpty) {
//       Get.snackbar(
//         'Receipt',
//         "No Vehicle / Account entered",
//         backgroundColor: Colors.red, // Customize the background color
//         duration: const Duration(
//             seconds: 3), // Set the duration the snackbar is displayed
//         snackPosition: SnackPosition.BOTTOM, // Set the position of the snackbar
//       );
//       return;
//     }
//     if (Get.find<HeaderController>()
//         .amountEditingController
//         .value
//         .text
//         .isEmpty) {
//       Get.snackbar(
//         'Receipt',
//         "Amount Cannot be empty",
//         icon: const Icon(Icons.error),
//         backgroundColor: Colors.red, // Customize the background color
//         duration: const Duration(
//             seconds: 3), // Set the duration the snackbar is displayed
//         snackPosition: SnackPosition.BOTTOM, // Set the position of the snackbar
//       );
//       return;
//     }

//     if (Get.find<TransTypeController>().tType.value.Code == null ||
//         Get.find<TransTypeController>().tType.value.Code!.trim().isEmpty) {
//       Get.snackbar(
//         'Receipt',
//         "No Type Selected",
//         backgroundColor: Colors.red, // Customize the background color
//         duration: const Duration(
//             seconds: 3), // Set the duration the snackbar is displayed
//         snackPosition: SnackPosition.BOTTOM, // Set the position of the snackbar
//       );
//       return;
//     }
//     if ((Get.find<TransTypeController>().tType.value.Code == "EXPENSES") &&
//         ((Get.find<HeaderController>().curTran.value.Constituency == null) ||
//             (Get.find<HeaderController>()
//                 .curTran
//                 .value
//                 .Constituency!
//                 .isEmpty))) {
//       Get.snackbar(
//         'Receipt',
//         "Kindly select the Expenses",
//         backgroundColor: Colors.red, // Customize the background color
//         duration: const Duration(
//             seconds: 3), // Set the duration the snackbar is displayed
//         snackPosition: SnackPosition.BOTTOM, // Set the position of the snackbar
//       );
//       return;
//     }

//     createline();
//     clearlines();
//   }

//   Expanded veh_trans() {
//     return Expanded(
//       flex: 2,
//       child: Card(
//         elevation: 20,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(5), // Adjust the border radius
//           side: const BorderSide(
//               color: Color.fromARGB(255, 88, 122, 150),
//               width: 2), // Border color and width
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(2.0),
//           child: SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: SingleChildScrollView(
//               scrollDirection: Axis.vertical,
//               child: Obx(
//                 () => DataTable(
//                                     horizontalMargin: 10.0, // Set global horizontal margin
                                
//                   headingRowHeight: 30, // Set the height of the heading row
//                   dataTextStyle: const TextStyle(
//                     fontWeight: FontWeight.w400,
//                     color: AppColors.textColor,
//                   ),
//                   headingTextStyle: const TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: AppColors.textColor,
//                       fontSize: 12),
//                   columnSpacing: 30.0, // Set global column spacing
//                   dataRowMinHeight: 30,
//                   dataRowMaxHeight: 50,
//                   //headingRowHeight: 20,
//                   columns: [
//                     DataColumn(
//                       label: Container(
//                           alignment: Alignment.centerLeft,
//                           child: const Text('Type',
//                               style: TextStyle(fontSize: 14))),
//                     ),
//                     // DataColumn(
//                     //     label: Container(
//                     //         alignment: Alignment.centerRight,
//                     //         child: const Text('Expected',
//                     //             style: TextStyle(fontSize: 14)))),
//                     DataColumn(
//                         label: Container(
//                             alignment: Alignment.centerRight,
//                             child: const Text('Amount',
//                                 style: TextStyle(fontSize: 14)))),
//                     // DataColumn(
//                     //     label: Container(
//                     //         alignment: Alignment.centerRight,
//                     //         child: const Text('Bal',
//                     //             style: TextStyle(fontSize: 14)))),
//                   ],
//                   rows: [
//                     for (var tr in mainController.vehsummary)
//                       DataRow(
//                         cells: [
//                           DataCell(
//                             Container(
//                                 padding: const EdgeInsets.all(0.0),
//                                 margin: const EdgeInsets.all(
//                                     0.0), // Set margin for the cell content

//                                 child: Text(tr.Type.toString(),
//                                     style: const TextStyle(fontSize: 14))),
//                           ),
//                           // DataCell(Container(
//                           //     padding: const EdgeInsets.all(0.0),
//                           //     margin: const EdgeInsets.all(0.0),
//                           //     alignment: Alignment
//                           //         .centerRight, // // Set padding for the cell content
//                           //     child: Text(
//                           //         NumberFormat("#,##0.00", "en_US")
//                           //             .format(tr.Expected),
//                           //         style:
//                           //             VehiclesController().summaryexpected()))),
//                           DataCell(Container(
//                               padding: const EdgeInsets.all(0.0),
//                               margin: const EdgeInsets.all(0.0), //
//                               alignment: Alignment
//                                   .centerRight, // Set padding for the cell content
//                               child: Text(
//                                   NumberFormat("#,##0.00", "en_US")
//                                       .format(tr.Amount),
//                                   style:
//                                       VehiclesController().summaryAmount()))),
//                           // DataCell(Container(
//                           //     padding: const EdgeInsets.all(0.0),
//                           //     margin: const EdgeInsets.all(0.0), //
//                           //     alignment: Alignment
//                           //         .centerRight, // Set padding for the cell content
//                           //     child: Text(
//                           //         NumberFormat("#,##0.00", "en_US")
//                           //             .format(tr.balance),
//                           //         style: VehiclesController().summarybal()))),
//                         ],
//                       ),
//                     DataRow(
//                       color: MaterialStateProperty.resolveWith<Color?>(
//                         (Set<MaterialState> states) {
//                           // Set color based on the button's state
//                           if (states.contains(MaterialState.pressed)) {
//                             return Colors.red; // Color for pressed state
//                           }
//                           return Colors.lightGreen; // Default color
//                         },
//                       ),
//                       cells: [
//                         DataCell(Container(
//                           padding: const EdgeInsets.all(0.0),
//                           margin: const EdgeInsets.all(0.0),
//                           alignment: Alignment
//                               .centerLeft, // // Set padding for the cell content
//                           child: const Text(
//                             'Total',
//                             style: TextStyle(
//                                 fontSize: 15, fontWeight: FontWeight.bold),
//                           ),
//                         )),
//                         // DataCell(
//                         //   Text(
//                         //       NumberFormat("#,##0.00", "en_US").format(
//                         //           mainController.vehsummary.fold<double>(
//                         //               0.0,
//                         //               (double currentSum, TransSummary item) =>
//                         //                   currentSum +
//                         //                   num.tryParse(
//                         //                       item.Expected.toString())!)),
//                         //       style: const TextStyle(
//                         //           fontSize: 15, fontWeight: FontWeight.bold)),
//                         //   // Set padding directly to remove row margins
//                         // ),
//                         DataCell(
//                           Text(
//                               NumberFormat("#,##0.00", "en_US").format(
//                                   mainController.vehsummary.fold<double>(
//                                       0.0,
//                                       (double currentSum, TransSummary item) =>
//                                           currentSum +
//                                           num.tryParse(
//                                               item.Amount.toString())!)),
//                               style: const TextStyle(
//                                   fontSize: 15, fontWeight: FontWeight.bold)),
//                           // Set padding directly to remove row margins
//                         ),
//                         // DataCell(
//                         //   Text(
//                         //       NumberFormat("#,##0.00", "en_US").format(
//                         //           mainController.vehsummary.fold<double>(
//                         //               0.0,
//                         //               (double currentSum, TransSummary item) =>
//                         //                   currentSum +
//                         //                   num.tryParse(
//                         //                       item.balance.toString())!)),
//                         //       style: const TextStyle(
//                         //           fontSize: 15, fontWeight: FontWeight.bold)),
//                         //   // Set padding directly to remove row margins
//                         // ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Container veh_memb(BuildContext context) {
//     return Container(
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Autocomplete<Suggestion>(
//                 initialValue: TextEditingValue.empty,
//                 optionsBuilder: (TextEditingValue textEditingValue) async {
//                   if (textEditingValue.text.isEmpty) {
//                     return const Iterable<Suggestion>.empty();
//                   }
//                   return await memberController
//                       .getVehicleSuggestions(textEditingValue.text);
//                 },
//                 displayStringForOption: (Suggestion option) =>
//                     option.displayText,
//                 onSelected: (Suggestion selection) {
//                   Get.find<HeaderController>()
//                       .createheader(); // Assuming this method updates the header based on current selections
//                   Get.find<HeaderController>()
//                       .currTrans
//                       .clear(); // Clear current transactions
//                   Get.find<MainController>()
//                       .vehsummary
//                       .clear(); // Clear vehicle summary
//                   Get.find<MemberController>().initialize();
//                   Get.find<HeaderController>().currHeader.value.Account =
//                       selection.account;
//                   vehicleno.text = selection.displayText;
//                   if (selection.isVehicle) {
//                     // Handle vehicle selection
//                     // Assuming 'vehicleno' is a TextEditingController
//                     if (selection.id.isNotEmpty) {
//                       vehicleno.text = selection.id;  
//                       Get.find<HeaderController>().currHeader.value.Fleet =
//                         selection.id;
//                     }
//                     memberController.getcurrentcrew(selection
//                         .displayText); // Assuming this method sets the current crew based on vehicle ID
//                     Get.find<HeaderController>().currHeader.value.Vehicle =
//                         selection.displayText;
                  
//                     Get.find<VehiclesController>().getvehtrans(
//                         selection.displayText,
//                         DateTime.now()); // Re-initialize member controller
//                   }
//                 },
//                 fieldViewBuilder: (BuildContext context,
//                     TextEditingController vehicleno,
//                     FocusNode fieldFocusNode,
//                     VoidCallback onFieldSubmitted) {
//                   return TextField(
//                     controller: vehicleno,
//                     focusNode: fieldFocusNode,
//                     decoration: InputDecoration(
//                       hintText: 'Enter vehicle number or member name',
//                       prefixIcon: Icon(Icons.search),
//                         suffixIcon: IconButton(    // Clear button
//         icon: Icon(Icons.clear,color: Colors.red),
//         onPressed: () => vehicleno.clear(),  // Clears text
//       ),
//                       border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8)),
//                     ),
//                   );
//                 },
//                 optionsViewBuilder: (BuildContext context,
//                     AutocompleteOnSelected<Suggestion> onSelected,
//                     Iterable<Suggestion> options) {
//                   return Align(
//                     alignment: Alignment.topLeft,
//                     child: Material(
//                       elevation: 4.0,
//                       borderRadius: BorderRadius.circular(8),
//                       child: ListView(
//                         children: options.map((Suggestion option) {
//                           String title = option.id == ''
//                               ? option.displayText
//                               : '${option.id}-${option.displayText}';
//                           return Card(
//                             elevation: 2,
//                             child: ListTile(
//                               leading: option.isVehicle
//                                   ? const Icon(Icons.directions_bus,
//                                       color: Colors.blue, size: 24)
//                                   : const Icon(Icons.person,
//                                       color: Colors.green, size: 24),
//                               title: Text(option.isVehicle
//                                   ? title
//                                   : option.displayText),
//                               subtitle: Text(option.details),
//                               trailing: option.loan > 0
//                                   ? Text(
//                                       '${NumberFormat("#,##0.00", "en_US").format(option.loan)}',
//                                       style: const TextStyle(
//                                           fontSize: 12, color: Colors.red),
//                                     )
//                                   : null,
//                               onTap: () => onSelected(option),
//                             ),
//                           );
//                         }).toList(),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 2),
//             if (Get.find<MainController>().CurrentClient?.value.Attach_crew == true) 
//             GetBuilder<MemberController>(
//                 builder: (controller) => Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     if(Get.find<MainController>().CurrentClient?.value.Crew_to_attach == CrewToattach.Both || Get.find<MainController>().CurrentClient?.value.Crew_to_attach == CrewToattach.Driver)
//                     Expanded(
//                         flex: 2,
//                         child: _buildCrewInfo(
//                             "Driver", controller.currentdriver.value)),
//                     if(Get.find<MainController>().CurrentClient?.value.Crew_to_attach == CrewToattach.Both || Get.find<MainController>().CurrentClient?.value.Crew_to_attach == CrewToattach.Condutor)
//                     Expanded(
//                         flex: 2,
//                         child: _buildCrewInfo(
//                             "Conductor", controller.currentcunductor.value)),
//                     Expanded(
//                       flex: 1,
//                       child: IconButton(
//                         onPressed: () => Get.to(() => CrewAssignment(
//                             vehicle: Get.find<VehiclesController>()
//                                 .Currentvehicle
//                                 .value)),
//                         icon: const Icon(Icons.edit, size: 30),
//                       ),
//                     )
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildCrewInfo(String title, Member? member) {
//     return Container(
//       padding: EdgeInsets.all(4), // Reduced padding
//       margin: EdgeInsets.symmetric(vertical: 2), // Reduced margin
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.2),
//             spreadRadius: 1,
//             blurRadius: 3,
//             offset: Offset(0, 1), // changes position of shadow
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 12, // Reduced font size
//               fontWeight: FontWeight.bold,
//               color: Colors.blueGrey,
//             ),
//           ),
//           SizedBox(height: 2), // Reduced space
//           Text(
//             member != null ? "${member.Name}" : "Not Assigned",
//             style: TextStyle(
//                 fontSize: 10, // Reduced font size
//                 color: member != null ? Colors.black : Colors.red,
//                 overflow: TextOverflow.ellipsis),
//           ),
//           if (member != null) ...[
//             SizedBox(height: 2), // Reduced space
//             Text(
//               "${member.No ?? 'N/A'}",
//               style: TextStyle(
//                   fontSize: 10, // Reduced font size
//                   color: Colors.black54,
//                   overflow: TextOverflow.ellipsis),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   void _showDialog(BuildContext context) {
//     TextEditingController recamount = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           alignment: Alignment.topCenter,
//           backgroundColor: AppColors.backgroundColor,
//           //title: const Text('Transactions Types'),
//           titleTextStyle: const TextStyle(fontSize: 15),
//           content: SizedBox(
//             height: MediaQuery.of(context).size.height - 20,
//             width: MediaQuery.of(context).size.width - 2,
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Column(
//                   children: [
//                     Text(
//                       '${Get.find<HeaderController>().currHeader.value.Vehicle} - ${Get.find<HeaderController>().currHeader.value.Fleet}',
//                       style: const TextStyle(fontSize: 15),
//                     ),
//                     Text(
//                         NumberFormat("#,##0.00", "en_US").format(
//                             Get.find<MainController>().vehsummary.fold<
//                                     double>(
//                                 0.0,
//                                 (double currentSum, TransSummary item) =>
//                                     currentSum +
//                                     num.tryParse(item.Amount.toString())!)),
//                         style: const TextStyle(fontSize: 10))
//                   ],
//                 ),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       width: 200,
//                       child: TextFormField(
//                         keyboardType: TextInputType.number,
//                         controller: recamount,
//                         decoration: const InputDecoration(
//                             //labelText: "Amount",
//                             ),
//                         onChanged: (value) {
//                           try {
//                             if (value.isNotEmpty) {}
//                           } catch (e) {
//                             // Handle the case where parsing fails (e.g., non-numeric string)
//                             print("Error: $e");
//                           }
//                         },
//                       ),
//                     ),
//                     IconButton(
//                         onPressed: () {
//                           Get.find<TransTypeController>().distribute(
//                               double.tryParse(recamount.text) ?? 0);
//                         },
//                         icon: Icon(Icons.post_add_sharp))
//                   ],
//                 ),
//                 ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: Get.find<TransTypeController>()
//                       .vehicleTrantypes
//                       .where((p0) => p0.Name != null)
//                       .length,
//                   itemBuilder: (context, index) {
//                     return GetBuilder<TransTypeController>(
//                         builder: (controller) {
//                       return Card(
//                         elevation: 20,
//                         child: CheckboxListTile(
//                           dense: true,
//                           contentPadding: const EdgeInsets.only(left: 2),
//                           title: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             mainAxisSize: MainAxisSize.max,
//                             children: [
//                               Text(
//                                 '${controller.vehicleTrantypes[index].Name}(${Get.find<TransTypeController>().vehicleTrantypes[index].Amounttoday}/${controller.vehicleTrantypes[index].VehicleAmount})',
//                                 style: const TextStyle(fontSize: 12),
//                               ),
//                               Text(
//                                 '${Get.find<TransTypeController>().vehicleTrantypes[index].Amountedited}',
//                                 style: const TextStyle(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold),
//                               ),
//                             ],
//                           ),
//                           subtitle: Flexible(
//                             flex: 5,
//                             child: Visibility(
//                                 visible: (controller.vehicleTrantypes[index]
//                                             .VehicleAmount! ==
//                                         0 ||
//                                     controller.vehicleTrantypes[index].Code ==
//                                         "SAVINGS" ||
//                                     controller.vehicleTrantypes[index].Code ==
//                                         "SAVINGSCREW"),
//                                 child: TextFormField(
//                                   focusNode: controller
//                                       .vehicleTrantypes[index].FocusNodes,
//                                   keyboardType: TextInputType.number,
//                                   controller: controller
//                                       .vehicleTrantypes[index].eAmount,
//                                   decoration: const InputDecoration(
//                                       //labelText: "Amount",
//                                       ),
//                                   onChanged: (value) {
//                                     try {
//                                       controller.vehicleTrantypes[index]
//                                               .Amountedited =
//                                           double.parse(controller
//                                               .vehicleTrantypes[index]
//                                               .eAmount
//                                               .text);
//                                     } catch (e) {
//                                       // Handle the case where parsing fails (e.g., non-numeric string)
//                                       print("Error: $e");
//                                     }
//                                   },
//                                 )),
//                           ),
                
//                           //controlAffinity: ListTileControlAffinity.leading,
//                           tristate: true,
//                           checkColor: Colors.black,
//                           activeColor: Colors.red,
//                           value: controller.vehicleTrantypes[index].Checked,
                
//                           // Get.find<BluetoothController>().connected.value,
//                           onChanged: (bool? value) {
//                             controller.toggle(index);
//                             if (value == true) {
//                               double? vehicleamount = controller
//                                   .vehicleTrantypes[index].VehicleAmount;
                
//                               double? bal = vehicleamount! > 0
//                                   ? vehicleamount -
//                                       controller.vehicleTrantypes[index]
//                                           .Amounttoday!
//                                   : 0;
//                               bal = bal < 0 ? 0 : bal;
//                               // controller.vehicleTrantypes[index].eAmount
//                               // .text = '$bal';
//                               controller
//                                       .vehicleTrantypes[index].eAmount.text =
//                                   '${controller.vehicleTrantypes[index].VehicleAmount}';
//                               controller
//                                       .vehicleTrantypes[index].Amountedited =
//                                   controller
//                                       .vehicleTrantypes[index].VehicleAmount;
//                             } else {
//                               controller.vehicleTrantypes[index].eAmount
//                                   .text = '0.0';
//                               controller
//                                   .vehicleTrantypes[index].Amountedited = 0.0;
//                             }
                
//                             FocusScope.of(context).requestFocus(controller
//                                 .vehicleTrantypes[index].FocusNodes);
//                             controller.vehicleTrantypes[index].eAmount
//                                 .selection = TextSelection(
//                               baseOffset: 0,
//                               extentOffset: controller.vehicleTrantypes[index]
//                                   .eAmount.text.length,
//                             );
//                           },
//                         ),
//                       );
//                     });
//                     // return CheckboxListTile(
//                     //   title: Text(Get.find<TransTypeController>()
//                     //       .vehicleTrantypes[index]
//                     //       .Name
//                     //       .toString()),
//                     //   tristate: true,
//                     //   checkColor: Colors.black,
//                     //   activeColor: Colors.red,
//                     //   value: Get.find<TransTypeController>()
//                     //           .vehicleTrantypes[index]
//                     //           .Checked ??
//                     //       false, // Get.find<BluetoothController>().connected.value,
//                     //   onChanged: (bool? value) {
//                     //     Get.find<TransTypeController>()
//                     //             .vehicleTrantypes[index]
//                     //             .Checked =
//                     //         !Get.find<TransTypeController>()
//                     //             .vehicleTrantypes[index]
//                     //             .Checked!;
//                     //   },
//                     // );
//                   },
//                 ),
//               ],
//             ),
//           ),
//           actions: [
//             Flexible(
//               flex: 1,
//               child: GetBuilder<TransTypeController>(builder: (controller) {
//                 // double dd = 0;
//                 // List<TranTypes> tp = controller.vehicleTrantypes
//                 //     .where((p0) => p0.Checked == true && p0.Code != " ")
//                 //     .toList();
//                 // if (tp.isNotEmpty) {
//                 //   dd = tp.fold<double>(
//                 //       0.0,
//                 //       (double currentSum, item) =>
//                 //           currentSum +
//                 //           num.tryParse(item.Amountedited == null
//                 //               ? ""
//                 //               : item.Amountedited.toString())!);
//                 // }

//                 return Text(
//                   NumberFormat("#,##0.00", "en_US")
//                       .format(TransTypeController().get_selected()),
//                   style: const TextStyle(
//                       fontSize: 40, color: AppColors.accentColor),
//                 );
//               }),
//             ),
//             const Flexible(flex: 1, child: Spacer()),
//             Flexible(
//               flex: 1,
//               child: TextButton(
//                 onPressed: () {
//                   HeaderController().createlines();
//                   clearlines();
//                   Navigator.of(context).pop(); // Close the dialog
//                 },
//                 child: const Text('OK'),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
