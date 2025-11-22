import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Current user provider (stream)
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final userStream = authRepo.authStateChanges;

  return userStream.asyncMap((firebaseUser) async {
    if (firebaseUser == null) return null;
    try {
      return await authRepo.getUserData(firebaseUser.uid);
    } catch (e) {
      return null;
    }
  });
});

/// Auth state provider (simplified - just checks if user is logged in)
final authStateProvider = StreamProvider<bool>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges.map((user) => user != null);
});

/// Sign in provider (for login screen)
final signInProvider = Provider.family<Future<UserModel>, SignInParams>(
  (ref, params) async {
    final authRepo = ref.read(authRepositoryProvider);
    return await authRepo.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  },
);

/// Sign in parameters
class SignInParams {
  final String email;
  final String password;

  SignInParams({
    required this.email,
    required this.password,
  });
}

/// Sign out provider
final signOutProvider = Provider<Future<void>>((ref) async {
  final authRepo = ref.read(authRepositoryProvider);
  return await authRepo.signOut();
});

