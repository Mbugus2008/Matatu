import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/providers/client.dart';

class Lopha extends BaseClients {
  Lopha({
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
  }) : super(
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
            'Balance: ${Get.find<MainController>().agent.value.Account_Balance.toString()}', // Customize this text
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold, // Smaller than main title
            ),
          ),
        ],
      ),
    );
  }

  @override
  List<Widget>? clientMenu() {
    return null;
  }
}
