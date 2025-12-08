import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simplified Supabase service using direct REST API calls
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

  // Simple hash function for password verification
  static String hashPassword(String password) {
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
  }) async {
    try {
      // Check if user exists
      final checkUrl = '$supabaseUrl/rest/v1/app_users?or=(phone.eq.$phone,id_number.eq.$idNumber)&select=id';
      final checkRes = await http.get(Uri.parse(checkUrl), headers: _headers);
      
      if (checkRes.statusCode == 200) {
        final existing = jsonDecode(checkRes.body);
        if (existing is List && existing.isNotEmpty) {
          return {'success': false, 'error': 'Phone or ID already registered'};
        }
      }

      // Insert new user
      final insertUrl = '$supabaseUrl/rest/v1/app_users';
      final insertRes = await http.post(
        Uri.parse(insertUrl),
        headers: _headers,
        body: jsonEncode({
          'full_name': fullName,
          'phone': phone,
          'id_number': idNumber,
          'password_hash': hashPassword(password),
          'village': village,
        }),
      );

      if (insertRes.statusCode == 201) {
        final user = jsonDecode(insertRes.body);
        final userData = user is List ? user.first : user;
        return {
          'success': true,
          'user': {
            'id': userData['id'],
            'fullName': userData['full_name'],
            'phone': userData['phone'],
            'issuesReported': 0,
          }
        };
      } else {
        return {'success': false, 'error': 'Registration failed: ${insertRes.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final url = '$supabaseUrl/rest/v1/app_users?phone=eq.$phone&select=*';
      final res = await http.get(Uri.parse(url), headers: _headers);

      if (res.statusCode == 200) {
        final users = jsonDecode(res.body);
        if (users is List && users.isEmpty) {
          return {'success': false, 'error': 'User not found'};
        }

        final user = users.first;
        if (user['password_hash'] != hashPassword(password)) {
          return {'success': false, 'error': 'Invalid password'};
        }

        return {
          'success': true,
          'user': {
            'id': user['id'],
            'fullName': user['full_name'],
            'phone': user['phone'],
            'issuesReported': user['issues_reported'] ?? 0,
            'issuesResolved': user['issues_resolved'] ?? 0,
          }
        };
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }

  // ============ PASSWORD RESET ============

  static Future<Map<String, dynamic>> updatePassword({
    required String phone,
    required String newPassword,
  }) async {
    try {
      // First find the user
      final findUrl = '$supabaseUrl/rest/v1/app_users?phone=eq.$phone&select=id';
      final findRes = await http.get(Uri.parse(findUrl), headers: _headers);
      
      if (findRes.statusCode == 200) {
        final users = jsonDecode(findRes.body);
        if (users is List && users.isEmpty) {
          return {'success': false, 'error': 'User not found'};
        }
        
        final userId = users.first['id'];
        
        // Update the password
        final updateUrl = '$supabaseUrl/rest/v1/app_users?id=eq.$userId';
        final updateRes = await http.patch(
          Uri.parse(updateUrl),
          headers: _headers,
          body: jsonEncode({'password_hash': hashPassword(newPassword)}),
        );
        
        if (updateRes.statusCode == 200 || updateRes.statusCode == 204) {
          return {'success': true};
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

  static Future<Map<String, dynamic>> createIssue({
    required String userId,
    required String userPhone,
    required String title,
    required String description,
    required String category,
    String? urgency,
    List<String>? images,
    Map<String, dynamic>? location,
  }) async {
    try {
      final issueNumber = 'VOO-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
      
      final url = '$supabaseUrl/rest/v1/issues';
      final res = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          'issue_number': issueNumber,
          'user_id': userId,
          'user_phone': userPhone,
          'title': title,
          'description': description,
          'category': category,
          'urgency': urgency ?? 'medium',
          'images': images ?? [],
          'location': location,
          'status': 'pending',
        }),
      );

      if (res.statusCode == 201) {
        final issue = jsonDecode(res.body);
        return {'success': true, 'issue': issue is List ? issue.first : issue, 'issueNumber': issueNumber};
      } else {
        return {'success': false, 'error': 'Failed to create issue'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Failed to create issue: $e'};
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

  static Future<Map<String, dynamic>> applyForBursary({
    required String userId,
    required String institutionName,
    required String course,
    required String yearOfStudy,
    String? institutionType,
    String? reason,
    double? amountRequested,
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
          'reason': reason,
          'amount_requested': amountRequested,
          'status': 'pending',
        }),
      );

      if (res.statusCode == 201) {
        final app = jsonDecode(res.body);
        return {'success': true, 'application': app is List ? app.first : app};
      } else {
        return {'success': false, 'error': 'Application failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Application failed: $e'};
    }
  }
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? email,
    String? village,
  }) async {
    try {
      final url = '$supabaseUrl/rest/v1/app_users?id=eq.$userId';
      
      final Map<String, dynamic> updates = {};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;
      if (email != null) updates['email'] = email;
      if (village != null) updates['village'] = village;

      if (updates.isEmpty) {
        return {'success': true}; // No changes needed
      }

      final res = await http.patch(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(updates),
      );

      if (res.statusCode == 200 || res.statusCode == 204) {
         // Fetch updated user to return
         final getUrl = '$supabaseUrl/rest/v1/app_users?id=eq.$userId&select=*';
         final getRes = await http.get(Uri.parse(getUrl), headers: _headers);
         
         if (getRes.statusCode == 200) {
            final users = jsonDecode(getRes.body);
            if (users is List && users.isNotEmpty) {
               final user = users.first;
               return {
                  'success': true,
                  'user': {
                    'id': user['id'],
                    'fullName': user['full_name'],
                    'phone': user['phone'],
                    'email': user['email'], // Ensure email is handled if column exists, else might be null
                    'village': user['village'],
                    'issuesReported': user['issues_reported'] ?? 0,
                  }
               };
            }
         }
        return {'success': true}; 
      } else {
        return {'success': false, 'error': 'Update failed: ${res.body}'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Update failed: $e'};
    }
  }
}
