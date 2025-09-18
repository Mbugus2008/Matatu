import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/TypesController.dart';

class printer extends StatelessWidget {
  const printer({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      child:
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Text('Printer'),
        Obx(() => GestureDetector(
              onTap: () {
                Get.find<TransTypeController>().vehicleTrantypes[0].Checked ==
                        true
                    ? false
                    : true;
              },
              child: CheckboxListTile(
                title: Text("Test"),
                tristate: true,
                checkColor: Colors.black,
                activeColor: Colors.red,
                value: Get.find<TransTypeController>()
                        .vehicleTrantypes[0]
                        .Checked ??
                    false, // Get.find<BluetoothController>().connected.value,
                onChanged: (bool? value) {},
              ),
            ))
      ]),
    );
  }
}
