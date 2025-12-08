import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';
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

  // Theme colors matching reference
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color lightPink = Color(0xFFF5ADA7);
  static const Color darkPink = Color(0xFFD4635B);
  static const Color bgPink = Color(0xFFF9C5C1);

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            const Text('Terms & Privacy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'By using VOO Citizen, you agree to our Terms of Service and Privacy Policy. We collect necessary data to provide our services, including location and device information for verification purposes. Your data is encrypted and protected.',
                  style: TextStyle(color: Colors.grey.shade600, height: 1.6),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('I Understand', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final result = await GoogleAuthService.signInWithGoogle();
    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (result['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', 'google_session_${DateTime.now().millisecondsSinceEpoch}');
        await prefs.setString('user', jsonEncode(result['user']));
        await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
        _showSuccess('Welcome, ${result['user']['fullName']}!');
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _showError(result['error'] ?? 'Google sign-in failed');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: darkPink, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleLogin() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    if (!_acceptedTerms) {
      _showError('Please accept Terms & Privacy Policy');
      return;
    }
    final auth = context.read<AuthService>();
    final result = await auth.login(_phoneController.text, _passwordController.text);
    if (!result['success'] && mounted) {
      _showError(result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background with blob pattern
          Container(
            width: size.width,
            height: size.height,
            color: bgPink,
          ),
          
          // Decorative blobs
          Positioned(
            top: -50,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryPink.withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: lightPink.withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            top: size.height * 0.25,
            right: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryPink.withOpacity(0.3),
              ),
            ),
          ),

          // Welcome text
          Positioned(
            top: size.height * 0.12,
            left: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 2), blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          // White form card at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sign in', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                  const SizedBox(height: 28),

                  // Phone Field
                  _buildTextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    hint: 'Phone Number',
                    prefix: '+254',
                    keyboardType: TextInputType.phone,
                    icon: Icons.phone_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  _buildTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    obscure: _obscurePassword,
                    icon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Remember & Forgot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 22, height: 22,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              activeColor: primaryPink,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              side: BorderSide(color: Colors.grey.shade400),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('Remember me', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: Text('Forgot Password?', style: TextStyle(color: primaryPink, fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),

                  // Terms
                  Row(
                    children: [
                      SizedBox(
                        width: 22, height: 22,
                        child: Checkbox(
                          value: _acceptedTerms,
                          onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                          activeColor: primaryPink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          side: BorderSide(color: _acceptedTerms ? primaryPink : Colors.orange.shade400),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTermsDialog,
                          child: RichText(
                            text: TextSpan(
                              text: 'I agree to ',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              children: [
                                TextSpan(text: 'Terms & Privacy', style: TextStyle(color: primaryPink, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                      ),
                      Expanded(child: Container(height: 1, color: Colors.grey.shade200)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                      icon: _isGoogleLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Image.network('https://www.google.com/favicon.ico', width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata)),
                      label: Text(_isGoogleLoading ? 'Signing in...' : 'Continue with Google', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Register Link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: Colors.grey.shade600),
                          children: [TextSpan(text: 'Sign Up', style: TextStyle(color: primaryPink, fontWeight: FontWeight.w600))],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15, color: Color(0xFF333333)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: primaryPink, size: 22),
              if (prefix != null) ...[
                const SizedBox(width: 10),
                Text(prefix, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
              const SizedBox(width: 12),
            ],
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}
