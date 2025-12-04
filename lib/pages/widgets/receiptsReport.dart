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
  const receiptReport({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportController>();

    return Obx(() => Expanded(
        child: ctrl.daystrans.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 7,
                    child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: ctrl.daystrans.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = ctrl.daystrans[index];

                          bool reversed = item.Reversed ?? false;
                          bool reversal = item.Reversal ?? false;

                          String vehicle = item.Fleet ?? '';
                          if (vehicle.isEmpty) vehicle = item.Vehicle ?? '';
                          if (vehicle.isEmpty) vehicle = item.Account ?? '';

                          final sentVal = item.sent;
                          final bool isSent = sentVal == true ||
                              sentVal == 1 ||
                              (sentVal?.toString().toLowerCase() == 'true') ||
                              (sentVal?.toString() == '1');

                          return Card(
                            elevation: 20,
                            color: isSent ? Colors.green[100] : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 88, 122, 150),
                                  width: 2),
                            ),
                            child: ExpansionTile(
                                tilePadding: const EdgeInsets.only(left: 2),
                                leading: (reversed == false &&
                                        reversal == false)
                                    ? SizedBox(
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.print_sharp,
                                            color: AppColors.primaryColor,
                                          ),
                                          onPressed: () async {
                                            List<int>? bytes =
                                                await Get.find<MainController>()
                                                    .CurrentClient
                                                    ?.value
                                                    .printReceipt(item);
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
                                      item.Receipt_No.toString(),
                                      style: (reversed == false &&
                                              reversal == false)
                                          ? const TextStyle(fontSize: 12)
                                          : const TextStyle(
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: Colors.red,
                                              decorationThickness: 2.0,
                                            ),
                                    ),
                                    Text(NumberFormat("#,##0.00", "en_US")
                                        .format(item.Total_Amount ?? 0)),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(vehicle,
                                        style: const TextStyle(fontSize: 12)),
                                    Text(item.Agent ?? '',
                                        style: const TextStyle(fontSize: 10)),
                                    Text(
                                        formattedTime.format(
                                            DateTime.fromMicrosecondsSinceEpoch(
                                                int.tryParse(item.Receipt_No
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
                                          child: item.transtions != null
                                              ? Container(
                                                  width: double.infinity - 100,
                                                  height: 50,
                                                  margin: const EdgeInsets.only(
                                                      left: 20, right: 0),
                                                  child: ListView.builder(
                                                      itemCount: item
                                                          .transtions?.length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int i) {
                                                        final tx =
                                                            item.transtions?[i];
                                                        return Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                            border: Border(
                                                                bottom: BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: 1)),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              tx?.Type ==
                                                                      "SAVINGSCREW"
                                                                  ? Text(
                                                                      '${tx?.Description}(${tx?.Account_No})',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              12))
                                                                  : Text(
                                                                      tx?.Description
                                                                              .toString() ??
                                                                          '',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              12)),
                                                              Text(
                                                                  NumberFormat(
                                                                          "#,##0.00",
                                                                          "en_US")
                                                                      .format(
                                                                          tx?.Amount ??
                                                                              0),
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          15)),
                                                            ],
                                                          ),
                                                        );
                                                      }),
                                                )
                                              : const Text("No transactions"),
                                        ),
                                        Flexible(
                                            flex: 1,
                                            child: (reversal == false &&
                                                    reversed == false &&
                                                    (item.transtions == null ||
                                                        item.transtions!
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
                                                          .reverse(item);
                                                    },
                                                  )
                                                : const SizedBox())
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
                                ctrl.daystrans.fold<double>(
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
        ? const CircularProgressIndicator()
        : const Text("No Transactions");
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
                          bottom: BorderSide(color: Colors.black, width: 1)),
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
                            NumberFormat("#,##0.00", "en_US")
                                .format(t[i].Amount),
                            style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  );
                }),
          )
        : const Text("No transactions");
  }
}

