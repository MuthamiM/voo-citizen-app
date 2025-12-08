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

  // Theme colors
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color lightPink = Color(0xFFF5ADA7);
  static const Color bgPink = Color(0xFFF9C5C1);
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);

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
      const BursaryScreen(),
      const ServicesScreen(),
      _buildProfileTab(auth, user),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          indicatorColor: primaryPink.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          animationDuration: const Duration(milliseconds: 400),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined, color: textMuted), selectedIcon: Icon(Icons.home, color: primaryPink), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.list_alt_outlined, color: textMuted), selectedIcon: Icon(Icons.list_alt, color: primaryPink), label: 'Issues'),
            NavigationDestination(icon: Icon(Icons.school_outlined, color: textMuted), selectedIcon: Icon(Icons.school, color: primaryPink), label: 'Bursary'),
            NavigationDestination(icon: Icon(Icons.apps_outlined, color: textMuted), selectedIcon: Icon(Icons.apps, color: primaryPink), label: 'Services'),
            NavigationDestination(icon: Icon(Icons.person_outline, color: textMuted), selectedIcon: Icon(Icons.person, color: primaryPink), label: 'Profile'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? ScaleTransition(
        scale: _fadeAnim,
        child: FloatingActionButton.extended(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
          backgroundColor: primaryPink,
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
    final firstName = user?['fullName']?.split(' ')[0] ?? 'Citizen';

    return Stack(
      children: [
        // Animated background
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          width: size.width,
          height: size.height,
          color: bgPink,
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
              opacity: value,
              child: Transform.scale(scale: value, child: _buildCircle(160, primaryPink.withOpacity(0.4))),
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
              opacity: value,
              child: Transform.scale(scale: value, child: _buildCircle(120, lightPink.withOpacity(0.5))),
            ),
          ),
        ),

        SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshHome,
            color: primaryPink,
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
                              child: Opacity(opacity: value, child: Icon(_getGreetingIcon(), color: Colors.white, size: 28)),
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
                                Text('Welcome to Voo Kyamatu Ward', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark)),
                            const SizedBox(height: 16),
                            
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.9,
                              children: [
                                _buildQuickAction(Icons.school, 'Bursary', const Color(0xFF9333EA), screenWidth, isBursary: true, delay: 0),
                                _buildQuickAction(Icons.add_road, 'Roads', const Color(0xFFF97316), screenWidth, category: 'Damaged Roads', delay: 100),
                                _buildQuickAction(Icons.water_drop, 'Water', const Color(0xFF0EA5E9), screenWidth, category: 'Water/Sanitation', delay: 200),
                                _buildQuickAction(Icons.menu_book, 'Education', const Color(0xFF14B8A6), screenWidth, category: 'School Infrastructure', delay: 300),
                                _buildQuickAction(Icons.woman, 'Women', const Color(0xFFEC4899), screenWidth, category: 'Women Empowerment', delay: 400),
                                _buildQuickAction(Icons.more_horiz, 'Other', const Color(0xFF6B7280), screenWidth, category: 'Other', delay: 500),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Animated Announcements section
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Announcements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark)),
                                  TextButton(
                                    onPressed: () => setState(() => _currentIndex = 3),
                                    child: const Text('View All', style: TextStyle(color: primaryPink, fontWeight: FontWeight.w500)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              if (recentAnnouncement != null)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(16)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: primaryPink.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                                        child: const Icon(Icons.campaign, color: primaryPink, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(recentAnnouncement['title'] ?? 'New Announcement', style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                                            const SizedBox(height: 4),
                                            Text(recentAnnouncement['content'] ?? '', style: const TextStyle(color: textMuted, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, size: 16, color: textMuted),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(16)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.notifications_off_outlined, color: textMuted.withOpacity(0.5)),
                                      const SizedBox(width: 10),
                                      Text('No announcements. Pull to refresh.', style: TextStyle(color: textMuted.withOpacity(0.7))),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
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
      {String? category, bool autoPick = false, bool isBursary = false, int delay = 0}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(
          opacity: value,
          child: GestureDetector(
            onTap: () {
              if (isBursary) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BursaryScreen()));
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
                  Text(label, style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w500)),
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
        Container(width: size.width, height: size.height, color: bgPink),
        Positioned(top: -30, right: -40, child: _buildCircle(140, primaryPink.withOpacity(0.4))),
        
        SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
              
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Profile card with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 500),
                          builder: (context, value, child) => Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(16)),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56, height: 56,
                                      decoration: const BoxDecoration(color: primaryPink, shape: BoxShape.circle),
                                      child: Center(
                                        child: Text(
                                          (user?['fullName'] ?? 'C')[0].toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(user?['fullName'] ?? 'Citizen', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: textDark)),
                                          Text(user?['phone'] ?? '', style: const TextStyle(color: textMuted, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                    IconButton(onPressed: () => _showEditProfile(context), icon: const Icon(Icons.edit_outlined, color: primaryPink)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildSettingsItem(Icons.person_outline, 'Account', () => _showEditProfile(context), 0),
                        _buildSettingsItem(Icons.notifications_outlined, 'Notifications', () => _showNotifications(context), 100),
                        _buildAppearanceItem(context),
                        _buildSettingsItem(Icons.lock_outline, 'Privacy & Security', () => _showPrivacy(context), 200),
                        _buildSettingsItem(Icons.headset_mic_outlined, 'Help and Support', () => _showHelp(context), 300),
                        _buildSettingsItem(Icons.info_outline, 'About', () => _showAbout(context), 400),
                        
                        const SizedBox(height: 32),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  await auth.logout();
                                  if (mounted) {
                                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                        ),
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
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryPink.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: primaryPink, size: 22),
              ),
              title: Text(title, style: const TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w500)),
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
          opacity: value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryPink.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode, color: primaryPink, size: 22),
              ),
              title: const Text('Appearance', style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w500)),
              subtitle: Text(themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode', style: const TextStyle(color: textMuted, fontSize: 12)),
              trailing: Switch(value: themeProvider.isDarkMode, onChanged: (_) => themeProvider.toggleTheme(), activeColor: primaryPink),
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
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Edit Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textDark)),
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
                      style: ElevatedButton.styleFrom(backgroundColor: primaryPink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
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
      decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.grey.shade200)),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: textDark),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: primaryPink, size: 22),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textDark)),
            const SizedBox(height: 16),
            Text(content, style: const TextStyle(color: textMuted, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(backgroundColor: primaryPink, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
