import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/repositories/company_repository.dart';
import '../../data/models/company_model.dart';
import '../../../bookings/data/repositories/booking_repository.dart';
import '../../../vehicles/data/repositories/vehicle_repository.dart';
import '../../../../core/constants/firestore_paths.dart';

/// Company repository provider
final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

/// All companies provider
final allCompaniesProvider = StreamProvider<List<CompanyModel>>((ref) {
  final repository = ref.watch(companyRepositoryProvider);
  return repository.getAllCompaniesStream();
});

/// Company by ID provider
final companyByIdProvider = FutureProvider.family<CompanyModel?, String>(
  (ref, companyId) async {
    final repository = ref.watch(companyRepositoryProvider);
    return repository.getCompanyById(companyId);
  },
);

/// Create company provider
final createCompanyProvider =
    Provider.family<Future<String>, CreateCompanyParams>(
  (ref, params) async {
    final repository = ref.read(companyRepositoryProvider);
    final company = CompanyModel(
      id: '', // Will be set by repository
      name: params.name,
      clientType: params.clientType,
      email: params.email,
      password: params.password,
      city: params.city,
      isActive: params.isActive,
    );
    return repository.createCompany(company);
  },
);

/// Update company provider
final updateCompanyProvider =
    Provider.family<Future<void>, UpdateCompanyParams>(
  (ref, params) async {
    final repository = ref.read(companyRepositoryProvider);
    final company = params.company.copyWith(
      name: params.name,
      clientType: params.clientType,
      email: params.email,
      password: params.password,
      city: params.city,
      isActive: params.isActive,
    );
    return repository.updateCompany(company);
  },
);

/// Delete company provider
final deleteCompanyProvider = Provider.family<Future<void>, String>(
  (ref, companyId) async {
    final repository = ref.read(companyRepositoryProvider);
    final bookingRepository = BookingRepository();
    final vehicleRepository = VehicleRepository();
    
    // Delete all related data for this company
    await bookingRepository.deleteBookingsByCompany(companyId);
    await vehicleRepository.deleteVehiclesByCompany(companyId);
    
    // Delete the company user account if it exists
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection(FirestorePaths.users)
          .where('companyId', isEqualTo: companyId)
          .get();
      
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in usersSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Log but don't fail if user deletion fails
      debugPrint('Warning: Failed to delete company users: $e');
    }
    
    // Finally delete the company
    return repository.deleteCompany(companyId);
  },
);

/// Create company parameters
class CreateCompanyParams {
  final String name;
  final ClientType clientType;
  final String email;
  final String password;
  final String city;
  final bool isActive;

  const CreateCompanyParams({
    required this.name,
    required this.clientType,
    required this.email,
    required this.password,
    required this.city,
    this.isActive = true,
  });
}

/// Update company parameters
class UpdateCompanyParams {
  final CompanyModel company;
  final String name;
  final ClientType clientType;
  final String email;
  final String password;
  final String city;
  final bool isActive;

  const UpdateCompanyParams({
    required this.company,
    required this.name,
    required this.clientType,
    required this.email,
    required this.password,
    required this.city,
    required this.isActive,
  });
}


