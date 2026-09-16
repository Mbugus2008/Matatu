import 'dart:async';

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

  /// Crew currently carried by the vehicle (e.g. the dispatch row's driver and
  /// conductor). Used to prefill the form; when omitted the crew stored locally
  /// for the vehicle is used instead.
  final String? driverNo;
  final String? conductorNo;

  const CrewAssignment({
    Key? key,
    required this.vehicle,
    this.driverNo,
    this.conductorNo,
  }) : super(key: key);

  @override
  State<CrewAssignment> createState() => _CrewAssignmentState();
}

class _CrewAssignmentState extends State<CrewAssignment> {
  final TextEditingController driverController = TextEditingController();
  final TextEditingController conductorController = TextEditingController();

  /// Crew the vehicle carries right now. Several crew rows can share a vehicle,
  /// so these are tracked explicitly and only they get detached on replace.
  String? _previousDriverNo;
  String? _previousConductorNo;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCurrentCrew();
  }

  void _loadCurrentCrew() {
    final v = widget.vehicle;
    if (v == null) return;

    final memberController = Get.find<MemberController>();
    final members = memberController.allMembers;

    Member? byNo(String? no) => (no == null || no.isEmpty)
        ? null
        : members.firstWhereOrNull((m) => m.No == no);

    // The caller's crew is the source of truth; fall back to what is stored
    // locally for the vehicle.
    Member? driver = byNo(widget.driverNo);
    Member? conductor = byNo(widget.conductorNo);

    if (driver == null || conductor == null) {
      memberController.getcurrentcrew(v.Vehicle_Number.toString());
      final crew = memberController.currentcrew;
      driver ??= crew.firstWhereOrNull((m) => m.Crew_Type == Crew_type.Driver);
      conductor ??=
          crew.firstWhereOrNull((m) => m.Crew_Type == Crew_type.Conductor);
    }

    _previousDriverNo = widget.driverNo ?? driver?.No;
    _previousConductorNo = widget.conductorNo ?? conductor?.No;

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
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorBanner(),
              ],
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

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7B5B5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: Color(0xFFC62828)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF8E2424)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _saving ? null : _assignCrew,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: _saving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : const Text('Assign Crew', style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Future<void> _assignCrew() async {
    if (_saving) return;
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
      _fail('Driver not found. Pick a member from the suggestions list.');
      return;
    }
    if (conductorController.text.trim().isNotEmpty && conductor == null) {
      _fail('Conductor not found. Pick a member from the suggestions list.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    const saveTimeout = Duration(seconds: 15);
    final vehicleNo = v.Vehicle_Number.toString();

    try {
      // Only the crew being replaced is detached. Clearing the whole vehicle
      // would wipe the other crew rows attached to it.
      if (_previousDriverNo != null && _previousDriverNo != driver?.No) {
        await memberController
            .detachcrew(vehicleNo, _previousDriverNo)
            .timeout(saveTimeout);
      }
      if (_previousConductorNo != null &&
          _previousConductorNo != conductor?.No) {
        await memberController
            .detachcrew(vehicleNo, _previousConductorNo)
            .timeout(saveTimeout);
      }

      if (driver != null && driver.No != null && driver.No!.isNotEmpty) {
        driver.Vehicle = v.Vehicle_Number;
        await memberController
            .setcrew(vehicleNo, driver.No!, Crew_type.Driver)
            .timeout(saveTimeout);
      }

      if (conductor != null &&
          conductor.No != null &&
          conductor.No!.isNotEmpty) {
        conductor.Vehicle = v.Vehicle_Number;
        await memberController
            .setcrew(vehicleNo, conductor.No!, Crew_type.Conductor)
            .timeout(saveTimeout);
      }
    } on TimeoutException {
      _fail('Saving crew timed out. Check the connection and try again.');
      return;
    } catch (e) {
      _fail('Assign failed: $e');
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    // Hand the result back, including a cleared driver/conductor.
    v.Driver = driver;
    v.Conductor = conductor;
    _closePage(v);
  }

  /// Closes this page and hands [v] back to the caller.
  ///
  /// The raw navigator is used on purpose: Get.back() can pop an overlay
  /// (snackbar/dialog) instead of this page, which leaves the screen stuck
  /// open on top of the dispatch list.
  void _closePage(Vehicles? v) {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(v);
      return;
    }
    Get.back(result: v);
  }

  /// Shows [message] on the page itself.
  ///
  /// An inline banner is used instead of a dialog because a dialog can fail to
  /// appear (and then the button looks like it did nothing).
  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _saving = false;
    });
  }
}
