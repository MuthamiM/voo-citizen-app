import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/dashboard_service.dart';
import 'issue_details_screen.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  List<dynamic> _issues = [];
  bool _isLoading = true;

  // Theme colors
  static const Color primaryOrange = Color(0xFFFF8C00);
  static const Color bgDark = Color(0xFF1A1A1A);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF888888);
  static const Color cardBg = Color(0xFF2A2A2A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadIssues();
    });
  }

  Future<void> _loadIssues() async {
    final auth = context.read<AuthService>();
    final userId = auth.user?['id']?.toString();
    
    if (userId == null || userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 1. Load from cache immediately
    final cachedIssues = StorageService.getCachedIssues();
    if (cachedIssues.isNotEmpty && mounted) {
      setState(() {
        _issues = cachedIssues;
        _isLoading = false;
      });
    }

    // 2. Fetch fresh data from Dashboard API (USSD Dashboard)
    try {
      if (await StorageService.isOnline()) {
        final loadedIssues = await DashboardService.getIssuesByUserId(userId);
        if (mounted) {
          setState(() {
            _issues = loadedIssues;
            _isLoading = false;
          });
          StorageService.cacheIssues(loadedIssues);
        }
      } else if (_issues.isEmpty) {
         if (mounted) {
           setState(() => _isLoading = false);
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Offline. No cached/new issues found.'), backgroundColor: Colors.orange),
           );
         }
      }
    } catch (e) {
      if (mounted && _issues.isEmpty) {
        setState(() => _isLoading = false);
      }
    }
  }


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved': return const Color(0xFF10B981); // Green
      case 'in_progress': return const Color(0xFFF59E0B); // Amber/Orange
      default: return const Color(0xFF6B7280); // Gray
    }
  }

  String _getStatusLabel(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // Determine greeting based on time
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    if (hour >= 12 && hour < 17) greeting = 'Good Afternoon';
    else if (hour >= 17) greeting = 'Good Evening';

    return Scaffold(
      backgroundColor: bgDark,
      body: Stack(
        children: [
          // Static background decoration (no animation)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryOrange.withOpacity(0.3),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Reports',
                            style: TextStyle(
                              fontSize: 28, 
                              fontWeight: FontWeight.w800, 
                              color: Colors.white,
                              letterSpacing: -0.5
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Track your reports', 
                            style: TextStyle(color: textMuted, fontSize: 15)
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {}, 
                            icon: const Icon(Icons.search, color: Colors.white, size: 28)
                          ),
                          Container(
                            width: 36, height: 36,
                            decoration: const BoxDecoration(color: Color(0xFF333333), shape: BoxShape.circle),
                            child: const Icon(Icons.person, color: primaryOrange, size: 20),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: primaryOrange))
                        : _issues.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 60, color: textMuted.withOpacity(0.5)),
                                    const SizedBox(height: 16),
                                    const Text('No Issues Found', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context), // Go back to create
                                      child: const Text('Create New Issue', style: TextStyle(color: primaryOrange, fontWeight: FontWeight.w600, fontSize: 16)),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadIssues,
                                color: primaryOrange,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _issues.length,
                                  itemBuilder: (ctx, i) {
                                    final issue = _issues[i];
                                    final status = issue['status'] ?? 'pending';
                                    final category = issue['category'] ?? 'General';
                                    final date = issue['createdAt'] != null 
                                        ? DateTime.parse(issue['createdAt']).toString().substring(0, 10) 
                                        : 'Oct 26, 2023';
                                    
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => IssueDetailsScreen(issue: issue),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF333333),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Image
                                              Container(
                                                width: 80, height: 80,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  color: bgDark,
                                                  image: issue['images']?.isNotEmpty == true
                                                      ? DecorationImage(image: NetworkImage(issue['images'][0]), fit: BoxFit.cover)
                                                      : null,
                                                ),
                                                child: issue['images']?.isNotEmpty == true ? null : const Icon(Icons.broken_image, color: textMuted),
                                              ),
                                              const SizedBox(width: 12),
                                              
                                              // Details
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: Colors.blue.withOpacity(0.2),
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
                                                          child: Text(category, style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                                                        ),
                                                        Text(date, style: const TextStyle(color: textMuted, fontSize: 12)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      issue['title'] ?? 'Untitled',
                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(status).withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(20),
                                                      ),
                                                      child: Text(
                                                        _getStatusLabel(status),
                                                        style: TextStyle(color: _getStatusColor(status), fontSize: 11, fontWeight: FontWeight.w600),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
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
}
