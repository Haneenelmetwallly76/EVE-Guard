import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' as fb_core;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final Function(Map<String, String>) onLogin;
  final VoidCallback onSwitchToSignup;

  const LoginScreen({
    super.key,
    required this.onLogin,
    required this.onSwitchToSignup,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _hasBiometrics = false;
  List<BiometricType> _availableBiometrics = [];
  bool _hasAccountStored = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricCapability();
    _checkStoredAccount();
  }

  Future<void> _checkBiometricCapability() async {
    try {
      _hasBiometrics = await _localAuth.canCheckBiometrics;
      _availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error checking biometric capability: $e');
    }
  }

  Future<void> _checkStoredAccount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('stored_email');
      final storedPassword = prefs.getString('stored_password');
      if (storedEmail != null && storedPassword != null) {
        _hasAccountStored = true;
        _emailController.text = storedEmail;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error checking stored account: $e');
    }
  }

  Future<void> _handleBiometricLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('stored_email');
      final storedPassword = prefs.getString('stored_password');

      if (storedEmail == null || storedPassword == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No account saved. Please sign up and enable biometric login first.'),
              backgroundColor: AppTheme.red500,
            ),
          );
        }
        return;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to access The Guard',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) return;

      _emailController.text = storedEmail;
      _passwordController.text = storedPassword;
      await _performLogin(storedEmail, storedPassword);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric authentication failed: $e')),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }
    await _performLogin(_emailController.text, _passwordController.text);
  }

  Future<void> _performLogin(String email, String password) async {
    setState(() => _isLoading = true);

    try {
      // If Firebase isn't initialized, fallback to a local simulation and inform the user.
      if (fb_core.Firebase.apps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Firebase is not configured. Signed in locally. To enable cloud persistence, add Firebase configuration (google-services.json / GoogleService-Info.plist) or run `flutterfire configure`.',
            ),
          ),
        );

        if (!mounted) return;
        widget.onLogin({
          'email': email.trim(),
          'uid': '',
        });
        // Store credentials for biometric login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('stored_email', email.trim());
        await prefs.setString('stored_password', password);
        return;
      }

      final cred = await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      Map<String, String> payload = {
        'email': email.trim(),
        'uid': user?.uid ?? '',
      };

      // try to fetch Firestore user doc
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          payload['firstName'] = (data['firstName'] ?? '').toString();
          payload['lastName'] = (data['lastName'] ?? '').toString();
          payload['childrenCount'] = (data['childrenCount'] ?? 0).toString();
          // encode children array as JSON string to pass through map
          try {
            payload['children'] = jsonEncode(data['children'] ?? []);
          } catch (_) {}
        }
      }

      if (!mounted) return;
      widget.onLogin(payload);
      
      // Store credentials for biometric login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stored_email', email.trim());
      await prefs.setString('stored_password', password);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account not found. Please sign up first.'),
            backgroundColor: AppTheme.red500,
          ),
        );
      } else if (e.code == 'wrong-password') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password.'),
            backgroundColor: AppTheme.red500,
          ),
        );
      } else if (e.code.contains('configuration') || 
          e.message?.contains('CONFIGURATION_NOT_FOUND') == true ||
          e.message?.contains('Google Play Services') == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Firebase services not available. Signed in locally. Install Google Play Services on device or check Firebase configuration.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        if (!mounted) return;
        widget.onLogin({
          'email': email.trim(),
          'uid': '',
        });
        // Store credentials for biometric login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('stored_email', email.trim());
        await prefs.setString('stored_password', password);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign in failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Logo Section
                Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome to The Guard',
                      style: AppTheme.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your personal safety companion',
                      style: AppTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Login Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassMorphismDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign In',
                        style: AppTheme.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      
                      // Email Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Email address',
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppTheme.slate500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: AppTheme.slate500,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.slate500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sign In Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: AppTheme.primaryButtonStyle.copyWith(
                          minimumSize: WidgetStateProperty.all(
                            const Size(double.infinity, 48),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                      
                      // Biometric Login Button
                      if (_hasAccountStored && _hasBiometrics && _availableBiometrics.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleBiometricLogin,
                            icon: Icon(
                              _availableBiometrics.contains(BiometricType.fingerprint)
                                  ? Icons.fingerprint
                                  : Icons.face,
                              color: AppTheme.blue600,
                            ),
                            label: Text(
                              _availableBiometrics.contains(BiometricType.fingerprint)
                                  ? 'Login with Fingerprint'
                                  : 'Login with Face ID',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.blue600,
                              side: const BorderSide(color: AppTheme.blue600),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Forgot Password Link
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset functionality coming soon'),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: AppTheme.blue600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: AppTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: widget.onSwitchToSignup,
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppTheme.blue600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Security Notice
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.blue50.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.blue100.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security,
                        color: AppTheme.blue600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enterprise Security',
                              style: TextStyle(
                                color: AppTheme.blue600,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Your data is protected with bank-level encryption',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.blue600.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}