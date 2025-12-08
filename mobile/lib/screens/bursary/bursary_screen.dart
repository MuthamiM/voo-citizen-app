import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

class BursaryScreen extends StatefulWidget {
  const BursaryScreen({super.key});

  @override
  State<BursaryScreen> createState() => _BursaryScreenState();
}

class _BursaryScreenState extends State<BursaryScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;
  bool _showForm = false;

  // Form controllers
  final _institutionController = TextEditingController();
  final _admissionController = TextEditingController();
  final _courseController = TextEditingController();
  final _yearController = TextEditingController(text: '1');
  final _annualFeesController = TextEditingController();
  // Amount requested removed as per feedback
  final _guardianNameController = TextEditingController();
  
  // New fields
  bool _hasHelb = false;
  bool _hasGoKSponsorship = false;
  final _sponsorshipDetailsController = TextEditingController();
  final _guardianPhoneController = TextEditingController();
  final _reasonController = TextEditingController();
  String _institutionType = 'university';
  String _guardianRelation = 'parent';
  bool _isSubmitting = false;

  final List<String> _institutions = [
    'University of Nairobi',
    'Kenyatta University',
    'Moi University',
    'Jomo Kenyatta University of Agriculture and Technology',
    'Egerton University',
    'Maseno University',
    'Masinde Muliro University of Science and Technology',
    'Dedan Kimathi University of Technology',
    'Technical University of Kenya',
    'Technical University of Mombasa',
    'Pwani University',
    'Kisii University',
    'University of Eldoret',
    'Maasai Mara University',
    'Jaramogi Oginga Odinga University of Science and Technology',
    'Laikipia University',
    'South Eastern Kenya University',
    'Meru University of Science and Technology',
    'Multi-Media University of Kenya',
    'University of Kabianga',
    'Karatina University',
    'Chuka University',
    'Mount Kenya University',
    'Strathmore University',
    'USIU Africa',
    'Daystar University',
    'Catholic University of Eastern Africa',
    'KCA University',
    'Kabarak University',
    'Riara University',
    'Zetech University',
    'Machakos University',
    'Embu University',
    'Kirinyaga University',
    'Muranga University of Technology',
    'Rongo University',
    'Taita Taveta University',
    'Kenya Coast National Polytechnic',
    'Nyeri National Polytechnic',
    'Kisumu National Polytechnic',
    'Eldoret National Polytechnic',
    'Kabete National Polytechnic',
    'Meru National Polytechnic',
    'Nairobi Technical Training Institute',
    'Kenya School of Government',
    'Kenya Medical Training College (KMTC)',
    'Teachers Training College (TTC)',
    'Rift Valley Technical Training Institute',
    'Sigalagala National Polytechnic',
    'Kisii National Polytechnic',
    'Nyeri National Polytechnic',
    'Thika Technical Training Institute',
    'Kiambu Institute of Science and Technology',
    'Machakos Institute of Technology',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApplications();
    });
  }

  Future<void> _loadApplications() async {
    final auth = context.read<AuthService>();
    
    // Get user ID
    final userId = auth.user?['id']?.toString();
    if (userId == null || userId.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final loadedApps = await SupabaseService.getMyBursaryApplications(userId);
      if (mounted) {
        setState(() {
          _applications = loadedApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load applications. Check your connection.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (_institutionController.text.isEmpty || _courseController.text.isEmpty ||
        _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthService>();
      
      // Pack extra details into reason since schema is limited
      final verboseReason = '''
${_reasonController.text}

--- Additional Details ---
Admission: ${_admissionController.text}
Fees: ${_annualFeesController.text}
Guardian: ${_guardianNameController.text} (${_guardianRelation}) - ${_guardianPhoneController.text}
HELB: ${_hasHelb ? 'Yes' : 'No'}
Other Sponsorship: ${_hasGoKSponsorship ? 'Yes' : 'No'} ${_hasGoKSponsorship ? '(${_sponsorshipDetailsController.text})' : ''}
''';

      final result = await SupabaseService.applyForBursary(
        userId: auth.user!['id'],
        institutionName: _institutionController.text,
        institutionType: _institutionType,
        course: _courseController.text,
        yearOfStudy: _yearController.text,
        amountRequested: double.tryParse(_annualFeesController.text.replaceAll(',', '')),
        reason: verboseReason,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
              content: Text('Application submitted successfully! 🎓'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _showForm = false;
            _clearForm();
            _loadApplications(); // Reload list
          });
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to submit application');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
    // amount cleared removed
    _guardianNameController.clear();
    _guardianPhoneController.clear();
    _reasonController.clear();
    setState(() {
      _hasHelb = false;
      _hasGoKSponsorship = false;
      _sponsorshipDetailsController.clear();
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'denied': return Colors.red;
      default: return Colors.orange;
    }
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: const Color(0xFF6366f1), size: 20),
      filled: true,
      fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF6366f1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bursary Applications'),
        backgroundColor: const Color(0xFF1a1a3e),
        actions: [
          if (!_showForm)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _showForm = true),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)]),
        ),
        child: _showForm ? _buildApplicationForm() : _buildApplicationsList(),
      ),
    );
  }

  Widget _buildApplicationsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 80, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('No bursary applications yet', style: TextStyle(color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.add),
              label: const Text('Apply for Bursary'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366f1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _applications.length,
        itemBuilder: (ctx, i) {
          final app = _applications[i];
          return Card(
            color: const Color(0xFF1a1a3e),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        app['applicationNumber'] ?? '',
                        style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(app['status'] ?? '').withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          (app['status'] ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(app['status'] ?? ''),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    app['institutionName'] ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    app['course'] ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (app['status'] == 'approved') 
                        Text(
                          'Approved: KES ${app['amountApproved'] ?? 0}',
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApplicationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _showForm = false),
              ),
              const Text('New Application', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),

          // Institution Section
          const Text('Institution Details', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text == '') {
                return const Iterable<String>.empty();
              }
              return _institutions.where((String option) {
                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
              });
            },
            onSelected: (String selection) {
              _institutionController.text = selection;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              textEditingController.addListener(() {
                 _institutionController.text = textEditingController.text;
              });
              
              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Institution Name (Search or Type) *', Icons.school),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: const Color(0xFF1a1a3e),
                  elevation: 4,
                  child: Container(
                    width: 300,
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return ListTile(
                          title: Text(option, style: const TextStyle(color: Colors.white)),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _institutionType,
                  dropdownColor: const Color(0xFF1a1a3e),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Type', Icons.category),
                  items: const [
                    DropdownMenuItem(value: 'university', child: Text('University')),
                    DropdownMenuItem(value: 'college', child: Text('College')),
                    DropdownMenuItem(value: 'polytechnic', child: Text('Polytechnic')),
                    DropdownMenuItem(value: 'secondary', child: Text('Secondary')),
                  ],
                  onChanged: (v) => setState(() => _institutionType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _admissionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Adm No', Icons.numbers),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _courseController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Course *', Icons.book),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Year', Icons.calendar_today),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Financial Section
          const Text('Financial Details', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _annualFeesController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Annual Fees', Icons.payments),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0f0f23).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text('Do you have HELB Loan?', style: TextStyle(color: Colors.white)),
                  value: _hasHelb,
                  onChanged: (v) => setState(() => _hasHelb = v!),
                  activeColor: const Color(0xFF6366f1),
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Any other GoK Sponsorship?', style: TextStyle(color: Colors.white)),
                  value: _hasGoKSponsorship,
                  onChanged: (v) => setState(() => _hasGoKSponsorship = v!),
                  activeColor: const Color(0xFF6366f1),
                  contentPadding: EdgeInsets.zero,
                ),
                if (_hasGoKSponsorship) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sponsorshipDetailsController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Specify Sponsorship', Icons.description),
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Guardian Section
          const Text('Guardian Details', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _guardianNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Name', Icons.person),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _guardianPhoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Phone', Icons.phone),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _guardianRelation,
            dropdownColor: const Color(0xFF1a1a3e),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Relationship', Icons.family_restroom),
            items: const [
              DropdownMenuItem(value: 'parent', child: Text('Parent')),
              DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
              DropdownMenuItem(value: 'sibling', child: Text('Sibling')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) => setState(() => _guardianRelation = v!),
          ),
          const SizedBox(height: 20),

          // Reason
          const Text('Reason for Application', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          TextField(
            controller: _reasonController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Explain why you need this bursary *', Icons.description),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366f1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit Application', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
