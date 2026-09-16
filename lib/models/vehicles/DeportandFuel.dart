// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:t_matatu/controllers/vehicles/vehicles.dart';
import 'package:t_matatu/models/Utils/util.dart';
import 'package:t_matatu/models/enums.dart';
import 'package:t_matatu/models/expenses/expenses.dart';
import 'package:t_matatu/models/mappings.dart';
import 'package:t_matatu/models/vehicles/vehicle.dart';
import 'package:t_matatu/network/Apis.dart';
import 'package:t_matatu/network/errors.dart';
import 'package:t_matatu/network/request.dart';
import 'package:t_matatu/network/results/results.dart';

class DepotFuel implements Tomaps {
  String? Key;
  String? Vehicle;
  String? Fleet;
  bool? _On_route;
  bool? get On_route => _On_route;
  set On_route(bool? value) {
    _On_route = value;
    // Keep the "all on route" switch in sync. Callers that update many rows
    // should use setOnRouteSilently() and refresh once afterwards.
    if (Get.isRegistered<DepotController>()) {
      Get.find<DepotController>().updateCheckAll();
    }
  }

  /// Set [On_route] without refreshing the depot list (bulk updates).
  void setOnRouteSilently(bool? value) {
    _On_route = value;
  }

  bool? _Run_Back;
  bool? get Run_Back => _Run_Back;
  set Run_Back(bool? value) {
    _Run_Back = value;
  }

  DateTime? Run_Bak_Time;
  double? Management;
  double? Management_Target;

  DateTime? From;
  String? Nro_Defects;
  String? _Descrition;
  String? get Descrition => _Descrition;
  set Descrition(String? value) {
    // Do not write back into desc_editor here: the UI owns that controller and
    // assigning to it mid-typing resets the caret position.
    _Descrition = value;
  }

  /// Called from the description field in the dispatch sheet.
  ///
  /// Only the model is updated - the editor keeps ownership of its own text.
  void onDescriptionChanged(String? value) {
    _Descrition = value;
    dirty = true;
  }

  DateTime? Date;
  String? User;
  vehicle_type? Capacity;
  int? _Millage;

  int? get Millage => _Millage;

  set Millage(int? value) {
    _Millage = value;
    //milleage_editor.text =  value.toString();
  }

  String? Driver;
  String? Conductor;
  double? Offload;
  double? _Fuel;
  double? get Fuel => _Fuel;
  set Fuel(double? value) {
    _Fuel = value;
    Balance = (Amount_Paid ?? 0) - (value ?? 0);
    //fuel_editor.text =  value.toString();
  }

  double? _Amount_Paid;
  double? get Amount_Paid => _Amount_Paid;
  set Amount_Paid(double? value) {
    _Amount_Paid = value;
    Balance = (value ?? 0) - (Fuel ?? 0);
    //amountpaid_editor.text = value.toString();
  }

  double? Balance;
  double? Net_Offload;
  double? _Total_litres;
  double? get Total_litres => _Total_litres;
  set Total_litres(double? value) {
    _Total_litres = value;

    //litres_editor.text = value.toString();
  }

  double? Km_Litre;
  String? Fuel_Agent;
  String? Driver_Name;
  String? Conductor_Name;
  double? Offload_Target;
  double? Offload_Balance;
  double? Management_Balance;
  Whos_to_blame? Whos_to_blame_for_Deficiet;
  String? Comments;
  double? Total_Collection;
  double? Fuel_Balance;
  double? Odometer_Reading;
  DateTime? Tlb_Expiry;
  DateTime? Insurance_expiry;
  DateTime? Driver_Licence_Expiry;
  DateTime? Conductor_Licence_Expiry;
  DateTime? Driver_Badge_Expiry;
  DateTime? Conductor_Badge_Expiry;

  /// Track whether this record has been modified locally
  bool dirty = false;

  // TextEditingControllers
  late TextEditingController Nro_Defects_editor;
  late TextEditingController desc_editor;
  late TextEditingController fuel_editor;
  late TextEditingController amountpaid_editor;
  late TextEditingController milleage_editor;
  late TextEditingController litres_editor;

  // FocusNodes
  late FocusNode fuel_focus_node;
  late FocusNode amount_paid_focus_node;
  late FocusNode litres_focus_node;
  late FocusNode milleage_focus_node;

