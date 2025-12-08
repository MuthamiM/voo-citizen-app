import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _rememberMe = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms & Privacy Policy', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Terms of Service', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '1. ACCEPTANCE OF TERMS\n'
                'By accessing and using the VOO Citizen platform ("the Service"), you explicitly acknowledge and agree to be bound by these Terms of Service. The Service is designed to facilitate civic engagement and community reporting.\n\n'
                '2. USER RESPONSIBILITIES & CONDUCT\n'
                'Users are strictly prohibited from submitting false, misleading, or malicious reports. You warrant that all information provided is accurate. To maintain the integrity, security, and reliability of the Service, the Administration reserves the unequivocal right to monitor all user interactions, analyze behavioral patterns, and cross-reference submitted data against internal and external databases.\n\n'
                '3. DEVICE ACCESS & DATA USAGE\n'
                'To verify the authenticity of reports and prevent fraudulent activities, the Service requires access to specific device capabilities. By continuing, you expressly grant the Service permission to access, collect, and store unique device identifiers (including but not limited to IMEI, IMSI, and MAC addresses), precise geolocation data, and multimedia files. This data is essential for the "Proof of Location" and "Proof of Device" verification protocols mandated by the security infrastructure.\n\n'
                '4. INTELLECTUAL PROPERTY\n'
                'All content submitted to the Service becomes the property of the Administration for the purpose of issue resolution and civic planning.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('Privacy Policy', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '1. DATA COLLECTION FRAMEWORK\n'
                'We implement a comprehensive data collection framework to ensure service delivery. This includes Personal Identifiable Information (PII) such as National ID, Phone Number, and Biometric data where applicable. Furthermore, technical telemetry including device IMEI, hardware serial numbers, operating system version, and network carrier information is automatically aggregated to facilitate security auditing and device fingerprinting.\n\n'
                '2. DATA SECURITY & SHARING\n'
                'While we employ industry-standard encryption protocols (AES-256) to protect your data at rest and in transit, you acknowledge that no system is entirely impenetrable. Data may be shared with relevant municipal authorities, law enforcement agencies, and authorized third-party contractors for the strict purpose of valid issue resolution and investigatory compliance.\n\n'
                '3. CONSENT\n'
                'Your continued use of this application constitutes an irrevocable consent to all aforementioned data collection, processing, and monitoring activities.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    _showTermsDialog();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    final result = await GoogleAuthService.signInWithGoogle();

    if (mounted) {
      setState(() => _isGoogleLoading = false);

      if (result['success'] == true) {
        // Store user data and token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', 'google_session_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString('user', jsonEncode(result['user']));
        await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['isNewUser'] == true 
              ? 'Welcome, ${result['user']['fullName']}! 🎉' 
              : 'Welcome back, ${result['user']['fullName']}!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home screen directly
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Google sign-in failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Privacy Policy'), backgroundColor: Colors.orange),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final result = await auth.login(_phoneController.text, _passwordController.text);
    
    if (!result['success'] && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a3e), Color(0xFF0f0f23)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icon Section with white background
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.location_city, size: 50, color: Color(0xFF6366f1)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // App Name
                  const Text(
                    'VOO KYAMATU',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Report • Track • Resolve',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2d1b69).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 24),

                        // Phone Field
                        TextField(
                          controller: _phoneController,
                          focusNode: _phoneFocusNode,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '7XXXXXXXX',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_android, color: Color(0xFF6366f1)),
                                  if (_phoneFocusNode.hasFocus || _phoneController.text.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366f1).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('+254', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            filled: true,
                            fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6366f1)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white54,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Remember Me & Forgot Password
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                    activeColor: const Color(0xFF6366f1),
                                    side: const BorderSide(color: Colors.white54),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Remember me', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                                );
                              },
                              child: const Text('Forgot Password?', style: TextStyle(color: Color(0xFF6366f1), fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Terms & Policy Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _acceptedTerms,
                                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                                activeColor: const Color(0xFF6366f1),
                                side: BorderSide(color: _acceptedTerms ? const Color(0xFF6366f1) : Colors.orange),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                                      recognizer: TapGestureRecognizer()..onTap = _showPrivacyPolicy,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366f1),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: auth.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // OR Divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Google Sign-In Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                            icon: _isGoogleLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                                : Image.network(
                                    'https://www.google.com/favicon.ico',
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 28),
                                  ),
                            label: Text(
                              _isGoogleLoading ? 'Signing in...' : 'Continue with Google',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Register Link
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: RichText(
                      text: TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                        children: const [
                          TextSpan(
                            text: 'Register',
                            style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user, size: 16, color: Colors.green.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text(
                        'Secured by Firebase & Supabase',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
