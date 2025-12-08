import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  String _sentOtp = '';
  String _generatedPassword = '';
  
  // Theme colors
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color lightPink = Color(0xFFF5ADA7);
  static const Color bgPink = Color(0xFFF9C5C1);
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);
  
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otherVillageController = TextEditingController();
  String? _selectedVillage;

  final List<String> _villages = [
    'Kyamatu', 'Mwanyani', 'Itoloni', 'Kisovo', 'Iiani',
    'Kituluni', 'Kwa Mutonga', 'Kwa Mutuvi', 'Kwa Kasee', 'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _otherVillageController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD4635B), behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF4CAF50), behavior: SnackBarBehavior.floating),
    );
  }

  void _generatePassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%&*';
    final random = Random.secure();
    setState(() {
      _generatedPassword = List.generate(12, (_) => chars[random.nextInt(chars.length)]).join();
      _passwordController.text = _generatedPassword;
    });
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    _showSuccess('Password generated and copied!');
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.length < 9) {
      _showError('Please enter a valid phone number');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final result = await DashboardService.requestOtp('+254${_phoneController.text}');
      if (result['success'] == true) {
        setState(() {
          _otpSent = true;
          _sentOtp = result['otp'] ?? '123456';
        });
        _showSuccess('OTP sent to your phone');
      } else {
        _showError(result['error'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showError('Error sending OTP');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _verifyOtp() {
    if (_otpController.text == _sentOtp) {
      setState(() => _otpVerified = true);
      _showSuccess('Phone verified!');
      Future.delayed(const Duration(milliseconds: 500), _nextStep);
    } else {
      _showError('Invalid OTP');
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _handleRegister() async {
    if (!_agreedToTerms) {
      _showError('Please accept the terms');
      return;
    }
    if (_passwordController.text.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final village = _selectedVillage == 'Other' ? _otherVillageController.text : _selectedVillage;
      final result = await auth.register(
        _nameController.text,
        '+254${_phoneController.text}',
        _idController.text,
        _passwordController.text,
        village: village,
      );

      if (result['success'] == true) {
        _showSuccess('Registration successful!');
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        }
      } else {
        _showError(result['error'] ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(width: size.width, height: size.height, color: bgPink),
          
          // Decorative circles
          Positioned(top: -60, left: -80, child: _buildCircle(220, primaryPink.withOpacity(0.4))),
          Positioned(top: 150, right: -50, child: _buildCircle(160, lightPink.withOpacity(0.5))),
          Positioned(bottom: size.height * 0.5, left: -40, child: _buildCircle(100, primaryPink.withOpacity(0.3))),

          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _currentStep > 0 ? _prevStep() : Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  ),
                  const Spacer(),
                  Text('Step ${_currentStep + 1} of 3', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),

          // Title
          Positioned(
            top: size.height * 0.14,
            left: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitles()[_currentStep],
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 2), blurRadius: 4)],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getSubtitles()[_currentStep],
                  style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9)),
                ),
              ],
            ),
          ),

          // White card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              constraints: BoxConstraints(maxHeight: size.height * 0.65),
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: SingleChildScrollView(
                child: _buildCurrentStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTitles() => ['Your Info', 'Verify Phone', 'Create Password'];
  List<String> _getSubtitles() => ['Tell us about yourself', 'We\'ll send a code', 'Secure your account'];

  Widget _buildCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildInfoStep();
      case 1: return _buildVerifyStep();
      case 2: return _buildPasswordStep();
      default: return const SizedBox();
    }
  }

  Widget _buildInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Full Name'),
        _buildTextField(_nameController, 'Enter your name', Icons.person_outline, TextInputType.name, cap: TextCapitalization.words),
        const SizedBox(height: 20),
        
        _buildLabel('Phone Number'),
        _buildTextField(_phoneController, '7XX XXX XXX', Icons.phone_outlined, TextInputType.phone, prefix: '+254'),
        const SizedBox(height: 20),
        
        _buildLabel('National ID'),
        _buildTextField(_idController, 'Enter ID number', Icons.badge_outlined, TextInputType.number),
        const SizedBox(height: 20),
        
        _buildLabel('Village'),
        _buildDropdown(),
        
        if (_selectedVillage == 'Other') ...[
          const SizedBox(height: 16),
          _buildTextField(_otherVillageController, 'Enter village name', Icons.location_on_outlined, TextInputType.text),
        ],
        
        const SizedBox(height: 32),
        _buildButton('Continue', _nextStep),
      ],
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _otpVerified ? const Color(0xFF4CAF50) : primaryPink,
            shape: BoxShape.circle,
          ),
          child: Icon(_otpVerified ? Icons.check : Icons.sms_outlined, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 24),
        Text(
          _otpVerified ? 'Verified!' : 'Verify Phone',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textDark),
        ),
        const SizedBox(height: 8),
        Text(
          _otpVerified ? 'Your phone is verified' : 'We\'ll send a code to +254${_phoneController.text}',
          style: TextStyle(color: textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        
        if (!_otpVerified) ...[
          if (!_otpSent) ...[
            _buildButton(_isLoading ? 'Sending...' : 'Send OTP', _isLoading ? null : _sendOtp),
          ] else ...[
            _buildTextField(_otpController, 'Enter 6-digit code', Icons.lock_outline, TextInputType.number),
            const SizedBox(height: 20),
            _buildButton('Verify', _verifyOtp),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _sendOtp,
              child: const Text('Resend Code', style: TextStyle(color: primaryPink)),
            ),
          ],
        ] else ...[
          _buildButton('Continue', _nextStep),
        ],
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Password'),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_passwordController, 'Min 8 characters', Icons.lock_outline, TextInputType.text, obscure: true),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(color: primaryPink, borderRadius: BorderRadius.circular(14)),
              child: IconButton(
                onPressed: _generatePassword,
                icon: const Icon(Icons.auto_awesome, color: Colors.white),
                tooltip: 'Generate Password',
              ),
            ),
          ],
        ),
        if (_generatedPassword.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 8),
                const Text('Password copied to clipboard', style: TextStyle(color: Color(0xFF166534), fontSize: 13)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        
        Row(
          children: [
            SizedBox(
              width: 22, height: 22,
              child: Checkbox(
                value: _agreedToTerms,
                onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                activeColor: primaryPink,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(color: textMuted, fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        _buildButton(_isLoading ? 'Creating Account...' : 'Create Account', _isLoading ? null : _handleRegister),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark)),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
    TextInputType type, {
    TextCapitalization cap = TextCapitalization.none,
    String? prefix,
    bool obscure = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        textCapitalization: cap,
        obscureText: obscure,
        style: const TextStyle(fontSize: 15, color: textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF999999)),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: primaryPink, size: 22),
              if (prefix != null) ...[
                const SizedBox(width: 10),
                Text(prefix, style: const TextStyle(color: textMuted, fontWeight: FontWeight.w500)),
              ],
              const SizedBox(width: 12),
            ],
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedVillage,
        hint: const Text('Select village', style: TextStyle(color: Color(0xFF999999))),
        icon: const Icon(Icons.keyboard_arrow_down, color: primaryPink),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.location_on_outlined, color: primaryPink, size: 22),
          prefixIconConstraints: BoxConstraints(minWidth: 40),
          border: InputBorder.none,
        ),
        items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: (v) => setState(() => _selectedVillage = v),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: primaryPink.withOpacity(0.5),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
