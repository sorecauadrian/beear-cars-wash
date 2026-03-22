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
    
    UserCredential userCredential;
    try {
      userCredential = await auth.createUserWithEmailAndPassword(
        email: params.email.trim(),
        password: params.password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Check if this is an orphaned auth account (no Firestore user doc)
        final orphaned = await _tryCleanOrphanedAuthAccount(
          auth, firestore, params.email.trim(), params.password,
        );
        if (orphaned) {
          // Retry after cleanup
          try {
            userCredential = await auth.createUserWithEmailAndPassword(
              email: params.email.trim(),
              password: params.password,
            );
          } on FirebaseAuthException catch (retryError) {
            throw Exception('Eroare la recrearea contului: ${retryError.message ?? retryError.code}');
          }
        } else {
          throw Exception('Există deja un cont activ cu acest email.');
        }
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
      id: '',
      name: params.name,
      clientType: params.clientType,
      email: params.email,
      phone: params.phone,
      city: params.city,
      isActive: params.isActive,
      cui: params.cui,
      nrRegCom: params.nrRegCom,
      adresaSediu: params.adresaSediu,
      judet: params.judet,
      banca: params.banca,
      iban: params.iban,
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
      phone: params.phone,
      city: params.city,
      isActive: params.isActive,
      cui: params.cui,
      nrRegCom: params.nrRegCom,
      adresaSediu: params.adresaSediu,
      judet: params.judet,
      banca: params.banca,
      iban: params.iban,
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

/// Checks if an "email-already-in-use" error is caused by an orphaned
/// Firebase Auth account (auth exists but no Firestore user document).
/// If orphaned and we can sign in with the provided password, deletes
/// the old auth account and returns true so the caller can retry.
Future<bool> _tryCleanOrphanedAuthAccount(
  FirebaseAuth auth,
  FirebaseFirestore firestore,
  String email,
  String password,
) async {
  try {
    // Check if any Firestore user doc exists with this email
    final usersQuery = await firestore
        .collection(FirestorePaths.users)
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (usersQuery.docs.isNotEmpty) {
      // There IS a Firestore user doc → this is a real duplicate, not orphaned
      return false;
    }

    // No Firestore user doc → orphaned auth account
    // Try signing in to reclaim and delete it
    final currentUser = auth.currentUser;
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await credential.user!.delete();
      }
    } catch (_) {
      // Password doesn't match the orphaned account — send reset email
      try {
        await auth.sendPasswordResetEmail(email: email);
      } catch (_) {}
      throw Exception(
        'Un cont vechi cu acest email a fost găsit. '
        'Am trimis un email de resetare a parolei la $email. '
        'Resetează parola și apoi conectează-te cu „Am uitat parola".',
      );
    }

    // Restore admin session if one was active
    if (currentUser != null) {
      try {
        await currentUser.reload();
      } catch (_) {}
    }

    return true;
  } catch (e) {
    if (e is Exception && e.toString().contains('Un cont vechi')) {
      rethrow;
    }
    return false;
  }
}

class CreateCompanyParams {
  final String name;
  final ClientType clientType;
  final String email;
  final String password;
  final String phone;
  final String city;
  final bool isActive;
  final String? cui;
  final String? nrRegCom;
  final String? adresaSediu;
  final String? judet;
  final String? banca;
  final String? iban;

  const CreateCompanyParams({
    required this.name,
    required this.clientType,
    required this.email,
    required this.password,
    this.phone = '',
    required this.city,
    this.isActive = true,
    this.cui,
    this.nrRegCom,
    this.adresaSediu,
    this.judet,
    this.banca,
    this.iban,
  });
}

class UpdateCompanyParams {
  final CompanyModel company;
  final String name;
  final ClientType clientType;
  final String email;
  final String phone;
  final String city;
  final bool isActive;
  final String? cui;
  final String? nrRegCom;
  final String? adresaSediu;
  final String? judet;
  final String? banca;
  final String? iban;

  const UpdateCompanyParams({
    required this.company,
    required this.name,
    required this.clientType,
    required this.email,
    required this.phone,
    required this.city,
    required this.isActive,
    this.cui,
    this.nrRegCom,
    this.adresaSediu,
    this.judet,
    this.banca,
    this.iban,
  });
}


