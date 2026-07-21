import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/pages/login.dart';
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/colors.dart';


const simplePeriodicTask =
    "be.tramckrijte.workmanagerExample.simplePeriodicTask";
const simplePeriodic1HourTask =
    "be.tramckrijte.workmanagerExample.simplePeriodic1HourTask";

class MyAppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      //Get.find<MainController>().CurrentClient!.value.init();
    }
  }
}

class start {
  start(AppConfig clientId) {

  
        init().then((value) { 
    Get.find<MainController>().config?.value = clientId;
    AppConfig().init(clientId);

   
   
    Get.find<MainController>()
        .CurrentClient
        ?.value
        .init(); //Inistialize client dependent processeses

    
      initializedata();

      // Workmanager().initialize(
      //   callbackDispatcher,
      //   isInDebugMode: true,
      // );
      // Workmanager().registerPeriodicTask(
      //   simplePeriodicTask,
      //   simplePeriodic1HourTask,
      //   initialDelay: const Duration(seconds: 10),
      //   frequency: const Duration(seconds: 20),
      // );
    });
    //initiate();
  }

  Future<void> initiate() async {
    
    if (Platform.isAndroid) {
      [
        Permission.location,
        Permission.storage,
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
       
      ].request().then((status) async {
        await init().then((value) {
          initializedata();
   // After app starts, check for updates
     
          // Workmanager().initialize(
          //   callbackDispatcher,
          //   isInDebugMode: true,
          // );
          // Workmanager().registerPeriodicTask(
          //   simplePeriodicTask,
          //   simplePeriodic1HourTask,
          //   initialDelay: const Duration(seconds: 10),
          //   frequency: const Duration(seconds: 20),
          // );
        });
      });
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Matatu',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primaryColor),
        useMaterial3: true,
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
      ),
      home: const Login(),
      getPages: [],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}
