import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart' as fb_core;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  final Function(Map<String, String>) onSignup;
  final VoidCallback onSwitchToLogin;

  const SignupScreen({
    super.key,
    required this.onSignup,
    required this.onSwitchToLogin,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _agreeToTerms = false;

  Future<void> _handleSignup() async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms of Service'),
          backgroundColor: AppTheme.red500,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // If Firebase is not configured, fall back to a local simulation and inform the user.
    if (fb_core.Firebase.apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase is not configured. Signed up locally. To enable cloud persistence, add Firebase configuration (google-services.json / GoogleService-Info.plist) or run `flutterfire configure`.',
          ),
        ),
      );

      if (!mounted) return;
      widget.onSignup({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'childrenCount': _childrenController.text.trim(),
        'uid': '',
      });
      // Store credentials for biometric login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stored_email', _emailController.text.trim());
      await prefs.setString('stored_password', _passwordController.text);
      setState(() => _isLoading = false);
      return;
    }

    try {
      final cred = await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = cred.user;
      final childrenCount = int.tryParse(_childrenController.text.trim()) ?? 0;
      final children = List<Map<String, String>>.generate(childrenCount, (i) => {
            'id': 'child_${i + 1}',
            'name': 'Child ${i + 1}',
          });

      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'firstName': _firstNameController.text.trim(),
          'lastName': _firstNameController.text.trim(),
          'email': _emailController.text.trim(),
          'childrenCount': childrenCount,
          'children': children,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      widget.onSignup({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'childrenCount': _childrenController.text.trim(),
        'uid': user?.uid ?? '',
      });
      // Store credentials for biometric login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('stored_email', _emailController.text.trim());
      await prefs.setString('stored_password', _passwordController.text);
    } on fb_auth.FirebaseAuthException catch (e) {
      // If CONFIGURATION_NOT_FOUND or other Firebase config issue, fall back to local
      if (e.code.contains('configuration') || 
          e.message?.contains('CONFIGURATION_NOT_FOUND') == true ||
          e.message?.contains('Google Play Services') == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Firebase services not available. Signed up locally. Install Google Play Services on device or check Firebase configuration.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
        if (!mounted) return;
        widget.onSignup({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'childrenCount': _childrenController.text.trim(),
          'uid': '',
        });
        // Store credentials for biometric login
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('stored_email', _emailController.text.trim());
        await prefs.setString('stored_password', _passwordController.text);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
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
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Join The Guard',
                        style: AppTheme.headingLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your secure account',
                        style: AppTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Signup Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppTheme.glassMorphismDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        style: AppTheme.headingMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Name Fields Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _firstNameController,
                              decoration: AppTheme.inputDecoration(
                                hintText: 'First Name',
                                prefixIcon: const Icon(
                                  Icons.person_outlined,
                                  color: AppTheme.slate500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _lastNameController,
                              decoration: AppTheme.inputDecoration(
                                hintText: 'Last Name',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

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
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Confirm Password',
                          prefixIcon: const Icon(
                            Icons.lock_outlined,
                            color: AppTheme.slate500,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.slate500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Number of Children
                      TextField(
                        controller: _childrenController,
                        keyboardType: TextInputType.number,
                        decoration: AppTheme.inputDecoration(
                          hintText: 'Number of children (optional)',
                          prefixIcon: const Icon(
                            Icons.child_care_outlined,
                            color: AppTheme.slate500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Terms Agreement
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) {
                              setState(() => _agreeToTerms = value ?? false);
                            },
                            activeColor: AppTheme.blue600,
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: const TextSpan(
                                  style: AppTheme.bodySmall,
                                  children: [
                                    TextSpan(text: 'I agree to the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: TextStyle(
                                        color: AppTheme.blue600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: AppTheme.blue600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignup,
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
                            : const Text('Create Account'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Sign In Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: AppTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: widget.onSwitchToLogin,
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.blue600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}