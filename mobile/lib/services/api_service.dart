import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = AuthService.baseUrl;

  final String? authToken;

  ApiService({this.authToken});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  // Get categories
  Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/issues/categories'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['categories']);
      }
    } catch (e) {
      // ignore
    }
    return ['Roads', 'Water', 'Electricity', 'Waste Management', 'Public Safety', 'Other'];
  }

  // Get my issues
  Future<Map<String, dynamic>> getMyIssues({String status = 'all', int page = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/issues/my?status=$status&page=$page'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore
    }
    return {'issues': [], 'stats': {}};
  }

  // Get single issue
  Future<Map<String, dynamic>?> getIssue(String issueId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/issues/$issueId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // Submit issue
  Future<Map<String, dynamic>> submitIssue({
    required String title,
    required String description,
    required String category,
    String? address,
    double? lat,
    double? lng,
    List<String>? images,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/issues'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'category': category,
          'location': {
            'address': address ?? '',
            'lat': lat,
            'lng': lng,
          },
          'images': images ?? [],
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  // Chat with AI
  Future<String> chatWithAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ai/chat'),
        headers: _headers,
        body: jsonEncode({'message': message}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'No response';
      }
    } catch (e) {
      // ignore
    }
    return 'Sorry, I could not connect to the assistant.';
  }

  // Upload image
  Future<Map<String, dynamic>?> uploadImage(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/upload'),
        headers: _headers,
        body: jsonEncode({'image': base64Image}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // Get user profile
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  // Update FCM token
  Future<bool> updateFcmToken(String fcmToken) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/profile/fcm-token'),
        headers: _headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ============ BURSARY ============

  // Get my bursary applications
  Future<List<dynamic>> getMyBursaryApplications() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bursary/my'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['applications'] ?? [];
      }
    } catch (e) {
      // ignore
    }
    return [];
  }

  // Submit bursary application
  Future<Map<String, dynamic>> submitBursaryApplication(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bursary/apply'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }
}
