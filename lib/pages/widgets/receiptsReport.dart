
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/header.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/Header.dart';
import 'package:t_matatu/models/Transaction.dart' as tmatatu;
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/bluetooth/bluetoothManager.dart';
import 'package:t_matatu/providers/colors.dart';
import 'package:t_matatu/reports/controller.dart';


class receiptReport extends StatelessWidget {
  const receiptReport({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(()=>  Expanded(
                    child: Get.find<ReportController>().daystrans.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                flex: 7,
                                child: ListView.builder(
                                    itemCount: Get.find<ReportController>()
                                        .daystrans
                                        .length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      bool reversed =
                                          Get.find<ReportController>()
                                                  .daystrans[index]
                                                  .Reversed ??
                                              false;
                                      bool reversal =
                                          Get.find<ReportController>()
                                                  .daystrans[index]
                                                  .Reversal ??
                                              false;
String vehicle = Get.find<ReportController>().daystrans[index]
                                                  .Fleet ?? '';
if (vehicle.isEmpty) {
vehicle = Get.find<ReportController>().daystrans[index]
                                                  .Vehicle ?? '';
}
if (vehicle.isEmpty) {
vehicle = Get.find<ReportController>().daystrans[index]
                                                  .Account ?? '';
}

                                      return Card(
                                        elevation: 20,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              12), // Adjust the border radius
                                          side: const BorderSide(
                                              color: Color.fromARGB(
                                                  255, 88, 122, 150),
                                              width:
                                                  2), // Border color and width
                                        ),
                                        child: ExpansionTile(
                                            tilePadding:
                                                const EdgeInsets.only(
                                                    left: 2),
                                            leading: (reversed == false &&
                                                    reversal == false)
                                                ? SizedBox(
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Icons.print_sharp,
                                                        color: AppColors
                                                            .primaryColor,
                                                      ),
                                                      onPressed: () async {
                                                        List<int>? bytes = await Get.find<MainController>().CurrentClient?.value.printReceipt(Get
                                                            .find<
                                                            ReportController>()
                                                            .daystrans[index]);
                                                        if (bytes != null)
                                                          Get.find<BluetoothManager>().printReceip( bytes);


                                                      },
                                                    ),
                                                  )
                                                : null,
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  Get.find<ReportController>()
                                                      .daystrans[index]
                                                      .Receipt_No
                                                      .toString(),
                                                  style: (reversed == false &&
                                                          reversal == false)
                                                      ? const TextStyle(
                                                          fontSize: 12,
                                                        )
                                                      : const TextStyle(
                                                          fontSize: 12,
                                                          decoration:
                                                              TextDecoration
                                                                  .lineThrough,
                                                          decorationColor:
                                                              Colors.red,
                                                          decorationThickness:
                                                              2.0,
                                                        ),
                                                ),
                                                Text(NumberFormat(
                                                        "#,##0.00", "en_US")
                                                    .format(Get.find<
                                                            ReportController>()
                                                        .daystrans[index]
                                                        .Total_Amount)),
                                              ],
                                            ),
                                            subtitle: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                    vehicle,
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                                Text(
                                                    Get.find<ReportController>()
                                                            .daystrans[index]
                                                            .Agent ??
                                                        '',
                                                    style: const TextStyle(
                                                        fontSize: 10)),
                                                Text(
                                                    formattedTime.format(DateTime
                                                        .fromMicrosecondsSinceEpoch(
                                                            int.tryParse(Get.find<
                                                                        ReportController>()
                                                                    .daystrans[
                                                                        index]
                                                                    .Receipt_No
                                                                    .toString()) ??
                                                                0)),
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                              ],
                                            ),
                                            children: <Widget>[
                                              SizedBox(
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Flexible(
                                                      flex: 7,
                                                      child: Get.find<ReportController>()
                                                                  .daystrans[
                                                                      index]
                                                                  .transtions !=
                                                              null
                                                          ? Container(
                                                              width: double
                                                                      .infinity -
                                                                  100,
                                                              height: 50,
                                                              margin:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      left:
                                                                          20,
                                                                      right:
                                                                          0),
                                                              child: ListView
                                                                  .builder(
                                                                      itemCount: Get.find<ReportController>()
                                                                          .daystrans[
                                                                              index]
                                                                          .transtions
                                                                          ?.length,
                                                                      itemBuilder:
                                                                          (BuildContext context,
                                                                              int i) {
                                                                        return Container(
                                                                          decoration:
                                                                              const BoxDecoration(
                                                                            border: Border(
                                                                                bottom: BorderSide(
                                                                              color: Colors.black, // Border color
                                                                              width: 1, // Border width
                                                                            )),
                                                                          ),
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                            children: [
                                                                              Get.find<ReportController>().daystrans[index].transtions?[i].Type == "SAVINGSCREW" ? Text('${Get.find<ReportController>().daystrans[index].transtions?[i].Description}(${Get.find<ReportController>().daystrans[index].transtions?[i].Account_No})', style: const TextStyle(fontSize: 12)) : Text(Get.find<ReportController>().daystrans[index].transtions![i].Description.toString(), style: const TextStyle(fontSize: 12)),
                                                                              Text(
                                                                                NumberFormat("#,##0.00", "en_US").format(Get.find<ReportController>().daystrans[index].transtions?[i].Amount),
                                                                                style: const TextStyle(fontSize: 15),
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
                                                        child: (reversed ==
                                                                    false &&
                                                                (Get.find<ReportController>()
                                                                            .daystrans[
                                                                                index]
                                                                            .transtions ==
                                                                        null ||
                                                                    Get.find<
                                                                            ReportController>()
                                                                        .daystrans[
                                                                            index]
                                                                        .transtions!
                                                                        .isNotEmpty))
                                                            ? IconButton(
                                                                icon:
                                                                    const Icon(
                                                                  Icons
                                                                      .cancel,
                                                                  color: Colors
                                                                      .red,
                                                                  size: 30,
                                                                ),
                                                                onPressed:
                                                                    () {
                                                                  Get.find<
                                                                          HeaderController>()
                                                                      .reverse(
                                                                          Get.find<ReportController>().daystrans[index]);
                                                                },
                                                              )
                                                            : const CircularProgressIndicator())
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
                                        color:
                                            Color.fromARGB(255, 88, 122, 150),
                                        width: 2), // Border color and width
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("Totals"),
                                      Text(
                                        NumberFormat("#,##0.00", "en_US")
                                            .format(Get.find<
                                                    ReportController>()
                                                .daystrans
                                                .fold<double>(
                                                    0.0,
                                                    (double currentSum,
                                                            Header item) =>
                                                        currentSum +
                                                        num.tryParse(item
                                                                .Total_Amount
                                                            .toString())!)),
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(child: loading())
    ));
  }
   Widget loading() {
    return Get.find<ReportController>().searching == true
        ? CircularProgressIndicator()
        : Text("No Transactions");
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
  }}