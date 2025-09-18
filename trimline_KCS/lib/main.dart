import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:t_matatu/main.dart' as tmatatu;
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/client.dart';
import 'package:t_matatu/providers/clients/KCS.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BaseClients client = Kcs(clientName: "KANGEMI CLASSIC SHUTTLE", clientName_line2: "", email: "ungemishuttle@gmail.com",
   telephone: "0723254334 | 0722401284", 
   street: "Tom Mboya St. Opp. Co-op Bank", 
   address: "Njengi Hse 4rd Floor",
    city: "Nairobi, Kenya", Box: "P.O Box 31164-00600",
     Auto_Assign: false , Attach_crew: false);

  if (Platform.isAndroid) {
    [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan
     
    ].request().then((status) async {
         
    }).then((value) async {
     AppConfig   config = AppConfig(
        apiBaseUrl: 'http://nav.trimline.co.ke:4010/api/Matatu/',
        clientId: "KC-SHUTTLE",
        clientName: "KC-SHUTTLE",
        Client: client,
        logo: 'assets/logo.png',
      );
       await tmatatu.start(config);
       runApp(tmatatu.MyApp());
    });
  }
 
}

