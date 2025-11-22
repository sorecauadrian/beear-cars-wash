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
      return await getUserData(credential.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
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

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }
}

