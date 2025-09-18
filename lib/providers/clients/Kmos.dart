import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/pages/widgets/Groupbox.dart';

import 'package:t_matatu/providers/client.dart';
import 'package:t_matatu/reports/controller.dart';


class Kmos extends BaseClients {
  Kmos({
     clientName,
     clientName_line2,
     email,
     telephone,
    street,
    address,
    city,
    Box,
     Auto_Assign,
     Attach_crew,
     Crew_to_attach,
  }) :super(
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
    Crew_to_attach: Crew_to_attach,
  );

  @override
  Future<void> init() async {
ReportController().gettransbydate(DateTime.now());
        MainController().getvehiclecrew();
  }

AppBar? appBar() {
  return AppBar(
    title: Text(
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
   
  );
}
  @override
  String v_description(Header header) {
    return '${header.Vehicle ?? ''}';
  }

  @override
  Future<List<int>> printReceipt(Header header) async {
    List<int> bytes = [];

    bytes = await getHeader() + await getTicket(header);

    return Future.value(bytes);
  }

  @override
  GroupBox? clientMenu() {
    return null;
  }
  


  
}
