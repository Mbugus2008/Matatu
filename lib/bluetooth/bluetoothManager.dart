import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

class BluetoothManager extends GetxController{
  var defaultPrinterType = PrinterType.bluetooth;
  RxBool _isBle = false.obs;
  RxBool _reconnect = true.obs;
  RxBool _isConnected = false.obs;
  var printerManager = PrinterManager.instance;
  RxList<BluetoothPrinter> devices = <BluetoothPrinter>[].obs;
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;

  //BluetoothPrinter? selectedPrinter;
  final selectedPrinter = Rx<BluetoothPrinter?>(null);
  BTStatus _currentStatus = BTStatus.none;


  @override
  void onInit() {
    super.onInit();
print("Initializing Bluetooth");

    // _subscriptionBtStatus = PrinterManager.instance.stateBluetooth.listen((status) {
    //   log(' ----------------- status bt $status ------------------ ');
    //   _currentStatus = status;
    //   if (status == BTStatus.connected) {
    //
    //       _isConnected.value = true;
    //
    //   }
    //   if (status == BTStatus.none) {
    //
    //       _isConnected.value = false;
    //
    //   }
    //
    // });

  }

  void Subscriptionstatus()
  {
    _subscriptionBtStatus = PrinterManager.instance.stateBluetooth.listen((status) {
      log(' ----------------- status bt $status ------------------ ');
      _currentStatus = status;
      if (status == BTStatus.connected) {

        Get.find<BluetoothManager>()._isConnected.value = true;
          print("Connected");
        Fluttertoast.showToast(
          msg: "Bluetooth Connected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      }
      if (status == BTStatus.none) {

        Get.find<BluetoothManager>()._isConnected.value = false;
          print("Disconnected");
        Fluttertoast.showToast(
          msg: "Bluetooth Disconnected",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.black,
        );
      }

    });

  }
  void Scan() {
  devices.clear();
   _subscription = printerManager.discovery(type: defaultPrinterType, isBle: Get.find<BluetoothManager>()._isBle.value ).listen((device) {
      Get.find<BluetoothManager>().devices.add(BluetoothPrinter(
        deviceName: device.name,
        address: device.address,
        isBle: Get.find<BluetoothManager>()._isBle.value,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: defaultPrinterType,
      ));
    });
  }
  void selectDevice(BluetoothPrinter device) async {
    if (Get.find<BluetoothManager>().selectedPrinter != null) {
      if ((device.address != Get.find<BluetoothManager>().selectedPrinter.value!.address) || (device.typePrinter == PrinterType.usb && Get.find<BluetoothManager>().selectedPrinter.value!.vendorId != device.vendorId)) {
        await PrinterManager.instance.disconnect(type: Get.find<BluetoothManager>().selectedPrinter.value!.typePrinter);
      }
    }

    Get.find<BluetoothManager>().selectedPrinter.value = device;

  }
void connect(BluetoothPrinter device) async {
    if (Get.find<BluetoothManager>()._isConnected == false){
  await printerManager.connect(
      type: device.typePrinter,
      model: BluetoothPrinterInput(
          name: device.deviceName,
          address: device.address!,
          isBle: device.isBle ?? false,
          autoConnect: Get
              .find<BluetoothManager>()
              ._reconnect
              .value));
}}
void printReceip(List<int> bytes){
  if (Get.find<BluetoothManager>(). _isConnected ==true) {
    printerManager.send(type:  defaultPrinterType, bytes: bytes);

  }

}
  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();

    super.dispose();
  }

}
class BluetoothPrinter {
  int? id;
  String? deviceName;
  String? address;
  String? port;
  String? vendorId;
  String? productId;
  bool? isBle;

  PrinterType typePrinter;
  bool? state;

  BluetoothPrinter(
      {this.deviceName,
        this.address,
        this.port,
        this.state,
        this.vendorId,
        this.productId,
        this.typePrinter = PrinterType.bluetooth,
        this.isBle = false});
}