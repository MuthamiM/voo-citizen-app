import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  static const String baseUrl = 'https://voo-citizen-api.onrender.com/api';
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
    _token = await _storage.read(key: 'token');
    final userData = await _storage.read(key: 'user');
    if (userData != null) _user = jsonDecode(userData);
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phone': phone, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _token = data['token'];
        _user = data['user'];
        await _storage.write(key: 'token', value: _token);
        await _storage.write(key: 'user', value: jsonEncode(_user));
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> register(String fullName, String phone, String idNumber, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'phone': phone,
          'idNumber': idNumber,
          'password': password
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _token = data['token'];
        _user = data['user'];
        await _storage.write(key: 'token', value: _token);
        await _storage.write(key: 'user', value: jsonEncode(_user));
        notifyListeners();
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