  DepotFuel({
    this.Key,
    this.Vehicle,
    this.Fleet,
    bool? On_route,
    this.From,
    this.Nro_Defects,
    String? Descrition,
    this.Date,
    this.User,
    this.Capacity,
    int? Millage,
    this.Driver,
    this.Conductor,
    this.Offload,
    double? Fuel,
    double? Amount_Paid,
    this.Balance,
    this.Net_Offload,
    double? Total_litres,
    double? Km_Litre,
    String? Fuel_Agent,
    this.Driver_Name,
    this.Conductor_Name,
    bool? Run_Back,
    this.Run_Bak_Time,
    this.Whos_to_blame_for_Deficiet,
    this.Offload_Target,
    this.Offload_Balance,
    this.Management_Balance,
    this.Management,
    this.Management_Target,
    this.Comments,
    this.Total_Collection,
    this.Fuel_Balance,
    this.Odometer_Reading,
    this.Tlb_Expiry,
    this.Insurance_expiry,
    this.Driver_Licence_Expiry,
    this.Conductor_Licence_Expiry,
    this.Driver_Badge_Expiry,
    this.Conductor_Badge_Expiry,
  })  : _Millage = Millage,
        _Amount_Paid = Amount_Paid,
        _Fuel = Fuel,
        _On_route = On_route,
        _Descrition = Descrition,
        _Total_litres = Total_litres,
        _Run_Back = Run_Back {
    // Initialize TextEditingControllers with current values or empty string
    Nro_Defects_editor =
        TextEditingController(text: Nro_Defects?.toString() ?? '');
    desc_editor = TextEditingController(
        text: _Descrition ??
            ''); // Assuming _Descrition holds the description value
    fuel_editor = TextEditingController(text: _Fuel?.toStringAsFixed(2) ?? '');
    amountpaid_editor =
        TextEditingController(text: _Amount_Paid?.toStringAsFixed(2) ?? '');
    milleage_editor = TextEditingController(
        text: Odometer_Reading != null && Odometer_Reading! > 0
            ? Odometer_Reading!.toStringAsFixed(0)
            : '');
    litres_editor =
        TextEditingController(text: _Total_litres?.toStringAsFixed(2) ?? '');

    // Initialize FocusNodes
    fuel_focus_node = FocusNode();
    amount_paid_focus_node = FocusNode();
    litres_focus_node = FocusNode();
    milleage_focus_node = FocusNode();
  }

  // Dispose method to clean up controllers and focus nodes
  void dispose() {
    Nro_Defects_editor.dispose();
    desc_editor.dispose();
    fuel_editor.dispose();
    amountpaid_editor.dispose();
    milleage_editor.dispose();
    litres_editor.dispose();

    fuel_focus_node.dispose();
    amount_paid_focus_node.dispose();
    litres_focus_node.dispose();
    milleage_focus_node.dispose();
    // print('DepotFuel disposed for vehicle: $Vehicle'); // Optional: for debugging
  }

