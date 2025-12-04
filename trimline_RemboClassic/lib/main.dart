import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:t_matatu/main.dart' as tmatatu;
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/client.dart';
import 'package:t_matatu/providers/clients/RemboClassic.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BaseClients client = RemboClassic(clientName: "REMBO CLASSIC SACCO", 
  clientName_line2: "", 
  email: "remboclassicsaccos@gmail.com",
  telephone: "0715118735 | 0787188117", 
  Show_comments: true,
 
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
        //apiBaseUrl: 'http://nav.trimline.co.ke:4010/api/Matatu/',
        apiBaseUrl: 'http://195.26.249.217:4010/api/Matatu/',
        //updateUrl: 'https://trimline.co.ke/apps/RemboClassic/',
          updateUrl: 'https://5.189.167.52/apps/RemboClassic/',
        clientId: "REMBOCLASIC",
        clientName: "REMBOCLASIC",
        Client: client,
        logo: 'assets/logo.png',
      );
       await tmatatu.start(config);
       runApp(tmatatu.MyApp());
       
    });
  }
 
}

