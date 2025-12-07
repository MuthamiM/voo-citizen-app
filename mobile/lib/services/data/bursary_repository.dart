/// Bursary Repository
/// Handles bursary application submission and retrieval
library;

import '../network/supabase_client.dart';

/// Repository for bursary application management
class BursaryRepository {
  static const String _bursaryTable = '/rest/v1/bursary_applications';

  /// Get all bursary applications for a user
  static Future<List<Map<String, dynamic>>> getMyApplications(String userId) async {
    try {
      final result = await SupabaseClient.get(
        _bursaryTable,
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
      debugLog('❌ getMyBursaryApplications error: $e');
      return [];
    }
  }

  /// Submit a new bursary application
  static Future<Map<String, dynamic>> submitApplication({
    required String userId,
    required String institutionName,
    required String course,
    required String yearOfStudy,
    String? institutionType,
    double? amountRequested,
    String? reason,
  }) async {
    try {
      final result = await SupabaseClient.post(_bursaryTable, {
        'user_id': userId,
        'institution_name': institutionName,
        'course': course,
        'year_of_study': yearOfStudy,
        'institution_type': institutionType,
        'amount_requested': amountRequested,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (result['success']) {
        debugLog('✅ Bursary application submitted');
        return {'success': true, 'application': result['data']};
      } else {
        return {'success': false, 'error': 'Failed to submit application'};
      }
    } catch (e) {
      debugLog('❌ submitBursaryApplication error: $e');
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }

  /// Get application by ID
  static Future<Map<String, dynamic>?> getApplicationById(String applicationId) async {
    try {
      final result = await SupabaseClient.get(
        _bursaryTable,
        queryParams: {
          'id': 'eq.$applicationId',
          'select': '*',
        },
      );
      
      if (result != null && result is List && result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      debugLog('❌ getBursaryById error: $e');
      return null;
    }
  }

  /// Get bursary statistics for a user
  static Future<Map<String, dynamic>> getUserBursaryStats(String userId) async {
    try {
      final applications = await getMyApplications(userId);
      
      int pending = 0;
      int approved = 0;
      int rejected = 0;
      double totalApproved = 0;
      
      for (final app in applications) {
        final status = (app['status'] ?? 'pending').toString().toLowerCase();
        if (status == 'pending') pending++;
        else if (status == 'approved') {
          approved++;
          totalApproved += (app['approved_amount'] ?? 0).toDouble();
        }
        else if (status == 'rejected') rejected++;
      }
      
      return {
        'total': applications.length,
        'pending': pending,
        'approved': approved,
        'rejected': rejected,
        'totalApprovedAmount': totalApproved,
      };
    } catch (e) {
      debugLog('❌ getUserBursaryStats error: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0, 'totalApprovedAmount': 0.0};
    }
  }
}
