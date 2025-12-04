import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/pages/widgets/Groupbox.dart';
import 'package:t_matatu/pages/widgets/receiptsReport.dart';
import 'package:t_matatu/pages/widgets/searchreceipts.dart';
// ignore: unused_import
import 'package:t_matatu/reports/receipts.dart';

import '../models/Header.dart';
import '../models/summary/Tsummary.dart';

enum CrewToattach { Both, Driver, Condutor }

class BaseClients {
  BaseClients({
    this.clientName,
    this.clientName_line2,
    this.email,
    this.telephone,
    this.street,
    this.address,
    this.city,
    this.Box,
    this.Auto_Assign,
    this.Attach_crew,
    this.Crew_to_attach,
    this.Show_comments,
  });
  factory BaseClients.fromMap(Map<String, dynamic> map) {
    return BaseClients(
      clientName: map['clientName'],
      clientName_line2: map['clientName_line2'],
      email: map['email'],
      telephone: map['telephone'],
      street: map['street'],
      address: map['address'],
      city: map['city'],
      Box: map['Box'],
      Auto_Assign: map['Auto_Assign'],
      Attach_crew: map['Attach_crew'],
      Crew_to_attach: map['Crew_to_attach'],
      Show_comments: map['Show_comments'],
    );
  }
  String? clientName = "TrimLine Systems & Solutions";
  String? clientName_line2 = "";
  String? email = "info@trimline.co.ke";
  String? telephone = "0710563359";
  String? street = "Kijabe Street";
  String? address = "Norfolk Towers, 1st Floor Room 1";
  String? city = "Nairobi, Kenya";
  String? Box = "P. O. Box 074-00600";

  //String v_description(Header header);
  String v_description(Header header) {
    return '${header.Vehicle ?? ''}';
  }

  bool? Auto_Assign;
  bool? Show_comments = false;
  //Future<void> init();
  Future<void> init() async {}
  //GroupBox? clientMenu();
  GroupBox? clientMenu() {
    return null;
  }

  bool? Attach_crew = false;
  CrewToattach? Crew_to_attach = CrewToattach.Both;

  Widget homelist() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          searchReceiptToday(),
          receiptReporttoday(),
        ]);
  }

  AppBar? appBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Get.find<MainController>().CurrentClient?.value.clientName ?? '',
            style: TextStyle(
              fontSize: GetTitleFontSize(Get.find<MainController>()
                      .CurrentClient
                      ?.value
                      .clientName
                      ?.length ??
                  0),
            ),
          ),
          Text(
            'Balance: ${NumberFormat('#,##0.00', 'en_US').format(Get.find<MainController>().agent.value.Account_Balance ?? 0)}', // Customize this text
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold, // Smaller than main title
            ),
          ),
        ],
      ),
    );
  }

  Future<List<int>> printReceipt(Header header) async {
    List<int> bytes = [];

    bytes = await getHeader() + await getTicket(header);

    return Future.value(bytes);
  }

  Future<List<int>> getHeader() async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.text(
      clientName!,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size1,
      ),
    );
    if (clientName_line2!.isNotEmpty) {
      bytes += generator.text(
        clientName_line2!,
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size1,
        ),
      );
    }
    if (Box != null) {
      bytes += generator.text(
        Box!,
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }
    if (city != null) {
      bytes += generator.text(
        city!,
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }
    if (address != null) {
      bytes += generator.text(
        address!,
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }
    if (street != null) {
      bytes += generator.text(
        street!,
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }
    if (telephone != null) {
      bytes += generator.text(
        telephone!,
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }
    if (email != null) {
      bytes += generator.text(
        email!,
        styles: const PosStyles(
          align: PosAlign.center,
        ),
      );
    }
    bytes += generator.hr();
    return bytes;
  }

  Future<List<int>> getTicket(Header header) async {
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += generator.text("Cash Collection Receipt",
        styles: const PosStyles(
            align: PosAlign.center, bold: true, fontType: PosFontType.fontA));

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Rec. No:',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: header.Receipt_No.toString(),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Member No:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: header.Account.toString(),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Vehicle:',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: '${header.Vehicle}',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Date',
          width: 2,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text:
              "${formattedDate2.format(header.Date!)} ${formattedTime.format(DateTime.fromMicrosecondsSinceEpoch(int.tryParse(header.Receipt_No.toString())!))}",
          width: 10,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
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
      for (var type in header.transtions!.toList()) {
        bytes += generator.row([
          PosColumn(
              text: type.Description.toString(),
              width: 8,
              styles: const PosStyles(
                align: PosAlign.left,
              )),
          PosColumn(
              text: NumberFormat("#,##0.00", "en_US").format(type.Amount),
              width: 4,
              styles: const PosStyles(
                align: PosAlign.right,
              )),
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
          )),
      PosColumn(
          text: NumberFormat("#,##0.00", "en_US").format(header.Total_Amount),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.hr(ch: '=');

    bytes += generator.row([
      PosColumn(
          text: 'Served by',
          width: 6,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: Get.find<MainController>().agent.value.Name.toString(),
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);

    bytes += generator.row([
      PosColumn(
          text: 'Printed on',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printedon.format(DateTime.now()),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    // ticket.feed(2);

    bytes += generator.cut();
    return bytes;
  }

  // Future<List<int>> printReceipt(Header header);
  //Future<List<int>> getZreport(Tsummary summary);
  Future<List<int>> getZreport(Tsummary summary) async {
    // TODO: implement getZreport
    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);

    bytes += await getHeader();

    bytes += generator.text("ZReport",
        styles: const PosStyles(
            align: PosAlign.center, bold: true, fontType: PosFontType.fontA));

    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
          text: 'Date:',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: formattedDate2.format(summary.Date!),
          width: 8,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.row([
      PosColumn(
          text: 'Agent:',
          width: 8,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: summary.Agent!,
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.hr();
    if (summary.trans != null) {
      for (var type in summary.trans!.toList()) {
        bytes += generator.row([
          PosColumn(
              text: type.Description.toString(),
              width: 8,
              styles: const PosStyles(
                align: PosAlign.left,
              )),
          PosColumn(
              text: NumberFormat("#,##0.00", "en_US").format(type.Total),
              width: 4,
              styles: const PosStyles(
                align: PosAlign.right,
              )),
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
          )),
      PosColumn(
          text: NumberFormat("#,##0.00", "en_US").format(summary.Total),
          width: 4,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          )),
    ]);

    bytes += generator.hr(ch: '=', linesAfter: 1);

    bytes += generator.row([
      PosColumn(
          text: 'Printed by',
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: Get.find<MainController>().agent.value.Name.toString(),
          width: 7,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    // ticket.feed(2);
    bytes += generator.row([
      PosColumn(
          text: 'Printed On: ',
          width: 5,
          styles: const PosStyles(
            align: PosAlign.left,
          )),
      PosColumn(
          text: printedon.format(DateTime.now()),
          width: 7,
          styles: const PosStyles(
            align: PosAlign.right,
          )),
    ]);
    bytes += generator.cut();
    return bytes;
  }
}
