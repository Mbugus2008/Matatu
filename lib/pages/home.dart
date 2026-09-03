import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/main.dart';
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
          ? Get.find<MainController>().CurrentClient?.value.appBar()
          : null,
      body: (controller.isLoading.value == true)
          ? Center(child: CircularProgressIndicator())
          : Get.find<MainController>().CurrentClient?.value.homelist() ??
              Container(),
      drawer: CustomDrawer(),
      floatingActionButton: (controller.agent.value.Account_type == 3 ||
              controller.agent.value.Account_type == 6)
          ? null
          : Container(
              alignment: Alignment.bottomCenter,
              child: _buildAnimatedAddReceiptButton(),
            ),
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