  @override
  String toString() {
    return '$Vehicle $Fleet $Driver_Name $Conductor_Name';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Key': Key,
      'Vehicle': Vehicle,
      'Fleet': Fleet,
      'On_route': On_route,
      'From': From != null ? formattedTime.format(From!) : null,
      'Nro_Defects': Nro_Defects,
      'Descrition': Descrition,
      'Date': formattedDate.format(Date ?? getdate()),
      'User': User,
      'Capacity': Capacity?.index,
      'Millage': Millage,
      'Driver': Driver,
      'Conductor': Conductor,
      'Offload': Offload,
      'Fuel': Fuel,
      'Amount_Paid': Amount_Paid,
      'Balance': Balance,
      'Net_Offload': Net_Offload,
      'Total_litres': Total_litres,
      'Km_Litre': Km_Litre,
      'Fuel_Agent': Fuel_Agent,
      'Driver_Name': Driver_Name,
      'Conductor_Name': Conductor_Name,
      'Run_Back': Run_Back,
      'Run_Bak_Time':
          Run_Bak_Time != null ? formattedTime.format(Run_Bak_Time!) : null,
      'Whos_to_blame_for_Deficiet': Whos_to_blame_for_Deficiet == null
          ? null
          : Whos_to_blame_for_Deficiet!.index,
      'Whos_to_blame_for_DeficietSpecified': Whos_to_blame_for_Deficiet != null,
      'Offload_Target': Offload_Target,
      'Offload_Balance': Offload_Balance,
      'Management_Balance': Management_Balance,
      'Management': Management,
      'Management_Target': Management_Target,
      'Comments': Comments,
      'Total_Collection': Total_Collection,
      'Total_CollectionSpecified': Total_Collection != null,
      'Fuel_Balance': Fuel_Balance,
      'Fuel_BalanceSpecified': Fuel_Balance != null,
      'Odometer_Reading': Odometer_Reading,
      'Odometer_ReadingSpecified': Odometer_Reading != null,
    };
  }

  factory DepotFuel.fromMap(Map<String, dynamic> map) {
    final dateFormat = DateFormat('HH:mm:ss');
    DateTime? parsedDate, runbacktime;
    try {
      parsedDate = dateFormat.parse(map['From'] as String);
      runbacktime = dateFormat.parse(map['Run_Bak_Time'] as String);
    } catch (e) {}
    String? driver_name = map['Driver_Name']?.toString();
    String? conductor_name = map['Conductor_Name']?.toString();

    DepotFuel df = DepotFuel(
      Key: map['Key'] != null ? map['Key'] as String : null,
      Vehicle: map['Vehicle'] != null ? map['Vehicle'] as String : null,
      Fleet: map['Fleet'] != null ? map['Fleet'] as String : null,
      On_route: map['On_route'] != null ? map['On_route'] as bool : null,
      From: parsedDate,
      Nro_Defects:
          map['Nro_Defects'] != null ? map['Nro_Defects'] as String : null,
      Descrition:
          map['Descrition'] != null ? map['Descrition'] as String : null,
      Date: map['Date'] != null
          ? DateFormat("MM/dd/yyyy").parse((map['Date'] ?? 0))
          : null,
      User: map['User'] != null ? map['User'] as String : null,
      Capacity: map['Capacity'] != null
          ? vehicle_type.values[(map['Capacity']) as int]
          : null,
      Millage: map['Millage'] != null ? map['Millage'] as int : null,
      Driver: map['Driver'] != null ? map['Driver'] as String : null,
      Conductor: map['Conductor'] != null ? map['Conductor'] as String : null,
      Offload:
          map['Offload'] != null ? (map['Offload'] as num).toDouble() : null,
      Fuel: map['Fuel'] != null ? (map['Fuel'] as num).toDouble() : null,
      Amount_Paid: map['Amount_Paid'] != null
          ? (map['Amount_Paid'] as num).toDouble()
          : null,
      Balance:
          map['Balance'] != null ? (map['Balance'] as num).toDouble() : null,
      Net_Offload: map['Net_Offload'] != null
          ? (map['Net_Offload'] as num).toDouble()
          : null,
      Total_litres: map['Total_Litres'] != null
          ? (map['Total_Litres'] as num).toDouble()
          : null,
      Km_Litre:
          map['Km_Litre'] != null ? (map['Km_Litre'] as num).toDouble() : null,
      Fuel_Agent:
          map['Fuel_Agent'] != null ? map['Fuel_Agent'] as String : null,
      Driver_Name: driver_name,
      Conductor_Name: conductor_name,
      Run_Back: map['Run_Back'] != null ? map['Run_Back'] as bool : null,
      Run_Bak_Time: runbacktime,
      Whos_to_blame_for_Deficiet: map['Whos_to_blame_for_Deficiet'] != null
          ? Whos_to_blame.values[map['Whos_to_blame_for_Deficiet'] as int]
          : null,
      Offload_Target: map['Offload_Target'] != null
          ? (map['Offload_Target'] as num).toDouble()
          : null,
      Offload_Balance: map['Offload_Balance'] != null
          ? (map['Offload_Balance'] as num).toDouble()
          : null,
      Management_Balance: map['Management_Balance'] != null
          ? (map['Management_Balance'] as num).toDouble()
          : null,
      Management: map['Management'] != null
          ? (map['Management'] as num).toDouble()
          : null,
      Management_Target: map['Management_Target'] != null
          ? (map['Management_Target'] as num).toDouble()
          : null,
      Comments: map['Comments'] as String?,
      Total_Collection: map['Total_Collection'] != null
          ? (map['Total_Collection'] as num).toDouble()
          : null,
      Fuel_Balance: map['Fuel_Balance'] != null
          ? (map['Fuel_Balance'] as num).toDouble()
          : null,
      Odometer_Reading: map['Odometer_Reading'] != null
          ? (map['Odometer_Reading'] as num).toDouble()
          : null,
      Tlb_Expiry: _tryParseExpiry(map['Tlb_Expiry']),
      Insurance_expiry: _tryParseExpiry(map['Insurance_expiry']),
      Driver_Licence_Expiry: _tryParseExpiry(map['Driver_Licence_Expiry']),
      Conductor_Licence_Expiry:
          _tryParseExpiry(map['Conductor_Licence_Expiry']),
      Driver_Badge_Expiry: _tryParseExpiry(map['Driver_Badge_Expiry']),
      Conductor_Badge_Expiry: _tryParseExpiry(map['Conductor_Badge_Expiry']),
    );

    return df;
  }
  String toJson() => json.encode(toMap());

  /// Parse an expiry date from the API (MM/dd/yyyy HH:mm:ss) or DB value.
  static DateTime? _tryParseExpiry(dynamic v) {
    if (v == null) return null;
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    final s = v.toString();
    if (s.trim().isEmpty) return null;
    return DateFormat('MM/dd/yyyy HH:mm:ss').tryParse(s) ??
        DateFormat('MM/dd/yyyy').tryParse(s) ??
        DateTime.tryParse(s);
  }

  factory DepotFuel.fromJson(String source) =>
      DepotFuel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  fromMap_table(Map<String, dynamic> map) {
    return DepotFuel.fromMap(map);
  }

  /// Loads the NRO defect codes used by the defect type-ahead.
  Future<void> getNRODefects() async {
    try {
      final request = Request(body: null);
      final r = await ApiClient().postdata("NRODefects", request.toJson());
      if (r.statusCode != 200) return;
      final results = Results<Expenses>.fromJson(r.body, Expenses.fromMap);
      if (results.Code == 0 && results.Contents != null) {
        Get.find<VehiclesController>().NRODefects.value =
            results.Contents as List<Expenses>;
      }
    } catch (e) {
      _log('NRODefects load failed: $e');
      Errors().report(e is Exception ? e : Exception(e.toString()));
    }
  }

  /// Loads the dispatch/depot rows for [date].
  /// Returns true when the list was refreshed from the server.
  Future<bool> getdata(DateTime date) async {
    final ctrl = Get.find<DepotController>();
    ctrl.loading.value = true;
    try {
      final request = Request(body: null, date: date);
      final r = await ApiClient().postdata("getdepotdata", request.toJson());
      if (r.statusCode != 200) {
        _notifyError(
            'Server error ${r.statusCode} while loading dispatch data');
        return false;
      }
      final results = Results<DepotFuel>.fromJson(r.body, DepotFuel.fromMap);
      if (results.Code != 0) {
        _notifyError(results.Desc ?? 'Could not load dispatch data');
        return false;
      }
      final ll = results.Contents ?? <DepotFuel>[];
      ll.sort((a, b) => (a.Fleet ?? '').compareTo(b.Fleet ?? ''));
      ctrl.updateDepotTrans(ll);
      return true;
    } catch (e) {
      _notifyError('Could not load dispatch data: $e');
      return false;
    } finally {
      ctrl.loading.value = false;
    }
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[DISPATCH] $message');
  }

  static void _notifyError(String message) {
    _log(message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        Get.snackbar(
          'Dispatch',
          message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFC62828),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
      } catch (_) {
        // No overlay available (e.g. during start-up) - the log entry is enough.
      }
    });
  }

  /// Saves every dirty row. Returns true when the server accepted the batch.
  Future<bool> updatedepot(List<DepotFuel> depots) async {
    final ctrl = Get.find<DepotController>();
    ctrl.updating.value = true;
    var saved = false;
    final dirty = depots.where((d) => d.dirty).toList();
    if (dirty.isEmpty) {
      _log('nothing to save');
      ctrl.updating.value = false;
      return false;
    }
    ctrl.updateTotal.value = dirty.length;
    ctrl.updateProgress.value = 0;

    // Ensure null decimals become 0 to satisfy ASP.NET model binder
    for (var depot in dirty) {
      depot.Km_Litre ??= 0;
      depot.Total_litres ??= 0;
      depot.Net_Offload ??= 0;
      depot.Offload_Target ??= 0;
      depot.Offload_Balance ??= 0;
      depot.Management_Balance ??= 0;
      depot.Management_Target ??= 0;
      depot.Management ??= 0;
      depot.Comments ??= '';
      depot.Total_Collection ??= 0;
      depot.Fuel_Balance ??= 0;
      depot.Odometer_Reading ??= 0;
    }

    // Send all dirty records in a single batch request.
    final payload = json.encode(dirty.map((d) => d.toMap()).toList());
    _log('batch sending ${dirty.length} records');
    try {
      final r = await ApiClient().postdata("setdepotdatabatch", payload);
      if (r.statusCode == 200) {
        final results = Results<DepotFuel>.fromJson(r.body, DepotFuel.fromMap);
        if (results.Code == 0) {
          for (final d in dirty) {
            d.dirty = false;
          }
          saved = true;
        } else {
          _notifyError(
              'Failed to update dispatch: ${results.Desc ?? 'Unknown error'}');
        }
      } else {
        _notifyError('Server error ${r.statusCode} while updating dispatch');
      }
    } catch (e) {
      _log('batch failed: $e');
      // Fall back to one-by-one saving for compatibility.
      saved = await _updatedepotOneByOne(dirty, ctrl);
    }
    ctrl.updateProgress.value = ctrl.updateTotal.value;
    ctrl.updating.value = false;
    ctrl.refreshDirty();
    return saved;
  }

  Future<bool> _updatedepotOneByOne(
      List<DepotFuel> dirty, DepotController ctrl) async {
    var allSaved = true;
    for (final depot in dirty) {
      try {
        final r = await ApiClient().postdata("setdepotdata", depot.toJson());
        if (r.statusCode == 200) {
          final results =
              Results2<DepotFuel>.fromJson(r.body, DepotFuel.fromMap);
          if (results.Code == 0) {
            depot.dirty = false;
          } else {
            allSaved = false;
            _notifyError('Failed to update ${depot.Vehicle}: '
                '${results.Desc ?? 'Unknown error'}');
          }
        } else {
          allSaved = false;
          _notifyError(
              'Server error ${r.statusCode} while updating ${depot.Vehicle}');
        }
      } catch (e) {
        allSaved = false;
        _notifyError('Failed to update ${depot.Vehicle}: $e');
      }
      ctrl.updateProgress.value++;
    }
    return allSaved;
  }

  String serializeDepotList(List<DepotFuel> depots) {
    List<Map<String, dynamic>> jsonList =
        depots.map((depot) => depot.toMap()).toList();
    return json.encode(jsonList);
  }
}

