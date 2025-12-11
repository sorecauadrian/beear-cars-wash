import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    // Create Firebase Auth user first
    UserCredential userCredential;
    try {
      userCredential = await auth.createUserWithEmailAndPassword(
        email: params.email.trim(),
        password: params.password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Există deja un cont cu acest email.');
      } else if (e.code == 'weak-password') {
        throw Exception('Parola este prea slabă.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Adresă de email invalidă.');
      } else {
        throw Exception('Eroare la crearea contului: ${e.message ?? e.code}');
      }
    }
    
    if (userCredential.user == null) {
      throw Exception('Eroare: Utilizatorul nu a fost creat.');
    }
    
    final userId = userCredential.user!.uid;
    
    // Create company in Firestore
    final company = CompanyModel(
      id: '', // Will be set by repository
      name: params.name,
      clientType: params.clientType,
      email: params.email,
      password: params.password,
      city: params.city,
      isActive: params.isActive,
    );
    
    String companyId;
    try {
      companyId = await repository.createCompany(company);
    } catch (e) {
      // If company creation fails, delete the Firebase Auth user
      try {
        await userCredential.user!.delete();
      } catch (_) {
        // Ignore errors when cleaning up
      }
      rethrow;
    }
    
    // Create user document in Firestore
    try {
      await firestore.collection(FirestorePaths.users).doc(userId).set({
        'name': params.name,
        'email': params.email.trim(),
        'role': 'company_admin',
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If user document creation fails, delete company and Firebase Auth user
      try {
        await repository.deleteCompany(companyId);
        await userCredential.user!.delete();
      } catch (_) {
        // Ignore errors when cleaning up
      }
      throw Exception('Eroare la crearea documentului utilizator: ${e.toString()}');
    }
    
    return companyId;
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
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    // Delete all related data for this company
    await bookingRepository.deleteBookingsByCompany(companyId);
    await vehicleRepository.deleteVehiclesByCompany(companyId);
    
    // Delete the company user accounts (Firestore documents)
    // Note: Firebase Auth users can only be deleted server-side or by the user themselves
    // Deleting Firestore documents will prevent login (user data won't be found)
    try {
      final usersSnapshot = await firestore
          .collection(FirestorePaths.users)
          .where('companyId', isEqualTo: companyId)
          .get();
      
      final batch = firestore.batch();
      final currentUserId = auth.currentUser?.uid;
      
      for (final doc in usersSnapshot.docs) {
        final userId = doc.id;
        batch.delete(doc.reference);
        
        // If deleting the current user, sign them out
        if (currentUserId == userId) {
          try {
            await auth.signOut();
          } catch (e) {
            debugPrint('Warning: Failed to sign out current user: $e');
          }
        }
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


