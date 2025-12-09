import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String? prefilledUsername;
  const LoginScreen({super.key, this.prefilledUsername});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _acceptedTerms = false;
  bool _isGoogleLoading = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.prefilledUsername ?? '');
  }

  // Dark Orange Theme Colors
  static const Color bgDark = Color(0xFF1A1A1A);
  static const Color cardDark = Color(0xFF2A2A2A);
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color lightOrange = Color(0xFFFFB347);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color inputBg = Color(0xFF333333);

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    final result = await GoogleAuthService.signInWithGoogle();
    if (mounted) {
      setState(() => _isGoogleLoading = false);
      if (result['success'] == true) {
        final auth = context.read<AuthService>();
        await auth.setGoogleUser(result['user']);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        _showSnackBar(result['error'] ?? 'Google sign-in failed', isError: true);
      }
    }
  }

  Future<void> _handleLogin() async {
    final phone = _usernameController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      _showSnackBar('Please enter phone and password', isError: true);
      return;
    }

    if (!_acceptedTerms) {
      _showSnackBar('Please accept Terms & Privacy', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthService>();
    final result = await auth.login(phone, password);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        _showSnackBar(result['error'] ?? 'Login failed', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : primaryOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              
              // Title
              const Text(
                'LOGIN TO',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: textLight,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                'VOO WARD',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: primaryOrange,
                  letterSpacing: 1,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Login Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryOrange.withOpacity(0.3), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: primaryOrange.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Username Input (matching mockup)
                    _buildInputField(
                      controller: _usernameController,
                      hint: 'Username',
                      prefix: '@',
                      icon: Icons.alternate_email,
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Input
                    _buildInputField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: textMuted,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Terms Checkbox
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                            activeColor: primaryOrange,
                            checkColor: bgDark,
                            side: BorderSide(color: textMuted),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(color: textMuted, fontSize: 13),
                              children: [
                                const TextSpan(text: 'I accept the '),
                                TextSpan(
                                  text: 'Terms & Privacy',
                                  style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                        child: const Text('Forgot Password?', style: TextStyle(color: primaryOrange, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Sign In Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryOrange,
                          foregroundColor: bgDark,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: bgDark, strokeWidth: 2))
                            : const Text('SIGN IN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Google Sign In Removed (Manual Registration Only)
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: textMuted, fontSize: 14)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Register', style: TextStyle(color: primaryOrange, fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? prefix,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF555555), width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        cursorColor: primaryOrange,
        cursorWidth: 2,
        style: const TextStyle(
          color: Color(0xFFFFFFFF), 
          fontSize: 16, 
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 15),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: primaryOrange, size: 22),
              if (prefix != null) ...[
                const SizedBox(width: 10),
                Text(prefix, style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16)),
                const SizedBox(width: 4),
              ],
            ],
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
          ),
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: textMuted, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Terms & Privacy', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textLight)),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  'By using VOO Citizen, you agree to our Terms of Service and Privacy Policy. We collect necessary data to provide our services, including location and device information for verification purposes. Your data is encrypted and protected.',
                  style: TextStyle(color: textMuted, height: 1.6),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('I Understand', style: TextStyle(color: bgDark, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
