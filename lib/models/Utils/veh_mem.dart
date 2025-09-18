// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:t_matatu/models/vehicles/vehicle.dart';

class InputSuggetions {
  String? Vehicle;
  String? Fleet;
  String? Account;
  vehicle_type? Vehicle_Type;
  SuggestionType? type;
  InputSuggetions({
    this.Vehicle,
    this.Fleet,
    this.Account,
    this.Vehicle_Type,
    this.type,
  });
  @override
  String toString() {
    return '$Vehicle $Account $Fleet';
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is InputSuggetions &&
        other.Vehicle == Vehicle &&
        other.Fleet == Fleet;
  }

  @override
  int get hashCode => Object.hash(Vehicle, Fleet);
}

enum SuggestionType { vehicle, Member, Crew }
