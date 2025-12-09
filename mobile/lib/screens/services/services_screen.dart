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
    {'name': 'Police Emergency', 'phone': '999', 'icon': Icons.shield_outlined},
    {'name': 'Ambulance', 'phone': '112', 'icon': Icons.medical_services_outlined},
    {'name': 'Fire Brigade', 'phone': '999', 'icon': Icons.local_fire_department_outlined},
    {'name': 'County Office', 'phone': '+254700000000', 'icon': Icons.business_outlined},
  ];
  bool _isLoading = false;

  // Theme colors - Dark Orange Theme
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color bgDark = Color(0xFF1A1A1A);
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color cardBg = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_announcements.isEmpty) setState(() => _isLoading = true);
    
    final isOnline = await StorageService.isOnline();
    
    if (!isOnline) {
      final cachedAnnouncements = StorageService.getCachedAnnouncements();
      if (mounted) {
        setState(() {
          _announcements = cachedAnnouncements;
          _isLoading = false;
        });
        if (_announcements.isEmpty) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline: Showing cached data'), backgroundColor: Color(0xFFF59E0B)),
          );
        }
      }
      return;
    }

    try {
      final announcementsRes = await http.get(Uri.parse('${AuthService.baseUrl}/announcements'));
      // Emergency contacts might be hardcoded or fetched, keeping logic simple
      
      if (announcementsRes.statusCode == 200) {
        final data = jsonDecode(announcementsRes.body)['announcements'] ?? [];
        if (mounted) {
          setState(() {
            _announcements = data;
          });
        }
        StorageService.cacheAnnouncements(data);
      }
    } catch (e) {
      final cached = StorageService.getCachedAnnouncements();
      if (mounted) {
         setState(() {
           _announcements = cached;
         });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Static background decoration
          Positioned(
            top: -40,
            right: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withOpacity(0.4),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Services',
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.w800, 
                          color: Colors.white,
                          letterSpacing: -0.5
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Access government services & info', 
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9), 
                          fontSize: 15
                        )
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A), // cardDark instead of light
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: RefreshIndicator(
                      onRefresh: _loadData,
                      color: primaryOrange,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick Access', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 1.3,
                              children: [
                                _buildServiceCard(Icons.badge_outlined, 'Lost ID', 'Report lost ID', const Color(0xFFEF4444), () => _showLostIdForm(context)),
                                _buildServiceCard(Icons.feedback_outlined, 'Feedback', 'Send suggestions', const Color(0xFF3B82F6), () => _showFeedbackForm(context)),
                                _buildServiceCard(Icons.emergency_outlined, 'Emergency', 'Get instant help', const Color(0xFFF59E0B), () => _showEmergencyContacts(context)),
                                _buildServiceCard(Icons.info_outline, 'About', 'App info', const Color(0xFF8B5CF6), () => _showAbout(context)),
                              ],
                            ),

                            const SizedBox(height: 32),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Emergency Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                TextButton(
                                  onPressed: () => _showEmergencyContacts(context),
                                  child: const Text('View All', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _emergencyContacts.length,
                                itemBuilder: (context, index) {
                                  final c = _emergencyContacts[index];
                                  return Container(
                                    width: 140,
                                    margin: const EdgeInsets.only(right: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF333333),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFF444444)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(c['icon'] ?? Icons.phone, color: const Color(0xFFEF4444), size: 28),
                                        const SizedBox(height: 12),
                                        Text(c['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 16),
                            
                            if (_announcements.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333333),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF444444)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications_off_outlined, color: textMuted.withOpacity(0.5), size: 24),
                                    const SizedBox(width: 16),
                                    const Text('No new announcements', style: TextStyle(color: textMuted, fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              )
                            else
                              ..._announcements.map((a) => Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF333333),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF444444)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                          child: const Icon(Icons.campaign_outlined, color: primaryOrange, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(a['content'] ?? '', style: const TextStyle(color: textMuted, fontSize: 14, height: 1.5)),
                                    if (a['date'] != null) ...[
                                      const SizedBox(height: 12),
                                      Text(a['date'], style: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 12)),
                                    ],
                                  ],
                                ),
                              )),
                              
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF333333),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 24),
            ),
            constSpacer(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: textMuted, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  SizedBox constSpacer({double height = 0}) => SizedBox(height: height);

  // Forms and dialogs with new theme
  void _showLostIdForm(BuildContext context) {
    final idController = TextEditingController();
    final nameController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Report Lost ID', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 8),
            const Text('We will notify you if your ID is found.', style: TextStyle(color: textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            _buildTextField(idController, 'National ID Number', Icons.badge_outlined),
            const SizedBox(height: 16),
            _buildTextField(nameController, 'Full Name on ID', Icons.person_outline),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (idController.text.isEmpty || nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields'), backgroundColor: Color(0xFFEF4444)));
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Color(0xFF10B981)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Submit Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showFeedbackForm(BuildContext context) {
    final messageController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Send Feedback', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 8),
            const Text('Your feedback helps us improve.', style: TextStyle(color: textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            _buildTextField(messageController, 'Your message', Icons.edit_outlined, maxLines: 4),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (messageController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message'), backgroundColor: Color(0xFFEF4444)));
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!'), backgroundColor: Color(0xFF10B981)));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Send Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: maxLines == 1 ? Icon(icon, color: primaryOrange, size: 22) : Container(margin: const EdgeInsets.only(top: 12), alignment: Alignment.topCenter, width: 48, child: Icon(icon, color: primaryOrange, size: 22)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  void _showEmergencyContacts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Text('Emergency Contacts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textDark)),
            const SizedBox(height: 24),
            ..._emergencyContacts.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                  child: Icon(c['icon'], color: const Color(0xFFEF4444)),
                ),
                title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                subtitle: Text(c['phone'], style: const TextStyle(color: textMuted)),
                trailing: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.call, color: Color(0xFF10B981), size: 20),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _callNumber(c['phone']);
                },
              ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('About VOO Citizen', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.1', style: TextStyle(color: textMuted)),
            SizedBox(height: 12),
            Text('Empowering the citizens of Voo Kyamatu Ward with easy access to services and reporting tools.', style: TextStyle(color: textDark, height: 1.5)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text('Close', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w600))
          ),
        ],
      ),
    );
  }

  Future<void> _callNumber(String number) async {
    final Uri launchUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}
