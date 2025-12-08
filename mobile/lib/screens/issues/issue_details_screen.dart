import 'package:flutter/material.dart';

class IssueDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> issue;

  const IssueDetailsScreen({super.key, required this.issue});

  // Theme colors
  static const Color primaryPink = Color(0xFFE8847C);
  static const Color bgPink = Color(0xFFF9C5C1);
  static const Color textDark = Color(0xFF333333);
  static const Color textMuted = Color(0xFF666666);
  static const Color cardBg = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final status = (issue['status'] ?? 'pending').toString().toLowerCase();
    
    return Scaffold(
      backgroundColor: bgPink,
      appBar: AppBar(
        title: const Text('Issue Details', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
        backgroundColor: bgPink,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        margin: const EdgeInsets.only(top: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header
              if (issue['images']?.isNotEmpty == true)
                Container(
                  height: 220,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: NetworkImage(issue['images'][0]),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: bgPink.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: bgPink),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 40, color: primaryPink.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text('No image provided', style: TextStyle(color: textMuted.withOpacity(0.7))),
                      ],
                    ),
                  ),
                ),
              
              // Title & Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      issue['title'] ?? 'Untitled Issue',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textDark, height: 1.2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: primaryPink),
                  const SizedBox(width: 4),
                  Text(
                    issue['location'] ?? 'Unknown Location',
                    style: const TextStyle(color: textMuted, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Text(
                    issue['category'] ?? 'General',
                    style: const TextStyle(color: textMuted),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 32),

              // Description
              const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 12),
              Text(
                issue['description'] ?? 'No description provided.',
                style: const TextStyle(color: textMuted, height: 1.6, fontSize: 15),
              ),
              
              const SizedBox(height: 32),
              Divider(height: 1, color: Colors.grey.shade100),
              const SizedBox(height: 32),

              // Visual Timeline
              const Text('Resolution Timeline', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 24),
              _buildTimelineItem(
                'Report Received',
                'Your issue has been logged successfully.',
                '2023-10-25 09:30 AM',
                true,
                isLast: status == 'pending',
              ),
              _buildTimelineItem(
                'Team Assigned',
                'Maintenance team dispatched for assessment.',
                '2023-10-26 10:00 AM',
                status == 'in_progress' || status == 'resolved',
                isLast: status == 'in_progress',
                showTeam: true,
              ),
              _buildTimelineItem(
                'Issue Resolved',
                'Repair works completed and verified.',
                '2023-10-28 04:15 PM',
                status == 'resolved',
                isLast: true,
                isCompleted: status == 'resolved',
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved': return const Color(0xFF10B981);
      case 'in_progress': return const Color(0xFFF59E0B);
      default: return const Color(0xFF6B7280);
    }
  }

  Widget _buildTimelineItem(String title, String desc, String time, bool isActive, {bool isLast = false, bool isCompleted = false, bool showTeam = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? (isCompleted ? const Color(0xFF10B981) : primaryPink) : Colors.grey.shade200,
                  border: Border.all(
                    color: isActive ? (isCompleted ? const Color(0xFF10B981) : primaryPink) : Colors.grey.shade300, 
                    width: 2
                  ),
                  boxShadow: isActive ? [
                    BoxShadow(color: (isCompleted ? const Color(0xFF10B981) : primaryPink).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))
                  ] : null,
                ),
                child: isActive && isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isActive ? primaryPink.withOpacity(0.3) : Colors.grey.shade200,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(
                    color: isActive ? textDark : textMuted.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  )),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(color: textMuted, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(time, style: TextStyle(color: textMuted.withOpacity(0.6), fontSize: 12)),
                  
                  if (showTeam && isActive) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0)),
                            child: const Icon(Icons.people, color: textMuted),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Assigned Team', style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Roads & Infrastructure Unit', style: TextStyle(color: textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
