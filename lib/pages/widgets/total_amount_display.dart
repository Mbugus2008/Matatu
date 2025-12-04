import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/header.dart';

class TotalAmountDisplay extends StatelessWidget {
  const TotalAmountDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    

        
 return Obx((){ 
  final controller = Get.find<HeaderController>();
      final total = controller.currTrans.fold<double>(
          0.0, (sum, item) => sum + (item.Amount ?? 0));
  return Container(
          color: Colors.lightGreen.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Total', 
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                NumberFormat("#,##0.00").format(total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        );
  });
  }
}
