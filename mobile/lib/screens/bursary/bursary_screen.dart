import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/storage_service.dart';

class BursaryScreen extends StatefulWidget {
  const BursaryScreen({super.key});

  @override
  State<BursaryScreen> createState() => _BursaryScreenState();
}

class _BursaryScreenState extends State<BursaryScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  bool _showForm = false;
  int _currentStep = 0;
  bool _isSubmitting = false;
  String _institutionType = 'university';
  String _guardianRelation = 'parent';

  // Theme colors - Matching ReportIssueScreen
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color bgDark = Color(0xFF000000); // Pure Black
  static const Color cardDark = Color(0xFF1C1C1C); // Dark Gray
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color inputBg = Color(0xFF2A2A2A); // Matches ReportIssue

  // Controllers
  final _institutionController = TextEditingController();
  final _admissionController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController();
  final _annualFeesController = TextEditingController();
  final _sponsorshipDetailsController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _reasonController = TextEditingController();
  
  bool _hasHelb = false;
  bool _hasGoKSponsorship = false;
  
  final List<String> _institutions = [
    'University of Nairobi',
    'Kenyatta University',
    'JKUAT',
    'Moi University',
    'Egerton University',
    'Maseno University',
    'Other'
  ];

  @override
  void dispose() {
    _institutionController.dispose();
    _admissionController.dispose();
    _courseController.dispose();
    _yearController.dispose();
    _annualFeesController.dispose();
    _sponsorshipDetailsController.dispose();
    _guardianNameController.dispose();
    _guardianPhoneController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    
    final isOnline = await StorageService.isOnline();
    if (!isOnline) {
       setState(() => _isLoading = false);
       return;
    }

    try {
      final user = Provider.of<AuthService>(context, listen: false).user;
      final userId = user?['id']?.toString();
      
      if (userId != null) {
        final apps = await DashboardService.fetchUserBursaries(userId);
        if (mounted) {
          setState(() {
            _applications = apps;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading bursaries: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitApplication() async {
    if (_institutionController.text.isEmpty || _annualFeesController.text.isEmpty || _courseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Color(0xFFEF4444)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      final userId = user?['id']?.toString() ?? user?['userId']?.toString();
      final phone = user?['phone']?.toString();
      final name = user?['full_name'] ?? user?['fullName'] ?? '';

      await DashboardService.applyForBursary(
        institutionName: _institutionController.text,
        course: _courseController.text,
        yearOfStudy: _yearController.text,
        institutionType: _institutionType,
        reason: _reasonController.text,
        amountRequested: double.tryParse(_annualFeesController.text) ?? 0,
        phoneNumber: phone,
        userId: userId,
        fullName: name,
        hasHelb: _hasHelb,
        hasScholarship: _hasGoKSponsorship,
        feesPerSemester: double.tryParse(_annualFeesController.text) ?? 0,
        admissionNumber: _admissionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Application Submitted Successfully!'), backgroundColor: Color(0xFF10B981)));
        setState(() {
          _showForm = false;
          _currentStep = 0;
          _clearForm();
        });
        _loadApplications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _institutionController.clear();
    _admissionController.clear();
    _courseController.clear();
    _yearController.clear();
    _annualFeesController.clear();
    _sponsorshipDetailsController.clear();
    _guardianNameController.clear();
    _guardianPhoneController.clear();
    _reasonController.clear();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF10B981); // Green
      case 'rejected': return const Color(0xFFEF4444); // Red
      case 'pending': return const Color(0xFFF59E0B); // Orange
      default: return const Color(0xFF888888); // Grey
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Background - Pure Black
          Container(width: size.width, height: size.height, color: bgDark),
          
          // Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _showForm ? setState(() { _showForm = false; _currentStep = 0; }) : Navigator.pop(context),
                        icon: Icon(_showForm ? Icons.arrow_back_ios : Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          _showForm ? 'New Application' : 'Bursary Applications',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (!_showForm)
                        Container(
                          decoration: BoxDecoration(color: cardDark, borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            onPressed: () => setState(() => _showForm = true),
                            icon: const Icon(Icons.add, color: primaryOrange),
                          ),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // Body
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    decoration: const BoxDecoration(
                      color: cardDark, // cardDark
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: _showForm ? _buildApplicationForm() : _buildApplicationsList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Column(
      children: [
        // Numbered Step Indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(4, (i) {
              final isActive = i <= _currentStep;
              return Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: isActive ? primaryOrange : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isActive ? primaryOrange : Colors.grey.shade700, width: 2),
                    ),
                    child: Center(
                      child: isActive 
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : Text('${i + 1}', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (i < 3)
                    Container(
                      width: 40, height: 2,
                      color: i < _currentStep ? primaryOrange : Colors.grey.shade800,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                ],
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(['Applicant Details', 'Financial Info', 'Guardian Details', 'Reason'][_currentStep], 
            style: const TextStyle(color: primaryOrange, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: _buildCurrentStep(),
          ),
        ),
        
        // Buttons
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _prevStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textLight,
                      side: BorderSide(color: Colors.grey.shade700),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentStep < 3 ? _nextStep : (_isSubmitting ? null : _submitApplication),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_currentStep < 3 ? 'Continue' : (_isSubmitting ? 'Submitting...' : 'Submit Amount'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0: return _buildInstitutionStep();
      case 1: return _buildFinancialStep();
      case 2: return _buildGuardianStep();
      case 3: return _buildReasonStep();
      default: return const SizedBox();
    }
  }

  Widget _buildInstitutionStep() {
    final bool isOtherSelected = _institutionController.text == 'Other' || 
        (_institutionController.text.isNotEmpty && !_institutions.contains(_institutionController.text));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownField(
          _institutions, 
          isOtherSelected ? 'Other' : (_institutionController.text.isEmpty ? null : _institutionController.text), 
          (v) {
            if (v == 'Other') {
              setState(() => _institutionController.text = 'Other');
            } else {
              setState(() => _institutionController.text = v ?? '');
            }
          },
          hint: 'Select Institution'
        ),
        const SizedBox(height: 16),
        if (isOtherSelected) ...[
          _buildTextField(
            _institutionController, 
            'Enter your institution name', 
            Icons.edit_outlined
          ),
          const SizedBox(height: 16),
        ],
        // Institution type removed per user request - defaults to 'university'
        _buildTextField(_admissionController, 'Admission Number', Icons.badge_outlined),
        const SizedBox(height: 16),
        _buildTextField(_courseController, 'Course Name', Icons.book_outlined),
        const SizedBox(height: 16),
        _buildTextField(_yearController, 'Year of Study (e.g. 1)', Icons.calendar_today_outlined, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildFinancialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_annualFeesController, 'Annual Fees (KES)', Icons.payments_outlined, keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        _buildSwitch('Do you have HELB Loan?', _hasHelb, (v) => setState(() => _hasHelb = v)),
        _buildSwitch('Any other GoK Sponsorship?', _hasGoKSponsorship, (v) => setState(() => _hasGoKSponsorship = v)),
        if (_hasGoKSponsorship) ...[
          const SizedBox(height: 16),
          _buildTextField(_sponsorshipDetailsController, 'Specify sponsorship', Icons.info_outline),
        ],
      ],
    );
  }

  Widget _buildGuardianStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_guardianNameController, 'Guardian Full Name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_guardianPhoneController, 'Guardian Phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildLabel('Relationship'),
        _buildRelationSelector(),
      ],
    );
  }

  Widget _buildReasonStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: inputBg, // Dark black
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.transparent), // No border style
          ),
          child: TextField(
            controller: _reasonController,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Explain why you need this bursary...',
              hintStyle: TextStyle(color: Colors.grey.shade600),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Be specific about your needs for better chances', style: TextStyle(color: Colors.amber.shade900, fontSize: 13)),
              ),
            ],
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

  // Consistent Styling with ReportIssueScreen
  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: inputBg,
        prefixIcon: Icon(icon, color: primaryOrange, size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryOrange, width: 2)),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, String? value, Function(String?) onChanged, {required String hint}) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: const TextStyle(color: Colors.grey)),
      dropdownColor: cardDark,
      style: const TextStyle(color: textLight),
      icon: const Icon(Icons.keyboard_arrow_down, color: primaryOrange),
      decoration: InputDecoration(
        filled: true,
        fillColor: inputBg,
        prefixIcon: const Icon(Icons.school_outlined, color: primaryOrange, size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: primaryOrange, width: 2)),
      ),
      items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTypeSelector() {
    final types = ['university', 'college', 'polytechnic', 'secondary'];
    final labels = ['Uni', 'College', 'Poly', 'School'];
    return Row(
      children: List.generate(types.length, (i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _institutionType = types[i]),
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _institutionType == types[i] ? primaryOrange : inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _institutionType == types[i] ? primaryOrange : Colors.transparent),
            ),
            child: Text(
              labels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _institutionType == types[i] ? Colors.white : textMuted,
                fontWeight: _institutionType == types[i] ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: inputBg, // Dark black
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: textLight))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildRelationSelector() {
    final relations = ['parent', 'guardian', 'sibling', 'other'];
    final icons = [Icons.family_restroom, Icons.person_outline, Icons.people_outline, Icons.more_horiz];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(relations.length, (i) {
        final isSelected = _guardianRelation == relations[i];
        return GestureDetector(
          onTap: () => setState(() => _guardianRelation = relations[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryOrange : inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? primaryOrange : Colors.transparent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i], color: isSelected ? Colors.white : textMuted, size: 18),
                const SizedBox(width: 8),
                Text(
                  relations[i][0].toUpperCase() + relations[i].substring(1),
                  style: TextStyle(color: isSelected ? Colors.white : textMuted),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildApplicationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryOrange));
    }

    if (_applications.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(color: cardDark, shape: BoxShape.circle),
                child: const Icon(Icons.history_edu, size: 48, color: textMuted),
              ),
              const SizedBox(height: 24),
              const Text('No Applications Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textLight)),
              const SizedBox(height: 8),
              const Text('Your bursary history will appear here.', textAlign: TextAlign.center, style: TextStyle(color: textMuted)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => setState(() => _showForm = true),
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('New Application'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        final status = (app['status'] ?? 'pending').toString().toLowerCase();
        final amountApproved = app['amount_approved'] ?? 0;
        final bool isApproved = status == 'approved';
        
        Color statusColor = Colors.amber;
        if (isApproved) statusColor = Colors.green;
        if (status == 'rejected') statusColor = Colors.red;

        return Card(
          color: cardDark,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              collapsedIconColor: textMuted,
              iconColor: primaryOrange,
              title: Text(
                app['institution_name'] ?? app['school_name'] ?? 'Unknown Institution',
                style: const TextStyle(fontWeight: FontWeight.bold, color: textLight),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(app['created_at']),
                      style: const TextStyle(color: textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.grey),
                      _buildDetailRow('Course', app['course']),
                      _buildDetailRow('Ref Code', app['ref_code'] ?? app['application_number']),
                      _buildDetailRow('Amount Requested', 'KES ${app['amount_requested'] ?? 0}'),
                      if (isApproved) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('APPROVED AMOUNT', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('KES $amountApproved', style: const TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                      if (app['admin_notes'] != null && app['admin_notes'].toString().isNotEmpty) ...[
                         const SizedBox(height: 8),
                         const Text('Note:', style: TextStyle(color: textMuted, fontSize: 12)),
                         Text(app['admin_notes'], style: const TextStyle(color: textLight)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: textMuted, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: textLight, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }
}

