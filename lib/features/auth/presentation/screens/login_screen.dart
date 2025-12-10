import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/notification_service.dart';
import 'package:go_router/go_router.dart';

/// Login screen with email/password authentication
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Set user ID in notification service for FCM token storage
      NotificationService().setUserId(user.id);

      // Navigate based on user role
      if (user.isAdmin) {
        context.go(RouteNames.adminHome);
      } else if (user.isCompanyAdmin) {
        context.go(RouteNames.companyHome);
      } else {
        // Company Worker role - for now, redirect to company home
        // (Worker features will be implemented later)
        context.go(RouteNames.companyHome);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
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

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // User is already logged in, navigate to appropriate home
        _checkAndNavigate(context);
      }
    });
  }

  Future<void> _checkAndNavigate(BuildContext context) async {
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        final user = await authRepo.getUserData(firebaseUser.uid);
        if (!context.mounted) return;
        
        if (user.isAdmin) {
          context.go(RouteNames.adminHome);
        } else {
          context.go(RouteNames.companyHome);
        }
      }
    } catch (e) {
      // If error, stay on login screen
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary,
              colorScheme.primary.withValues(alpha: 0.9),
              colorScheme.secondary.withValues(alpha: 0.8),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // App name with logo text - matching splash screen style
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/beear-cars-wash-no-text.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.local_car_wash,
                            size: 80,
                            color: colorScheme.primary,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Card with form - modern design
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Autentificare',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: colorScheme.tertiary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'Introdu adresa de email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: Validators.email,
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 24),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _handleLogin(),
                              decoration: InputDecoration(
                                labelText: 'Parolă',
                                hintText: 'Introdu parola',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) => Validators.required(
                                value,
                                fieldName: 'Parola',
                              ),
                              enabled: !_isLoading,
                            ),
                            const SizedBox(height: 36),

                            // Login button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Conectează-te',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
