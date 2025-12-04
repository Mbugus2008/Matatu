import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/pages/widgets/receiptsReport.dart';
import 'package:t_matatu/pages/widgets/searchreceipts.dart';
import 'package:t_matatu/reports/controller.dart';

import '../models/Header.dart';
import '../models/Utils/util.dart';

class ReceiptReport extends StatelessWidget {
  const ReceiptReport({super.key});

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate:
          Get.find<ReportController>().selectedDate?.value?.toLocal() ??
              DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    Get.find<ReportController>().searching.value = true;
    Get.find<ReportController>().selectedDate!.value = picked;
    await Get.find<ReportController>().gettransbydate(picked);
    Get.find<ReportController>().searching.value = false;
    // Get.find<ReportController>().daystrans.forEach((element) {
    //   print(element.toString());
    //   element.transtions?.forEach((element) {
    //     print(element.toString());
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    List<Header> list = Get.find<ReportController>().daystrans;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Receipts"),
          centerTitle: true,
          // actions: [const printer()],
        ),
        body: Center(
          child: Obx(() => Column(
                children: [
                  ElevatedButton(
                    onPressed: _selectDate,
                    child: Text(formattedDate.format(
                        Get.find<ReportController>().selectedDate == null
                            ? DateTime.now()
                            : Get.find<ReportController>()
                                .selectedDate!
                                .value
                                .toLocal())),
                  ),
                  searchReceipt(),
                  receiptReport(),
                ],
              )),
        ),
      ),
    );
  }
}
