import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Debug logger - only prints in debug mode
void _debugLog(String message) {
  if (kDebugMode) {
    // ignore: avoid_print
    debugPrint(message);
  }
}

/// Supabase service with hardened authentication
class SupabaseService {
  static const String supabaseUrl = 'https://xzhmdxtzpuxycvsatjoe.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6aG1keHR6cHV4eWN2c2F0am9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxNTYwNzAsImV4cCI6MjA4MDczMjA3MH0.2tZ7eu6DtBg2mSOitpRa4RNvgCGg3nvMWeDmn9fPJY0';
  
  static Map<String, String> get _headers => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  static Future<void> initialize() async {
    // No initialization needed for REST API approach
  }

  // ============ SECURE PASSWORD HASHING ============
  
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

  // ============ AUTH METHODS ============

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

      // Format phone
      String formattedPhone = phone.trim();
      if (!formattedPhone.startsWith('+')) {
        if (formattedPhone.startsWith('0')) {
          formattedPhone = '+254${formattedPhone.substring(1)}';
        } else if (!formattedPhone.startsWith('254')) {
          formattedPhone = '+254$formattedPhone';
        } else {
          formattedPhone = '+$formattedPhone';
        }
      }

      // Check if user exists by phone OR national ID
      final checkUrl = Uri.parse('$supabaseUrl/rest/v1/app_users')
          .replace(queryParameters: {
            'or': '(phone.eq.$formattedPhone,id_number.eq.$idNumber)',
            'select': 'id,phone,id_number',
          });
      
      final checkRes = await http.get(checkUrl, headers: _headers);
      
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

