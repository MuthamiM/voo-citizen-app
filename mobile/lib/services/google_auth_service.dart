  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Sign in with Google and authenticate via Backend
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return {'success': false, 'error': 'Google sign-in was cancelled'};
      }

      // 2. Get Google auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Send ID Token to Backend
      // Uses the same backend URL as AuthService
      final backendUrl = '${AuthService.backendUrl}/google';
      print('Sending Google Token to: $backendUrl');
      
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'credential': googleAuth.idToken, // Backend uses this to verify user
        }),
      ).timeout(const Duration(seconds: 40));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        return {'success': false, 'error': data['error'] ?? 'Google backend auth failed'};
      }

    } catch (e) {
      print('Google Sign-In Exception: $e');
      return {'success': false, 'error': 'Google sign-in failed: $e'};
    }
  }

  /// Sign out from Google
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
