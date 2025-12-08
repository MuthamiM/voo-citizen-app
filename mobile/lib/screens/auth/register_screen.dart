import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/password_generator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _otherVillageController = TextEditingController();
  final _captchaController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  
  bool _acceptedTerms = false;
  String? _selectedVillage;
  String? _generatedPassword;
  bool _passwordCopied = false;
  
  final _villages = [
    'Muthungue', 'Nditime', 'Maskikalini', 'Kamwiu', 'Ituusya', 'Ivitasya',
    'Kyamatu/Nzanzu', 'Nzunguni', 'Kasasi', 'Kaluasi', 'Other'
  ];

  // CAPTCHA State
  late int _num1;
  late int _num2;
  late int _captchaResult;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() => setState(() {}));
    _generateCaptcha();
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _generateCaptcha() {
    setState(() {
      _num1 = DateTime.now().millisecond % 10;
      _num2 = DateTime.now().microsecond % 10;
      _captchaResult = _num1 + _num2;
      _captchaController.clear();
    });
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
                'By accessing and using the VOO Citizen platform, you agree to be bound by these Terms of Service.\n\n'
                '2. USER RESPONSIBILITIES\n'
                'Users are prohibited from submitting false or malicious reports. All information provided must be accurate.\n\n'
                '3. DATA USAGE\n'
                'The Service may access device identifiers and location data for verification purposes.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('Privacy Policy', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'We collect Personal Identifiable Information including National ID and Phone Number. '
                'Data is secured with encryption and may be shared with relevant authorities for issue resolution.',
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

  // Generate password and show dialog
  void _generateAndShowPassword() {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields first'), backgroundColor: Colors.red),
      );
      return;
    }

    final password = PasswordGenerator.generate(length: 12);
    setState(() {
      _generatedPassword = password;
      _passwordCopied = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1a1a3e),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.key, color: Color(0xFF6366f1), size: 28),
              SizedBox(width: 8),
              Text('Your Password', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Copy this password now! It will not be shown again after you close this dialog.',
                style: TextStyle(color: Colors.orange.withOpacity(0.9), fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0f0f23),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366f1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SelectableText(
                      password,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: password));
                    setDialogState(() => _passwordCopied = true);
                    setState(() => _passwordCopied = true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password copied! ✅'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                      );
                    }
                  },
                  icon: Icon(_passwordCopied ? Icons.check : Icons.copy, size: 18),
                  label: Text(_passwordCopied ? 'Copied!' : 'Copy to Clipboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _passwordCopied ? Colors.green : const Color(0xFF6366f1),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _generatedPassword = null);
                Navigator.pop(ctx);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _passwordCopied ? () => Navigator.pop(ctx) : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
              child: const Text('I\'ve Saved It', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    // CAPTCHA Validation
    if (_captchaController.text != _captchaResult.toString()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect CAPTCHA. Please try again.'), backgroundColor: Colors.red),
      );
      _generateCaptcha();
      return;
    }

    // Basic validation
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    // Password generation is REQUIRED
    if (_generatedPassword == null || !_passwordCopied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please generate and copy your password first'), backgroundColor: Colors.orange),
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
    final result = await auth.register(
      _nameController.text,
      _phoneController.text,
      _idController.text,
      _generatedPassword!,
      village: _selectedVillage == 'Other' ? _otherVillageController.text : _selectedVillage,
    );

    if (mounted) {
      if (result['success']) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1a1a3e),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Account Created!', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your account has been created successfully!', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF6366f1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Login with:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Phone: ${_phoneController.text}', style: const TextStyle(color: Colors.white)),
                      const SizedBox(height: 4),
                      const Text('Password: (the one you copied)', style: TextStyle(color: Colors.green)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
                child: const Text('Go to Login', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {Widget? suffix, bool showPrefix = false}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      prefixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12),
          Icon(icon, color: const Color(0xFF6366f1)),
          if (showPrefix) ...[
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
          const SizedBox(width: 12),
        ],
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1a1a3e), Color(0xFF0f0f23)]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white)),
                    const Expanded(child: Text('Sign Up', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white))),
                  ],
                ),
                const SizedBox(height: 20),

                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.location_city, size: 40, color: Color(0xFF6366f1)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2d1b69).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // Name and ID Row
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _nameController, style: const TextStyle(color: Colors.white), textCapitalization: TextCapitalization.words, decoration: _buildInputDecoration('Full Name', Icons.person_outline))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _idController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _buildInputDecoration('National ID', Icons.badge_outlined))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      TextField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Phone Number', Icons.phone_android, showPrefix: _phoneFocusNode.hasFocus || _phoneController.text.isNotEmpty),
                      ),
                      const SizedBox(height: 16),

                      // Village Selection
                      DropdownButtonFormField<String>(
                        value: _selectedVillage,
                        dropdownColor: const Color(0xFF1a1a3e),
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Select Village/Location', Icons.location_on),
                        items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setState(() {
                          _selectedVillage = v;
                          if (v != 'Other') _otherVillageController.clear();
                        }),
                      ),
                      if (_selectedVillage == 'Other') ...[
                        const SizedBox(height: 16),
                        TextField(controller: _otherVillageController, style: const TextStyle(color: Colors.white), textCapitalization: TextCapitalization.words, decoration: _buildInputDecoration('Enter Village Name', Icons.home_work)),
                      ],
                      const SizedBox(height: 16),

                      // Generate Password Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _generatedPassword != null && _passwordCopied ? null : _generateAndShowPassword,
                          icon: Icon(_generatedPassword != null && _passwordCopied ? Icons.check : Icons.key),
                          label: Text(_generatedPassword != null && _passwordCopied ? 'Password Ready ✓' : 'Generate Password'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _generatedPassword != null && _passwordCopied ? Colors.green : const Color(0xFF6366f1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      if (_generatedPassword == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('A strong password will be generated for you', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ),
                      const SizedBox(height: 20),

                      // CAPTCHA
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1a1a3e), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.1))),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: const Color(0xFF6366f1).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text('$_num1 + $_num2 = ?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: TextField(controller: _captchaController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Answer', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none, isDense: true))),
                            IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF6366f1)), onPressed: _generateCaptcha),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Terms
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 24, height: 24, child: Checkbox(value: _acceptedTerms, onChanged: (v) => setState(() => _acceptedTerms = v ?? false), activeColor: const Color(0xFF6366f1), side: BorderSide(color: _acceptedTerms ? const Color(0xFF6366f1) : Colors.orange))),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                children: [
                                  TextSpan(text: 'Terms of Service', style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold), recognizer: TapGestureRecognizer()..onTap = _showTermsDialog),
                                  const TextSpan(text: ' and '),
                                  TextSpan(text: 'Privacy Policy', style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold), recognizer: TapGestureRecognizer()..onTap = _showTermsDialog),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                          child: auth.isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Login Link
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      children: const [TextSpan(text: 'Sign In', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold))],
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
                    Text('Your data is protected', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
