import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';

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
      backgroundColor: const Color(0xFF1a1a3e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Photo', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt, 'Camera', ImageSource.camera),
                _buildSourceOption(Icons.photo_library, 'Gallery', ImageSource.gallery),
              ],
            ),
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
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF6366f1).withOpacity(0.2),
            child: Icon(icon, color: const Color(0xFF6366f1), size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      _position = await Geolocator.getCurrentPosition();
    } catch (e) {
      debugPrint('Location error: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null && _images.length < 5) {
      setState(() => _images.add(File(picked.path)));
    }
  }

  Future<void> _submitIssue() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in title and description'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthService>();
      final List<String> base64Images = [];
      
      for (final img in _images) {
        final bytes = await img.readAsBytes();
        base64Images.add(base64Encode(bytes));
      }

      final result = await SupabaseService.createIssue(
        userId: auth.user!['id'],
        userPhone: auth.user!['phone'] ?? 'N/A', // Handle missing phone for Google users
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory == 'Other' ? _specifyIssueController.text : _selectedCategory,
        images: base64Images,
        location: {
          'address': _locationController.text,
          'lat': _position?.latitude,
          'lng': _position?.longitude,
        },
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Issue reported successfully! ✅'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(result['error'] ?? 'Failed to submit');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)]),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Images
              const Text('Photos (tap to add)', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._images.map((img) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(img, width: 100, height: 100, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4, right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.remove(img)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (_images.length < 5) ...[
                      _addPhotoButton(Icons.camera_alt, 'Camera', () => _pickImage(ImageSource.camera)),
                      _addPhotoButton(Icons.photo_library, 'Gallery', () => _pickImage(ImageSource.gallery)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Issue Title', hintStyle: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: const Color(0xFF1a1a3e),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              if (_selectedCategory == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _specifyIssueController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Specify Issue',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Village Selection
              DropdownButtonFormField<String>(
                value: _selectedVillage,
                dropdownColor: const Color(0xFF1a1a3e),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Select Village'),
                items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _selectedVillage = v),
              ),
              if (_selectedVillage == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Enter your village name',
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  onChanged: (v) => _customVillage = v,
                ),
              ],
              const SizedBox(height: 16),

              TextField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Describe the issue...', hintStyle: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _locationController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Location (optional)',
                  hintStyle: const TextStyle(color: Colors.white54),
                  suffixIcon: _position != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.location_searching, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitIssue,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addPhotoButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100, height: 100,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2d1b69).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF6366f1), size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
