// lib/screens/issues/report_issue_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController(); // Manual location input for now

  bool _isLoading = false;
  String _selectedCategory = 'Roads';
  String _selectedVillage = 'Select Village';
  
  final List<String> _categories = [
    'Roads',
    'Water',
    'Electricity',
    'Waste Management',
    'Public Safety',
    'Other'
  ];
  final List<String> _villages = [
    'Ndili', 'Katulani', 'Kyamatu', 'Nzunguni', 'Wikililye',
    'Mbiuni', 'Kasikeu', 'Kwa Munyao', 'Miandani', 'Nguutani', 'Other'
  ];

  // Image Upload Logic
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _selectedImages = [];
  final List<String> _base64Images = [];

  // Theme colors
  static const Color bg = Color(0xFF000000); // Pure Black
  static const Color cardBg = Color(0xFF1C1C1C); // Dark Gray Card
  static const Color accent = Color(0xFFFF8C00); // Orange
  static const Color fieldBg = Color(0xFF2A2A2A); // Input BG

  Future<void> _showPicker(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Gallery', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: const Text('Camera', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 5 images allowed')),
      );
      return;
    }
    
    try {
      final XFile? image = await _picker.pickImage(
        source: source, 
        imageQuality: 50, 
        maxWidth: 1024, 
        maxHeight: 1024
      );
      
      if (image != null) {
        final file = File(image.path);
        // Check size: 5MB = 5 * 1024 * 1024 bytes
        if (await file.length() > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image is too large (Max 5MB)')),
          );
          }
          return;
        }

        final bytes = await file.readAsBytes();
        final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}'; // Data URI format
        
        setState(() {
          _selectedImages.add(image);
          _base64Images.add(base64);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _base64Images.removeAt(index);
    });
  }

  Future<void> _submitIssue() async {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Title and Description')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.user;
      
      // Fallback location if empty
      final location = _locationController.text.isNotEmpty 
          ? '$_selectedVillage - ${_locationController.text}' 
          : _selectedVillage;

      final result = await DashboardService.submitMobileIssue(
        phoneNumber: user?['phone'] ?? user?['phoneNumber'] ?? '0000000000',
        title: _titleController.text,
        category: _selectedCategory,
        description: _descController.text,
        location: location,
        images: _base64Images,
        userId: user?['id']?.toString(),
        fullName: user?['fullName'] ?? 'Citizen',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Success', style: TextStyle(color: Colors.white)),
            content: const Text('Issue submitted successfully! We will review it shortly.', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to Home
                },
                child: const Text('OK', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              )
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Submission failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration({required String hint, Widget? prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: fieldBg,
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Report Issue', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: accent))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Issue Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DETAILS', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // Category
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: cardBg,
                        decoration: _fieldDecoration(
                          hint: 'Category',
                          prefix: const Icon(Icons.category_outlined, color: accent),
                        ),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration(
                          hint: 'Issue Title (e.g. Deep Pothole)',
                          prefix: const Icon(Icons.title, color: accent),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 4,
                        decoration: _fieldDecoration(
                          hint: 'Describe the issue in detail...',
                          prefix: const Icon(Icons.description_outlined, color: accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Location Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LOCATION', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      
                      // Village
                      DropdownButtonFormField<String>(
                        value: _selectedVillage,
                        dropdownColor: cardBg,
                        decoration: _fieldDecoration(
                          hint: 'Select Village',
                          prefix: const Icon(Icons.location_on_outlined, color: accent),
                        ),
                        items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: Colors.white)))).toList(),
                        onChanged: (v) => setState(() => _selectedVillage = v!),
                      ),
                      const SizedBox(height: 16),

                      // Specific Location
                      TextField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDecoration(
                          hint: 'Specific Location/Landmark',
                          prefix: const Icon(Icons.add_location_alt_outlined, color: accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Photos Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PHOTOS (Max 5)', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${_selectedImages.length}/5', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // Add Button
                            GestureDetector(
                              onTap: () => _showPicker(context),
                              child: Container(
                                width: 80, height: 80,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: fieldBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: accent.withOpacity(0.5), style: BorderStyle.solid),
                                ),
                                child: const Icon(Icons.add_a_photo, color: accent),
                              ),
                            ),
                            
                            // Image List
                            ..._selectedImages.asMap().entries.map((entry) {
                              final index = entry.key;
                              final file = entry.value;
                              return Stack(
                                children: [
                                  Container(
                                    width: 80, height: 80,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(image: FileImage(File(file.path)), fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0, right: 12,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Submit Button
                ElevatedButton(
                  onPressed: _submitIssue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: const Text('SUBMIT REPORT', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