class DepotController extends GetxController {
  RxBool checkall = false.obs;
  RxBool updating = false.obs;
  RxBool loading = false.obs;
  RxInt updateProgress = 0.obs;
  RxInt updateTotal = 0.obs;

  /// Number of rows with unsaved edits (drives the save bar).
  RxInt dirtyCount = 0.obs;

  final RxList<DepotFuel> depottrans = <DepotFuel>[].obs;
  final RxList<DepotFuel> depottrans1 = <DepotFuel>[].obs;

  /// Unfiltered snapshot of the last loaded list, so searching never loses rows.
  List<DepotFuel> _snapshot = <DepotFuel>[];

  /// All loaded rows, regardless of the active search filter.
  List<DepotFuel> get allDepots =>
      _snapshot.isNotEmpty ? _snapshot : depottrans.toList();

  bool get hasDirty => dirtyCount.value > 0;

  @override
  void onInit() {
    super.onInit();
    depottrans.value = [];
  }

  /// Recomputes the "all on route" switch state and the unsaved counter.
  void updateCheckAll() {
    final onRoute = depottrans.where((dt) => dt.On_route == true).length;
    checkall.value = depottrans.isNotEmpty && onRoute == depottrans.length;
    refreshDirty();
    update();
  }

  /// Recomputes how many rows still need saving.
  void refreshDirty() {
    dirtyCount.value = allDepots.where((d) => d.dirty).length;
  }

