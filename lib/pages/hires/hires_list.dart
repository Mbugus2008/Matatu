import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/models/Hires.dart';
import 'package:t_matatu/models/enums.dart';
 


import 'package:t_matatu/pages/hires/addhire.dart';
import 'package:t_matatu/components/shimmer_loading.dart';
import 'package:t_matatu/utils/snackbar_service.dart';

class HiresListScreen extends StatelessWidget {
 
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;

  HiresListScreen() {
    fetchHires();
  }

  Future<void> fetchHires() async {
    try {
      hasError.value = false;
      isLoading.value = true;
      await Hires().getthires();
      // Assuming getthires updates a global or singleton list of Hires
      // Replace with actual data fetching logic
    } catch (e) {
      hasError.value = true;
      SnackbarService.showError('Failed to load hires: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiresController = Get.put(HiresController());
    return Scaffold(
      body: Obx(() {
        if (isLoading.value) return ShimmerLoading();
        if (hasError.value) return _buildErrorState();
        return _buildHiresList(hiresController);
      }),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => Get.to(() => AddHireScreen(hire: Hires())),
      ),
    );
  }

  Widget _buildHiresList(HiresController hiresController) {
    return hiresController.hires.isEmpty
          ? Center(child: CircularProgressIndicator())
          : SizedBox(
              width: MediaQuery.of(Get.context!).size.width,
              child: ListView.builder(
              itemCount: hiresController.hires.length,
              itemBuilder: (context, index) {
                final hire = hiresController.hires[index];
              
                return InkWell(
                  onTap: () {
                    Get.to(() =>  AddHireScreen(hire: hire));
                  },
                  child: Card(
                  color:(hire.Key != null) ? Colors.white : Colors.grey[300],
                  elevation: 3,
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         Expanded(
                          flex: 1,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text( '', style: TextStyle(fontWeight: FontWeight.bold)),
                               Transform.rotate(angle: 1.5708, child: Icon(Icons.linear_scale_sharp)),
                                ],
                              )),
                             
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 16,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            
                              Expanded(
                                flex: 2,
                               
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(hire.Fleet_No != null ? '${hire.Fleet_No} - ${hire.Vehicle_No}' : hire.Vehicle_No ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(DateFormat('dd-MMM-yyyy HH:mm:ss').format(DateTime(hire.Start_Date!.year, 
                                      hire.Start_Date!.month, hire.Start_Date!.day, hire.Start_Time!.hour, hire.Start_Time!.minute, 
                                      hire.Start_Time!.second)), style: TextStyle(fontSize: 12,)),
                                    
                                      Text(hire.Return_Date != null ? DateFormat('dd-MMM-yyyy HH:mm:ss')
                                      .format(DateTime(hire.Return_Date!.year, hire.Return_Date!.month, 
                                      hire.Return_Date!.day, hire.Return_Time!.hour, hire.Return_Time!.minute, hire.Return_Time!.second)) : ''
                                      , style: TextStyle(fontSize: 12,)),
                                    ],
                                  ),
                               
                              ),
                              Expanded(
                                child:
                               Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [ 
                                    Text(
                                      hire_type_desc.desc.values.elementAt(hire.Hire_Type?.index ?? 0), 
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      client_desc.desc.values.elementAt(hire.Client?.index ?? 0), 
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [ 
                                    Text(hire.Amount != null ? NumberFormat.simpleCurrency(name: "KES").format(hire.Amount) : '0.00'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
              },
              ))  ;
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          SizedBox(height: 16),
          Text('Failed to load hires', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          ElevatedButton(
            child: Text('Retry'),
            onPressed: fetchHires,
          ),
        ],
      ),
    );
  }
}