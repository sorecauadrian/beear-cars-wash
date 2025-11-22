import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';
import '../../../../core/constants/firestore_paths.dart';

/// Vehicle repository
/// Handles all Firestore operations for vehicles
class VehicleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all vehicles for a company
  Future<List<VehicleModel>> getVehiclesByCompany(String companyId) async {
    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.vehicles)
          .where('companyId', isEqualTo: companyId)
          .orderBy('plateNumber')
          .get();

      return snapshot.docs
          .map((doc) => VehicleModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get vehicles: ${e.toString()}');
    }
  }

  /// Get vehicles stream for a company
  Stream<List<VehicleModel>> getVehiclesByCompanyStream(String companyId) {
    return _firestore
        .collection(FirestorePaths.vehicles)
        .where('companyId', isEqualTo: companyId)
        .orderBy('plateNumber')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleModel.fromFirestore(doc))
            .toList());
  }

  /// Get vehicle by ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.vehicles)
          .doc(vehicleId)
          .get();

      if (!doc.exists) return null;
      return VehicleModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get vehicle: ${e.toString()}');
    }
  }

  /// Create a new vehicle
  Future<String> createVehicle(VehicleModel vehicle) async {
    try {
      final docRef = await _firestore
          .collection(FirestorePaths.vehicles)
          .add(vehicle.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create vehicle: ${e.toString()}');
    }
  }

  /// Update vehicle
  Future<void> updateVehicle(VehicleModel vehicle) async {
    try {
      await _firestore
          .collection(FirestorePaths.vehicles)
          .doc(vehicle.id)
          .update(vehicle.toFirestore());
    } catch (e) {
      throw Exception('Failed to update vehicle: ${e.toString()}');
    }
  }

  /// Delete vehicle
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore
          .collection(FirestorePaths.vehicles)
          .doc(vehicleId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete vehicle: ${e.toString()}');
    }
  }

  /// Check if vehicle has future bookings
  /// Returns true if vehicle has any bookings with status != rejected and date >= today
  Future<bool> hasFutureBookings(String vehicleId) async {
    try {
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final snapshot = await _firestore
          .collection(FirestorePaths.bookings)
          .where('vehicleId', isEqualTo: vehicleId)
          .where('date', isGreaterThanOrEqualTo: todayString)
          .where('status', whereIn: ['requested', 'accepted', 'in_progress'])
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // If query fails, assume there are bookings to be safe
      return true;
    }
  }
}