      // Generate secure password hash with salt
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);

      // Insert new user
      final insertUrl = '$supabaseUrl/rest/v1/app_users';
      final insertRes = await http.post(
        Uri.parse(insertUrl),
        headers: _headers,
        body: jsonEncode({
          'full_name': fullName.trim(),
          'phone': formattedPhone,
          'id_number': idNumber.trim(),
          'password_hash': passwordHash,
          'village': village?.trim(),
          'username': username?.trim() ?? formattedPhone.replaceAll('+254', ''),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (insertRes.statusCode == 201) {
        final user = jsonDecode(insertRes.body);
        final userData = user is List ? user.first : user;
        _debugLog('✅ Registration SUCCESS - User ID: ${userData['id']}, Username: ${userData['username']}, Phone: ${userData['phone']}');
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
        _debugLog('❌ Registration FAILED: ${insertRes.statusCode} - ${insertRes.body}');
        return {'success': false, 'error': 'Registration failed. Please try again.'};
      }
    } catch (e) {
      _debugLog('❌ Registration exception: $e');
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final inputValue = phone.trim();
      _debugLog('🔐 Login attempt with input: $inputValue');
      
      // Check if input looks like a phone number (starts with +, 0, or is all digits)
      final isPhoneNumber = inputValue.startsWith('+') || 
                            inputValue.startsWith('0') ||
                            inputValue.startsWith('254') ||
                            RegExp(r'^\d{9,}$').hasMatch(inputValue);
      
      String? formattedPhone;
      if (isPhoneNumber) {
        formattedPhone = inputValue;
        if (!formattedPhone.startsWith('+')) {
          if (formattedPhone.startsWith('0')) {
            formattedPhone = '+254${formattedPhone.substring(1)}';
          } else if (formattedPhone.startsWith('254')) {
            formattedPhone = '+$formattedPhone';
          } else {
            formattedPhone = '+254$formattedPhone';
          }
        }
        _debugLog('🔐 Looking for phone: $formattedPhone');
      } else {
        _debugLog('🔐 Looking for username: $inputValue');
      }

      // Try to find user by phone first (if it's a phone number)
      List users = [];
      if (formattedPhone != null) {
        var url = Uri.parse('$supabaseUrl/rest/v1/app_users')
            .replace(queryParameters: {
              'phone': 'eq.$formattedPhone',
              'select': '*',
            });
        
        var res = await http.get(url, headers: _headers);
        users = jsonDecode(res.body);
        _debugLog('🔐 Phone lookup result: ${users.length} users found');
      }

      // If no user found by phone, try username
      if (users.isEmpty) {
        _debugLog('🔐 Trying username lookup...');
        var url = Uri.parse('$supabaseUrl/rest/v1/app_users')
            .replace(queryParameters: {
              'username': 'eq.$inputValue',
              'select': '*',
            });
        var res = await http.get(url, headers: _headers);
        users = jsonDecode(res.body);
        _debugLog('🔐 Username lookup result: ${users.length} users found');
      }

      // Fallback: try full_name (case-insensitive) if username not found
      if (users.isEmpty) {
        _debugLog('🔐 Trying full_name fallback lookup...');
        var url = Uri.parse('$supabaseUrl/rest/v1/app_users')
            .replace(queryParameters: {
              'full_name': 'ilike.$inputValue',
              'select': '*',
            });
        var res = await http.get(url, headers: _headers);
        users = jsonDecode(res.body);
        _debugLog('🔐 Full name lookup result: ${users.length} users found');
      }

      if (users.isEmpty) {
        _debugLog('❌ No user found with phone $formattedPhone, username $inputValue, or full_name');
        return {'success': false, 'error': 'User not found. Please register first.'};
      }

      final user = users.first;
      _debugLog('✅ User found: ${user['username']} / ${user['phone']}');
      final storedHash = user['password_hash'] ?? '';
      
      if (!_verifyPassword(password, storedHash)) {
        _debugLog('❌ Password verification failed');
        return {'success': false, 'error': 'Invalid password'};
      }

      _debugLog('✅ Login SUCCESS for user: ${user['username']}');
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
      _debugLog('❌ Login exception: $e');
      return {'success': false, 'error': 'Network error. Please check your connection.'};
    }
  }

  // ============ PASSWORD RESET ============

  static Future<Map<String, dynamic>> updatePassword({
    required String phone,
    required String newPassword,
  }) async {
    try {
      if (newPassword.length < 6) {
        return {'success': false, 'error': 'Password must be at least 6 characters'};
      }

      // Format phone
      String formattedPhone = phone.trim();
      if (!formattedPhone.startsWith('+254')) {
        formattedPhone = '+254$formattedPhone';
      }

      // Find the user
      final findUrl = Uri.parse('$supabaseUrl/rest/v1/app_users')
          .replace(queryParameters: {
            'phone': 'eq.$formattedPhone',
            'select': 'id',
          });
      final findRes = await http.get(findUrl, headers: _headers);
      
      if (findRes.statusCode == 200) {
        final users = jsonDecode(findRes.body);
        if (users is List && users.isEmpty) {
          return {'success': false, 'error': 'User not found'};
        }
        
        final userId = users.first['id'];
        
        // Generate new secure hash
        final salt = _generateSalt();
        final passwordHash = _hashPassword(newPassword, salt);
        
        // Update the password
        final updateUrl = '$supabaseUrl/rest/v1/app_users?id=eq.$userId';
        final updateRes = await http.patch(
          Uri.parse(updateUrl),
          headers: _headers,
          body: jsonEncode({'password_hash': passwordHash}),
        );
        
        if (updateRes.statusCode == 200 || updateRes.statusCode == 204) {
          return {'success': true, 'message': 'Password updated successfully'};
        } else {
          return {'success': false, 'error': 'Failed to update password'};
        }
      } else {
        return {'success': false, 'error': 'User not found'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Password reset failed: $e'};
    }
  }

  /// SECURE password reset - requires both phone AND ID verification
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

      // Format phone
      String formattedPhone = phone.trim();
      if (!formattedPhone.startsWith('+254')) {
        formattedPhone = '+254$formattedPhone';
      }

      // Find the user by BOTH phone AND ID number
      final findUrl = Uri.parse('$supabaseUrl/rest/v1/app_users')
          .replace(queryParameters: {
            'phone': 'eq.$formattedPhone',
            'id_number': 'eq.${idNumber.trim()}',
            'select': 'id,phone,id_number',
          });
      final findRes = await http.get(findUrl, headers: _headers);
      
      if (findRes.statusCode == 200) {
        final users = jsonDecode(findRes.body);
        if (users is List && users.isEmpty) {
          // Don't reveal if phone exists - security best practice
          return {'success': false, 'error': 'Phone and ID do not match. Please check your details.'};
        }
        
        final userId = users.first['id'];
        
        // Generate new secure hash
        final salt = _generateSalt();
        final passwordHash = _hashPassword(newPassword, salt);
        
        // Update the password
        final updateUrl = '$supabaseUrl/rest/v1/app_users?id=eq.$userId';
        final updateRes = await http.patch(
          Uri.parse(updateUrl),
          headers: _headers,
          body: jsonEncode({'password_hash': passwordHash}),
        );
        
        if (updateRes.statusCode == 200 || updateRes.statusCode == 204) {
          _debugLog('✅ Password reset successful for user $userId');
          return {'success': true, 'message': 'Password updated successfully'};
        } else {
          return {'success': false, 'error': 'Failed to update password'};
        }
      } else {
        return {'success': false, 'error': 'Verification failed'};
      }
    } catch (e) {
      _debugLog('❌ Password reset error: $e');
      return {'success': false, 'error': 'Password reset failed: $e'};
    }
  }

  // ============ PROFILE UPDATE ============

  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String fullName,
    required String phone,
    String? email,
    String? village,
  }) async {
    try {
      final updateUrl = '$supabaseUrl/rest/v1/app_users?id=eq.$userId';
      final updateRes = await http.patch(
        Uri.parse(updateUrl),
        headers: _headers,
        body: jsonEncode({
          'full_name': fullName,
          'phone': phone,
          if (email != null) 'email': email,
          if (village != null) 'village': village,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (updateRes.statusCode == 200 || updateRes.statusCode == 204) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Update failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final deleteUrl = '$supabaseUrl/rest/v1/app_users?id=eq.$userId';
      final deleteRes = await http.delete(Uri.parse(deleteUrl), headers: _headers);

      if (deleteRes.statusCode == 200 || deleteRes.statusCode == 204) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Delete failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Delete failed: $e'};
    }
  }

  // ============ ANNOUNCEMENTS ============

  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final url = '$supabaseUrl/rest/v1/announcements?is_active=eq.true&order=created_at.desc&limit=10';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============ EMERGENCY CONTACTS ============

  static Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      final url = '$supabaseUrl/rest/v1/emergency_contacts?is_active=eq.true';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============ ISSUES ============

  static Future<List<Map<String, dynamic>>> getMyIssues(String userId) async {
    try {
      final url = '$supabaseUrl/rest/v1/issues?user_id=eq.$userId&order=created_at.desc';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitIssue({
    required String userId,
    required String title,
    required String category,
    required String description,
    String? location,
    List<String>? imageUrls,
  }) async {
    try {
      final url = '$supabaseUrl/rest/v1/issues';
      // Generate issue number ISS-XXXXXX
      final issueNumber = 'ISS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}${Random().nextInt(999)}';
      
      final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'title': title,
          'issue_number': issueNumber,
          'category': category,
          'description': description,
          'location': location,
          'images': imageUrls, // Changed from image_urls to match schema
          'status': 'pending',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (res.statusCode == 201) {
        return {'success': true, 'issue': jsonDecode(res.body)};
      } else {
        return {'success': false, 'error': 'Failed to submit issue'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }

  // ============ BURSARY ============

  static Future<List<Map<String, dynamic>>> getMyBursaryApplications(String userId) async {
    try {
      final url = '$supabaseUrl/rest/v1/bursary_applications?user_id=eq.$userId&order=created_at.desc';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> submitBursaryApplication({
    required String userId,
    required String institutionName,
    required String course,
    required String yearOfStudy,
    String? institutionType,
    double? amountRequested,
    String? reason,
  }) async {
    try {
      final url = '$supabaseUrl/rest/v1/bursary_applications';
      final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'user_id': userId,
          'institution_name': institutionName,
          'course': course,
          'year_of_study': yearOfStudy,
          'institution_type': institutionType,
          'amount_requested': amountRequested,
          'reason': reason,
          'status': 'pending',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (res.statusCode == 201) {
        return {'success': true, 'application': jsonDecode(res.body)};
      } else {
        return {'success': false, 'error': 'Failed to submit application'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }

  // ============ APP CONFIG ============

  static Future<Map<String, dynamic>> getAppConfig() async {
    try {
      final url = '$supabaseUrl/rest/v1/app_config?select=*';
      final res = await http.get(Uri.parse(url), headers: _headers);
      if (res.statusCode == 200) {
        final configs = jsonDecode(res.body) as List;
        final configMap = <String, dynamic>{};
        for (final config in configs) {
          configMap[config['key']] = config['value'];
        }
        return configMap;
      }
      return {};
    } catch (e) {
      return {};
    }
  }
  // ============ TOKEN MANAGEMENT ============
  
  static Future<void> updateFCMToken(String userId, String token) async {
    try {
      final updateUrl = '$supabaseUrl/rest/v1/app_users?id=eq.$userId';
      await http.patch(
        Uri.parse(updateUrl),
        headers: _headers,
        body: jsonEncode({'fcm_token': token}),
      );
    } catch (e) {
      _debugLog('Failed to update FCM token: $e');
    }
  }

  // ============ LOST ID & FEEDBACK ============

  static Future<Map<String, dynamic>> submitLostId({
    required String fullName,
    required String idNumber,
    String? phoneNumber,
    String? description,
  }) async {
    try {
      final url = '$supabaseUrl/rest/v1/lost_ids';
      final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'full_name': fullName,
          'id_number': idNumber,
          'phone_number': phoneNumber,
          'description': description,
          'status': 'reported',
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (res.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to submit report'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> submitFeedback({
    required String message,
    String? userId,
  }) async {
    try {
      final url = '$supabaseUrl/rest/v1/app_feedback';
      final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'message': message,
          if (userId != null) 'user_id': userId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      if (res.statusCode == 201) {
        return {'success': true};
      } else {
        return {'success': false, 'error': 'Failed to submit feedback'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }
}
