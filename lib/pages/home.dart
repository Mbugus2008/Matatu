import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/pages/TwoTabScreen.dart';
import 'package:t_matatu/pages/optimized_receipt.dart';
import 'package:t_matatu/pages/setting.dart';

class HomePage extends GetView<MainController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final homeList = Get.find<MainController>().CurrentClient?.value.homelist();
    return Scaffold(
      appBar: (homeList is! TwoTabScreen)
          ? AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(Get.find<MainController>()
                          .CurrentClient
                          ?.value
                          .clientName ??
                      ''),
                  Text(
                    'Balance: ${NumberFormat('#,##0.00', 'en_US').format(Get.find<MainController>().agent.value.Account_Balance ?? 0)}', // Customize this text
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold, // Smaller than main title
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    upload();
                    Get.to(() => Receipt());
                  },
                  icon: Icon(Icons.add),
                  iconSize: 50,
                  color: Colors.blue,
                )
              ],
            )
          : null,
      body: (controller.isLoading.value == true)
          ? Center(child: CircularProgressIndicator())
          : Get.find<MainController>().CurrentClient?.value.homelist() ??
              Container(),

      drawer: CustomDrawer(),
      // floatingActionButton: Container(
      //   alignment:  Alignment.topCenter,
      //   child: _buildAnimatedAddReceiptButton(),
      // ),
    );
  }

  Widget _buildAnimatedAddReceiptButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        Get.find<MainController>().vehsummary.clear();
        Get.find<MemberController>().currentcrew.clear();
        Get.to(() => Receipt());
      },
      icon: Icon(Icons.add),
      label: Text('New Receipt'),
      backgroundColor: Colors.blue,
      elevation: 4.0,
    );
  }
}
