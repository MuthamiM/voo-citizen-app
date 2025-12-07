import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../issues/report_issue_screen.dart';
import '../issues/my_issues_screen.dart';

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

    final screens = [
      _buildHomeTab(user),
      const MyIssuesScreen(),
      _buildProfileTab(auth, user),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF1a1a3e),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'My Issues'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
        backgroundColor: const Color(0xFF6366f1),
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Report Issue'),
      ),
    );
  }

  Widget _buildHomeTab(Map<String, dynamic>? user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${user?['fullName']?.split(' ')[0] ?? 'Citizen'}! 👋',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              Text('Report issues in your community',
                  style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 32),
              
              // Stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF4c1d95)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Issues Reported', '${user?['issuesReported'] ?? 0}'),
                    _buildStat('Resolved', '0'),
                    _buildStat('Pending', '0'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildQuickAction(Icons.road, 'Roads', Colors.orange),
                  _buildQuickAction(Icons.lightbulb, 'Lights', Colors.yellow),
                  _buildQuickAction(Icons.water_drop, 'Water', Colors.blue),
                  _buildQuickAction(Icons.school, 'Schools', Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportIssueScreen())),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab(AuthService auth, Map<String, dynamic>? user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)]),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(radius: 50, backgroundColor: Color(0xFF6366f1), child: Icon(Icons.person, size: 50, color: Colors.white)),
              const SizedBox(height: 16),
              Text(user?['fullName'] ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(user?['phone'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () => auth.logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
