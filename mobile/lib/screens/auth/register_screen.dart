import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  String _generatedOtp = '';
  bool _obscurePassword = true;
  bool _showOtpCopyBox = false;
  
  // Dark Orange Theme Colors (matching mockups exactly)
  static const Color bgDark = Color(0xFF000000); // Pure Black
  static const Color cardDark = Color(0xFF2A2A2A);
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color inputBg = Color(0xFF333333);
  static const Color inputBorder = Color(0xFF444444);
  
  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otherVillageController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  String? _selectedVillage;
  final _infoFormKey = GlobalKey<FormState>();

  final List<String> _villages = [
    'Ndili', 'Katulani', 'Kyamatu', 'Nzunguni', 'Wikililye',
    'Mbiuni', 'Kasikeu', 'Kwa Munyao', 'Miandani', 'Nguutani', 'Other'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otherVillageController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: primaryOrange, behavior: SnackBarBehavior.floating),
    );
  }

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  String _getPasswordStrength() {
    final p = _passwordController.text;
    if (p.isEmpty) return '';
    if (p.length < 6) return 'Weak';
    if (p.length < 8) return 'Fair';
    if (_isPasswordStrong(p)) return 'Strong';
    return 'Medium';
  }

  Color _getStrengthColor() {
    switch (_getPasswordStrength()) {
      case 'Weak': return Colors.red;
      case 'Fair': return Colors.orange;
      case 'Medium': return Colors.yellow;
      case 'Strong': return Colors.green;
      default: return textMuted;
    }
  }

  Future<void> _sendOtp() async {
    if (_phoneController.text.length < 9) {
      _showError('Please enter a valid phone number');
      return;
    }
    setState(() => _isLoading = true);
    
    try {
      final auth = context.read<AuthService>();
      final result = await auth.sendOtp('+254${_phoneController.text}');
      
      if (result['success'] == true) {
        setState(() {
          _otpSent = true;
          // In production, this would be hidden or empty as it comes via SMS
          // For now we show the debug_otp returned by the server
          _generatedOtp = result['debug_otp']?.toString() ?? ''; 
          _showOtpCopyBox = _generatedOtp.isNotEmpty;
          _isLoading = false;
        });
        _showSuccess('OTP sent! Code: $_generatedOtp'); // Show in snackbar too for ease
      } else {
        setState(() => _isLoading = false);
        _showError(result['error']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to send OTP: $e');
    }
  }

  Future<void> _verifyOtp() async {
    final enteredOtp = _otpControllers.map((c) => c.text).join();
    if (enteredOtp.length < 6) {
      _showError('Please enter complete OTP');
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthService>();
      final result = await auth.verifyOtp('+254${_phoneController.text}', enteredOtp);
      
      setState(() => _isLoading = false);
      
      if (result['success'] == true) {
        setState(() => _otpVerified = true);
        _showSuccess('Phone verified!');
        // Store the verification token to use in the final step
        // We can store it in a member variable or pass it to next step
        // For now, let's assume we store it in a variable "_verificationToken"
        _verificationToken = result['token'];
        Future.delayed(const Duration(milliseconds: 500), _nextStep);
      } else {
        _showError(result['error']);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Verification failed: $e');
    }
  }

  // Add this variable to the class state
  String? _verificationToken;

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_infoFormKey.currentState!.validate()) return;
      if (_selectedVillage == null) {
        _showError('Please select a village');
        return;
      }
    }
    if (_currentStep < 2) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _handleRegister() async {
    if (!_agreedToTerms) {
      _showError('Please accept the terms');
      return;
    }
    if (!_isPasswordStrong(_passwordController.text)) {
      _showError('Password must be 8+ chars with uppercase, lowercase, number & symbol');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }
    if (_verificationToken == null) {
      _showError('Phone verification missing. Please go back and verify.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthService>();
      final village = _selectedVillage == 'Other' ? _otherVillageController.text : _selectedVillage;
      
      final result = await auth.completeRegistration(
        fullName: _nameController.text,
        phone: '+254${_phoneController.text}',
        idNumber: _idController.text,
        password: _passwordController.text,
        village: village,
        username: _usernameController.text,
        token: _verificationToken!,
      );

      if (result['success'] == true) {
        _showSuccess('Registration successful! Please login.');
        if (mounted) {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (_) => LoginScreen(prefilledUsername: _usernameController.text)),
          );
        }
      } else {
        _showError(result['error'] ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // Header with step indicators (matching mockup exactly)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _currentStep > 0 ? _prevStep() : Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios, color: textLight, size: 20),
                  ),
                  const Spacer(),
                  // Numbered step indicators (1, 2, 3) matching mockup
                  Row(
                    children: List.generate(3, (i) => Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: i == _currentStep ? primaryOrange : (i < _currentStep ? primaryOrange.withOpacity(0.3) : inputBg),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: i <= _currentStep ? primaryOrange : inputBorder,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: i == _currentStep ? bgDark : (i < _currentStep ? primaryOrange : textMuted),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Title (matching mockup)
                    Text(
                      _getTitles()[_currentStep],
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: primaryOrange),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Form Card (matching mockup dark card style)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardDark,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: inputBorder),
                      ),
                      child: _buildCurrentStep(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Already have account link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ', style: TextStyle(color: textMuted, fontSize: 14)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Sign in', style: TextStyle(color: primaryOrange, fontSize: 14, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getTitles() => ['Create Account', 'Verify Your Phone', 'Set Password'];

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildInfoStep();
      case 1: return _buildVerifyStep();
      case 2: return _buildPasswordStep();
      default: return const SizedBox();
    }
  }

  Widget _buildInfoStep() {
    return Form(
      key: _infoFormKey,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Full Name'),
        _buildInputField(_nameController, 'Enter your full name', TextInputType.name, validator: (v) => v!.isEmpty ? 'Name required' : null),
        const SizedBox(height: 16),
        
        _buildLabel('Username'),
        _buildInputField(_usernameController, 'username', TextInputType.text, prefix: '@', validator: (v) => v!.length < 3 ? 'Min 3 chars' : null),
        const SizedBox(height: 16),
        
        _buildLabel('Phone Number'),
        _buildInputField(_phoneController, '7XX XXX XXX', TextInputType.phone, prefix: '+254', validator: (v) => v!.length < 9 ? 'Invalid phone' : null),
        const SizedBox(height: 16),
        
        _buildLabel('National ID'),
        _buildInputField(_idController, 'Enter your ID number', TextInputType.number, validator: (v) => v!.isEmpty ? 'ID required' : null),
        const SizedBox(height: 16),
        
        _buildLabel('Village'),
        _buildVillageSelector(),
        
        if (_selectedVillage == 'Other') ...[
          const SizedBox(height: 16),
          _buildInputField(_otherVillageController, 'Enter village name', TextInputType.text),
        ],
        
        const SizedBox(height: 24),
        _buildOrangeButton('Continue', _nextStep),
      ],
    ),
    );
  }

  Widget _buildVerifyStep() {
    return Column(
      children: [
        // SMS Icon (matching mockup)
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: _otpVerified ? Colors.green : primaryOrange,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _otpVerified ? Icons.check : Icons.sms_outlined,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        
        Text(
          _otpVerified ? 'Verified!' : 'Verify Your Phone',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textLight),
        ),
        const SizedBox(height: 8),
        Text(
          _otpVerified ? 'Your phone is verified' : 'Code sent to +254 ${_phoneController.text}',
          style: const TextStyle(color: textMuted),
          textAlign: TextAlign.center,
        ),
        
        if (!_otpVerified) ...[
          const SizedBox(height: 32),
          
          if (!_otpSent) ...[
            _buildOrangeButton(_isLoading ? 'Sending...' : 'Send OTP', _isLoading ? null : _sendOtp),
          ] else ...[
            // Show generated OTP in compact glass box (auto-hides when typing)
            if (_showOtpCopyBox) ...[
              AnimatedOpacity(
                opacity: _showOtpCopyBox ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryOrange.withOpacity(0.15),
                        primaryOrange.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: primaryOrange.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: primaryOrange.withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.key, color: primaryOrange.withOpacity(0.8), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _generatedOtp,
                        style: const TextStyle(
                          color: primaryOrange,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // 6 individual OTP digit boxes (matching mockup glass style)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => SizedBox(
                width: 48,
                height: 56,
                child: TextField(
                  controller: _otpControllers[i],
                  focusNode: _otpFocusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(color: textLight, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: inputBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryOrange, width: 2),
                    ),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    // Auto-hide OTP copy box when user starts typing
                    if (_showOtpCopyBox && v.isNotEmpty) {
                      setState(() => _showOtpCopyBox = false);
                    }
                    if (v.isNotEmpty && i < 5) {
                      _otpFocusNodes[i + 1].requestFocus();
                    }
                    if (v.isEmpty && i > 0) {
                      _otpFocusNodes[i - 1].requestFocus();
                    }
                  },
                ),
              )),
            ),
            
            const SizedBox(height: 24),
            _buildOrangeButton('Verify', _verifyOtp),
            const SizedBox(height: 16),
            
            // Resend countdown (matching mockup)
            TextButton(
              onPressed: _sendOtp,
              child: const Text('Resend Code in 0:59s', style: TextStyle(color: primaryOrange)),
            ),
          ],
        ] else ...[
          const SizedBox(height: 32),
          _buildOrangeButton('Continue', _nextStep),
        ],
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step indicator text
        Center(
          child: Text(
            'Step 3 of 3',
            style: TextStyle(color: textMuted, fontSize: 14),
          ),
        ),
        const SizedBox(height: 24),
        
        _buildLabel('Password'),
        _buildPasswordField(_passwordController, 'Password'),
        
        // Password strength indicator (matching mockup)
        if (_passwordController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _getPasswordStrength() == 'Strong' ? 1.0 : 
                           _getPasswordStrength() == 'Medium' ? 0.66 :
                           _getPasswordStrength() == 'Fair' ? 0.33 : 0.15,
                    backgroundColor: inputBg,
                    color: _getStrengthColor(),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Strength: ${_getPasswordStrength()}',
                style: TextStyle(color: _getStrengthColor(), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
        
        const SizedBox(height: 20),
        _buildLabel('Confirm Password'),
        _buildPasswordField(_confirmPasswordController, 'Confirm Password'),
        
        const SizedBox(height: 16),
        
        // Checkboxes row (matching mockup layout)
        Row(
          children: [
            // Show password checkbox
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: !_obscurePassword,
                      onChanged: (v) => setState(() => _obscurePassword = !(v ?? false)),
                      activeColor: primaryOrange,
                      checkColor: bgDark,
                      side: const BorderSide(color: textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Show password', style: TextStyle(color: textMuted, fontSize: 12)),
                ],
              ),
            ),
            // Terms checkbox
            Expanded(
              child: Row(
                children: [
                  SizedBox(
                    width: 20, height: 20,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      activeColor: primaryOrange,
                      checkColor: bgDark,
                      side: const BorderSide(color: textMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('I agree to ', style: TextStyle(color: textMuted, fontSize: 12)),
                  const Text('Terms', style: TextStyle(color: primaryOrange, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        _buildOrangeButton(_isLoading ? 'Creating Account...' : 'Create Account', _isLoading ? null : _handleRegister),
        
        const SizedBox(height: 12),
        Center(
          child: Text(
            '8+ chars, uppercase, lowercase, number, symbol',
            style: TextStyle(color: textMuted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textLight)),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hint, TextInputType type, {String? prefix, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark black
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF555555), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        cursorColor: primaryOrange,
        cursorWidth: 2,
        validator: validator,
        style: const TextStyle(
          color: Color(0xFFFFFFFF), 
          fontSize: 16, 
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 15),
          prefixText: prefix != null ? '$prefix  ' : null,
          prefixStyle: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16, fontWeight: FontWeight.w500),
          border: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF8C00), width: 2),
          ),
          errorBorder: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12),
             borderSide: const BorderSide(color: Colors.red, width: 1),
          ),
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A), // Dark black
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryOrange, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        obscureText: _obscurePassword,
        onChanged: (_) => setState(() {}),
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
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildVillageSelector() {
    return GestureDetector(
      onTap: () => _showVillagePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Dark black to match inputs
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF555555), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedVillage ?? 'Select Village',
              style: TextStyle(
                color: _selectedVillage == null ? const Color(0xFF888888) : const Color(0xFFFFFFFF),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: primaryOrange),
          ],
        ),
      ),
    );
  }

  void _showVillagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _VillageSearchSheet(
            villages: _villages,
            onSelect: (village) {
              setState(() => _selectedVillage = village);
              Navigator.pop(ctx);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrangeButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: bgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          disabledBackgroundColor: primaryOrange.withOpacity(0.5),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _VillageSearchSheet extends StatefulWidget {
  final List<String> villages;
  final Function(String) onSelect;

  const _VillageSearchSheet({required this.villages, required this.onSelect});

  @override
  State<_VillageSearchSheet> createState() => _VillageSearchSheetState();
}

class _VillageSearchSheetState extends State<_VillageSearchSheet> {
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color bgDark = Color(0xFF000000);

  final _searchController = TextEditingController();
  List<String> _filteredVillages = [];

  @override
  void initState() {
    super.initState();
    _filteredVillages = widget.villages;
  }

  void _filter(String query) {
    setState(() {
      _filteredVillages = widget.villages
          .where((v) => v.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade700, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 20),
          const Text('Select Village', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          // Search Bar
          TextField(
            controller: _searchController,
            onChanged: _filter,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search village...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Color(0xFFFF8C00)),
              filled: true,
              fillColor: const Color(0xFF1A1A1A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: ListView.separated(
              itemCount: _filteredVillages.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFF333333)),
              itemBuilder: (context, index) {
                final village = _filteredVillages[index];
                return ListTile(
                  title: Text(village, style: const TextStyle(color: Colors.white, fontSize: 16)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  onTap: () => widget.onSelect(village),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrangeButton(String text, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: bgDark,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          disabledBackgroundColor: primaryOrange.withOpacity(0.5),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
