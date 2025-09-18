import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/models/Utils/util.dart';

class MyDatePicker extends GetView {
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  Future<void> _selectDate() async {
    DateTime picked = await Get.bottomSheet(
      DatePicker(
        DateTime.now(),
        onDateChange: (DateTime date) {
          Get.back(result: date);
        },
      ),
    );
    selectedDate.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Obx(
          () => ElevatedButton(
            onPressed: _selectDate,
            child: Text(formattedDate.format(selectedDate.value.toLocal())),
          ),
        )
      ],
    );
  }
}

class DatePicker extends StatelessWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateChange;

  DatePicker(this.initialDate, {required this.onDateChange});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              Get.back();
            },
            child: Text('Close'),
          ),
          Container(
            height: 200.0,
            child: CalendarDatePicker(
              initialDate: initialDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              onDateChanged: onDateChange,
            ),
          ),
        ],
      ),
    );
  }
}
