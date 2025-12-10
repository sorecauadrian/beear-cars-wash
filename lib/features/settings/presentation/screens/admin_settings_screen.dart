import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Admin settings screen
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  bool _isPasswordLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userAsync = ref.read(currentUserProvider);
    userAsync.whenData((user) {
      if (user != null) {
        setState(() {
          _nameController.text = user.name;
          _emailController.text = user.email;
        });
      }
    });

    // Load notification preference
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _notificationsEnabled = data['notificationsEnabled'] as bool? ?? true;
          });
        }
      } catch (e) {
        // Use default value
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Utilizatorul nu este autentificat');
      }

      // Update Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'notificationsEnabled': _notificationsEnabled,
      });

      // Update Firebase Auth email if changed
      if (_emailController.text.trim() != firebaseUser.email) {
        await firebaseUser.verifyBeforeUpdateEmail(_emailController.text.trim());
      }

      // Invalidate user provider to refresh data
      ref.invalidate(currentUserProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil actualizat cu succes'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eroare: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introdu parola nouă'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parolele nu se potrivesc'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parola trebuie să aibă cel puțin 6 caractere'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isPasswordLoading = true;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        throw Exception('Utilizatorul nu este autentificat');
      }

      await firebaseUser.updatePassword(_passwordController.text);

      // Clear password fields
      _passwordController.clear();
      _confirmPasswordController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parolă actualizată cu succes'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String errorMessage = 'Eroare la actualizarea parolei';
      if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Pentru securitate, te rugăm să te autentifici din nou înainte de a schimba parola';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPasswordLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(height: 32),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Utilizatorul nu este autentificat'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Profil',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nume *',
                              hintText: 'Introdu numele',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) => Validators.required(
                              value,
                              fieldName: 'Numele',
                            ),
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              hintText: 'Introdu email-ul',
                              prefixIcon: Icon(Icons.email),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Introdu email-ul';
                              }
                              if (!value.contains('@')) {
                                return 'Email invalid';
                              }
                              return null;
                            },
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              backgroundColor: AppColors.primary,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Salvează profilul',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Password Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.lock, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Parolă',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Parolă nouă',
                              hintText: 'Introdu parola nouă',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            enabled: !_isPasswordLoading,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirmă parola',
                              hintText: 'Introdu din nou parola',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            obscureText: true,
                            enabled: !_isPasswordLoading,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _isPasswordLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              backgroundColor: AppColors.primary,
                            ),
                            child: _isPasswordLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Schimbă parola',
                                    style: TextStyle(color: Colors.white),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Notifications Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Notificări',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text('Activează notificările'),
                            subtitle: const Text('Primește notificări despre rezervări noi'),
                            value: _notificationsEnabled,
                            onChanged: _isLoading
                                ? null
                                  : (value) async {
                                    setState(() {
                                      _notificationsEnabled = value;
                                    });
                                    // Save immediately
                                    final firebaseUser = FirebaseAuth.instance.currentUser;
                                    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
                                    if (firebaseUser != null) {
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(firebaseUser.uid)
                                            .update({
                                          'notificationsEnabled': value,
                                        });
                                      } catch (e) {
                                        // Revert on error
                                        if (!mounted) return;
                                        setState(() {
                                          _notificationsEnabled = !value;
                                        });
                                        scaffoldMessenger?.showSnackBar(
                                          const SnackBar(
                                            content: Text('Eroare la actualizarea setărilor'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Eroare: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

