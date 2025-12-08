import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';

class ReportIssueScreen extends StatefulWidget {
  final String? initialCategory;
  final bool autoPickImage;
  
  const ReportIssueScreen({super.key, this.initialCategory, this.autoPickImage = false});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _specifyIssueController = TextEditingController();
  late String _selectedCategory;
  final List<File> _images = [];
  bool _isSubmitting = false;
  Position? _position;

  // Theme colors
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color bgPink = Color(0xFFF9C5C1);
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);

  final categories = [
    'Damaged Roads',
    'Water/Sanitation', 
    'School Infrastructure', 
    'Healthcare Facilities', 
    'Security Concerns',
    'Broken Streetlights',
    'Women Empowerment',
    'Other'
  ];
  
  String? _selectedVillage;
  final _villages = [
    'Muthungue', 'Nditime', 'Maskikalini', 'Kamwiu', 'Ituusya', 'Ivitasya',
    'Kyamatu/Nzanzu', 'Nzunguni', 'Kasasi', 'Kaluasi', 'Other'
  ];
  String _customVillage = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Damaged Roads';
    _getLocation();
    if (widget.autoPickImage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showImageSourceDialog());
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Add Photo', style: TextStyle(color: textDark, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_outlined, 'Camera', ImageSource.camera),
                _buildSourceOption(Icons.photo_library_outlined, 'Gallery', ImageSource.gallery),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _pickImage(source);
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryPink.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryPink, size: 30),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: textDark, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _position = position;
      _locationController.text = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    });
  }

  Future<void> _submitIssue() async {
    if (_titleController.text.isEmpty || _selectedVillage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthService>();
      final user = auth.user;
      final userId = user?['id']?.toString() ?? 'anonymous';
      
      List<String> base64Images = [];
      for (var image in _images) {
        List<int> imageBytes = await image.readAsBytes();
        String base64Image = base64Encode(imageBytes);
        base64Images.add('data:image/jpeg;base64,$base64Image');
      }

      await DashboardService.submitMobileIssue(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory == 'Women Empowerment' ? 'Women Empowerment' : 
                 (_selectedCategory == 'Other' ? _specifyIssueController.text : _selectedCategory),
        location: _selectedVillage == 'Other' ? _customVillage : _selectedVillage!,
        images: base64Images,
        phoneNumber: user?['phone'] ?? '',
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Issue reported successfully!'), backgroundColor: Color(0xFF10B981)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      appBar: AppBar(
        title: const Text('Report Issue', style: TextStyle(color: textDark, fontWeight: FontWeight.w700)),
        backgroundColor: bgPink,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text('Issue Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 24),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: Colors.white,
              decoration: _inputDecoration('Category', Icons.category_outlined),
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: textDark)))).toList(),
              onChanged: (v) => setState(() => _selectedCategory = v!),
            ),
            
            if (_selectedCategory == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _specifyIssueController,
                decoration: _inputDecoration('Specify Issue', Icons.edit_outlined),
                style: const TextStyle(color: textDark),
              ),
            ],

            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: _inputDecoration('Title (e.g., Deep Pothole)', Icons.title),
              style: const TextStyle(color: textDark),
            ),

            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _inputDecoration('Description', Icons.description_outlined),
              style: const TextStyle(color: textDark),
            ),

            const SizedBox(height: 24),
            const Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 16),

            // Village Dropdown
            DropdownButtonFormField<String>(
              value: _selectedVillage,
              dropdownColor: Colors.white,
              decoration: _inputDecoration('Select Village', Icons.location_city),
              items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(color: textDark)))).toList(),
              onChanged: (v) => setState(() => _selectedVillage = v),
            ),

            if (_selectedVillage == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => _customVillage = v,
                decoration: _inputDecoration('Enter Village Name', Icons.add_home_work_outlined),
                style: const TextStyle(color: textDark),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // GPS Location
            TextField(
              controller: _locationController,
              readOnly: true,
              decoration: _inputDecoration('GPS Coordinates', Icons.gps_fixed).copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.my_location, color: primaryPink),
                  onPressed: _getLocation,
                ),
              ),
              style: const TextStyle(color: textDark),
            ),

            const SizedBox(height: 24),
            const Text('Photos (Evidence)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 16),

            // Image Picker
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      width: 100,
                      decoration: BoxDecoration(
                        color: primaryPink.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryPink.withOpacity(0.3), width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_outlined, color: primaryPink, size: 28),
                          const SizedBox(height: 4),
                          Text('Add', style: TextStyle(color: primaryPink.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  ..._images.map((img) => Stack(
                    children: [
                      Container(
                        width: 100,
                        margin: const EdgeInsets.only(left: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(image: FileImage(img), fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() => _images.remove(img)),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.close, size: 14, color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: primaryPink.withOpacity(0.3),
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: textMuted),
      prefixIcon: Icon(icon, color: primaryPink, size: 22),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryPink, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