  @override
  void onClose() {
    // depottrans and depottrans1 can hold the same instances - dispose once.
    final disposed = <DepotFuel>{};
    for (final instance in <DepotFuel>[...depottrans, ...depottrans1]) {
      if (disposed.add(instance)) {
        instance.dispose();
      }
    }
    depottrans.clear();
    depottrans1.clear();
    _snapshot = <DepotFuel>[];
    super.onClose();
  }

  void checkallvehicles(bool check) {
    for (var element in Get.find<DepotController>().depottrans) {
      element.On_route = check;
      if (check) {
        // Only stamp the dispatch time when the vehicle actually goes on route.
        element.From ??= getdatetime();
      }
      element.dirty = true;
    }
    updateCheckAll();
  }

  void updateDepotTrans(List<DepotFuel> newDepotTrans) {
    _snapshot = List<DepotFuel>.from(newDepotTrans);
    depottrans.value = newDepotTrans;
    depottrans1.value = newDepotTrans;
    updateCheckAll();
  }

  /// Drops every loaded row (used when switching to a fresh dispatch/fuel flow).
  void clearAll() {
    _snapshot = <DepotFuel>[];
    depottrans.clear();
    depottrans1.clear();
    checkall.value = false;
    dirtyCount.value = 0;
    update();
  }

  /// Filters the visible rows by vehicle/fleet/crew/defect text.
  void filterDepotTrans(String value) {
    final query = value.trim().toUpperCase();
    final source = allDepots;
    depottrans.value = query.isEmpty
        ? List<DepotFuel>.from(source)
        : source
            .where((item) => item.toString().toUpperCase().contains(query))
            .toList();
    updateCheckAll();
  }
}
