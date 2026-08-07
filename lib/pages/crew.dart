import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:t_matatu/controllers/Members.dart';
import 'package:t_matatu/controllers/main.dart';
import 'package:t_matatu/models/member.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/pages/widgets/autoc.dart';
import 'package:t_matatu/providers/client.dart';

class CrewAssignment extends StatefulWidget {
  final Vehicles? vehicle;

  const CrewAssignment({Key? key, required this.vehicle}) : super(key: key);

  @override
  State<CrewAssignment> createState() => _CrewAssignmentState();
}

class _CrewAssignmentState extends State<CrewAssignment> {
  final TextEditingController driverController = TextEditingController();
  final TextEditingController conductorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentCrew();
  }

  void _loadCurrentCrew() {
    final v = widget.vehicle;
    if (v == null) return;
    final memberController = Get.find<MemberController>();
    memberController.getcurrentcrew(v.Vehicle_Number.toString());

    final driver = memberController.currentcrew
        .firstWhereOrNull((m) => m.Crew_Type == Crew_type.Driver);
    final conductor = memberController.currentcrew
        .firstWhereOrNull((m) => m.Crew_Type == Crew_type.Conductor);

    if (driver != null) {
      driverController.text = driver.No.toString();
      memberController.currentdriver.value = driver;
    }
    if (conductor != null) {
      conductorController.text = conductor.No.toString();
      memberController.currentcunductor.value = conductor;
    }
  }

  @override
  void dispose() {
    driverController.dispose();
    conductorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    if (v == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(child: Text('No vehicle data available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Assign Crew - ${v.Vehicle_Number}'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVehicleInfo(),
              const SizedBox(height: 24),
              _buildCrewForm(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleInfo() {
    final v = widget.vehicle!;
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vehicle Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Number: ${v.Vehicle_Number}'),
            if (v.Fleet_No != null && v.Fleet_No!.isNotEmpty)
              Text('Fleet: ${v.Fleet_No}'),
            Text(
                'Type: ${vehicle_type_desc.desc[v.Vehicle_Type] ?? 'Unknown'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCrewForm() {
    return Column(
      children: [
        if (Get.find<MainController>().CurrentClient?.value.Crew_to_attach ==
                CrewToattach.Both ||
            Get.find<MainController>().CurrentClient?.value.Crew_to_attach ==
                CrewToattach.Driver)
          CustomAutocomplete(
            textEditingController: driverController,
            crew_type: Crew_type.Driver,
            caption: "Driver",
            leadingicon: Icon(Icons.person),
          ),
        SizedBox(height: 16),
        if (Get.find<MainController>().CurrentClient?.value.Crew_to_attach ==
                CrewToattach.Both ||
            Get.find<MainController>().CurrentClient?.value.Crew_to_attach ==
                CrewToattach.Condutor)
          CustomAutocomplete(
            textEditingController: conductorController,
            crew_type: Crew_type.Conductor,
            caption: "Conductor",
            leadingicon: Icon(Icons.person_outline),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _assignCrew,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text('Assign Crew', style: TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _assignCrew() {
    final v = widget.vehicle;
    if (v == null) return;

    final memberController = Get.find<MemberController>();

    memberController.clearcrew(v.Vehicle_Number.toString());

    if (memberController.currentdriver.value != null) {
      memberController.currentdriver.value!.Vehicle = v.Vehicle_Number;
      memberController.setcrew(
        v.Vehicle_Number.toString(),
        memberController.currentdriver.value!.No.toString(),
        Crew_type.Driver,
      );
      v.Driver = memberController.currentdriver.value;
    }

    if (memberController.currentcunductor.value != null) {
      memberController.currentcunductor.value!.Vehicle = v.Vehicle_Number;
      memberController.setcrew(
        v.Vehicle_Number.toString(),
        memberController.currentcunductor.value!.No.toString(),
        Crew_type.Conductor,
      );
      v.Conductor = memberController.currentcunductor.value;
    }
    memberController.getcurrentcrew(v.Vehicle_Number.toString());
    Get.back(result: v);
  }
}
