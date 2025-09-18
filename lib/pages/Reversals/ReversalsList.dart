import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/Reversal.dart';

import '../../providers/db.dart';

class ReversalListScreen extends StatelessWidget {
  final List<Reversal> reversal;

  ReversalListScreen({required this.reversal});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reversals'),
        centerTitle: true ,
      ),
      body: Obx(
        () {
          final List<Reversal> reversals = Get.find<ReversalController>().reversals.value;
          return RefreshIndicator(
            color: Colors.blue, // Customize color of refresh indicator
            backgroundColor: Colors.white, // Customize background color
            onRefresh: Get.find<ReversalController>().refreshData,
            child: ListView.builder(
            itemCount: reversals.length,
            itemBuilder: (context, index) {
              final reversal = reversals[index];
              return Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                      12), // Adjust the border radius
                  side:  BorderSide(
                      color: getTileColor(reversal.Status),
                      width:
                      2), // Border color and width
                ),
                child: ListTile(
                  horizontalTitleGap: 0,
                  contentPadding:EdgeInsets.zero,
                  minLeadingWidth: 0,
                  minTileHeight: 0,
                  minVerticalPadding: 0,
                  //tileColor: getTileColor(reversal.Status),
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${reversal.Receipt_No ?? 'No Receipt'}(${reversal.Total_Trans})'),
                      Text(DateFormat('dd-MMM-yy').format(reversal.Transction_Date!) ?? ''),
                    ],
                  ),
                  titleAlignment: ListTileTitleAlignment.center,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Spacer(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(reversal.Vehicle ?? '0.00',style: TextStyle(fontSize: 12 ),),
                          Text(reversal.Total_Amount?.toStringAsFixed(2) ?? '0.00'),
                        ],
                      ),
                      Spacer(),Text('${reversal.Status!.description}'),
                    ],
                  ),
                  // subtitle:
                  //     Text(reversal.Total_Amount?.toStringAsFixed(2) ?? '0.00'),
                  onTap: () {
                    // Navigate to edit form with selected reversal
                  },
                  trailing: (reversal.Status == STatus.Open ) ? PopupMenuButton<String>(
                        onSelected: (String value) {
                          // Handle the selection
                          print(reversal.Status!.description);
                          reversal.Status = STatus.Rejected;
                          reversal.Sent = false ;
                           Get.find<db_Provider>().insert(Reversal.table, reversal);
                           Reversal().uploadreversal();
                        },
                        itemBuilder: (BuildContext context) {
                          return {'Cancel'}.map((String choice) {
                            return PopupMenuItem<String>(
                              value: choice,
                              child: Row(
                                children: [
                                  Icon(Icons.cancel, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Cancel'),
                                ],
                              ),
                            );
                          }).toList();
                        },
                      ):Spacer()
                  // trailing:  Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Text('${reversal.Status!.description}'),
                  //     // PopupMenuButton<String>(
                  //     //   onSelected: (String value) {
                  //     //     // Handle the selection
                  //     //     print('Selected: $value');
                  //     //   },
                  //     //   itemBuilder: (BuildContext context) {
                  //     //     return {'Option 1', 'Option 2', 'Option 3'}.map((String choice) {
                  //     //       return PopupMenuItem<String>(
                  //     //         value: choice,
                  //     //         child: Text(choice),
                  //     //       );
                  //     //     }).toList();
                  //     //   },
                  //     // ),
                  //   ],
                  // )
                ),
              );
            },
                    ),
          );
        },
      ),
    );
  }

  Color getTileColor(STatus? state) {
    switch (state) {

      case STatus.Pending_Approval:
        return Colors.blueGrey;
      case STatus.Approved:
        return Colors.grey;
      case STatus.Released:
        return Colors.green;
      case STatus.Rejected:
        return Colors.red;
      default:
        return Colors.white;
    }
  }
}
