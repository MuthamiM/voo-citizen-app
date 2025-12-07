import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class AuthService extends ChangeNotifier {
  // Backend API URL
  static const String backendUrl = 'https://voo-ward-ussd-1.onrender.com/api/auth';
  
  // Session expires after 6 days of inactivity (in milliseconds)
  static const int sessionTimeoutDays = 6;
  static const int sessionTimeoutMs = sessionTimeoutDays * 24 * 60 * 60 * 1000;
  
  // Use FlutterSecureStorage for sensitive data
  final _storage = const FlutterSecureStorage();
  
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  bool get isLoggedIn => _token != null;
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;

  AuthService() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    // Load sensitive data from SecureStorage
    _token = await _storage.read(key: 'token');
    final userData = await _storage.read(key: 'user');
    
    if (userData != null) {
      try {
        _user = jsonDecode(userData);
      } catch (e) {
        print('Error decoding user data: $e');
        await logout(); // Corrupt data, logout
        return;
      }
    }
    
    // Check for session expiry (6 days of inactivity)
    // We can keep `last_activity` in SharedPreferences as it's not sensitive
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt('last_activity');
    
    if (_token != null && lastActivity != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - lastActivity > sessionTimeoutMs) {
        // Session expired, force logout
        await logout();
        return;
      }
    }
    
    // Update last activity timestamp
    if (_token != null) {
      await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
      if (_user != null && _user!['id'] != null) {
        _updateFCM(_user!['id'].toString());
      }
    }
    
    notifyListeners();
  }

  // Call this method when user performs any action to keep session alive
  Future<void> updateLastActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
  }

  /// Set user state from Google sign-in
  Future<void> setGoogleUser(Map<String, dynamic> userData) async {
    _token = 'google_session_${DateTime.now().millisecondsSinceEpoch}';
    _user = userData;
    
    // Save to SecureStorage
    await _storage.write(key: 'token', value: _token!);
    await _storage.write(key: 'user', value: jsonEncode(_user));
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
    
    // Update FCM
    if (_user!['id'] != null) {
      _updateFCM(_user!['id'].toString());
    }

    notifyListeners();
  }

  /// Reload user data from SharedPreferences (useful after external login)
  Future<void> reloadUserData() async {
    _token = await _storage.read(key: 'token');
    final userData = await _storage.read(key: 'user');
    if (userData != null) {
      try {
        _user = jsonDecode(userData);
      } catch (_) {}
    }
    notifyListeners();
  }

  // Helper to update FCM token
  Future<void> _updateFCM(String userId) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await SupabaseService.updateFCMToken(userId, token);
      }
    } catch (_) {}
  }

  // ============ NEW BACKEND AUTH METHODS ============

  /// Send OTP (Server-side)
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/register-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone}),
      );
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data; // {success: true, debug_otp: '123456'}
      } else {
        return {'success': false, 'error': data['error'] ?? 'Failed to send OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Verify OTP (Server-side)
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$backendUrl/register-verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'otp': otp}),
      );
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return data; // {success: true, token: '...'}
      } else {
        return {'success': false, 'error': data['error'] ?? 'Invalid OTP'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }

  /// Complete Registration (Server-side)
  Future<Map<String, dynamic>> completeRegistration({
    required String fullName,
    required String phone,
    required String idNumber,
    required String password,
    required String token,
    String? village,
    String? username,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$backendUrl/register-complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'phone': phone,
          'idNumber': idNumber,
          'password': password,
          'village': village,
          'username': username,
          'token': token, // Proof of OTP verification
        }),
      );
      
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'user': data['user']};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login (Server-side)
  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await http.post(
        Uri.parse('$backendUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        _user = data['user'];
        _token = 'backend_session_${DateTime.now().millisecondsSinceEpoch}';
        
        if (_user!['id'] != null) {
          _updateFCM(_user!['id'].toString());
        }
        
        await _storage.write(key: 'token', value: _token!);
        await _storage.write(key: 'user', value: jsonEncode(_user));
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('last_activity', DateTime.now().millisecondsSinceEpoch);
        
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error. Please check your connection. ($e)'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Deprecated/Legacy Register (kept if needed but unused in new flow)
  Future<Map<String, dynamic>> register(String fullName, String phone, String idNumber, String password, {String? village, String? username}) async {
    return {'success': false, 'error': 'Please use the new registration flow'};
  }

  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String phone,
    String? email,
    String? village,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      // Format phone number
      String formattedPhone = phone;
      if (!phone.startsWith('+254')) {
        formattedPhone = '+254$phone';
      }

      final userId = _user!['id'].toString();
      
      final result = await SupabaseService.updateUserProfile(
        userId: userId,
        fullName: fullName,
        phone: formattedPhone,
        email: email,
        village: village,
      );

      if (result['success'] == true) {
        // Update local user state if new data returned, otherwise just update fields we know changed
        if (result['user'] != null) {
          _user = result['user'];
        } else {
          // Fallback manual update if server didn't return object
          _user!['fullName'] = fullName;
          _user!['phone'] = formattedPhone;
          if (email != null) _user!['email'] = email;
          if (village != null) _user!['village'] = village;
        }

        // Persist to SecureStorage
        await _storage.write(key: 'user', value: jsonEncode(_user));
        
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Update failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear other preferences if needed
    notifyListeners();
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_user == null) {
        return {'success': false, 'error': 'No user logged in'};
      }

      final userId = _user!['id'].toString();
      final result = await SupabaseService.deleteUser(userId);

      if (result['success'] == true) {
        // Clear local data
        await logout();
        return {'success': true};
      } else {
        return {'success': false, 'error': result['error'] ?? 'Failed to delete account'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Delete failed: $e'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
