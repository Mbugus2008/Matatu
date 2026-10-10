import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/main.dart';

/// The per-vehicle collections list (today's figures per vehicle) — the
/// default home list for normal users, also opened from the drawer's
/// "Vehicle Collections" tile. The day summary at the bottom is left off
/// here; it belongs to the home screen.
class VehicleCollectionsView extends StatelessWidget {
  const VehicleCollectionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final list = Get.find<MainController>()
        .CurrentClient
        ?.value
        .vehicleCollectionsList(showSummary: false);
    return list ??
        const Center(
          child: Text('Vehicle collections are not available for this client'),
        );
  }
}
