import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../services/supabase_service.dart';
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
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color bgPink = Color(0xFFF9C5C1);
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);
  static const Color cardBg = Color(0xFFFFFFFF);

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

    // 2. Fetch fresh data
    try {
      if (await StorageService.isOnline()) {
        final loadedIssues = await SupabaseService.getMyIssues(userId);
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
      backgroundColor: bgPink,
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
                color: primaryPink.withOpacity(0.3),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reported Issues',
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.w800, 
                          color: Colors.white,
                          letterSpacing: -0.5
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Track the status of your reports', 
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
                      color: Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: primaryPink))
                        : _issues.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: bgPink.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.assignment_outlined, size: 60, color: primaryPink.withOpacity(0.6)),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No issues reported yet', 
                                      style: TextStyle(
                                        color: textMuted, 
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16
                                      )
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Reports you submit will appear here', 
                                      style: TextStyle(
                                        color: textMuted, 
                                        fontSize: 14
                                      )
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadIssues,
                                color: primaryPink,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(20),
                                  itemCount: _issues.length,
                                  itemBuilder: (ctx, i) {
                                    final issue = _issues[i];
                                    final status = issue['status'] ?? 'pending';
                                    final statusColor = _getStatusColor(status);
                                    
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
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 15,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Image or Icon
                                              Container(
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(16),
                                                  color: bgPink.withOpacity(0.3),
                                                  image: issue['images']?.isNotEmpty == true
                                                      ? DecorationImage(
                                                          image: NetworkImage(issue['images'][0]),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: issue['images']?.isNotEmpty == true
                                                    ? null
                                                    : const Icon(Icons.image_outlined, color: primaryPink, size: 30),
                                              ),
                                              const SizedBox(width: 16),
                                              
                                              // Content
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: statusColor.withOpacity(0.1),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            _getStatusLabel(status),
                                                            style: TextStyle(
                                                              color: statusColor, 
                                                              fontSize: 10, 
                                                              fontWeight: FontWeight.bold,
                                                              letterSpacing: 0.5
                                                            ),
                                                          ),
                                                        ),
                                                        
                                                        const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFD1D5DB)),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      issue['title'] ?? 'Untitled Issue', 
                                                      style: const TextStyle(
                                                        color: textDark, 
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Icon(Icons.location_on_outlined, size: 14, color: textMuted.withOpacity(0.7)),
                                                        const SizedBox(width: 4),
                                                        Expanded(
                                                          child: Text(
                                                            issue['location'] ?? 'Unknown Location', 
                                                            style: const TextStyle(
                                                              color: textMuted, 
                                                              fontSize: 13
                                                            ),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
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
