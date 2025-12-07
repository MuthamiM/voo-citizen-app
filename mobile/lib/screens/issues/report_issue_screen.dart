import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Damaged Roads';
  final List<File> _images = [];
  bool _isSubmitting = false;
  Position? _position;

  final categories = [
    'Damaged Roads', 'Broken Streetlights', 'Water/Sanitation',
    'School Infrastructure', 'Healthcare Facilities', 'Security Concerns', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
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

      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/issues'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${auth.token}',
        },
        body: jsonEncode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'category': _selectedCategory,
          'location': {
            'address': _locationController.text,
            'lat': _position?.latitude,
            'lng': _position?.longitude,
          },
          'images': base64Images,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Issue reported successfully! ✅'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception('Failed to submit');
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
