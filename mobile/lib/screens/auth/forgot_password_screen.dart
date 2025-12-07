import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/supabase_service.dart';
import '../../utils/password_generator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Dark Orange Theme Colors
  static const Color bgDark = Color(0xFF000000); // Pure Black
  static const Color cardDark = Color(0xFF2A2A2A);
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color inputBg = Color(0xFF1A1A1A);
  static const Color inputBorder = Color(0xFF555555);

  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  bool _isLoading = false;
  String? _generatedPassword;
  bool _passwordCopied = false;

  @override
  void initState() {
    super.initState();
    _phoneFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _phoneFocusNode.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_phoneController.text.isEmpty || _idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your phone number and ID'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Format phone
    String phone = _phoneController.text;
    if (!phone.startsWith('+254')) {
      phone = '+254$phone';
    }

    // Generate new password
    final newPassword = PasswordGenerator.generate(length: 12);

    // Update in Supabase (with ID verification)
    final result = await SupabaseService.updatePasswordWithVerification(
      phone: phone, 
      idNumber: _idController.text.trim(),
      newPassword: newPassword,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        setState(() {
          _generatedPassword = newPassword;
          _passwordCopied = false;
        });
        _showPasswordDialog(newPassword);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'User not found or verification failed'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showPasswordDialog(String password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: primaryOrange.withOpacity(0.3))),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('Password Reset!', style: TextStyle(color: textLight, fontSize: 20))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Copy this password now! It will not be shown again.',
                style: TextStyle(color: textMuted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: bgDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryOrange.withOpacity(0.5)),
                ),
                child: SelectableText(
                  password,
                  style: const TextStyle(
                    color: primaryOrange,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: password));
                    setDialogState(() => _passwordCopied = true);
                    setState(() => _passwordCopied = true);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password copied!'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
                      );
                    }
                  },
                  icon: Icon(_passwordCopied ? Icons.check : Icons.copy, size: 18),
                  label: Text(_passwordCopied ? 'Copied!' : 'Copy to Clipboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _passwordCopied ? Colors.green : primaryOrange,
                    foregroundColor: bgDark,
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _passwordCopied
                    ? () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardDark,
                  foregroundColor: primaryOrange,
                  side: const BorderSide(color: primaryOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: cardDark.withOpacity(0.5),
                  disabledForegroundColor: textMuted,
                ),
                child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(color: textLight, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textLight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_reset, size: 50, color: primaryOrange),
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textLight),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter your phone number and National ID to verify your identity and generate a new password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: textMuted, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 40),

              // Phone Number
              _buildInputField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                hint: 'Phone Number',
                icon: Icons.phone_android,
                isPhone: true,
                prefixText: '+254',
              ),
              const SizedBox(height: 20),

              // National ID
              _buildInputField(
                controller: _idController,
                hint: 'National ID (Verification)',
                icon: Icons.badge_outlined,
                isPhone: false,
              ),
              const SizedBox(height: 32),

              // Info box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryOrange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: primaryOrange, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'A new strong password will be generated for you instantly.',
                        style: TextStyle(color: primaryOrange, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  icon: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: bgDark, strokeWidth: 2))
                      : const Icon(Icons.vpn_key),
                  label: Text(
                    _isLoading ? 'Verifying & Generating...' : 'Generate New Password',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    foregroundColor: bgDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
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
    FocusNode? focusNode,
    bool isPhone = false,
    String? prefixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: inputBorder),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.number,
        style: const TextStyle(color: textLight, fontSize: 16, fontWeight: FontWeight.w500),
        cursorColor: primaryOrange,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: textMuted),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              Icon(icon, color: primaryOrange, size: 22),
              if (prefixText != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(prefixText, style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold)),
                ),
              ],
              const SizedBox(width: 12),
            ],
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primaryOrange, width: 2),
          ),
        ),
      ),
    );
  }
}