class receiptReporttoday extends StatelessWidget {
  const receiptReporttoday({super.key});
  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ReportController>();
    return Obx(() => Expanded(
        child: ctrl.daystranstoday.isNotEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    flex: 7,
                    child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: ctrl.daystranstoday.length,
                        itemBuilder: (BuildContext context, int index) {
                          final item = ctrl.daystranstoday[index];
                          bool reversed = item.Reversed ?? false;
                          bool reversal = item.Reversal ?? false;

                          String vehicle = item.Fleet ?? '';
                          if (vehicle.isEmpty) vehicle = item.Vehicle ?? '';
                          if (vehicle.isEmpty) vehicle = item.Account ?? '';

                          final sentVal = item.sent;
                          final bool isSent = sentVal == true ||
                              sentVal == 1 ||
                              (sentVal?.toString().toLowerCase() == 'true') ||
                              (sentVal?.toString() == '1');

                          return Card(
                            elevation: 20,
                            color: isSent ? Colors.green[100] : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                  color: Color.fromARGB(255, 88, 122, 150),
                                  width: 2),
                            ),
                            child: ExpansionTile(
                                tilePadding: const EdgeInsets.only(left: 2),
                                leading: (reversed == false &&
                                        reversal == false)
                                    ? SizedBox(
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.print_sharp,
                                            color: AppColors.primaryColor,
                                          ),
                                          onPressed: () async {
                                            List<int>? bytes =
                                                await Get.find<MainController>()
                                                    .CurrentClient
                                                    ?.value
                                                    .printReceipt(item);
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
                                      item.Receipt_No.toString(),
                                      style: (reversed == false &&
                                              reversal == false)
                                          ? const TextStyle(fontSize: 12)
                                          : const TextStyle(
                                              fontSize: 12,
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationColor: Colors.red,
                                              decorationThickness: 2.0,
                                            ),
                                    ),
                                    Text(NumberFormat("#,##0.00", "en_US")
                                        .format(item.Total_Amount ?? 0)),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(vehicle,
                                        style: const TextStyle(fontSize: 12)),
                                    Text(item.Agent ?? '',
                                        style: const TextStyle(fontSize: 10)),
                                    Text(
                                        formattedTime.format(
                                            DateTime.fromMicrosecondsSinceEpoch(
                                                int.tryParse(item.Receipt_No
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
                                          child: item.transtions != null
                                              ? Container(
                                                  width: double.infinity - 100,
                                                  height: 50,
                                                  margin: const EdgeInsets.only(
                                                      left: 20, right: 0),
                                                  child: ListView.builder(
                                                      itemCount: item
                                                          .transtions?.length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int i) {
                                                        final tx =
                                                            item.transtions?[i];
                                                        return Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                            border: Border(
                                                                bottom: BorderSide(
                                                                    color: Colors
                                                                        .black,
                                                                    width: 1)),
                                                          ),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              tx?.Type ==
                                                                      "SAVINGSCREW"
                                                                  ? Text(
                                                                      '${tx?.Description}(${tx?.Account_No})',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              12))
                                                                  : Text(
                                                                      tx?.Description
                                                                              .toString() ??
                                                                          '',
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              12)),
                                                              Text(
                                                                  NumberFormat(
                                                                          "#,##0.00",
                                                                          "en_US")
                                                                      .format(
                                                                          tx?.Amount ??
                                                                              0),
                                                                  style: const TextStyle(
                                                                      fontSize:
                                                                          15)),
                                                            ],
                                                          ),
                                                        );
                                                      }),
                                                )
                                              : const Text("No transactions"),
                                        ),
                                        Flexible(
                                            flex: 1,
                                            child: (reversal == false &&
                                                    reversed == false &&
                                                    (item.transtions == null ||
                                                        item.transtions!
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
                                                          .reverse(item);
                                                    },
                                                  )
                                                : const SizedBox())
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
                                ctrl.daystrans.fold<double>(
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
        ? const CircularProgressIndicator()
        : const Text("No Transactions");
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
                          bottom: BorderSide(color: Colors.black, width: 1)),
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
                            NumberFormat("#,##0.00", "en_US")
                                .format(t[i].Amount),
                            style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  );
                }),
          )
        : const Text("No transactions");
  }
}
