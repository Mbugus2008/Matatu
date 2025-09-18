import 'package:get/get.dart';
import 'package:t_matatu/models/vehicle.dart';

class VehiclesController extends GetxController {
  final RxList<Vehicle> _vehicles = <Vehicle>[].obs;
  
  List<Vehicle> get vehicles => _vehicles;
  
  // Fetch vehicles from the database
  Future<void> fetchVehicles() async {
    try {
      // TODO: Implement actual database fetch
      // For now, return mock data
      _vehicles.value = [
        Vehicle(
          id: 1,
          vehicleNumber: 'KAA 123A',
          fleetNumber: 'FLEET001',
          make: 'Toyota',
          model: 'Hiace',
          year: 2020,
        ),
        // Add more mock vehicles as needed
      ];
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch vehicles: $e');
      rethrow;
    }
  }
  
  // Search for vehicles by number or fleet number
  Future<List<Vehicle>> searchVehicles(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    // If we have cached vehicles, search in them
    if (_vehicles.isNotEmpty) {
      return _vehicles.where((vehicle) {
        return (vehicle.vehicleNumber.toLowerCase().contains(query.toLowerCase())) ||
               (vehicle.fleetNumber?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    }
    
    // Otherwise, fetch from the database
    await fetchVehicles();
    return _vehicles.where((vehicle) {
      return (vehicle.vehicleNumber.toLowerCase().contains(query.toLowerCase())) ||
             (vehicle.fleetNumber?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();
  }
  
  // Get vehicle suggestions for autocomplete
  Future<List<Vehicle>> getVehicleSuggestions(String query) async {
    if (query.length < 2) {
      return [];
    }
    
    final results = await searchVehicles(query);
    return results.take(5).toList(); // Limit to 5 suggestions
  }
  
  // Add a new vehicle
  Future<void> addVehicle(Vehicle vehicle) async {
    try {
      // TODO: Implement actual database insert
      // For now, just add to the list
      _vehicles.add(vehicle);
      Get.snackbar('Success', 'Vehicle added successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to add vehicle: $e');
      rethrow;
    }
  }
  
  // Update an existing vehicle
  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      // TODO: Implement actual database update
      // For now, just update in the list
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      if (index != -1) {
        _vehicles[index] = vehicle;
        Get.snackbar('Success', 'Vehicle updated successfully');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update vehicle: $e');
      rethrow;
    }
  }
  
  // Delete a vehicle
  Future<void> deleteVehicle(int id) async {
    try {
      // TODO: Implement actual database delete
      // For now, just remove from the list
      _vehicles.removeWhere((v) => v.id == id);
      Get.snackbar('Success', 'Vehicle deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete vehicle: $e');
      rethrow;
    }
  }
}
