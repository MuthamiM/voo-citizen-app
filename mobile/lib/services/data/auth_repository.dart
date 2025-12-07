/// Authentication Repository
/// Handles user registration, login, password management, and profile operations
library;

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../network/supabase_client.dart';

/// Authentication repository for user management
class AuthRepository {
  static const String _usersTable = '/rest/v1/app_users';

  // ============ PASSWORD HASHING ============
  
  /// Generate a random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Hash password with SHA-256 and salt
  static String _hashPassword(String password, String salt) {
    final saltedPassword = '$salt:$password';
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return '$salt:${digest.toString()}';
  }

  /// Verify password against stored hash
  static bool _verifyPassword(String password, String storedHash) {
    if (!storedHash.contains(':')) {
      // Legacy hash (old format) - for backwards compatibility
      return _legacyHashPassword(password) == storedHash;
    }
    final parts = storedHash.split(':');
    if (parts.length < 2) return false;
    final salt = parts[0];
    final expectedHash = _hashPassword(password, salt);
    return expectedHash == storedHash;
  }

  /// Legacy hash for backwards compatibility with existing users
  static String _legacyHashPassword(String password) {
    var hash = 0;
    for (var i = 0; i < password.length; i++) {
      hash = ((hash << 5) - hash) + password.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }

  /// Format phone number to international format
  static String _formatPhone(String phone) {
    String formatted = phone.trim();
    if (!formatted.startsWith('+')) {
      if (formatted.startsWith('0')) {
        formatted = '+254${formatted.substring(1)}';
      } else if (formatted.startsWith('254')) {
        formatted = '+$formatted';
      } else {
        formatted = '+254$formatted';
      }
    }
    return formatted;
  }

  // ============ REGISTRATION ============

  /// Register a new user
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String idNumber,
    required String password,
    String? village,
    String? username,
  }) async {
    try {
      // Validate inputs
      if (fullName.trim().isEmpty) {
        return {'success': false, 'error': 'Full name is required'};
      }
      if (phone.trim().isEmpty) {
        return {'success': false, 'error': 'Phone number is required'};
      }
      if (password.length < 6) {
        return {'success': false, 'error': 'Password must be at least 6 characters'};
      }

      final formattedPhone = _formatPhone(phone);

      // Check if user exists
      final checkUrl = Uri.parse('${SupabaseClient.supabaseUrl}$_usersTable')
          .replace(queryParameters: {
            'or': '(phone.eq.$formattedPhone,id_number.eq.$idNumber)',
            'select': 'id,phone,id_number',
          });
      
      final checkRes = await http.get(checkUrl, headers: SupabaseClient.headers);
      
      if (checkRes.statusCode == 200) {
        final existing = jsonDecode(checkRes.body);
        if (existing is List && existing.isNotEmpty) {
          final existingUser = existing.first;
          if (existingUser['phone'] == formattedPhone) {
            return {'success': false, 'error': 'Phone number already registered'};
          }
          if (existingUser['id_number'] == idNumber) {
            return {'success': false, 'error': 'National ID already registered'};
          }
          return {'success': false, 'error': 'User already exists'};
        }
      }

      // Generate secure password hash
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);

      // Insert new user
      final result = await SupabaseClient.post(_usersTable, {
        'full_name': fullName.trim(),
        'phone': formattedPhone,
        'id_number': idNumber.trim(),
        'password_hash': passwordHash,
        'village': village?.trim(),
        'username': username?.trim() ?? formattedPhone.replaceAll('+254', ''),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      if (result['success']) {
        final userData = result['data'];
        debugLog('✅ Registration SUCCESS - User ID: ${userData['id']}');
        return {
          'success': true,
          'message': 'Registration successful',
          'user': {
            'id': userData['id'],
            'fullName': userData['full_name'],
            'phone': userData['phone'],
            'username': userData['username'] ?? formattedPhone.replaceAll('+254', ''),
            'village': userData['village'],
          }
        };
      } else {
        return {'success': false, 'error': 'Registration failed. Please try again.'};
      }
    } catch (e) {
      debugLog('❌ Registration exception: $e');
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    }
  }

  // ============ LOGIN ============

  /// Login with phone/username and password
  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final inputValue = phone.trim();
      debugLog('🔐 Login attempt with input: $inputValue');
      
      // Check if input looks like a phone number
      final isPhoneNumber = inputValue.startsWith('+') || 
                            inputValue.startsWith('0') ||
                            inputValue.startsWith('254') ||
                            RegExp(r'^\d{9,}$').hasMatch(inputValue);
      
      String? formattedPhone;
      if (isPhoneNumber) {
        formattedPhone = _formatPhone(inputValue);
      }

      // Try to find user
      List users = [];
      
      // Try phone first
      if (formattedPhone != null) {
        final result = await SupabaseClient.get(_usersTable, queryParams: {
          'phone': 'eq.$formattedPhone',
          'select': '*',
        });
        if (result != null) users = result;
      }

      // Try username if not found
      if (users.isEmpty) {
        final result = await SupabaseClient.get(_usersTable, queryParams: {
          'username': 'eq.$inputValue',
          'select': '*',
        });
        if (result != null) users = result;
      }

      // Try full_name fallback
      if (users.isEmpty) {
        final result = await SupabaseClient.get(_usersTable, queryParams: {
          'full_name': 'ilike.$inputValue',
          'select': '*',
        });
        if (result != null) users = result;
      }

      if (users.isEmpty) {
        return {'success': false, 'error': 'User not found. Please register first.'};
      }

      final user = users.first;
      final storedHash = user['password_hash'] ?? '';
      
      if (!_verifyPassword(password, storedHash)) {
        return {'success': false, 'error': 'Invalid password'};
      }

      debugLog('✅ Login SUCCESS for user: ${user['username']}');
      return {
        'success': true,
        'user': {
          'id': user['id'],
          'fullName': user['full_name'],
          'phone': user['phone'],
          'username': user['username'],
          'village': user['village'],
          'email': user['email'],
          'issuesReported': user['issues_reported'] ?? 0,
          'issuesResolved': user['issues_resolved'] ?? 0,
        }
      };
    } catch (e) {
      debugLog('❌ Login exception: $e');
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    }
  }

  // ============ PASSWORD MANAGEMENT ============

  /// Update password (simple - just phone verification)
  static Future<Map<String, dynamic>> updatePassword({
    required String phone,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        return {'success': false, 'error': 'Password must be at least 6 characters'};
      }

      final formattedPhone = _formatPhone(phone);

      // Find user
      final users = await SupabaseClient.get(_usersTable, queryParams: {
        'phone': 'eq.$formattedPhone',
        'select': 'id',
      });

      if (users == null || (users is List && users.isEmpty)) {
        return {'success': false, 'error': 'User not found'};
      }

      final userId = users.first['id'];
      
      // Generate new secure hash
      final salt = _generateSalt();
      final passwordHash = _hashPassword(newPassword, salt);
      
      // Update password
      final result = await SupabaseClient.patch(
        '$_usersTable?id=eq.$userId',
        {'password_hash': passwordHash},
      );
      
      if (result['success']) {
        return {'success': true, 'message': 'Password updated successfully'};
      } else {
        return {'success': false, 'error': 'Failed to update password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Password reset failed: $e'};
    }
  }

  /// Secure password reset - requires phone AND ID verification
  static Future<Map<String, dynamic>> updatePasswordWithVerification({
    required String phone,
    required String idNumber,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        return {'success': false, 'error': 'Password must be at least 6 characters'};
      }
      if (idNumber.trim().isEmpty) {
        return {'success': false, 'error': 'National ID is required for verification'};
      }

      final formattedPhone = _formatPhone(phone);

      // Find user by BOTH phone AND ID
      final users = await SupabaseClient.get(_usersTable, queryParams: {
        'phone': 'eq.$formattedPhone',
        'id_number': 'eq.${idNumber.trim()}',
        'select': 'id',
      });

      if (users == null || (users is List && users.isEmpty)) {
        return {'success': false, 'error': 'Phone and ID do not match. Please check your details.'};
      }

      final userId = users.first['id'];
      
      // Generate new secure hash
      final salt = _generateSalt();
      final passwordHash = _hashPassword(newPassword, salt);
      
      // Update password
      final result = await SupabaseClient.patch(
        '$_usersTable?id=eq.$userId',
        {'password_hash': passwordHash},
      );
      
      if (result['success']) {
        return {'success': true, 'message': 'Password updated successfully'};
      } else {
        return {'success': false, 'error': 'Failed to update password'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Password reset failed: $e'};
    }
  }

  // ============ PROFILE MANAGEMENT ============

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? email,
    String? village,
  }) async {
    return SupabaseClient.patch('$_usersTable?id=eq.$userId', {
      'full_name': fullName,
      'phone': phone,
      if (email != null) 'email': email,
      if (village != null) 'village': village,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Delete user account
  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    return SupabaseClient.delete('$_usersTable?id=eq.$userId');
  }

  /// Update FCM token for push notifications
  static Future<void> updateFCMToken(String userId, String token) async {
    await SupabaseClient.patch('$_usersTable?id=eq.$userId', {
      'fcm_token': token,
    });
  }
}
