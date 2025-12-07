/// Base Supabase HTTP client configuration
/// Provides shared configuration and request methods for all repositories
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Debug logger - only prints in debug mode
void debugLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

/// Base Supabase client with shared configuration
class SupabaseClient {
  static const String supabaseUrl = 'https://xzhmdxtzpuxycvsatjoe.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh6aG1keHR6cHV4eWN2c2F0am9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxNTYwNzAsImV4cCI6MjA4MDczMjA3MH0.2tZ7eu6DtBg2mSOitpRa4RNvgCGg3nvMWeDmn9fPJY0';
  
  static Map<String, String> get headers => {
    'apikey': supabaseAnonKey,
    'Authorization': 'Bearer $supabaseAnonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  /// GET request to Supabase REST API
  static Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      var url = Uri.parse('$supabaseUrl$endpoint');
      if (queryParams != null) {
        url = url.replace(queryParameters: queryParams);
      }
      
      final res = await http.get(url, headers: headers);
      
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        debugLog('GET $endpoint failed: ${res.statusCode} - ${res.body}');
        return null;
      }
    } catch (e) {
      debugLog('GET $endpoint exception: $e');
      return null;
    }
  }

  /// POST request to Supabase REST API
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = '$supabaseUrl$endpoint';
      final res = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return {'success': true, 'data': data is List ? (data.isNotEmpty ? data.first : {}) : data};
      } else {
        debugLog('POST $endpoint failed: ${res.statusCode} - ${res.body}');
        return {'success': false, 'error': 'Request failed'};
      }
    } catch (e) {
      debugLog('POST $endpoint exception: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// PATCH request to Supabase REST API
  static Future<Map<String, dynamic>> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final url = '$supabaseUrl$endpoint';
      final res = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true};
      } else {
        debugLog('PATCH $endpoint failed: ${res.statusCode} - ${res.body}');
        return {'success': false, 'error': 'Update failed'};
      }
    } catch (e) {
      debugLog('PATCH $endpoint exception: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// DELETE request to Supabase REST API
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final url = '$supabaseUrl$endpoint';
      final res = await http.delete(Uri.parse(url), headers: headers);
      
      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true};
      } else {
        debugLog('DELETE $endpoint failed: ${res.statusCode} - ${res.body}');
        return {'success': false, 'error': 'Delete failed'};
      }
    } catch (e) {
      debugLog('DELETE $endpoint exception: $e');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }
}
