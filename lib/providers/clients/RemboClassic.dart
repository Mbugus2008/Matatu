import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/pages/expenses/vehicle_expenses_screen.dart';

import 'package:t_matatu/providers/client.dart';


class RemboClassic extends    BaseClients { 
  RemboClassic({
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
       Show_comments,
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
    Show_comments: Show_comments,
  );


  @override
  Future<void> init() async {}
 
  @override
  String v_description(Header header) {
    return '${header.Vehicle ?? ''}';
  }
  @override
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
    'Balance: ${Get.find<MainController>().agent .value.Account_Balance.toString()}', // Customize this text
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,// Smaller than main title
      ),
    ),
  ],
),
    );
  }

  @override
  bool? Auto_Assign = false;

  @override
  Future<List<int>> printReceipt(Header header) async {
    List<int> bytes = [];

    bytes = await getHeader() + await getTicket(header);

    return Future.value(bytes);
  }

  @override
  List<Widget>? clientMenu() {
    return [
      ListTile(
        leading: const Icon(Icons.receipt_long),
        title: const Text('Vehicle Expenses'),
        onTap: () {
          // The screen brings its own AppBar, so it is not wrapped in a
          // PageLoader - that would stack two app bars.
          Get.to(() => const VehicleExpensesScreen());
        },
      ),
    ];
  }

 

  
}
