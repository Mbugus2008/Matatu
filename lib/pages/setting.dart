import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';
import 'package:t_matatu/models/Reversal.dart';
import 'package:t_matatu/pages/Reversals/ReversalsList.dart';
import 'package:t_matatu/pages/change_password.dart';
import 'package:t_matatu/pages/widgets/Groupbox.dart';
import 'package:t_matatu/reports/Daily%20Summary.dart';
import 'package:t_matatu/reports/controller.dart';
import 'package:t_matatu/reports/receipts.dart';
import 'package:t_matatu/reports/vehicle_contributions.dart';
import 'package:t_matatu/utils/updater.dart';

import '../bluetooth/bluetoothscans.dart';
import '../controllers/main.dart';
import '../models/summary/Tsummary.dart';
import '../models/summary/TsummaryDetails.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<MainController>().getPreference("printer").toString();
    String? logoValue = Get.find<MainController>().config?.value.logo;
    String logo = logoValue ?? "";
    GroupBox? menu =
        Get.find<MainController>().CurrentClient!.value.clientMenu();
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      image: DecorationImage(
                          image: AssetImage(
                              logo), //'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png' Replace with your image asset path
                          fit: BoxFit
                              .cover, // Adjust this based on your layout requirements
                          opacity: 1),
                    ),
                    child: Align(
                      alignment: Alignment.topRight,
                      child: FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'v${snapshot.data!.version}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    )),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text('Printer: '),
                      ),
                      Expanded(
                        flex: 3,
                        child: Obx(() => Text(Get.find<BluetoothManager>()
                                .selectedPrinter
                                .value
                                ?.deviceName ??
                            '')),
                      ),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Get.to(() => const bluetoothScanresults());
                          },
                          child: const Text("Set"),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 1, // height of the line
                  width: double.infinity, // width of the line
                  color: Colors.black,
                ),
                GroupBox("Reports", [
                  ListTile(
                    leading: const Icon(Icons.receipt),
                    onTap: () {
                      ReportController().gettransbydate(DateTime.now());
                      Get.find<ReportController>().selectedDate?.value =
                          DateTime.now();
                      Get.to(() => const ReceiptReport());
                    },
                    title: const Text("Receipts"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.summarize),
                    onTap: () {
                      TsummaryDetails().getall();
                      Tsummary().getall();
                      Get.to(() => const SummaryReport());
                    },
                    title: const Text("Daily Summary"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.ev_station),
                    onTap: () {
                      Get.to(() => const VehicleContributionsReport());
                    },
                    title: const Text("Vehicle Collections"),
                  ),
                  ListTile(
                    leading: const Icon(Icons.summarize),
                    onTap: () {
                      Reversal().getreversals();
                      Reversal().uploadreversal();
                      Reversal().downloadreversals();
                      Get.to(() => ReversalListScreen(
                            reversal: Get.find<ReversalController>().reversals,
                          ));
                    },
                    title: const Text("Reversals"),
                  ),
                ]),
                if (menu != null) ...[menu],
                // Settings section
                GroupBox("Settings", [
                  ListTile(
                    leading: const Icon(Icons.lock, color: Colors.blue),
                    onTap: () {
                      Get.to(() => const ChangePasswordScreen());
                    },
                    title: const Text("Change Password"),
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.system_update, color: Colors.green),
                    onTap: () {
                      Get.find<UpdateController>().checkForUpdate();
                    },
                    title: const Text("Check for Updates"),
                  ),
                ]),
                // Add more drawer items as needed
              ],
            ),
          ),
          // App Version at bottom
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '© CityHoppa',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
