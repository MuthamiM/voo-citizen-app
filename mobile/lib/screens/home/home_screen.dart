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
import '../../services/dashboard_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Theme colors - Dark Orange Theme
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color lightOrange = Color(0xFFFFB347);
  static const Color bgDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 6) return Icons.nightlight_round;
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 17) return Icons.wb_sunny_outlined;
    if (hour < 21) return Icons.nights_stay_outlined;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.user;
    final screenWidth = MediaQuery.of(context).size.width;

    final screens = [
      _buildHomeTab(user, screenWidth),
      const MyIssuesScreen(),
      _buildProfileTab(auth, user),
    ];

    return Scaffold(
      backgroundColor: bgDark,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A), // cardDark
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: const Color(0xFF2A2A2A), // cardDark
          indicatorColor: Colors.transparent, // Remove indicator block
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          animationDuration: const Duration(milliseconds: 400),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined, color: textMuted), selectedIcon: Icon(Icons.home, color: primaryOrange), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.list_alt_outlined, color: textMuted), selectedIcon: Icon(Icons.list_alt, color: primaryOrange), label: 'My Reports'),
            NavigationDestination(icon: Icon(Icons.person_outline, color: textMuted), selectedIcon: Icon(Icons.person, color: primaryOrange), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? ScaleTransition(
        scale: _fadeAnim,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
          backgroundColor: primaryOrange,
          icon: const Icon(Icons.add_a_photo, color: Colors.white),
          label: const Text('Report Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ) : null,
    );
  }

  Widget _buildHomeTab(Map<String, dynamic>? user, double screenWidth) {
    final announcements = StorageService.getCachedAnnouncements();
    final recentAnnouncement = announcements.isNotEmpty ? announcements.first : null;
    final size = MediaQuery.of(context).size;
    final firstName = user?['fullName']?.split(' ')[0] ?? user?['email']?.split('@')[0] ?? 'User';

    return Stack(
      children: [
        // Animated background
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: size.width,
          height: size.height,
          color: bgDark,
        ),
        
        // Animated decorative circles
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          top: -40,
          right: -50,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) => Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(scale: value, child: _buildCircle(160, primaryOrange.withOpacity(0.4))),
            ),
          ),
        ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          top: 100,
          left: -40,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) => Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Transform.scale(scale: value, child: _buildCircle(120, lightOrange.withOpacity(0.5))),
            ),
          ),
        ),

        SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            color: primaryOrange,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated greeting
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Row(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) => Transform.rotate(
                              angle: (1 - value) * 0.5,
                              child: Opacity(opacity: value.clamp(0.0, 1.0), child: Icon(_getGreetingIcon(), color: Colors.white, size: 28)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getGreeting()}, $firstName',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    shadows: [Shadow(color: Colors.black.withOpacity(0.1), offset: const Offset(0, 1), blurRadius: 3)],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Welcome back', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Animated white card for Quick Actions
                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A), // cardDark
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textLight)),
                            const SizedBox(height: 16),
                            
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.3,
                              children: [
                                _buildQuickAction(Icons.report_problem_outlined, 'Report Issue', primaryOrange, screenWidth, isReport: true, delay: 0),
                                _buildQuickAction(Icons.list_alt, 'My Issues', const Color(0xFF0EA5E9), screenWidth, isMyIssues: true, delay: 100),
                                _buildQuickAction(Icons.school, 'Bursary', const Color(0xFF9333EA), screenWidth, isBursary: true, delay: 200),
                                _buildQuickAction(Icons.apps, 'Services', const Color(0xFF14B8A6), screenWidth, isServices: true, delay: 300),
                              ],
                            ),

                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Announcements Section
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('Announcements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    height: 200,
                    child: announcements.isEmpty 
                      ? Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFF2A2A2A), borderRadius: BorderRadius.circular(16)),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_none, color: textMuted, size: 30),
                                SizedBox(height: 8),
                                Text('No announcements yet', style: TextStyle(color: textMuted)),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: announcements.length,
                          itemBuilder: (context, index) {
                            final announcement = announcements[index];
                            final date = announcement['created_at'] != null 
                                ? DateTime.parse(announcement['created_at']) 
                                : DateTime.now();
                            final dateStr = '${date.day} ${_getMonth(date.month)}';
                            
                            return Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image area
                                      Container(
                                        height: 110,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                          color: bgDark,
                                          image: announcement['image_url'] != null
                                              ? DecorationImage(
                                                  image: NetworkImage(announcement['image_url']),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: announcement['image_url'] == null 
                                            ? Center(child: Icon(Icons.campaign_outlined, size: 40, color: primaryOrange.withOpacity(0.5)))
                                            : null,
                                      ),
                                      
                                      // Content
                                      Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              announcement['title'] ?? 'Announcement',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              announcement['content'] ?? '',
                                              style: const TextStyle(color: textMuted, fontSize: 13),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Date Badge
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: primaryOrange.withOpacity(0.5)),
                                      ),
                                      child: Text(
                                        dateStr,
                                        style: const TextStyle(color: primaryOrange, fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Future<void> _refreshHome() async {
    if (await StorageService.isOnline()) {
      var announcements = await DashboardService.getAnnouncements();
      if (announcements.isEmpty) {
        announcements = await SupabaseService.getAnnouncements();
      }
      await StorageService.cacheAnnouncements(announcements);
      if (mounted) setState(() {});
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline: Using cached data'), backgroundColor: Color(0xFFF59E0B), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, double screenWidth, 
      {String? category, bool autoPick = false, bool isBursary = false, bool isReport = false, bool isMyIssues = false, bool isServices = false, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: GestureDetector(
            onTap: () {
              if (isBursary) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BursaryScreen()));
              } else if (isReport) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen()));
              } else if (isMyIssues) {
                setState(() => _currentIndex = 1); // Navigate to Issues tab
              } else if (isServices) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ServicesScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReportIssueScreen(initialCategory: category, autoPickImage: autoPick)));
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: textLight, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTab(AuthService auth, Map<String, dynamic>? user) {
    final size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        Container(width: size.width, height: size.height, color: bgDark),
        
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Info
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: const BoxDecoration(color: Color(0xFF333333), shape: BoxShape.circle), // Darker gray bg
                      child: Center(
                        child: Text(
                          (user?['fullName'] ?? 'C')[0].toUpperCase(),
                          style: const TextStyle(color: primaryOrange, fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: primaryOrange, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?['fullName'] ?? user?['email']?.split('@')[0] ?? 'User',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                user?['phone'] ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 32),
              
              // Menu Items
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSettingsItem(Icons.edit_outlined, 'Edit Profile', () => _showEditProfile(context), 0),
                        _buildSettingsItem(Icons.lock_outline, 'Change Password', () {}, 100),
                        _buildSettingsItem(Icons.notifications_outlined, 'Notifications', () => _showNotifications(context), 200),
                        _buildAppearanceItem(context),
                        _buildSettingsItem(Icons.info_outline, 'About', () => _showAbout(context), 300),
                        
                        const SizedBox(height: 40),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () => auth.logout(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryOrange,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Version
                        Center(child: Text('Version 9.5.0', style: TextStyle(color: textMuted.withOpacity(0.5), fontSize: 12))),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap, int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(20 * (1 - value), 0),
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF444444)))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: primaryOrange, size: 22),
              ),
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.chevron_right, color: textMuted),
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceItem(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 550),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(20 * (1 - value), 0),
        child: Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: const Color(0xFF444444)))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: primaryOrange, size: 22),
              ),
              title: const Text('Appearance', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode', style: const TextStyle(color: textMuted, fontSize: 12)),
              trailing: Switch(value: themeProvider.isDarkMode, onChanged: (_) => themeProvider.toggleTheme(), activeColor: primaryOrange),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    final nameController = TextEditingController(text: auth.user?['fullName'] ?? '');
    final phoneController = TextEditingController(text: auth.user?['phone'] ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A), // Dark theme
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF555555), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 24),
              _buildDialogField(nameController, 'Full Name', Icons.person_outline),
              const SizedBox(height: 16),
              _buildDialogField(phoneController, 'Phone Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving ? null : () async {
                        setState(() => isSaving = true);
                        final result = await auth.updateProfile(fullName: nameController.text, phone: phoneController.text);
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['success'] ? 'Profile updated!' : result['error']), backgroundColor: result['success'] ? const Color(0xFF4CAF50) : const Color(0xFFEF4444), behavior: SnackBarBehavior.floating),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF555555))),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        cursorColor: primaryOrange,
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(color: Color(0xFF666666)),
          prefixIcon: Icon(icon, color: primaryOrange, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) => _showSimpleDialog(context, 'Notifications', 'You have no new notifications.');
  void _showPrivacy(BuildContext context) => _showSimpleDialog(context, 'Privacy & Security', 'Your privacy is important. We collect minimal data only for service delivery.');
  void _showHelp(BuildContext context) => _showSimpleDialog(context, 'Help & Support', 'Contact the Ward Admin office or email support@voo-ward.go.ke');
  void _showAbout(BuildContext context) => _showSimpleDialog(context, 'About VOO Citizen', 'Version 1.0.1\n\nEmpowering citizens.\n\n© 2025 Voo Kyamatu Ward');

  void _showSimpleDialog(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A), // Dark theme
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFF555555), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 16),
            Text(content, style: const TextStyle(color: textMuted, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: primaryOrange, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A), // Dark theme
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 28),
                SizedBox(width: 12),
                Text('Delete Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Are you sure you want to delete your account? This action cannot be undone.',
              style: TextStyle(color: textMuted, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text(
              '• All your reported issues will be kept for record\n• Your bursary applications will remain in the system\n• You will need to register again to use the app',
              style: TextStyle(color: textMuted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      // Delete account
                      final result = await auth.deleteAccount();
                      if (mounted) {
                        if (result['success'] == true) {
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account deleted successfully'), backgroundColor: Color(0xFF10B981)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['error'] ?? 'Failed to delete account'), backgroundColor: const Color(0xFFEF4444)),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
