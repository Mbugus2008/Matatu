// ignore_for_file: public_member_api_docs

import 'package:get/get.dart';

import '../controllers/Members.dart';
import '../models/member.dart';

/// Business Central stores a waybill's crew as the crew number (e.g. `A978`),
/// not the name — the BC field is only 10 characters wide and rejects names.
/// The app therefore keeps crew numbers on the waybill and shows the matching
/// name in the UI, resolving through the locally cached crew list.

List<Member> _crew() {
  try {
    if (!Get.isRegistered<MemberController>()) return const [];
    return Get.find<MemberController>().allMembers;
  } catch (_) {
    return const [];
  }
}

String _norm(String? value) => (value ?? '').trim().toUpperCase();

/// Crew number for a typed name (or an already-entered crew number).
/// Prefers a crew member assigned to [vehicle], then one matching [type].
/// Returns null when the value cannot be resolved.
String? crewNumberFor(
  String? nameOrNumber, {
  String? vehicle,
  Crew_type? type,
}) {
  final input = _norm(nameOrNumber);
  if (input.isEmpty) return null;

  final members = _crew();

  // Already a crew number?
  for (final m in members) {
    if (_norm(m.No) == input) return m.No;
  }

  final byName = members.where((m) => _norm(m.Name) == input).toList();
  if (byName.isEmpty) return null;

  final sameVehicle = byName
      .where((m) => vehicle != null && _norm(m.Vehicle) == _norm(vehicle))
      .toList();
  final pool = sameVehicle.isNotEmpty ? sameVehicle : byName;

  if (type != null) {
    final typed = pool.where((m) => m.Crew_Type == type).toList();
    if (typed.isNotEmpty) return typed.first.No;
  }
  return pool.first.No;
}

/// Display name for a stored crew number (or name). Null when empty.
String? crewNameFor(String? numberOrName) {
  final value = (numberOrName ?? '').trim();
  if (value.isEmpty) return null;

  final input = _norm(value);
  for (final m in _crew()) {
    if (_norm(m.No) == input) return (m.Name ?? value).trim();
  }
  return value;
}

/// Display label for a stored crew number — falls back to the raw value.
String crewLabelFor(String? numberOrName) => crewNameFor(numberOrName) ?? '-';
