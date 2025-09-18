// ignore_for_file: public_member_api_docs, sort_constructors_first, constant_identifier_names

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/Tamounts.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/summary/Tsummary.dart';
import 'package:t_matatu/models/trantypes.dart';
import 'package:t_matatu/models/vehicles/DeportandFuel.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/pages/Depot.dart';
import 'package:t_matatu/pages/Fuel.dart';
import 'package:t_matatu/pages/hires/hires_list.dart';
import 'package:t_matatu/pages/pageloader.dart';
import 'package:t_matatu/pages/vehicles/vehdetails.dart';
import 'package:t_matatu/providers/client.dart';

import '../../controllers/vehicles/vehicles.dart';
import '../../pages/widgets/Groupbox.dart';
import '../../reports/controller.dart';
import '../../pages/TwoTabScreen.dart';

enum Receipttype { Member, Crew, Both }

class Cityhoppa extends  BaseClients {

  Cityhoppa({clientName,clientName_line2,email,
  telephone,street,address,city,
  Box,Auto_Assign,Attach_crew}):super(
    clientName: clientName,
    clientName_line2: clientName_line2,
    email: email,
    telephone: telephone,
    street: street,
    address: address,
    city: city,
    Box: Box,
    Auto_Assign: Auto_Assign,
    Attach_crew: Attach_crew,
  );

  @override
  Future<void> init() async {
    if (!Get.isRegistered<DepotController>()) {
      Get.put(DepotController());
    }
    Tamounts().getttypesamounts();
    await Vehicles().Daily_Contributions(getdate());
    await MainController().getvehiclecrew();
  }

  @override
  AppBar? appBar() {
    return AppBar(
      title: Text(
        Get.find<MainController>().CurrentClient?.value.clientName ?? '',
        style: TextStyle(
          fontSize: _getTitleFontSize(Get.find<MainController>()
                  .CurrentClient
                  ?.value
                  .clientName
                  ?.length ??
              0),
        ),
      ),
    );
  }

  @override
  Widget homelist() {
    int? account_type = Get.find<MainController>().agent.value.Account_type;
    switch (account_type) {
      case 3:
        ReportController().gettransbydate(DateTime.now());
        Get.find<ReportController>().selectedDate?.value = DateTime.now();
        DepotFuel().getNRODefects();
        DepotFuel().getdata(Get.find<ReportController>().selectedDate!.value);
        return const TwoTabScreen(); // Use the TwoTabScreen for account_type 3
      default:
        return GetBuilder<VehiclesController>(
          builder: (controller) {
            if (controller.vehdailycollections.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              children: [
                _buildSearchField(controller),
                Expanded(child: _buildVehicleList(controller)),
                _buildSummaryCard(controller),
              ],
            );
          },
        );
    }
  }

