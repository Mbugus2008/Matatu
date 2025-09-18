
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t_matatu/bluetooth/bluetooth.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/models/Devices.dart';
import 'package:t_matatu/models/TransSummary.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/agents.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';
import 'package:t_matatu/providers/AppConfig.dart';
import 'package:t_matatu/providers/client.dart';
import 'package:t_matatu/providers/clients/Citihoppa.dart';
import 'package:t_matatu/providers/db.dart';

import '../models/vehicles/Vehicle_crew.dart';
import '../models/vehicles/vehicle.dart';
import '../network/results/results.dart';

class MainController extends GetxController {
  RxList<String> tables = <String>[].obs;
  RxString? username = ''.obs;
  RxList<tmatatu.Trans> vehtrans = <tmatatu.Trans>[].obs;
  RxList<TransSummary> vehsummary = <TransSummary>[].obs;
  Rx<AppConfig>? config = AppConfig().obs;

  Rx<BaseClients>? CurrentClient = BaseClients().obs;
  Rx<Agent> agent = Agent().obs;

  final Rx<Logger> logger = Logger().obs;
  final RxBool isLoading = false.obs;

  RxList<VehicleTransaction> vehicleTransactions = <VehicleTransaction>[].obs;

  @override
  void onInit() {
    super.onInit();
    //refreshData();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    try {
      // Refresh your data here
      await Vehicles().Daily_Contributions(DateTime.now());
      await fetchVehicleTransactions();
      // Add any other data refresh logic you need
    } catch (e) {
      print('Error refreshing data: $e');
      // You might want to show an error message to the user here
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchVehicleTransactions() async {
    // TODO: Implement the logic to fetch vehicle transactions
    // This could involve querying a local database or making an API call
    // For now, we'll use dummy data
    vehicleTransactions.value = [
      VehicleTransaction(vehicle: 'Bus 1', date: '2023-04-20', amount: 100.0),
      VehicleTransaction(vehicle: 'Bus 2', date: '2023-04-20', amount: 150.0),
      // Add more dummy data as needed
    ];
  }

  @override
  void onReady() {
    super.onReady();
    // Called when the widget is ready, like initState in StatefulWidgets
    // Place your refresh logic here when the page becomes active
    update(); // This triggers the refresh of GetBuilder or Obx
  }


  // Future<void> devices() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //   var dev = Devices(
  //       Device_id: androidInfo.androidId,
  //       Manufacturer: androidInfo.manufacturer,
  //       Brand: androidInfo.brand);
  //   ApiClient().postdata("Devices", dev.toJson()).then((r) async {
  //     if (r.statusCode == 200) {
  //       Results<Agent> results = Results<Agent>.fromJson(r.body, Agent.fromMap);
  //       if (results.Code == 0) {
  //         if (results.Contents != null) {
  //           Get.find<db_Provider>().batchinsert(
  //               Agent.tableagents, results.Contents as List<Agent>);
  //         }
  //       }
  //     }
  //   });
  // }

 

  

  Future<void> getvehiclecrew() async {
    bool hasdata = true;
    String? bookmark;
    int? size = 100;
    var request = Request(body: null, bookmark: bookmark, size: size);
    while (hasdata) {
      await ApiClient()
          .postdata("vehiclecrew", request.toJson())
          .then((r) async {
        if (r.statusCode == 200) {
          Results<Vehicle_Crew> results =
              Results<Vehicle_Crew>.fromJson(r.body, Vehicle_Crew.fromMap);
          if (results.Code == 0) {
            if (results.Contents != null) {
              hasdata = results.Contents!.isNotEmpty;
              if (results.Contents!.isNotEmpty) {
                Get.find<db_Provider>().batchinsert(
                    Vehicle_Crew.table, results.Contents as List<Vehicle_Crew>);
                bookmark = results.Contents!.last.Key;
                request = Request(body: null, bookmark: bookmark, size: size);
              }

              // for (Vehicles element in results.Contents as List<Vehicles>) {
              // db.insert(Vehicles.table, element);

              //}
            }
          } else {
            if (results.Desc == 'The operation has timed out') {
              size = (size! / 2).round();
            }
          }
        } else {
          hasdata = false;
        }
        //The operation has timed out
      });
    }
  }

  Future<void> savePreference(String key, String value) async {
    print(value);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(key, value);
  }

// Retrieving a preference
  Future<String?> getPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == "printer") {

      for (var element in Get.find<BluetoothManager>().devices) {

        if (element.address == prefs.getString(key)) {
          Get.find<BluetoothManager>().selectedPrinter.value = element;
          print( "set print: ${element.address}");
        }


      }
      if (Get.find<BluetoothManager>().selectedPrinter.value != null)
        Get.find<BluetoothManager>().connect(Get.find<BluetoothManager>().selectedPrinter.value as BluetoothPrinter);

    }
    // print(prefs.getString(key));
    return prefs.getString(key);
  }

  // Future<AndroidDeviceInfo> getDeviceInfo() async {
  //   DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //   AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //   return androidInfo;
  // }

  void addReceipt({required String date, required double amount, required String vehicle}) {
    // TODO: Implement the logic to add the receipt to your data source
    // This could involve updating a local database, sending data to a server, etc.
    print('Adding receipt: Date: $date, Amount: $amount, Vehicle: $vehicle');
    // After adding the receipt, you might want to refresh the data
    refreshData();
  }
}

class VehicleTransaction {
  final String vehicle;
  final String date;
  final double amount;

  VehicleTransaction({required this.vehicle, required this.date, required this.amount});
}
