import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/summary/Tsummary.dart';
import 'package:t_matatu/models/summary/TsummaryDetails.dart';
import 'package:t_matatu/reports/controller.dart';

import '../bluetooth/bluetooth.dart';
import '../controllers/main.dart';
import '../models/Utils/util.dart';
import '../bluetooth/bluetoothManager.dart';

class SummaryReport extends StatelessWidget {
  const SummaryReport({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Daily Summary"),
          centerTitle: true,
          // actions: [const printer()],
        ),
        body: GetBuilder<ReportController>(builder: (controller) {
          return Center(
            child: Column(
              children: [
                TextFormField(
                  onChanged: (value) {
                    value = value.toUpperCase();
                    controller.tsummary.where((item) {
                      return (item.toString().contains(value) == true);
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
                ),
                Expanded(
                    child: controller.tsummary.isNotEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                flex: 7,
                                child: ListView.builder(
                                    itemCount: controller.tsummary.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
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
                                            childrenPadding:
                                                EdgeInsets.only(right: 8),
                                            onExpansionChanged:
                                                (value) async {},
                                            leading: IconButton(
                                              icon:
                                                  const Icon(Icons.print_sharp),
                                              onPressed: () async {
                                                List<int>? bytes = await Get.find<MainController>().CurrentClient?.value.getZreport(controller
                                                    .tsummary[index]);
                                                if (bytes != null)
                                                  Get.find<BluetoothManager>().printReceip( bytes);



                                              },
                                            ),
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  formattedDate2.format(
                                                      controller.tsummary[index]
                                                          .Date ??  DateTime(2024)),
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                                Text(NumberFormat(
                                                        "#,##0.00", "en_US")
                                                    .format(controller
                                                        .tsummary[index]
                                                        .Total)),
                                              ],
                                            ),
                                            subtitle: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                    '${controller.tsummary[index].No_Of_Veh} Vehicle(s)',
                                                    style: const TextStyle(
                                                        fontSize: 12)),
                                                Text(
                                                    controller.tsummary[index]
                                                            .Agent ??
                                                        '',
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
                                                      child: tlist(controller
                                                          .tsummary[index]
                                                          .trans!),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ]),
                                      );
                                    }),
                              ),
                              // Expanded(
                              //   flex: 1,
                              //   child: Card(
                              //     elevation: 20,
                              //     shape: RoundedRectangleBorder(
                              //       borderRadius: BorderRadius.circular(
                              //           12), // Adjust the border radius
                              //       side: const BorderSide(
                              //           color:
                              //               Color.fromARGB(255, 88, 122, 150),
                              //           width: 2), // Border color and width
                              //     ),
                              //     child: Row(
                              //       mainAxisAlignment:
                              //           MainAxisAlignment.spaceBetween,
                              //       children: [
                              //         const Text("Totals"),
                              //         Text(
                              //           NumberFormat("#,##0.00", "en_US")
                              //               .format(controller.tsummary
                              //                   .fold<double>(
                              //                       0.0,
                              //                       (double currentSum,
                              //                               Tsummary item) =>
                              //                           currentSum +
                              //                           num.tryParse(item.Total
                              //                               .toString())!)),
                              //           style: const TextStyle(fontSize: 20),
                              //         ),
                              //       ],
                              //     ),
                              //   ),
                              // ),
                            ],
                          )
                        : const Center(
                            child: Text('No Transations today'),
                          )),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget tlist(List<TsummaryDetails> t) {
    return t.isNotEmpty
        ? Container(
            width: double.infinity - 100,
            height: 100,
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
                        Text(t[i].Description.toString(),
                            style: const TextStyle(fontSize: 12)),
                        Text(
                          NumberFormat("#,##0.00", "en_US").format(t[i].Total),
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