  Widget _buildSearchField(VehiclesController controller) {
    return TextFormField(
      onChanged: (value) => controller.filterVehicles(value.toUpperCase()),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search, color: Colors.blue),
        labelText: 'Find Vehicle',
        labelStyle: TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildVehicleList(VehiclesController controller) {
    return ListView.builder(
      itemCount: controller.vehdailycollections.length,
      itemBuilder: (context, index) {
        final vehicle = controller.vehdailycollections[index];
        return _buildVehicleCard(vehicle);
      },
    );
  }

  Widget _buildVehicleCard(Vehicles vehicle) {
    return Card(
      color: vehicle.total > 0 ? Colors.green[100] : Colors.white,
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          Get.find<VehiclesController>().vehcollections.clear();
          Vehicles().Daily_Veh_Contributions(getdate(), vehicle.Vehicle_Number);
          Get.to(() => VehDetails(vehicle: vehicle));
        },
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildVehicleInfo(vehicle),
              ),
              Expanded(
                flex: 3,
                child: _buildpaymethodInfo(vehicle),
              ),
              Expanded(
                flex: 3,
                child: _buildFinancialInfo(vehicle),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfo(Vehicles vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          vehicle.Fleet_No.toString(),
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          vehicle.Vehicle_Number ?? 'No Fleet',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          vehicle_type_desc.desc[vehicle.Vehicle_Type] ?? 'Unknown Type',
          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
        ),
      ],
    );
  }

  Widget _buildCrewInfo(Vehicles vehicle) {
    // Assuming memberController.getcurrentcrew returns a Future<List<Member>?>
    return Obx(() {
      var crew = MemberController().getcurrentcrew(vehicle.Vehicle_Number
          .toString()); // Assuming currentCrew is an Rx<List<Member>?>

      // Check if crew is null or empty
      if (crew == null || crew.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Driver: No Driver Assigned',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            Text(
              'Conductor: No Conductor Assigned',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
        );
      }

      // Display Driver information
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Driver: ${crew[0].isDriver ? crew[0].name : 'No Driver Assigned'}',
            style: TextStyle(
              fontSize: 12,
              color: crew[0].isDriver
                  ? Colors.black
                  : Colors.red, // Change color if driver is not available
            ),
          ),
          // Display Conductor information
          Text(
            'Conductor: ${crew[1].isConductor ? crew[1].name : 'No Conductor Assigned'}',
            style: TextStyle(
              fontSize: 12,
              color: crew[1].isConductor
                  ? Colors.black
                  : Colors.red, // Change color if conductor is not available
            ),
          ),
        ],
      );
    });
  }

  Widget _buildFinancialInfo(Vehicles vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFinancialItem('Mgmt', vehicle.Management ?? 0),
        _buildFinancialItem('Offload', vehicle.Offload ?? 0),
        Text(
          NumberFormat("#,##0.00", "en_US").format(vehicle.total),
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green[700]),
        ),
      ],
    );
  }

  Widget _buildpaymethodInfo(Vehicles vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFinancialItem('Cash', vehicle.Cash ?? 0),
        _buildFinancialItem('Mpesa', vehicle.Mpesa ?? 0),
      ],
    );
  }

  Widget _buildFinancialItem(String label, double amount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        Text(
          NumberFormat("#,##0.00", "en_US").format(amount),
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(Vehicles vehicle) {
    bool isActive = vehicle.total > 0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.green[100] : Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isActive ? Icons.check_circle_outline : Icons.remove_circle_outline,
        color: isActive ? Colors.green[700] : Colors.red[700],
        size: 12, // Reduced icon size from 20 to 16
      ),
    );
  }

  Widget _buildSummaryCard(VehiclesController controller) {
    final activeVehicles =
        controller.vehdailycollections.where((v) => v.total > 0).length;
    final totalVehicles = controller.vehdailycollections.length;
    final totalManagement = controller.vehdailycollections
        .fold<double>(0, (sum, v) => sum + (v.Management ?? 0));
    final totalOffload = controller.vehdailycollections
        .fold<double>(0, (sum, v) => sum + (v.Offload ?? 0));
    final totalAmount = controller.vehdailycollections
        .fold<double>(0, (sum, v) => sum + v.total);
    final cash = controller.vehdailycollections
        .fold<double>(0, (sum, v) => sum + (v.Cash ?? 0));
    final mpesa = controller.vehdailycollections
        .fold<double>(0, (sum, v) => sum + (v.Mpesa ?? 0));

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Active Vehicles',
                    '$activeVehicles / $totalVehicles', Icons.directions_bus),
                //_buildSummaryItem('Management', totalManagement, Icons.business_center),
                //_buildSummaryItem('Offload', totalOffload, Icons.local_shipping),
                _buildSummaryItem('Cash', cash, Icons.money),
                _buildSummaryItem('Mpesa', mpesa, Icons.money_off),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total Amount: ',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800),
                ),
                Text(
                  NumberFormat("#,##0.00", "en_US").format(totalAmount),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, dynamic value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue.shade600, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
        ),
        SizedBox(height: 2),
        Text(
          value is double
              ? NumberFormat("#,##0.00", "en_US").format(value)
              : value.toString(),
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900),
        ),
      ],
    );
  }

  Receipttype gettype(List<tmatatu.Trans>? t) {
    tmatatu.Trans? crew = t?.firstWhereOrNull((element) =>
        element.Type == "SAVINGSCREW" || element.Type == "SAVINGS");
    tmatatu.Trans? member = t?.firstWhereOrNull((element) =>
        element.Type != "SAVINGSCREW" && element.Type != "SAVINGS");
    if (crew != null && member != null) return Receipttype.Both;
    if (crew != null) return Receipttype.Crew;
    return Receipttype.Member;
  }

  @override
  Future<List<int>> printReceipt(Header header) async {
    List<int> bytes = [];
    Receipttype type = gettype(header.transtions);
    switch (type) {
      case Receipttype.Member:
       clientName = "City Hoppa Limited";
      clientName_line2 = "";
        bytes += await getHeader() + await getTicket(header);
        break;
      case Receipttype.Crew:
      clientName = "Citi Travel Savings & Credit";
      clientName_line2 = "Co-operative Society Ltd";
        for (var element in header.transtions!) {
          Header h = header.copyWith();
          if (element.Type == "SAVINGSCREW") h.Account = element.Account_No;
          h.transtions = [element];
          h.Total_Amount = element.Amount;
          bytes += await getHeader() + await getTicketcrew(h);
        }
        break;
      case Receipttype.Both:
       clientName = "City Hoppa Limited";
      clientName_line2 = "";
        List<tmatatu.Trans> listcopy = header.transtions!;
        List<tmatatu.Trans> mtr = listcopy
            .where((element) =>
                element.Type != "SAVINGSCREW" && element.Type != "SAVINGS")
            .toList();
        if (mtr.isNotEmpty) {
          Header h = header.copyWith();
          h.transtions = mtr;
          h.Total_Amount = mtr.fold<double>(
              0.0,
              (currentSum, item) =>
                  currentSum + num.tryParse(item.Amount.toString())!);
          bytes += await getTicket(h);
        }
        List<tmatatu.Trans> mtrc = listcopy
            .where((element) =>
                element.Type == "SAVINGSCREW" || element.Type == "SAVINGS")
            .toList();
        for (var element in mtrc) {
          Header h = header.copyWith();
          if (element.Type == "SAVINGSCREW") h.Account = element.Account_No;
          h.transtions = [element];
          h.Total_Amount = element.Amount;
          bytes += await getTicketcrew(h);
        }
        break;
    }
    return Future.value(bytes);
  }

  Future<List<int>> getTicket(Header header) async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // bytes += generator.text(
    //   "CITYHOPPER Ltd",
    //   styles: const PosStyles(
    //     align: PosAlign.center,
    //     height: PosTextSize.size2,
    //     width: PosTextSize.size2,
    //   ),
    // );
    // bytes += generator.text(
    //   "Chambia House, Ngara P.O Box 74925-00200",
    //   styles:
    //       const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    // );
    // bytes += generator.text(
    //   "Nairobi,",
    //   styles: const PosStyles(align: PosAlign.center),
    // );
    // bytes += generator.text(
    //   "Telephone: 312058/9 Fax: 312057",
    //   styles: const PosStyles(align: PosAlign.center),
    // );
    // bytes += generator.text(
    //   "Email: info@citihoppa.co.ke",
    //   styles: const PosStyles(align: PosAlign.center),
    //   linesAfter: 1,
    // );
    bytes += generator.text(
      "Cash Collection Receipt",
      styles: const PosStyles(
          align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
    );

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
          text: 'Rec. No:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: header.Receipt_No.toString(),
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Member No:',
          width: 8,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: header.Account.toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Vehicle:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: '${header.Vehicle} - ${header.Fleet}',
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Date',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: formattedDate2.format(header.Date!),
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Time',
          width: 8,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: formattedTime.format(DateTime.fromMicrosecondsSinceEpoch(
              int.tryParse(header.Receipt_No.toString())!)),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Description',
          width: 9,
          styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Amount',
          width: 3,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();
    if (header.transtions != null) {
      for (var type in header.transtions!) {
        bytes += generator.row([
          PosColumn(
              text: type.Description.toString(),
              width: 8,
              styles: const PosStyles(align: PosAlign.left)),
          PosColumn(
              text: NumberFormat("#,##0.00", "en_US").format(type.Amount),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
      PosColumn(
        text: NumberFormat("#,##0.00", "en_US").format(header.Total_Amount),
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);

    bytes += generator.row([
      PosColumn(
          text: 'Served by',
          width: 6,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: Get.find<MainController>().agent.value.Name.toString(),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.cut();
    return bytes;
  }

  Future<List<int>> getTicketcrew(Header header) async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    // bytes += generator.text(
    //   "Citi Travel Savings & Credit",
    //   styles: const PosStyles(
    //     align: PosAlign.center,
    //     height: PosTextSize.size1,
    //     width: PosTextSize.size1,
    //   ),
    // );
    // bytes += generator.text(
    //   "Co-operative Society Ltd",
    //   styles: const PosStyles(
    //     align: PosAlign.center,
    //     height: PosTextSize.size1,
    //     width: PosTextSize.size1,
    //   ),
    // );
    // bytes += generator.text(
    //   "Chambia House, Ngara P.O Box 74925-00200",
    //   styles:
    //       const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    // );
    // bytes += generator.text(
    //   "Nairobi,",
    //   styles: const PosStyles(align: PosAlign.center),
    // );
    // bytes += generator.text(
    //   "Telephone: 312058/9",
    //   styles: const PosStyles(align: PosAlign.center),
    // );

    bytes += generator.text(
      "Cash Collection Receipt",
      styles: const PosStyles(
          align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
    );

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Rec. No:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: header.Receipt_No.toString(),
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'No:', width: 8, styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: header.Account.toString(),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Vehicle:',
          width: 6,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: '${header.Vehicle} - ${header.Fleet}',
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Date',
          width: 8,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: formattedDate2.format(header.Date!),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Time',
          width: 8,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: formattedTime.format(DateTime.fromMicrosecondsSinceEpoch(
              int.tryParse(header.Receipt_No.toString())!)),
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Description',
          width: 9,
          styles: const PosStyles(align: PosAlign.left, bold: true)),
      PosColumn(
          text: 'Amount',
          width: 3,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();
    if (header.transtions != null) {
      for (var type in header.transtions!) {
        bytes += generator.row([
          PosColumn(
              text: type.Description.toString(),
              width: 8,
              styles: const PosStyles(align: PosAlign.left)),
          PosColumn(
              text: NumberFormat("#,##0.00", "en_US").format(type.Amount),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
      PosColumn(
        text: NumberFormat("#,##0.00", "en_US").format(header.Total_Amount),
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);

    bytes += generator.row([
      PosColumn(
          text: 'Served by',
          width: 6,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: Get.find<MainController>().agent.value.Name.toString(),
          width: 6,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.cut();
    return bytes;
  }
  @override
  Future<List<int>> getZreport(Tsummary summary) async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.text(
      "CITYHOPPER  Ltd",
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      "Chambia House, Ngara P.O Box 74925-00200",
      styles:
          const PosStyles(align: PosAlign.center, fontType: PosFontType.fontB),
    );
    bytes += generator.text(
      "Nairobi,",
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      "Telephone: 312058/9 Fax: 312057",
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      "Email: info@citihoppa.co.ke",
      styles: const PosStyles(align: PosAlign.center),
      linesAfter: 1,
    );
    bytes += generator.text(
      "ZReport",
      styles: const PosStyles(
          align: PosAlign.center, bold: true, fontType: PosFontType.fontA),
    );

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Date:',
          width: 4,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: formattedDate2.format(summary.Date!),
          width: 8,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Agent:',
          width: 8,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: summary.Agent!,
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr();
    if (summary.trans != null) {
      for (var type in summary.trans!) {
        bytes += generator.row([
          PosColumn(
              text: type.Description.toString(),
              width: 8,
              styles: const PosStyles(align: PosAlign.left)),
          PosColumn(
              text: NumberFormat("#,##0.00", "en_US").format(type.Total),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(
          align: PosAlign.left,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
      PosColumn(
        text: NumberFormat("#,##0.00", "en_US").format(summary.Total),
        width: 4,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      ),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);

    bytes += generator.row([
      PosColumn(
          text: 'Printed by',
          width: 5,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: Get.find<MainController>().agent.value.Name.toString(),
          width: 7,
          styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Time Printed',
          width: 5,
          styles: const PosStyles(align: PosAlign.left)),
      PosColumn(
          text: formattedTime.format(DateTime.now()),
          width: 7,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.cut();
    return bytes;
  }

  @override
  String v_description(Header header) {
    return '${header.Vehicle ?? ''}- ${header.Fleet}';
  }
  @override
  GroupBox? clientMenu() {
    return GroupBox("", [
      ListTile(
        leading: const Icon(Icons.receipt),
        onTap: () {
          ReportController().gettransbydate(DateTime.now());
          Get.find<ReportController>().selectedDate?.value = DateTime.now();
          DepotFuel().getNRODefects();
          DepotFuel().getdata(Get.find<ReportController>().selectedDate!.value);
          Get.to(() => const PageLoader(page: Depot(), title: "Dispatch"));
        },
        title: const Text("Dispatch"),
      ),
      ListTile(
        leading: const Icon(Icons.summarize),
        onTap: () {
          Get.find<ReportController>().selectedDate?.value = DateTime.now();
          DepotFuel().getdata(Get.find<ReportController>().selectedDate!.value);
          Get.to(() => const PageLoader(page: Fuel(), title: "Fuel"));
        },
        title: const Text("Fuel"),
      ),
      ListTile(
        leading: const Icon(Icons.summarize),
        onTap: () {
          Get.to(() => PageLoader(page: HiresListScreen(), title: "Hires"));
        },
        title: const Text("Hires"),
      ),
    ]);
  }



@override
bool? Attach_crew = true;

  double _getTitleFontSize(int length) {
    return 18.0; // Default title font size, adjust as needed
  }
}
