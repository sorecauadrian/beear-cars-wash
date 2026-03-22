import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/vehicle_repository.dart';
import '../../data/models/vehicle_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Vehicle repository provider
final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return VehicleRepository();
});

/// Vehicles list provider for a company
final vehiclesListProvider = StreamProvider.family<List<VehicleModel>, String>(
  (ref, companyId) {
    final repository = ref.watch(vehicleRepositoryProvider);
    return repository.getVehiclesByCompanyStream(companyId);
  },
);

/// Current user's vehicles provider
final myVehiclesProvider = StreamProvider<List<VehicleModel>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final repository = ref.watch(vehicleRepositoryProvider);

  return userAsync.when(
    data: (user) {
      if (user == null || user.companyId == null) {
        return Stream.value([]);
      }
      return repository.getVehiclesByCompanyStream(user.companyId!);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Create vehicle provider
final createVehicleProvider =
    Provider.family<Future<String>, CreateVehicleParams>(
  (ref, params) async {
    final repository = ref.read(vehicleRepositoryProvider);
    final userAsync = ref.read(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null || user.companyId == null) {
          throw Exception('User not found or no company assigned');
        }

        final vehicle = VehicleModel(
          id: '',
          companyId: user.companyId!,
          plateNumber: params.plateNumber,
          vehicleType: params.vehicleType,
          description: params.description,
        );

        return repository.createVehicle(vehicle);
      },
      loading: () => throw Exception('User data loading'),
      error: (e, _) => throw Exception('User error: $e'),
    );
  },
);

/// Update vehicle provider
final updateVehicleProvider =
    Provider.family<Future<void>, UpdateVehicleParams>(
  (ref, params) async {
    final repository = ref.read(vehicleRepositoryProvider);
    final vehicle = params.vehicle.copyWith(
      plateNumber: params.plateNumber,
      vehicleType: params.vehicleType,
      description: params.description,
    );
    return repository.updateVehicle(vehicle);
  },
);

/// Delete vehicle provider
final deleteVehicleProvider = Provider.family<Future<void>, String>(
  (ref, vehicleId) async {
    final repository = ref.read(vehicleRepositoryProvider);
    
    // Check if vehicle has future bookings
    final hasBookings = await repository.hasFutureBookings(vehicleId);
    if (hasBookings) {
      throw Exception(
        'Cannot delete vehicle with future bookings. Please cancel bookings first.',
      );
    }

    return repository.deleteVehicle(vehicleId);
  },
);

/// Create vehicle parameters
class CreateVehicleParams {
  final String plateNumber;
  final VehicleType vehicleType;
  final String? description;

  CreateVehicleParams({
    required this.plateNumber,
    required this.vehicleType,
    this.description,
  });
}

/// Update vehicle parameters
class UpdateVehicleParams {
  final VehicleModel vehicle;
  final String plateNumber;
  final VehicleType vehicleType;
  final String? description;

  UpdateVehicleParams({
    required this.vehicle,
    required this.plateNumber,
    required this.vehicleType,
    this.description,
  });
}

