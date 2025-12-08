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

  // Theme colors
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color lightPink = Color(0xFFF5ADA7);
  static const Color bgPink = Color(0xFFF9C5C1);
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);

  // Form controllers
  final _institutionController = TextEditingController();
  final _admissionController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController(text: '1');
  final _annualFeesController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _reasonController = TextEditingController();
  final _sponsorshipDetailsController = TextEditingController();
  
  bool _hasHelb = false;
  bool _hasGoKSponsorship = false;
  String _institutionType = 'university';
  String _guardianRelation = 'parent';

  final List<String> _institutions = [
    'University of Nairobi', 'Kenyatta University', 'Moi University',
    'Jomo Kenyatta University', 'Egerton University', 'Maseno University',
    'Technical University of Kenya', 'Mt Kenya University', 'Strathmore University',
    'USIU Africa', 'KCA University', 'Machakos University', 'KMTC', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadApplications());
  }

  Future<void> _loadApplications() async {
    final auth = context.read<AuthService>();
    final userId = auth.user?['id']?.toString();
    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final cachedApps = StorageService.getCachedBursaries();
    if (cachedApps.isNotEmpty && mounted) {
      setState(() { _applications = cachedApps; _isLoading = false; });
    }

    try {
      if (await StorageService.isOnline()) {
        var loadedApps = await DashboardService.getMyBursaryApplications();
        if (loadedApps.isEmpty && userId.isNotEmpty) {
          loadedApps = await SupabaseService.getMyBursaryApplications(userId);
        }
        if (mounted) {
          setState(() { _applications = loadedApps; _isLoading = false; });
          await StorageService.cacheBursaries(loadedApps);
        }
      }
    } catch (e) {
      if (mounted && _applications.isEmpty) setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep < 3) setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  Future<void> _submitApplication() async {
    if (_institutionController.text.isEmpty || _courseController.text.isEmpty || _reasonController.text.isEmpty) {
      _showError('Please fill all required fields');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthService>();
      final verboseReason = '''
${_reasonController.text}

Additional Details:
Admission: ${_admissionController.text}
Fees: ${_annualFeesController.text}
Guardian: ${_guardianNameController.text} (${_guardianRelation}) - ${_guardianPhoneController.text}
HELB: ${_hasHelb ? 'Yes' : 'No'}
Other Sponsorship: ${_hasGoKSponsorship ? 'Yes' : 'No'} ${_hasGoKSponsorship ? '(${_sponsorshipDetailsController.text})' : ''}
''';

      var result = await DashboardService.applyForBursary(
        institutionName: _institutionController.text,
        course: _courseController.text,
        yearOfStudy: _yearController.text,
        institutionType: _institutionType,
        reason: verboseReason,
        amountRequested: double.tryParse(_annualFeesController.text.replaceAll(',', '')),
      );
      
      if (result['success'] != true && auth.user != null) {
        result = await SupabaseService.applyForBursary(
          userId: auth.user!['id'],
          institutionName: _institutionController.text,
          institutionType: _institutionType,
          course: _courseController.text,
          yearOfStudy: _yearController.text,
          amountRequested: double.tryParse(_annualFeesController.text.replaceAll(',', '')),
          reason: verboseReason,
        );
      }

      if (result['success'] == true) {
        _showSuccess('Application submitted!');
        setState(() { _showForm = false; _currentStep = 0; _clearForm(); _loadApplications(); });
      } else {
        throw Exception(result['error'] ?? 'Failed to submit');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _institutionController.clear();
    _admissionController.clear();
    _courseController.clear();
    _yearController.text = '1';
    _annualFeesController.clear();
    _guardianNameController.clear();
    _guardianPhoneController.clear();
    _reasonController.clear();
    _sponsorshipDetailsController.clear();
    _hasHelb = false;
    _hasGoKSponsorship = false;
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF4CAF50);
      case 'denied': return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
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
          Positioned(top: -40, right: -60, child: _buildCircle(180, primaryPink.withOpacity(0.4))),
          Positioned(top: 120, left: -40, child: _buildCircle(120, lightPink.withOpacity(0.5))),

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
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: IconButton(
                            onPressed: () => setState(() => _showForm = true),
                            icon: const Icon(Icons.add, color: primaryPink),
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
                      color: Colors.white,
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

  Widget _buildCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _buildApplicationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: primaryPink));
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
                decoration: BoxDecoration(color: bgPink, shape: BoxShape.circle),
                child: const Icon(Icons.school_outlined, size: 50, color: primaryPink),
              ),
              const SizedBox(height: 24),
              const Text('No Applications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textDark)),
              const SizedBox(height: 8),
              Text('Apply for a bursary to fund your education', style: TextStyle(color: textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => setState(() => _showForm = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Apply Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: primaryPink,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _applications.length,
        itemBuilder: (ctx, i) {
          final app = _applications[i];
          final status = (app['status'] ?? 'pending').toString().toLowerCase();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(app['applicationNumber'] ?? '#${i + 1}', style: const TextStyle(color: primaryPink, fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(status.toUpperCase(), style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(app['institutionName'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textDark)),
                const SizedBox(height: 4),
                Text(app['course'] ?? '', style: TextStyle(color: textMuted)),
                if (status == 'approved') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                        const SizedBox(width: 6),
                        Text('Approved: KES ${app['amountApproved'] ?? 0}', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationForm() {
    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: List.generate(4, (i) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: i <= _currentStep ? primaryPink : Colors.grey.shade200,
                ),
              ),
            )),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(['Institution', 'Financial', 'Guardian', 'Reason'][_currentStep], style: TextStyle(color: textMuted, fontSize: 13)),
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
                      foregroundColor: textDark,
                      side: BorderSide(color: Colors.grey.shade300),
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
                    backgroundColor: primaryPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_currentStep < 3 ? 'Next' : (_isSubmitting ? 'Submitting...' : 'Submit'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Institution'),
        _buildDropdownField(_institutions, _institutionController.text.isEmpty ? null : _institutionController.text, (v) => _institutionController.text = v ?? ''),
        const SizedBox(height: 16),
        _buildLabel('Type'),
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildLabel('Admission Number'),
        _buildTextField(_admissionController, 'Enter admission no.', Icons.badge_outlined),
        const SizedBox(height: 16),
        _buildLabel('Course'),
        _buildTextField(_courseController, 'Enter course name', Icons.book_outlined),
        const SizedBox(height: 16),
        _buildLabel('Year of Study'),
        _buildTextField(_yearController, '1', Icons.calendar_today_outlined, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _buildFinancialStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Annual Fees (KES)'),
        _buildTextField(_annualFeesController, 'Enter amount', Icons.payments_outlined, keyboardType: TextInputType.number),
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
        _buildLabel('Guardian Name'),
        _buildTextField(_guardianNameController, 'Enter full name', Icons.person_outline),
        const SizedBox(height: 16),
        _buildLabel('Guardian Phone'),
        _buildTextField(_guardianPhoneController, 'Enter phone', Icons.phone_outlined, keyboardType: TextInputType.phone),
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
        _buildLabel('Why do you need this bursary?'),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: _reasonController,
            maxLines: 6,
            style: const TextStyle(color: textDark),
            decoration: InputDecoration(
              hintText: 'Explain your situation...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
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
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textDark)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: primaryPink, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, String? value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text('Select institution', style: TextStyle(color: Colors.grey.shade400)),
        icon: const Icon(Icons.keyboard_arrow_down, color: primaryPink),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.school_outlined, color: primaryPink, size: 22),
          prefixIconConstraints: BoxConstraints(minWidth: 40),
          border: InputBorder.none,
        ),
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: _institutionType == types[i] ? primaryPink : const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _institutionType == types[i] ? primaryPink : Colors.grey.shade200),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: textDark))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryPink,
          ),
        ],
      ),
    );
  }

  Widget _buildRelationSelector() {
    final relations = ['parent', 'guardian', 'sibling', 'other'];
    final icons = [Icons.family_restroom, Icons.person_outline, Icons.people_outline, Icons.more_horiz];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(relations.length, (i) => GestureDetector(
        onTap: () => setState(() => _guardianRelation = relations[i]),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _guardianRelation == relations[i] ? primaryPink : const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _guardianRelation == relations[i] ? primaryPink : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icons[i], color: _guardianRelation == relations[i] ? Colors.white : textMuted, size: 18),
              const SizedBox(width: 6),
              Text(
                relations[i][0].toUpperCase() + relations[i].substring(1),
                style: TextStyle(color: _guardianRelation == relations[i] ? Colors.white : textMuted),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
