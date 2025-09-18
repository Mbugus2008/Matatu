import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/bluetooth/bluetooth.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';

import '../providers/colors.dart';

class bluetoothScanresults extends StatelessWidget {
  const bluetoothScanresults({super.key});
  @override
  Widget build(BuildContext context) {

    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 20,
                child: ListView.builder(
                    // itemExtent: 10,
                    shrinkWrap: true,
                    itemCount:
                        Get.find<BluetoothManager>().devices.length,
                    itemBuilder: (BuildContext context, int index) {
                      BluetoothPrinter select = Get.find<BluetoothManager>().devices[index] ;
                      //List list = select.split("#");

                      return ListTile(
                        tileColor: AppColors.backgroundColor,
                        title: Text(select.deviceName ?? ''),
                        subtitle: Text(select.address ?? ''),
                        onTap: () async {
                          Get.find<MainController>()
                              .savePreference("printer", select.address ??'');
                          Get.find<BluetoothManager>().selectedPrinter.value = select;
                          Get.find<BluetoothManager>().connect(select);
                          Get.back();
                        },
                      );
                    }),
              ),
              // child: StreamBuilder<List<BluetoothDevice>>(
              //   stream: Get.find<BluetoothController>()
              //       .bluetoothPrint
              //       .scanResults,
              //   initialData: [],
              //   builder: (c, snapshot) => Column(
              //     children: snapshot.data!
              //         .map((d) => ListTile(
              //             tileColor: AppColors.backgroundColor,
              //             title: Text(d.name ?? ''),
              //             subtitle: Text(d.address ?? ''),
              //             onTap: () async {
              //               Get.find<BluetoothController>().device.value =
              //                   d;
              //               Get.find<MainController>().savePreference(
              //                   "printer",
              //                   json.encode(Get.find<BluetoothController>()
              //                       .toJson(d)));
              //             },
              //             trailing: Obx(
              //               () => Get.find<BluetoothController>().device !=
              //                           null &&
              //                       Get.find<BluetoothController>()
              //                               .device
              //                               .value!
              //                               .address ==
              //                           d.address
              //                   ? Icon(
              //                       Icons.check,
              //                       color: Colors.green,
              //                     )
              //                   : Text(""),
              //             )))
              //         .toList(),
              //   ),
              // ),
            ),
          ],
        ),
      ),
    );
  }
}
