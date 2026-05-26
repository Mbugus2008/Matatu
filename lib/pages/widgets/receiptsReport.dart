import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';
import 'package:t_matatu/controllers/header.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/providers/colors.dart';
import 'package:t_matatu/reports/controller.dart';

class receiptReport extends StatelessWidget {
  const receiptReport({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Expanded(
        child: Get.find<ReportController>().daystrans.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 7,
                    child: ListView.builder(
                        itemCount:
                            Get.find<ReportController>().daystrans.length,
                        itemBuilder: (BuildContext context, int index) {
                          bool reversed = Get.find<ReportController>()
                                  .daystrans[index]
                                  .Reversed ??
                              false;
                          bool reversal = Get.find<ReportController>()
                                  .daystrans[index]
                                  .Reversal ??
                              false;
                          final bool isPendingReversal =
                              reversal == true && reversed == false;
                          final bool isReversed = reversed == true;
                          String vehicle = Get.find<ReportController>()
                                  .daystrans[index]
                                  .Fleet ??
                              '';
                          if (vehicle.isEmpty) {
                            vehicle = Get.find<ReportController>()
                                    .daystrans[index]
                                    .Vehicle ??
                                '';
                          }
                          if (vehicle.isEmpty) {
                            vehicle = Get.find<ReportController>()
                                    .daystrans[index]
                                    .Account ??
                                '';
                          }

                          return Card(
                            elevation: 20,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  12), // Adjust the border radius
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 88, 122, 150),
                                  width: 2), // Border color and width
                            ),
                            child: ExpansionTile(
                                tilePadding: const EdgeInsets.only(left: 2),
                                leading: (!isReversed && !isPendingReversal)
                                    ? SizedBox(
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.print_sharp,
                                            color: AppColors.primaryColor,
                                          ),
                                          onPressed: () async {
                                            List<int>? bytes = await Get.find<
                                                    MainController>()
                                                .CurrentClient
                                                ?.value
                                                .printReceipt(
                                                    Get.find<ReportController>()
                                                        .daystrans[index]);
                                            if (bytes != null)
                                              Get.find<BluetoothManager>()
                                                  .printReceip(bytes);
                                          },
                                        ),
                                      )
                                    : null,
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      Get.find<ReportController>()
                                          .daystrans[index]
                                          .Receipt_No
                                          .toString(),
                                      style: isReversed
                                          ? const TextStyle(
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: Colors.red,
                                              decorationThickness: 2.0,
                                            )
                                          : TextStyle(
                                              fontSize: 12,
                                              color: isPendingReversal
                                                  ? Colors.orange[800]
                                                  : null,
                                              fontWeight: isPendingReversal
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                            ),
                                    ),
                                    Text(NumberFormat("#,##0.00", "en_US")
                                        .format(Get.find<ReportController>()
                                            .daystrans[index]
                                            .Total_Amount)),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(vehicle,
                                        style: const TextStyle(fontSize: 12)),
                                    Text(
                                        Get.find<ReportController>()
                                                .daystrans[index]
                                                .Agent ??
                                            '',
                                        style: const TextStyle(fontSize: 10)),
                                    Text(
                                        formattedTime.format(
                                            DateTime.fromMicrosecondsSinceEpoch(
                                                int.tryParse(Get.find<
                                                            ReportController>()
                                                        .daystrans[index]
                                                        .Receipt_No
                                                        .toString()) ??
                                                    0)),
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                children: <Widget>[
                                  SizedBox(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Flexible(
                                          flex: 7,
                                          child:
                                              Get.find<ReportController>()
                                                          .daystrans[index]
                                                          .transtions !=
                                                      null
                                                  ? Container(
                                                      width:
                                                          double.infinity - 100,
                                                      height: 50,
                                                      margin:
                                                          const EdgeInsets.only(
                                                              left: 20,
                                                              right: 0),
                                                      child: ListView.builder(
                                                          itemCount: Get.find<
                                                                  ReportController>()
                                                              .daystrans[index]
                                                              .transtions
                                                              ?.length,
                                                          itemBuilder:
                                                              (BuildContext
                                                                      context,
                                                                  int i) {
                                                            return Container(
                                                              decoration:
                                                                  const BoxDecoration(
                                                                border: Border(
                                                                    bottom:
                                                                        BorderSide(
                                                                  color: Colors
                                                                      .black, // Border color
                                                                  width:
                                                                      1, // Border width
                                                                )),
                                                              ),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Get.find<ReportController>()
                                                                              .daystrans[
                                                                                  index]
                                                                              .transtions?[
                                                                                  i]
                                                                              .Type ==
                                                                          "SAVINGSCREW"
                                                                      ? Text(
                                                                          '${Get.find<ReportController>().daystrans[index].transtions?[i].Description}(${Get.find<ReportController>().daystrans[index].transtions?[i].Account_No})',
                                                                          style: const TextStyle(
                                                                              fontSize:
                                                                                  12))
                                                                      : Text(
                                                                          Get.find<ReportController>()
                                                                              .daystrans[index]
                                                                              .transtions![i]
                                                                              .Description
                                                                              .toString(),
                                                                          style: const TextStyle(fontSize: 12)),
                                                                  Text(
                                                                    NumberFormat("#,##0.00", "en_US").format(Get.find<
                                                                            ReportController>()
                                                                        .daystrans[
                                                                            index]
                                                                        .transtions?[
                                                                            i]
                                                                        .Amount),
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            15),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          }),
                                                    )
                                                  : const Text(
                                                      "No transactions"),
                                        ),
                                        Flexible(
                                            flex: 1,
                                            child: (!isReversed &&
                                                    !isPendingReversal &&
                                                    (Get.find<ReportController>()
                                                                .daystrans[
                                                                    index]
                                                                .transtions ==
                                                            null ||
                                                        Get.find<
                                                                ReportController>()
                                                            .daystrans[index]
                                                            .transtions!
                                                            .isNotEmpty))
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.cancel,
                                                      color: Colors.red,
                                                      size: 30,
                                                    ),
                                                    onPressed: () {
                                                      Get.find<
                                                              HeaderController>()
                                                          .reverse(Get.find<
                                                                  ReportController>()
                                                              .daystrans[index]);
                                                    },
                                                  )
                                                : _buildReversalStatusBadge(
                                                    isPendingReversal:
                                                        isPendingReversal,
                                                    isReversed: isReversed,
                                                  ))
                                      ],
                                    ),
                                  ),
                                ]),
                          );
                        }),
                  ),
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 20,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            12), // Adjust the border radius
                        side: const BorderSide(
                            color: Color.fromARGB(255, 88, 122, 150),
                            width: 2), // Border color and width
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Totals"),
                          Text(
                            NumberFormat("#,##0.00", "en_US").format(
                                Get.find<ReportController>().daystrans.fold<
                                        double>(
                                    0.0,
                                    (double currentSum, Header item) =>
                                        currentSum +
                                        num.tryParse(
                                            item.Total_Amount.toString())!)),
                            style: const TextStyle(fontSize: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Center(child: loading())));
  }

  Widget loading() {
    return Get.find<ReportController>().searching == true
        ? CircularProgressIndicator()
        : Text("No Transactions");
  }

  Widget _buildReversalStatusBadge({
    required bool isPendingReversal,
    required bool isReversed,
  }) {
    if (isPendingReversal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha((255 * 0.12).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange),
        ),
        child: const Text(
          'Pending',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.orange,
          ),
        ),
      );
    }

    if (isReversed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha((255 * 0.12).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green),
        ),
        child: const Text(
          'Reversed',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget tlist(List<tmatatu.Trans>? t) {
    return t != null
        ? Container(
            width: double.infinity - 100,
            height: 50,
            margin: const EdgeInsets.only(left: 20, right: 0),
            child: ListView.builder(
                itemCount: t.length,
                itemBuilder: (BuildContext context, int i) {
                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(
                        color: Colors.black, // Border color
                        width: 1, // Border width
                      )),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        t[i].Type == "SAVINGSCREW"
                            ? Text('${t[i].Description}(${t[i].Account_No})',
                                style: const TextStyle(fontSize: 12))
                            : Text(t[i].Description.toString(),
                                style: const TextStyle(fontSize: 12)),
                        Text(
                          NumberFormat("#,##0.00", "en_US").format(t[i].Amount),
                          style: const TextStyle(fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }),
          )
        : const Text("No transactions");
  }
}
