/// Content Repository
/// Handles announcements, emergency contacts, app config, feedback, and lost IDs
library;

import '../network/supabase_client.dart';

/// Repository for app content and utilities
class ContentRepository {
  
  // ============ ANNOUNCEMENTS ============

  /// Get active announcements
  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final result = await SupabaseClient.get(
        '/rest/v1/announcements',
        queryParams: {
          'is_active': 'eq.true',
          'order': 'created_at.desc',
          'limit': '10',
          'select': '*',
        },
      );
      
      if (result != null && result is List) {
        return List<Map<String, dynamic>>.from(result);
      }
      return [];
    } catch (e) {
      debugLog('❌ getAnnouncements error: $e');
      return [];
    }
  }

  // ============ EMERGENCY CONTACTS ============

  /// Get emergency contacts
  static Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final result = await SupabaseClient.get(
        '/rest/v1/emergency_contacts',
        queryParams: {
          'is_active': 'eq.true',
          'select': '*',
        },
      );
      
      if (result != null && result is List) {
        return List<Map<String, dynamic>>.from(result);
      }
      return [];
    } catch (e) {
      debugLog('❌ getEmergencyContacts error: $e');
      return [];
    }
  }

  // ============ APP CONFIG ============

  /// Get app configuration
  static Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final result = await SupabaseClient.get(
        '/rest/v1/app_config',
        queryParams: {'select': '*'},
      );
      
      if (result != null && result is List) {
        final configMap = <String, dynamic>{};
        for (final config in result) {
          configMap[config['key']] = config['value'];
        }
        return configMap;
      }
      return {};
    } catch (e) {
      debugLog('❌ getAppConfig error: $e');
      return {};
    }
  }

  // ============ LOST ID ============

  /// Submit lost ID report
  static Future<Map<String, dynamic>> submitLostId({
    required String fullName,
    required String idNumber,
    String? phoneNumber,
    String? description,
  }) async {
    return SupabaseClient.post('/rest/v1/lost_ids', {
      'full_name': fullName,
      'id_number': idNumber,
      'phone_number': phoneNumber,
      'description': description,
      'status': 'reported',
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ============ FEEDBACK ============

  /// Submit app feedback
  static Future<Map<String, dynamic>> submitFeedback({
    required String message,
    String? userId,
  }) async {
    return SupabaseClient.post('/rest/v1/app_feedback', {
      'message': message,
      if (userId != null) 'user_id': userId,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
