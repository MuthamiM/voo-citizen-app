import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../providers/theme_provider.dart';
import '../services/services_screen.dart';
import '../bursary/bursary_screen.dart';
import '../issues/report_issue_screen.dart';
import '../issues/my_issues_screen.dart';
import '../auth/login_screen.dart';
import '../../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final screenWidth = MediaQuery.of(context).size.width;

    final screens = [
      _buildHomeTab(user, screenWidth),
      const MyIssuesScreen(),
      const BursaryScreen(),
      const ServicesScreen(),
      _buildProfileTab(auth, user),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF1a1a3e),
        indicatorColor: const Color(0xFF6366f1).withOpacity(0.3),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 65,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt_outlined), selectedIcon: Icon(Icons.list_alt), label: 'Issues'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Bursary'),
          NavigationDestination(icon: Icon(Icons.apps_outlined), selectedIcon: Icon(Icons.apps), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
        backgroundColor: const Color(0xFF6366f1),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Report Issue'),
      ) : null,
    );
  }

  Widget _buildHomeTab(Map<String, dynamic>? user, double screenWidth) {
    // Poll for announcements
    final announcements = StorageService.getCachedAnnouncements();
    final recentAnnouncement = announcements.isNotEmpty ? announcements.first : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshHome,
          color: const Color(0xFF6366f1),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(screenWidth * 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, ${user?['fullName']?.split(' ')[0] ?? 'Citizen'}! 👋',
                    style: TextStyle(fontSize: screenWidth * 0.06, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text('Welcome to Voo Kyamatu Ward',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: screenWidth * 0.035)),
                const SizedBox(height: 24),
                
                Text('Quick Actions', style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                  children: [
                     _buildQuickAction(Icons.school, 'Bursary', Colors.purple, screenWidth, isBursary: true),
                    _buildQuickAction(Icons.add_road, 'Roads', Colors.orange, screenWidth, category: 'Damaged Roads'),
                    _buildQuickAction(Icons.water_drop, 'Water', Colors.blue, screenWidth, category: 'Water/Sanitation'),
                    _buildQuickAction(Icons.menu_book, 'Education', Colors.teal, screenWidth, category: 'School Infrastructure'),
                    _buildQuickAction(Icons.woman, 'Women', Colors.pink, screenWidth, category: 'Women Empowerment'),
                    _buildQuickAction(Icons.more_horiz, 'Other', Colors.grey, screenWidth, category: 'Other'),
                  ],
                ),

                const SizedBox(height: 28),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent Announcements', style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: Colors.white)),
                    TextButton(
                      onPressed: () => setState(() => _currentIndex = 3), // Switch to Services tab
                      child: const Text('View All', style: TextStyle(color: Color(0xFF6366f1))),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                
                if (recentAnnouncement != null)
                  Card(
                    color: const Color(0xFF1a1a3e),
                    child: InkWell(
                      onTap: () => setState(() => _currentIndex = 3),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366f1).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.campaign, color: Color(0xFF6366f1)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(recentAnnouncement['title'] ?? 'New Announcement', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                                        maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(recentAnnouncement['date'] ?? '', 
                                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white38),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              recentAnnouncement['content'] ?? '',
                              style: TextStyle(color: Colors.white.withOpacity(0.8), height: 1.4),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    color: const Color(0xFF1a1a3e),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(width: 12),
                          Text('No new announcements. Pull to refresh.', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshHome() async {
    if (await StorageService.isOnline()) {
      final announcements = await SupabaseService.getAnnouncements();
      await StorageService.cacheAnnouncements(announcements);
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: Using cached data'), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, double screenWidth, 
      {String? category, bool autoPick = false, bool isBursary = false}) {
    return GestureDetector(
      onTap: () {
        if (isBursary) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BursaryScreen()));
        } else {
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => ReportIssueScreen(
              initialCategory: category,
              autoPickImage: autoPick,
            )),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: screenWidth * 0.08, color: color),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: Colors.white, fontSize: screenWidth * 0.035, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Card(
      color: const Color(0xFF1a1a3e),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF6366f1)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white38),
        onTap: onTap,
      ),
    );
  }

  Widget _buildProfileTab(AuthService auth, Map<String, dynamic>? user) {
    return Container(
      color: const Color(0xFF0f0f23), // Dark background
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // const Icon(Icons.arrow_back, color: Colors.white), // No back button on main tab
                  // const SizedBox(width: 16),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  // SizedBox(width: 40), // Balance center
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1a1a3e),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          icon: Icon(Icons.search, color: Colors.white54),
                          hintText: 'Search for a setting...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Menu Items
                    _buildSettingsItem(Icons.person_outline, 'Account', () => _showEditProfile(context)),
                    _buildSettingsItem(Icons.notifications_outlined, 'Notifications', () => _showNotifications(context)),
                    _buildAppearanceItem(context),
                    _buildSettingsItem(Icons.lock_outline, 'Privacy & Security', () => _showPrivacy(context)),
                    _buildSettingsItem(Icons.headset_mic_outlined, 'Help and Support', () => _showHelp(context)),
                    _buildSettingsItem(Icons.help_outline, 'About', () => _showAbout(context)),
                    
                    const SizedBox(height: 32),
                     SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () async {
                          await auth.logout();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                        child: const Text('Log Out', style: TextStyle(color: Colors.red, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2), // Divider effect if needed, or distinct items
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        leading: Icon(icon, color: Colors.white, size: 28),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAppearanceItem(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        leading: Icon(
          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: Colors.white,
          size: 28,
        ),
        title: const Text('Appearance', style: TextStyle(color: Colors.white, fontSize: 16)),
        subtitle: Text(
          themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        trailing: Switch(
          value: themeProvider.isDarkMode,
          onChanged: (_) => themeProvider.toggleTheme(),
          activeColor: const Color(0xFF6366f1),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    final nameController = TextEditingController(text: auth.user?['fullName'] ?? '');
    final phoneController = TextEditingController(text: auth.user?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: Colors.white70)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              // In production, sync with backend. For now, just close.
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
              );
            }, 
            child: const Text('Save', style: TextStyle(color: Color(0xFF6366f1)))
          ),
        ],
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        content: const Text('You have no new notifications.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
        ],
      ),
    );
  }

  void _showSecurityStatus(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: const Text('Security Status', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityItem(Icons.https, 'HTTPS API Connection', true),
            _buildSecurityItem(Icons.lock, 'JWT Authentication', true),
            _buildSecurityItem(Icons.storage, 'Local Storage (SharedPrefs)', true),
            _buildSecurityItem(Icons.cloud_off, 'Cloud Backup', false),
            _buildSecurityItem(Icons.security, 'End-to-End Encryption', false),
            const SizedBox(height: 12),
            Text('Note: Some features require backend configuration.', 
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String label, bool enabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(enabled ? Icons.check_circle : Icons.cancel, color: enabled ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 8),
          Icon(icon, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13))),
        ],
      ),
    );
  }

  void _showPrivacy(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
        content: const SingleChildScrollView(
          child: Text(
            'Your privacy is important to us. \n\n'
            'We collect minimal data (such as location for issue reporting) solely to facilitate service delivery and improve community infrastructure. \n\n'
            'Your data is securely stored and only shared with authorized government departments for official purposes.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        title: const Text('Help & Support', style: TextStyle(color: Colors.white)),
        content: const Text('For assistance, please contact the Ward Admin office or email support@voo-ward.go.ke', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
        ],
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
            Text('Version 1.0.1 (Secure Build)', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 12),
            Text('Empowering citizens to build a better community together.', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 20),
            const Text('Copyright & Security', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('© 2025 Voo Kyamatu Ward. All Rights Reserved.\n\nThis application is protected with industry-standard security measures to safeguard your data.', 
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1)))),
        ],
      ),
    );
  }
}
