// import 'package:bluetooth_thermal_printer/bluetooth_thermal_printer.dart';
// import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
// import 'package:get/get.dart';
// import 'package:t_matatu/controllers/main.dart';
// import 'package:t_matatu/models/summary/Tsummary.dart';
//
// import '../models/Header.dart';
//
// class Bluetooth extends GetxController {
//   RxList availableBluetoothDevices = [].obs;
//   RxString printer = ''.obs;
//   @override
//   Future<void> onInit() async {
//     super.onInit();
//     scan();
//   }
//
//   Future<bool> connect(String mac) async {
//     final String? result = await BluetoothThermalPrinter.connect(mac);
//     print("state conneected $result");
//     if (result == "true") {
//       return true;
//     } else {
//       return false;
//     }
//   }
//
//   Future<bool> connected(String mac) async {
//     String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//     if (isConnected == "true") {
//       return true;
//     }
//     return false;
//   }
//
//   Future<void> scan() async {
//     final List? bluetooths = await BluetoothThermalPrinter.getBluetooths;
//
//     print("Print $bluetooths");
//     Get.find<Bluetooth>().availableBluetoothDevices.value = bluetooths!;
//   }
//
//   Future<void> printTicket() async {
//     String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//     if (isConnected == "true") {
//       List<int> bytes = await getTickets();
//       final result = await BluetoothThermalPrinter.writeBytes(bytes);
//       print("Print $result");
//     } else {
//       //Hadnle Not Connected Senario
//     }
//   }
//
//   Future<void> printReceipt(Header header) async {
//     try {
//       String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//
//       if (isConnected == "true") {
//         List<int>? bytes = await Get.find<MainController>()
//             .CurrentClient
//             ?.value
//             .printReceipt(header);
//         await BluetoothThermalPrinter.writeBytes(bytes!);
//         //   Receipttype type = gettype(header.transtions);
//         //   switch (type) {
//         //     case Receipttype.Member:
//         //       {
//         //         List<int> bytes = await getTicket(header);
//         //         await BluetoothThermalPrinter.writeBytes(bytes);
//         //       }
//         //     case Receipttype.Crew:
//         //       {
//         //         List<int> bytes = await getTicketcrew(header);
//         //         await BluetoothThermalPrinter.writeBytes(bytes);
//         //       }
//         //     case Receipttype.Both:
//         //       {
//         //         List<tmatatu.Trans> listcopy = header.transtions!;
//         //         List<tmatatu.Trans> mtr = listcopy
//         //             .where((element) =>
//         //                 element.Type != "SAVINGSCREW" &&
//         //                 element.Type != "SAVINGS")
//         //             .toList();
//         //         if (mtr.isNotEmpty) {
//         //           Header h = header.copyWith();
//
//         //           h.transtions = mtr;
//         //           h.Total_Amount = mtr.fold<double>(
//         //               0.0,
//         //               (double currentSum, tmatatu.Trans item) =>
//         //                   currentSum + num.tryParse(item.Amount.toString())!);
//         //           List<int> bytes = await getTicket(h);
//         //           await BluetoothThermalPrinter.writeBytes(bytes);
//         //         }
//         //         listcopy = header.transtions!;
//         //         List<tmatatu.Trans> mtrc = listcopy
//         //             .where((element) =>
//         //                 element.Type == "SAVINGSCREW" ||
//         //                 element.Type == "SAVINGS")
//         //             .toList();
//         //         for (var element in mtrc) {
//         //           Header h = header.copyWith();
//         //           if (element.Type == "SAVINGSCREW")
//         //             h.Account = element.Account_No;
//         //           h.transtions = [element];
//         //           h.Total_Amount = element.Amount;
//         //           List<int> bytes = await getTicketcrew(h);
//         //           await BluetoothThermalPrinter.writeBytes(bytes);
//         //           // List<int> bytes1 = await seperator();
//         //           // await BluetoothThermalPrinter.writeBytes(bytes1);
//         //         }
//         //         if (mtrc.isNotEmpty) {}
//         //       }
//         //   }
//         // } else {
//         //   //Hadnle Not Connected Senario
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   Future<void> printReceipttest() async {
//     try {
//       String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//
//       if (isConnected == "true") {
//         List<int> bytes = await getTickettest();
//         final result = await BluetoothThermalPrinter.writeBytes(bytes);
//       } else {
//         //Hadnle Not Connected Senario
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
//
//   Future<List<int>> getTickettest() async {
//     List<int> bytes = [];
//     CapabilityProfile profile = await CapabilityProfile.load();
//     final generator = Generator(PaperSize.mm58, profile);
//
//     bytes += generator.text(
//       "Citi hopper Ltd",
//       styles: const PosStyles(
//         align: PosAlign.center,
//         height: PosTextSize.size2,
//         width: PosTextSize.size2,
//       ),
//     );
//     bytes += generator.cut();
//     return bytes;
//   }
//
//   Future<List<int>> seperator() async {
//     List<int> bytes = [];
//     CapabilityProfile profile = await CapabilityProfile.load();
//     final generator = Generator(PaperSize.mm58, profile);
//
//     bytes += generator.hr();
//     bytes += generator.hr();
//     bytes += generator.cut();
//     return bytes;
//   }
//
//   Future<List<int>> getTickets() async {
//     List<int> bytes = [];
//     CapabilityProfile profile = await CapabilityProfile.load();
//     final generator = Generator(PaperSize.mm58, profile);
//
//     bytes += generator.text("Demo Shop",
//         styles: const PosStyles(
//           align: PosAlign.center,
//           height: PosTextSize.size2,
//           width: PosTextSize.size2,
//         ),
//         linesAfter: 1);
//
//     bytes += generator.text(
//         "18th Main Road, 2nd Phase, J. P. Nagar, Bengaluru, Karnataka 560078",
//         styles: const PosStyles(align: PosAlign.center));
//     bytes += generator.text('Tel: +919591708470',
//         styles: const PosStyles(align: PosAlign.center));
//
//     bytes += generator.hr();
//     bytes += generator.row([
//       PosColumn(
//           text: 'No',
//           width: 1,
//           styles: const PosStyles(align: PosAlign.left, bold: true)),
//       PosColumn(
//           text: 'Item',
//           width: 5,
//           styles: const PosStyles(align: PosAlign.left, bold: true)),
//       PosColumn(
//           text: 'Price',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.center, bold: true)),
//       PosColumn(
//           text: 'Qty',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.center, bold: true)),
//       PosColumn(
//           text: 'Total',
//           width: 2,
//           styles: const PosStyles(align: PosAlign.right, bold: true)),
//     ]);
//
//     bytes += generator.row([
//       PosColumn(text: "1", width: 1),
//       PosColumn(
//           text: "Tea",
//           width: 5,
//           styles: const PosStyles(
//             align: PosAlign.left,
//           )),
//       PosColumn(
//           text: "10",
//           width: 2,
//           styles: const PosStyles(
//             align: PosAlign.center,
//           )),
//       PosColumn(
//           text: "1", width: 2, styles: const PosStyles(align: PosAlign.center)),
//       PosColumn(
//           text: "10", width: 2, styles: const PosStyles(align: PosAlign.right)),
//     ]);
//
//     bytes += generator.row([
//       PosColumn(text: "2", width: 1),
//       PosColumn(
//           text: "Sada Dosa",
//           width: 5,
//           styles: const PosStyles(
//             align: PosAlign.left,
//           )),
//       PosColumn(
//           text: "30",
//           width: 2,
//           styles: const PosStyles(
//             align: PosAlign.center,
//           )),
//       PosColumn(
//           text: "1", width: 2, styles: const PosStyles(align: PosAlign.center)),
//       PosColumn(
//           text: "30", width: 2, styles: const PosStyles(align: PosAlign.right)),
//     ]);
//
//     bytes += generator.row([
//       PosColumn(text: "3", width: 1),
//       PosColumn(
//           text: "Masala Dosa",
//           width: 5,
//           styles: const PosStyles(
//             align: PosAlign.left,
//           )),
//       PosColumn(
//           text: "50",
//           width: 2,
//           styles: const PosStyles(
//             align: PosAlign.center,
//           )),
//       PosColumn(
//           text: "1", width: 2, styles: const PosStyles(align: PosAlign.center)),
//       PosColumn(
//           text: "50", width: 2, styles: const PosStyles(align: PosAlign.right)),
//     ]);
//
//     bytes += generator.row([
//       PosColumn(text: "4", width: 1),
//       PosColumn(
//           text: "Rova Dosa",
//           width: 5,
//           styles: const PosStyles(
//             align: PosAlign.left,
//           )),
//       PosColumn(
//           text: "70",
//           width: 2,
//           styles: const PosStyles(
//             align: PosAlign.center,
//           )),
//       PosColumn(
//           text: "1", width: 2, styles: const PosStyles(align: PosAlign.center)),
//       PosColumn(
//           text: "70", width: 2, styles: const PosStyles(align: PosAlign.right)),
//     ]);
//
//     bytes += generator.hr();
//
//     bytes += generator.row([
//       PosColumn(
//           text: 'TOTAL',
//           width: 6,
//           styles: const PosStyles(
//             align: PosAlign.left,
//             height: PosTextSize.size2,
//             width: PosTextSize.size2,
//           )),
//       PosColumn(
//           text: "160",
//           width: 6,
//           styles: const PosStyles(
//             align: PosAlign.right,
//             height: PosTextSize.size2,
//             width: PosTextSize.size2,
//           )),
//     ]);
//
//     bytes += generator.hr(ch: '=', linesAfter: 1);
//
//     // ticket.feed(2);
//     bytes += generator.text('Thank you!',
//         styles: const PosStyles(align: PosAlign.center, bold: true));
//
//     bytes += generator.text("26-11-2020 15:22:45",
//         styles: const PosStyles(align: PosAlign.center), linesAfter: 1);
//
//     bytes += generator.text(
//         'Note: Goods once sold will not be taken back or exchanged.',
//         styles: const PosStyles(align: PosAlign.center, bold: false));
//     bytes += generator.cut();
//     return bytes;
//   }
//
//   String printout(String left, String right) {
//     int totallen = left.length + right.length;
//     String space = ' '.padLeft(32 - totallen);
//     return '$left$space$right';
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     BluetoothThermalPrinter.disconnect();
//   }
//
//   Future<void> printZreport(Tsummary tsummary) async {
//     try {
//       String? isConnected = await BluetoothThermalPrinter.connectionStatus;
//
//       if (isConnected == "true") {
//         List<int>? bytes = await await Get.find<MainController>()
//             .CurrentClient
//             ?.value
//             .getZreport(tsummary);
//         // List<int> bytes = await getZreport(tsummary);
//         final result = await BluetoothThermalPrinter.writeBytes(bytes!);
//         print("Print $result");
//       } else {
//         //Hadnle Not Connected Senario
//       }
//     } catch (e) {
//       print(e);
//     }
//   }
// }
