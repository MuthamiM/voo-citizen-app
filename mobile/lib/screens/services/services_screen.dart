import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<dynamic> _announcements = [];
  List<dynamic> _emergencyContacts = [
    {'name': 'Police Emergency', 'phone': '999', 'icon': Icons.shield},
    {'name': 'Ambulance', 'phone': '112', 'icon': Icons.medical_services},
    {'name': 'Fire Brigade', 'phone': '999', 'icon': Icons.local_fire_department},
    {'name': 'County Office', 'phone': '+254700000000', 'icon': Icons.business},
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Only show full screen loader if we have no data
    if (_announcements.isEmpty && _emergencyContacts.length <= 4) {
      setState(() => _isLoading = true);
    }
    
    // Check connectivity
    final isOnline = await StorageService.isOnline();
    
    if (!isOnline) {
      final cachedAnnouncements = StorageService.getCachedAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = cachedAnnouncements;
          _isLoading = false;
        });
        // Only show snackbar if we really need to
        if (_announcements.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are offline. Showing cached data.'), backgroundColor: Colors.orange),
          );
        }
      }
      return;
    }

    try {
      final announcementsRes = await http.get(Uri.parse('${AuthService.baseUrl}/announcements'));
      final contactsRes = await http.get(Uri.parse('${AuthService.baseUrl}/emergency-contacts'));

      if (announcementsRes.statusCode == 200) {
        final data = jsonDecode(announcementsRes.body)['announcements'] ?? [];
        if (mounted) {
          setState(() {
            _announcements = data;
          });
        }
        StorageService.cacheAnnouncements(data);
      }
      if (contactsRes.statusCode == 200) {
        final contacts = jsonDecode(contactsRes.body)['contacts'] ?? [];
        if (contacts.isNotEmpty && mounted) {
          setState(() {
             _emergencyContacts = contacts;
          });
        }
      }
    } catch (e) {
      // Fallback to cache if API fails
      final cached = StorageService.getCachedAnnouncements();
      if (mounted) {
         setState(() {
           _announcements = cached;
         });
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection failed. Showing cached data.'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCallDialog(String name, String phone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: Text('Call $name', style: const TextStyle(color: Colors.white)),
        content: Text('Dial: $phone', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)]),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366f1)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF6366f1),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      const Text('Services', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Access government services & info', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      const SizedBox(height: 16),

                      // Quick Services - Horizontal Row (Compact)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCompactServiceButton(Icons.badge, 'Lost ID', Colors.red, () => _showLostIdForm(context)),
                          _buildCompactServiceButton(Icons.feedback, 'Feedback', Colors.blue, () => _showFeedbackForm(context)),
                          _buildCompactServiceButton(Icons.phone_in_talk, 'Emergency', Colors.orange, () => _showEmergencyContacts(context)),
                          _buildCompactServiceButton(Icons.info, 'About', Colors.purple, () => _showAbout(context)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Emergency Contacts - Compact Horizontal Scroll
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Emergency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          TextButton(
                            onPressed: () => _showEmergencyContacts(context),
                            child: const Text('See All', style: TextStyle(color: Color(0xFF6366f1), fontSize: 12)),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _emergencyContacts.length,
                          itemBuilder: (context, index) {
                            final c = _emergencyContacts[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1a1a3e),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(c['icon'] ?? Icons.phone, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                                      Text(c['phone'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Announcements Section
                      const Text('Announcements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      
                      if (_announcements.isNotEmpty)
                        ..._announcements.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2d1b69).withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366f1).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.campaign, color: Color(0xFF6366f1), size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(a['content'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4)),
                              if (a['date'] != null) ...[
                                const SizedBox(height: 6),
                                Text(a['date'], style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
                              ],
                            ],
                          ),
                        ))
                      else
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2d1b69).withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, color: Color(0xFF6366f1), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('No announcements yet. Pull to refresh.', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCompactServiceButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showLostIdForm(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a3e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Lost ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('You will be notified when your ID is found', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 20),
              TextField(
                controller: idController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'National ID Number *',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.badge, color: Color(0xFF6366f1)),
                  filled: true,
                  fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1))),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Full Name on ID *',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  prefixIcon: const Icon(Icons.person, color: Color(0xFF6366f1)),
                  filled: true,
                  fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1))),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (idController.text.isEmpty || nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lost ID reported! You will be notified when found.'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
                  child: const Text('Submit Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedbackForm(BuildContext context) {
    final messageController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1a1a3e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send Feedback', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Share your feedback, suggestions, or complaints', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 20),
              TextField(
                controller: messageController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Your message *',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                  filled: true,
                  fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366f1))),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (messageController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter your message'), backgroundColor: Colors.red),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366f1)),
                  child: const Text('Submit Feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch $number';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer: $e')),
        );
      }
    }
  }

  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a3e),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            ...(_emergencyContacts).map((c) => ListTile(
              leading: Icon(c['icon'] ?? Icons.phone, color: Colors.red),
              title: Text(c['name'] ?? '', style: const TextStyle(color: Colors.white)),
              subtitle: Text(c['phone'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.6))),
              onTap: () {
                Navigator.pop(ctx);
                _callNumber(c['phone']!);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: const Text('About VOO Citizen', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 12),
            Text('VOO Citizen App helps you report community issues, apply for bursaries, and access government services.',
                style: TextStyle(color: Colors.white.withOpacity(0.7))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
        ],
      ),
    );
  }
}
