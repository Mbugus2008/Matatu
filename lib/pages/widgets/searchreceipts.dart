import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/reports/controller.dart';

class searchReceipt extends StatelessWidget {
  const searchReceipt({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: (input) {
        final reportController = Get.find<ReportController>();

        final query = input.trim().toUpperCase();

        if (query.isEmpty) {
          // Reset to original list
          reportController.daystrans.value = reportController.daystrans1;
          return;
        }

        reportController.daystrans.value =
            reportController.daystrans1.where((item) {
          return item.toString().toUpperCase().contains(query);
        }).toList();
      },
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.search_off,
            color: Colors.blue,
          ),
          floatingLabelAlignment: FloatingLabelAlignment.center,
          labelText: 'Find receipt',
          labelStyle: TextStyle(fontSize: 14)),
    );
  }
}

class searchReceiptToday extends StatelessWidget {
  const searchReceiptToday({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: (input) {
        final reportController = Get.find<ReportController>();

        final query = input.trim().toUpperCase();

        if (query.isEmpty) {
          // Reset to original list
          reportController.daystranstoday.value =
              reportController.daystranstoday1;
          return;
        }

        reportController.daystranstoday.value =
            reportController.daystranstoday1.where((item) {
          return item.toString().toUpperCase().contains(query);
        }).toList();
      },
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
          prefixIcon: Icon(
            Icons.search_off,
            color: Colors.blue,
          ),
          floatingLabelAlignment: FloatingLabelAlignment.center,
          labelText: 'Find receipt',
          labelStyle: TextStyle(fontSize: 14)),
    );
  }
}
