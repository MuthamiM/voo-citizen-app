import 'dart:convert';
import 'package:http/http.dart' as http;

/// Dashboard API Service - Connects mobile app to USSD Dashboard
/// Uses the citizen portal endpoints for shared data (issues, bursaries, announcements)
class DashboardService {
  // Production dashboard URL
  static const String dashboardUrl = 'https://voo-ward-ussd-1.onrender.com';
  static const String apiBase = '$dashboardUrl/api/citizen';
  
  // Session token (obtained after login)
  static String? _sessionToken;
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_sessionToken != null) 'Authorization': 'Bearer $_sessionToken',
  };

  // ============ MOBILE AUTH ============
  
  /// Request OTP for phone verification
  static Future<Map<String, dynamic>> requestOtp(String phoneNumber) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Request failed: $e'};
    }
  }

  /// Verify OTP
  static Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Verify failed: $e'};
    }
  }

  /// Register new mobile user
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String username,
    required String phoneNumber,
    required String password,
    String? nationalId,
    String? village,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'username': username,
          'phoneNumber': phoneNumber,
          'password': password,
          'nationalId': nationalId ?? '',
          'village': village ?? '',
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  /// Login with username/password
  static Future<Map<String, dynamic>> loginUser(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      
      final data = jsonDecode(res.body);
      if (data['success'] == true && data['token'] != null) {
        _sessionToken = data['token'];
      }
      return data;
    } catch (e) {
      return {'success': false, 'error': 'Login failed: $e'};
    }
  }

  /// Get user profile
  static Future<Map<String, dynamic>> getProfile(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/mobile/profile/$userId'),
        headers: _headers,
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to get profile: $e'};
    }
  }

  /// Update user profile
  static Future<Map<String, dynamic>> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final res = await http.put(
        Uri.parse('$apiBase/mobile/profile/$userId'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to update profile: $e'};
    }
  }

  /// Set session token (for when using Supabase auth but dashboard API)
  static void setToken(String token) {
    _sessionToken = token;
  }

  /// Clear session
  static void clearSession() {
    _sessionToken = null;
  }

  // ============ ANNOUNCEMENTS (PUBLIC) ============
  
  /// Get announcements - PUBLIC, no auth required
  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/announcements'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Get announcements error: $e');
      return [];
    }
  }

  // ============ ISSUES ============
  
  /// Get user's issues (requires auth)
  static Future<List<Map<String, dynamic>>> getMyIssues() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/issues'),
        headers: _headers,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Get issues error: $e');
      return [];
    }
  }

  /// Get issues by user ID (PUBLIC - for mobile app)
  static Future<List<Map<String, dynamic>>> getIssuesByUserId(String userId) async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/mobile/issues/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true && data['issues'] is List) {
          return List<Map<String, dynamic>>.from(data['issues']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Get issues by userId error: $e');
      return [];
    }
  }

  /// Submit new issue with images via mobile endpoint (PUBLIC - no auth required)
  /// Uses /api/citizen/mobile/issues endpoint which accepts base64 images
  static Future<Map<String, dynamic>> submitMobileIssue({
    required String phoneNumber,
    required String title,
    required String category,
    required String description,
    String? location,
    List<String>? images, // base64 encoded images
    String? userId,
    String? fullName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/issues'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'title': title,
          'category': category,
          'description': description,
          'location': location,
          'images': images ?? [],
          'userId': userId,
          'fullName': fullName,
        }),
      );
      
      try {
        final data = jsonDecode(res.body);
        if (res.statusCode == 201) {
          return {'success': true, ...data};
        } else {
          return {'success': false, 'error': data['error'] ?? 'Submit failed (Status ${res.statusCode})'};
        }
      } catch (decodeErr) {
        // If response is not JSON (e.g., HTML error page 413/500)
        final bodySample = res.body.length > 200 ? res.body.substring(0, 200) : res.body;
        return {'success': false, 'error': 'Server Error (${res.statusCode}): $bodySample'}; 
      }
    } catch (e) {
      print('Submit mobile issue error: $e');
      return {'success': false, 'error': 'Connection failed: $e'};
    }
  }

  /// Legacy submitIssue (requires citizen portal auth)
  static Future<Map<String, dynamic>> submitIssue({
    required String title,
    required String category,
    required String description,
    String? location,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/issues'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'category': category,
          'description': description,
          'location': location,
        }),
      );
      
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Submit failed: $e'};
    }
  }


  // ============ BURSARY ============
  
  /// Get user's bursary applications
  static Future<List<Map<String, dynamic>>> getMyBursaryApplications() async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/bursaries'),
        headers: _headers,
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
      }
      return [];
    } catch (e) {
      print('Get bursaries error: $e');
      return [];
    }
  }

  /// Submit bursary application via mobile endpoint (PUBLIC - no auth required)
  /// Uses /api/citizen/mobile/bursaries endpoint which stores directly to MongoDB
  static Future<Map<String, dynamic>> applyForBursary({
    required String institutionName,
    required String course,
    required String yearOfStudy,
    String? institutionType,
    String? reason,
    double? amountRequested,
    String? phoneNumber,
    String? userId,
    String? fullName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/mobile/bursaries'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'institutionName': institutionName,
          'course': course,
          'yearOfStudy': yearOfStudy,
          'institutionType': institutionType,
          'reason': reason,
          'amountRequested': amountRequested,
          'phoneNumber': phoneNumber,
          'userId': userId,
          'fullName': fullName,
        }),
      );
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return {'success': true, ...data};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Application failed'};
      }
    } catch (e) {
      print('Apply bursary error: $e');
      return {'success': false, 'error': 'Application failed: $e'};
    }
  }

  // ============ LOST ID REPORTING ============

  /// Report a lost ID
  static Future<Map<String, dynamic>> reportLostId({
    required String reporterPhone,
    required String reporterName,
    required String idOwnerName,
    String? idOwnerPhone,
    bool isForSelf = true,
    String? idNumber,
    String? lastSeenLocation,
    String? dateLost,
    String? additionalInfo,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/lost-ids'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'reporter_phone': reporterPhone,
          'reporter_name': reporterName,
          'id_owner_name': idOwnerName,
          'id_owner_phone': idOwnerPhone,
          'is_for_self': isForSelf,
          'id_number': idNumber,
          'last_seen_location': lastSeenLocation,
          'date_lost': dateLost,
          'additional_info': additionalInfo,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to report: $e'};
    }
  }

  /// Get lost ID reports for a user
  static Future<List<dynamic>> getLostIdReports(String phone) async {
    try {
      final res = await http.get(
        Uri.parse('$apiBase/lost-ids/$phone'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        return jsonDecode(res.body) ?? [];
      }
      return [];
    } catch (e) {
      print('Get lost IDs error: $e');
      return [];
    }
  }

  // ============ FEEDBACK ============

  /// Submit feedback
  static Future<Map<String, dynamic>> submitFeedback({
    String? userId,
    String? userPhone,
    String? userName,
    String category = 'general',
    required String message,
    int? rating,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$apiBase/feedback'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'user_phone': userPhone,
          'user_name': userName,
          'category': category,
          'message': message,
          'rating': rating,
        }),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'success': false, 'error': 'Failed to submit: $e'};
    }
  }
}
