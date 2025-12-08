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
      case 'resolved': return Colors.green;
      case 'in_progress': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF0f0f23), Color(0xFF1a1a3e)]),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('My Reported Issues', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _issues.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 80, color: Colors.white.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text('No issues reported yet', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadIssues,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _issues.length,
                            itemBuilder: (ctx, i) {
                              final issue = _issues[i];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => IssueDetailsScreen(issue: issue),
                                    ),
                                  );
                                },
                                child: Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: issue['images']?.isNotEmpty == true
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(issue['images'][0], width: 60, height: 60, fit: BoxFit.cover),
                                          )
                                        : Container(
                                            width: 60, height: 60,
                                            decoration: BoxDecoration(color: const Color(0xFF6366f1).withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                                            child: const Icon(Icons.image, color: Color(0xFF6366f1)),
                                          ),
                                    title: Text(issue['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(issue['category'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(issue['status'] ?? 'pending').withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            (issue['status'] ?? 'pending').toUpperCase(),
                                            style: TextStyle(color: _getStatusColor(issue['status'] ?? 'pending'), fontSize: 10, fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
