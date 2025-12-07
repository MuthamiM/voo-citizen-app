/// Issues Repository
/// Handles issue reporting and retrieval
library;

import 'dart:math';
import '../network/supabase_client.dart';

/// Repository for citizen issue management
class IssuesRepository {
  static const String _issuesTable = '/rest/v1/issues';

  /// Generate unique issue number
  static String _generateIssueNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final random = Random().nextInt(999);
    return 'ISS-$timestamp$random';
  }

  /// Get all issues for a user
  static Future<List<Map<String, dynamic>>> getMyIssues(String userId) async {
    try {
      final result = await SupabaseClient.get(
        _issuesTable,
        queryParams: {
          'user_id': 'eq.$userId',
          'order': 'created_at.desc',
          'select': '*',
        },
      );
      
      if (result != null && result is List) {
        return List<Map<String, dynamic>>.from(result);
      }
      return [];
    } catch (e) {
      debugLog('❌ getMyIssues error: $e');
      return [];
    }
  }

  /// Submit a new issue
  static Future<Map<String, dynamic>> submitIssue({
    required String userId,
    required String title,
    required String category,
    required String description,
    String? location,
    List<String>? imageUrls,
  }) async {
    try {
      final issueNumber = _generateIssueNumber();
      
      final result = await SupabaseClient.post(_issuesTable, {
        'user_id': userId,
        'title': title,
        'issue_number': issueNumber,
        'category': category,
        'description': description,
        'location': location,
        'images': imageUrls,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (result['success']) {
        debugLog('✅ Issue submitted: $issueNumber');
        return {'success': true, 'issue': result['data'], 'issueNumber': issueNumber};
      } else {
        return {'success': false, 'error': 'Failed to submit issue'};
      }
    } catch (e) {
      debugLog('❌ submitIssue error: $e');
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }

  /// Get issue by ID
  static Future<Map<String, dynamic>?> getIssueById(String issueId) async {
    try {
      final result = await SupabaseClient.get(
        _issuesTable,
        queryParams: {
          'id': 'eq.$issueId',
          'select': '*',
        },
      );
      
      if (result != null && result is List && result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      debugLog('❌ getIssueById error: $e');
      return null;
    }
  }

  /// Get issue by issue number
  static Future<Map<String, dynamic>?> getIssueByNumber(String issueNumber) async {
    try {
      final result = await SupabaseClient.get(
        _issuesTable,
        queryParams: {
          'issue_number': 'eq.$issueNumber',
          'select': '*',
        },
      );
      
      if (result != null && result is List && result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      debugLog('❌ getIssueByNumber error: $e');
      return null;
    }
  }

  /// Get issue statistics for a user
  static Future<Map<String, int>> getUserIssueStats(String userId) async {
    try {
      final issues = await getMyIssues(userId);
      
      int pending = 0;
      int inProgress = 0;
      int resolved = 0;
      
      for (final issue in issues) {
        final status = (issue['status'] ?? 'pending').toString().toLowerCase();
        if (status == 'pending') pending++;
        else if (status == 'in progress' || status == 'in_progress') inProgress++;
        else if (status == 'resolved') resolved++;
      }
      
      return {
        'total': issues.length,
        'pending': pending,
        'inProgress': inProgress,
        'resolved': resolved,
      };
    } catch (e) {
      debugLog('❌ getUserIssueStats error: $e');
      return {'total': 0, 'pending': 0, 'inProgress': 0, 'resolved': 0};
    }
  }
}
