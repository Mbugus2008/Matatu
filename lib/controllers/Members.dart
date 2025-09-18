import 'package:get/get.dart';
import 'package:t_matatu/init.dart';
import 'package:t_matatu/providers/db.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';  // Add this import

import '../models/member.dart';
import '../models/vehicles/vehicle.dart';  // Add this import
import '../network/Apis.dart';
import '../network/results/results.dart';
import 'header.dart';

class MemberController extends GetxController {
  RxList<Member> allMembers = <Member>[].obs;
  RxList<Member> Memberss = <Member>[].obs;
  RxList<Member> Crews = <Member>[].obs;
  RxList<Member> currentcrew = <Member>[].obs;
  Rx<Member?> currentdriver = Member().obs;
  Rx<Member?> currentcunductor = Member().obs;
  @override
  Future<void> onInit() async {
    super.onInit();
    // Start scanning for Bluetooth devices when the controller is initialized
    initialize();
  }

  Future<void> initialize() async {
    final List<Map<String, dynamic>> maps =
        await db_Provider().getdata(Member.table, Member.columns);
    Get.find<MemberController>().allMembers.value = maps.map((row) {
      return Member.fromMap(row);
    }).toList();

    Get.find<MemberController>().Crews.value =
        allMembers.where((p0) => p0.Customer_Posting_Group == "CREW").toList();
    Get.find<MemberController>().Memberss.value = allMembers
        .where((p0) => p0.Customer_Posting_Group == "MEMBER")
        .toList();
  }

  clearcurrentvehicle() {
    Get.find<MemberController>().currentdriver = Member().obs;
    Get.find<MemberController>().currentcunductor = Member().obs;
    Get.find<MemberController>().currentcrew.clear();
    update();
  }

  getcurrentcrew(String vehicle) {
    clearcurrentvehicle();
    print(Get.find<MemberController>().allMembers.length);
    Get.find<MemberController>().currentcrew.value =
        Get.find<MemberController>()
            .allMembers
            .where((p0) => p0.Vehicle == vehicle)
            .toList();

    if (Get.find<MemberController>().currentcrew.isNotEmpty) {
      final driver = Get.find<MemberController>()
          .currentcrew
          .firstWhereOrNull((po) => po.Crew_Type == Crew_type.Driver);
      if (driver != null) {
        Get.find<MemberController>().currentdriver.value = driver;
        Get.find<HeaderController>().currHeader.value.Crew = driver.No;
      }
      final cond = Get.find<MemberController>()
          .currentcrew
          .firstWhereOrNull((po) => po.Crew_Type == Crew_type.Conductor);
      if (cond != null) {
        Get.find<MemberController>().currentcunductor.value = cond;
        Get.find<HeaderController>().currHeader.value.Crew2 = cond.No;
      }
    }
    update();
  }
  clearcrew(String vehicle) async {
    await db_Provider().updatedata(
      Member.table,
      {Member.col_Vehicle: null},
      '${Member.col_Vehicle} = ?',
      [vehicle],
    );
    Get.find<MemberController>()
        .allMembers
        .where((m) => m.Vehicle == (vehicle))
        .forEach((m) {
      // Update the value
      Get.find<MemberController>()
          .allMembers[Get.find<MemberController>().allMembers.indexOf(m)]
          .Vehicle = '';
    });
    update();
  }

  setcrew(String vehicle, String crew, Crew_type crew_type) async {
    await db_Provider().updatedata(
      Member.table,
      {Member.col_Vehicle: vehicle, Member.col_Crew_Type: crew_type.index},
      '${Member.col_No} = ?',
      [crew],
    );
    Get.find<MemberController>()
        .allMembers
        .where((m) => m.No == (crew))
        .forEach((m) {
      // Update the value
      Get.find<MemberController>()
          .allMembers[Get.find<MemberController>().allMembers.indexOf(m)]
          .Vehicle = vehicle;
      Get.find<MemberController>()
          .allMembers[Get.find<MemberController>().allMembers.indexOf(m)]
          .Crew_Type = crew_type;
          m.Loans = 0;  
      updateremotecrew(m);
    });
    update();
  }

