// Today's numbers behind the M-Branch role-center "Summary" cues —
// returned by the API endpoint DashboardCues (BC Table 50050 "Transactions
// Cue": cash, M-Pesa and the M-Branch Transactions sums per collection type).
// ignore_for_file: non_constant_identifier_names

import 'package:t_matatu/models/mappings.dart';

class DashboardCues implements Tomaps<DashboardCues> {
  DateTime? Date;
  double Cash = 0;
  double Mpesa = 0;
  double Offload = 0;
  double Management = 0;
  double Savings = 0;
  double Carwash = 0;
  double DepotParking = 0;
  double Expenses = 0;
  double Body = 0;
  double Insurance = 0;
  double NccParking = 0;
  double Knh = 0;
  double SavingsCrew = 0;
  double Security = 0;
  double StatutorySundry = 0;
  double Stones = 0;
  double OffloadParking = 0;
  int OnRoute = 0;

  // Hires — today's activity + a 7-day trend.
  int HiresToday = 0;
  double HiresTodayAmount = 0;
  int HiresPaidToday = 0;
  int HiresUnpaidToday = 0;
  List<int> HiresByDay = const [];

  // Waybills — today's entries/totals + a 7-day trend.
  int WaybillsToday = 0;
  double WaybillTargetToday = 0;
  double WaybillActualToday = 0;
  double WaybillShortageToday = 0;
  List<double> WaybillTargetByDay = const [];
  List<double> WaybillActualByDay = const [];

  // Fuel — what the depot disbursed today + a 7-day trend.
  double FuelToday = 0;
  double FuelLitresToday = 0;
  List<double> FuelByDay = const [];

  // Cashiers — today's cash receipts per agent (sums to Cash).
  List<CashierCue> Cashiers = const [];

  DashboardCues();

  static double _d(Object? value) =>
      value == null ? 0 : (value as num).toDouble();

  static int _i(Object? value) => value == null ? 0 : (value as num).toInt();

  static List<int> _ints(Object? value) => value is List
      ? value.map((e) => (e as num).toInt()).toList()
      : const [];

  static List<double> _nums(Object? value) => value is List
      ? value.map((e) => (e as num).toDouble()).toList()
      : const [];

  static List<CashierCue> _cashiers(Object? value) => value is List
      ? value
          .whereType<Map>()
          .map((e) => CashierCue.fromMap(e))
          .toList()
      : const [];

  factory DashboardCues.fromMap(Map<String, dynamic> map) {
    return DashboardCues()
      ..Date = map['Date'] != null
          ? DateTime.tryParse(map['Date'].toString())
          : null
      ..Cash = _d(map['Cash'])
      ..Mpesa = _d(map['Mpesa'])
      ..Offload = _d(map['Offload'])
      ..Management = _d(map['Management'])
      ..Savings = _d(map['Savings'])
      ..Carwash = _d(map['Carwash'])
      ..DepotParking = _d(map['DepotParking'])
      ..Expenses = _d(map['Expenses'])
      ..Body = _d(map['Body'])
      ..Insurance = _d(map['Insurance'])
      ..NccParking = _d(map['NccParking'])
      ..Knh = _d(map['Knh'])
      ..SavingsCrew = _d(map['SavingsCrew'])
      ..Security = _d(map['Security'])
      ..StatutorySundry = _d(map['StatutorySundry'])
      ..Stones = _d(map['Stones'])
      ..OffloadParking = _d(map['OffloadParking'])
      ..OnRoute = _i(map['OnRoute'])
      ..HiresToday = _i(map['HiresToday'])
      ..HiresTodayAmount = _d(map['HiresTodayAmount'])
      ..HiresPaidToday = _i(map['HiresPaidToday'])
      ..HiresUnpaidToday = _i(map['HiresUnpaidToday'])
      ..HiresByDay = _ints(map['HiresByDay'])
      ..WaybillsToday = _i(map['WaybillsToday'])
      ..WaybillTargetToday = _d(map['WaybillTargetToday'])
      ..WaybillActualToday = _d(map['WaybillActualToday'])
      ..WaybillShortageToday = _d(map['WaybillShortageToday'])
      ..WaybillTargetByDay = _nums(map['WaybillTargetByDay'])
      ..WaybillActualByDay = _nums(map['WaybillActualByDay'])
      ..FuelToday = _d(map['FuelToday'])
      ..FuelLitresToday = _d(map['FuelLitresToday'])
      ..FuelByDay = _nums(map['FuelByDay'])
      ..Cashiers = _cashiers(map['Cashiers']);
  }

  @override
  DashboardCues fromMap_table(Map<String, dynamic> map) =>
      DashboardCues.fromMap(map);

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'Date': Date?.toIso8601String(),
      'Cash': Cash,
      'Mpesa': Mpesa,
      'Offload': Offload,
      'Management': Management,
      'Savings': Savings,
      'Carwash': Carwash,
      'DepotParking': DepotParking,
      'Expenses': Expenses,
      'Body': Body,
      'Insurance': Insurance,
      'NccParking': NccParking,
      'Knh': Knh,
      'SavingsCrew': SavingsCrew,
      'Security': Security,
      'StatutorySundry': StatutorySundry,
      'Stones': Stones,
      'OffloadParking': OffloadParking,
      'OnRoute': OnRoute,
      'HiresToday': HiresToday,
      'HiresTodayAmount': HiresTodayAmount,
      'HiresPaidToday': HiresPaidToday,
      'HiresUnpaidToday': HiresUnpaidToday,
      'HiresByDay': HiresByDay,
      'WaybillsToday': WaybillsToday,
      'WaybillTargetToday': WaybillTargetToday,
      'WaybillActualToday': WaybillActualToday,
      'WaybillShortageToday': WaybillShortageToday,
      'WaybillTargetByDay': WaybillTargetByDay,
      'WaybillActualByDay': WaybillActualByDay,
      'FuelToday': FuelToday,
      'FuelLitresToday': FuelLitresToday,
      'FuelByDay': FuelByDay,
      'Cashiers': [for (final c in Cashiers) c.toMap()],
    };
  }
}

/// One cashier's collection for the day (matches the API's CashierTotal).
class CashierCue {
  String Name = '';
  double Amount = 0;
  int Count = 0;

  CashierCue();

  factory CashierCue.fromMap(Map<dynamic, dynamic> map) {
    return CashierCue()
      ..Name = (map['Name'] ?? '').toString()
      ..Amount = map['Amount'] == null ? 0 : (map['Amount'] as num).toDouble()
      ..Count = map['Count'] == null ? 0 : (map['Count'] as num).toInt();
  }

  Map<String, dynamic> toMap() => {
        'Name': Name,
        'Amount': Amount,
        'Count': Count,
      };
}
