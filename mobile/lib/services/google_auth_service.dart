import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google and create/update user in Supabase
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in was cancelled'};
      }

      // Get Google auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return {'success': false, 'error': 'Failed to sign in with Google'};
      }

      // Extract user details from Google account
      final String fullName = firebaseUser.displayName ?? googleUser.displayName ?? 'User';
      final String email = firebaseUser.email ?? googleUser.email;
      final String? photoUrl = firebaseUser.photoURL ?? googleUser.photoUrl;
      final String googleId = firebaseUser.uid;

      // Check if user exists in Supabase by email or google_id
      final existingUser = await _checkExistingUser(email, googleId);

      if (existingUser != null) {
        // User exists, return their data
        return {
          'success': true,
          'user': existingUser,
          'isNewUser': false,
        };
      }

      // Create new user in Supabase
      final newUser = await _createUserInSupabase(
        fullName: fullName,
        email: email,
        googleId: googleId,
        photoUrl: photoUrl,
      );

      if (newUser != null) {
        return {
          'success': true,
          'user': newUser,
          'isNewUser': true,
        };
      }

      return {'success': false, 'error': 'Failed to create account'};
    } catch (e) {
      return {'success': false, 'error': 'Google sign-in failed: $e'};
    }
  }

  /// Check if user already exists in Supabase
  static Future<Map<String, dynamic>?> _checkExistingUser(String email, String googleId) async {
    try {
      final url = '${SupabaseService.supabaseUrl}/rest/v1/app_users?or=(email.eq.$email,google_id.eq.$googleId)&select=*';
      final headers = {
        'apikey': SupabaseService.supabaseAnonKey,
        'Authorization': 'Bearer ${SupabaseService.supabaseAnonKey}',
        'Content-Type': 'application/json',
      };

      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final user = data.first;
          return {
            'id': user['id'],
            'fullName': user['full_name'],
            'email': user['email'],
            'phone': user['phone'],
            'photoUrl': user['photo_url'],
            'issuesReported': user['issues_reported'] ?? 0,
          };
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create new user in Supabase with Google details
  static Future<Map<String, dynamic>?> _createUserInSupabase({
    required String fullName,
    required String email,
    required String googleId,
    String? photoUrl,
  }) async {
    try {
      final url = '${SupabaseService.supabaseUrl}/rest/v1/app_users';
      final headers = {
        'apikey': SupabaseService.supabaseAnonKey,
        'Authorization': 'Bearer ${SupabaseService.supabaseAnonKey}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation',
      };

      final body = jsonEncode({
        'full_name': fullName,
        'email': email,
        'google_id': googleId,
        'photo_url': photoUrl,
        'auth_provider': 'google',
      });

      print('Creating user in Supabase: $body');
      final response = await http.post(Uri.parse(url), headers: headers, body: body);
      print('Supabase response: ${response.statusCode} - ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = data is List ? data.first : data;
        return {
          'id': user['id'],
          'fullName': user['full_name'],
          'email': user['email'],
          'phone': user['phone'],
          'photoUrl': user['photo_url'],
          'issuesReported': 0,
        };
      } else {
        print('Error creating user: ${response.body}');
      }
      return null;
    } catch (e) {
      print('Exception in _createUserInSupabase: $e');
      return null;
    }
  }

  /// Sign out from Google and Firebase
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