  Future<void> updateremotecrew(Member member) async {
    ApiClient().postdata("updatecrew", member.toJson()).then((r) async {
      if (r.statusCode == 200) {
        Results2<Member> results =
            Results2<Member>.fromJson(r.body, Member.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            final h = results.Contents;
            if (h?.Key != null) {}
          }
        }
      }
    });
  }
  Future<void> updatephone(Member member) async {
    member.Loans = 0;
    ApiClient().postdata("updatephone", member.toJson()).then((r) async {
      if (r.statusCode == 200) {
        Results2<Member> results =
            Results2<Member>.fromJson(r.body, Member.fromMap);
        if (results.Code == 0) {
          if (results.Contents != null) {
            showToast('Updated successfully');
          }
            final h = results.Contents;
            if (h?.Key != null) {}
          
        }
      }
    });
  }
  Future<List<Suggestion>> getVehicleSuggestions(String pattern) async {
    List<Suggestion> suggestions = [];

    // Get vehicle suggestions first
    var vehiclesController = Get.find<VehiclesController>();
    if (vehiclesController.allVehicles.isEmpty) {
      await vehiclesController.loadVehicles();
    }
    var matchingVehicles = vehiclesController.allVehicles
        .where((vehicle) =>
          vehicle.toString().toLowerCase().contains(pattern.toLowerCase()) ?? false)
        .toList();

    suggestions.addAll(matchingVehicles.map((vehicle) => Suggestion(
      id: vehicle.Fleet_No ?? '',
      account: vehicle.Code ?? '',
      displayText:  vehicle.Vehicle_Number ?? '',
      details: vehicle_type_desc.desc[vehicle.Vehicle_Type] ?? '',
      isVehicle: true,
      customerPostingGroup: 'Vehicle',
      crewType: null,
    )));

    // Get member suggestions
    var matchingMembers = allMembers
        .where((member) => 
          member.toString().toLowerCase().contains(pattern.toLowerCase()) ?? false )
        .toList();
    
    suggestions.addAll(matchingMembers.map((member) => Suggestion(
      id: member.No ?? '',
      account: member.No ?? '',
      displayText: member.No ?? '',
      details: member.Name ?? '',
      isVehicle: false,
      customerPostingGroup: member.Customer_Posting_Group ?? 'Unknown',
      crewType: member.Crew_Type,
      loan: member.Loans ?? 0,
    )));

    // Sort suggestions to ensure vehicles appear first
    suggestions.sort((a, b) => a.isVehicle ? -1 : 1);

    return suggestions;
  }
}

class VehicleSuggestion {
  final String vehicle;
  final String vehicleNumber;
  final String fleetNo;
  final String vehicleType;

  VehicleSuggestion({
    required this.vehicle,
    required this.vehicleNumber,
    required this.fleetNo,
    required this.vehicleType
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleSuggestion &&
          runtimeType == other.runtimeType &&
          vehicle == other.vehicle;

  @override
  int get hashCode => vehicle.hashCode;

  @override
  String toString() {
    return '$vehicle - $vehicleNumber - Fleet: $fleetNo, Type: $vehicleType';
  }
}

class Suggestion {
  final String id;
  final String account;
  final String displayText;
  final String details;
  final bool isVehicle;
  final String customerPostingGroup;
  final Crew_type? crewType;
  final double loan;

  Suggestion({
    required this.id,
    required this.account,
    required this.displayText,
    required this.details,
    required this.isVehicle,
    required this.customerPostingGroup,
    this.crewType,
    this.loan = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isVehicle == other.isVehicle;

  @override
  int get hashCode => id.hashCode ^ isVehicle.hashCode;

  @override
  String toString() {
    String crewTypeStr = crewType != null ? ', Crew Type: ${crewType.toString().split('.').last}' : '';
    return '$displayText - $details - Group: $customerPostingGroup$crewTypeStr';
  }
}
