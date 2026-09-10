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

  Future<void> _assignCrew() async {
    final v = widget.vehicle;
    if (v == null) return;

    final memberController = Get.find<MemberController>();

    // Resolve the selected member from the typed text. The typeahead only
    // stores a selection when a suggestion is tapped, so fall back to
    // matching No / Phone / Name (exact or partial) when typed manually.
    Member? resolveMember(
        TextEditingController ctrl, Member? selected, Crew_type type) {
      final typed = ctrl.text.trim();
      if (typed.isEmpty) return null;
      if (selected != null && selected.No == typed) return selected;

      final all = memberController.allMembers;
      final exact = all.firstWhereOrNull((m) =>
          m.No == typed ||
          m.Phone_No == typed ||
          (m.Name != null && m.Name!.toLowerCase() == typed.toLowerCase()));
      if (exact != null) return exact;

      // Lenient: name contains the typed text, prefer the right crew type.
      final contains = all
          .where((m) =>
              m.Crew_Type == type &&
              m.Name != null &&
              m.Name!.toLowerCase().contains(typed.toLowerCase()))
          .toList();
      if (contains.length == 1) return contains.first;
      return null;
    }

    final driver = resolveMember(driverController,
        memberController.currentdriver.value, Crew_type.Driver);
    final conductor = resolveMember(conductorController,
        memberController.currentcunductor.value, Crew_type.Conductor);

    // Validate before changing anything.
    if (driverController.text.trim().isNotEmpty && driver == null) {
      _showError('Driver not found. Pick a member from the suggestions list.');
      return;
    }
    if (conductorController.text.trim().isNotEmpty && conductor == null) {
      _showError(
          'Conductor not found. Pick a member from the suggestions list.');
      return;
    }

    try {
      await memberController.clearcrew(v.Vehicle_Number.toString());

      if (driver != null && driver.No != null && driver.No!.isNotEmpty) {
        driver.Vehicle = v.Vehicle_Number;
        await memberController.setcrew(
          v.Vehicle_Number.toString(),
          driver.No!,
          Crew_type.Driver,
        );
        v.Driver = driver;
      }

      if (conductor != null &&
          conductor.No != null &&
          conductor.No!.isNotEmpty) {
        conductor.Vehicle = v.Vehicle_Number;
        await memberController.setcrew(
          v.Vehicle_Number.toString(),
          conductor.No!,
          Crew_type.Conductor,
        );
        v.Conductor = conductor;
      }

      memberController.getcurrentcrew(v.Vehicle_Number.toString());
    } catch (e) {
      _showError('Assign failed: $e');
      return;
    }

    _closePage(v);
  }

  /// Closes this page. GetX's Get.back() crashes with a
  /// LateInitializationError if the snackbar queue holds an unshown snackbar,
  /// so fall back to a raw navigator pop.
  void _closePage(Vehicles? v) {
    if (!mounted) return;
    try {
      Get.back(result: v);
    } catch (_) {
      if (mounted) Navigator.of(context).pop(v);
    }
  }

  void _showError(String message) {
    Get.dialog(
      AlertDialog(
        title: const Text('Assign Crew'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              if (mounted) Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
