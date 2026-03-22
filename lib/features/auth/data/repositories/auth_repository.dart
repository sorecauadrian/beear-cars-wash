import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/services/notification_service.dart';

/// Authentication repository
/// Handles all Firebase Authentication and user data operations
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current Firebase Auth user
  User? get currentUser => _auth.currentUser;

  /// Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user == null) {
        throw Exception('User is null after sign in');
      }

      // Fetch user data from Firestore
      final user = await getUserData(credential.user!.uid);
      
      // Validate that the company still exists (if user has a companyId)
      if (user.companyId != null && user.companyId!.isNotEmpty) {
        final companyDoc = await _firestore
            .collection(FirestorePaths.companies)
            .doc(user.companyId!)
            .get();
        
        if (!companyDoc.exists) {
          // Company doesn't exist, sign out and throw error
          await _auth.signOut();
          throw Exception('Contul este asociat cu o companie care nu mai există. Te rugăm să contactezi administratorul.');
        }
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Re-throw as-is if it's already an Exception with a message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    // Clear notification service user ID
    NotificationService().clearUserId();
    await _auth.signOut();
  }

  /// Get user data from Firestore
  Future<UserModel> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirestorePaths.users)
          .doc(userId)
          .get();

      if (!doc.exists) {
        throw Exception('User data not found in Firestore');
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  /// Delete the current user's account and all associated data
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Utilizatorul nu este autentificat');
    }

    final uid = user.uid;

    // Get user doc to find companyId
    final userDoc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data() as Map<String, dynamic>;
      final companyId = data['companyId'] as String?;

      if (companyId != null && companyId.isNotEmpty) {
        // Check if this is the only user in the company
        final companyUsers = await _firestore
            .collection(FirestorePaths.users)
            .where('companyId', isEqualTo: companyId)
            .get();

        if (companyUsers.docs.length <= 1) {
          // Last user in company -- delete company data too
          final batch = _firestore.batch();

          final vehicles = await _firestore
              .collection(FirestorePaths.vehicles)
              .where('companyId', isEqualTo: companyId)
              .get();
          for (final doc in vehicles.docs) {
            batch.delete(doc.reference);
          }

          final bookings = await _firestore
              .collection(FirestorePaths.bookings)
              .where('companyId', isEqualTo: companyId)
              .get();
          for (final doc in bookings.docs) {
            batch.delete(doc.reference);
          }

          batch.delete(_firestore.collection(FirestorePaths.companies).doc(companyId));
          await batch.commit();
        }
      }

      // Delete user document
      await _firestore.collection(FirestorePaths.users).doc(uid).delete();
    }

    // Clear notification service
    NotificationService().clearUserId();

    // Delete Firebase Auth account
    await user.delete();
  }

  /// Get user data stream
  Stream<UserModel?> getUserDataStream(String userId) {
    return _firestore
        .collection(FirestorePaths.users)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages (Romanian)
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'Nu există utilizator cu acest email.';
        break;
      case 'wrong-password':
        message = 'Parolă incorectă.';
        break;
      case 'invalid-credential':
      case 'invalid-login-credentials':
        message = 'Email sau parolă incorectă. Verifică datele și încearcă din nou.';
        break;
      case 'invalid-email':
        message = 'Adresă de email invalidă.';
        break;
      case 'user-disabled':
        message = 'Acest cont a fost dezactivat.';
        break;
      case 'too-many-requests':
        message = 'Prea multe încercări eșuate. Te rugăm să încerci din nou mai târziu.';
        break;
      case 'operation-not-allowed':
        message = 'Autentificarea cu email/parolă nu este activată.';
        break;
      case 'weak-password':
        message = 'Parola este prea slabă.';
        break;
      case 'email-already-in-use':
        message = 'Există deja un cont cu acest email.';
        break;
      default:
        message = 'Autentificare eșuată. Te rugăm să încerci din nou.';
    }
    return Exception(message);
  }
}

