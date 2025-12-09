import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

/// Service to check for app updates and FORCE users to update
class AppUpdateService {
  // Current app version - UPDATE THIS when releasing new versions
  static const String currentVersion = '7.0.0';
  static const int currentVersionCode = 70;
  
  // GitHub releases URL
  static const String githubReleasesUrl = 'https://github.com/MuthamiM/voo-citizen-app/releases/latest';
  static const String directDownloadUrl = 'https://github.com/MuthamiM/voo-citizen-app/releases/download/v7.0/VOO-Citizen-App-v7.0.apk';

  /// Check if an update is required
  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
      // Fetch minimum required version from Supabase
      final url = '${SupabaseService.supabaseUrl}/rest/v1/app_config?key=eq.min_version&select=value';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'apikey': SupabaseService.supabaseAnonKey,
          'Authorization': 'Bearer ${SupabaseService.supabaseAnonKey}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final minVersion = data[0]['value'];
          final isUpdateRequired = _compareVersions(currentVersion, minVersion) < 0;
          
          // Get download URL from config or use default
          String downloadUrl = directDownloadUrl;
          try {
            final urlResponse = await http.get(
              Uri.parse('${SupabaseService.supabaseUrl}/rest/v1/app_config?key=eq.download_url&select=value'),
              headers: {
                'apikey': SupabaseService.supabaseAnonKey,
                'Authorization': 'Bearer ${SupabaseService.supabaseAnonKey}',
              },
            );
            if (urlResponse.statusCode == 200) {
              final urlData = jsonDecode(urlResponse.body);
              if (urlData.isNotEmpty) {
                downloadUrl = urlData[0]['value'];
              }
            }
          } catch (_) {}

          return {
            'updateRequired': isUpdateRequired,
            'currentVersion': currentVersion,
            'minVersion': minVersion,
            'downloadUrl': downloadUrl,
          };
        }
      }

      // If we can't check, assume no update needed
      return {'updateRequired': false, 'currentVersion': currentVersion};
    } catch (e) {
      // On error, don't block the user
      return {'updateRequired': false, 'currentVersion': currentVersion, 'error': e.toString()};
    }
  }

  /// Compare version strings (e.g., "1.0.0" vs "7.0.0")
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map(int.parse).toList();
    final parts2 = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 != p2) return p1 - p2;
    }
    return 0;
  }

  /// Show MANDATORY full-screen blocking update overlay
  /// User CANNOT dismiss this - must update to continue
  static void showMandatoryUpdateOverlay(BuildContext context, {String? downloadUrl}) {
    final url = downloadUrl ?? directDownloadUrl;
    
    showDialog(
      context: context,
      barrierDismissible: false, // CANNOT dismiss by tapping outside
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // CANNOT use back button
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Update icon with animation
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF8C00), width: 3),
                      ),
                      child: const Icon(
                        Icons.system_update,
                        color: Color(0xFFFF8C00),
                        size: 50,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    const Text(
                      'Update Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'A new version of VOO Citizen App is available.\nPlease update to continue using the app.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Version info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF444444)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFFF8C00), size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Your version: v$currentVersion',
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Update button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => _openDownloadUrl(ctx, url),
                        icon: const Icon(Icons.download, color: Colors.black, size: 24),
                        label: const Text(
                          'UPDATE NOW',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Alternative: Open in browser
                    TextButton.icon(
                      onPressed: () => _openInBrowser(url),
                      icon: Icon(Icons.open_in_browser, color: Colors.white.withOpacity(0.6)),
                      label: Text(
                        'Open in Browser',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Open download URL
  static Future<void> _openDownloadUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showCopyUrlSnackBar(context, url);
      }
    } catch (e) {
      _showCopyUrlSnackBar(context, url);
    }
  }

  /// Open releases page in browser
  static Future<void> _openInBrowser(String url) async {
    try {
      final uri = Uri.parse(githubReleasesUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  /// Show snackbar with copy option
  static void _showCopyUrlSnackBar(BuildContext context, String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Download the update from GitHub Releases'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Open',
          onPressed: () => _openInBrowser(url),
        ),
      ),
    );
  }

  /// Non-blocking update dialog (for minor updates)
  static void showOptionalUpdateDialog(BuildContext context, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Color(0xFFFF8C00), size: 28),
            SizedBox(width: 8),
            Text('Update Available', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'A new version is available. Update for the best experience!',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Later', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openDownloadUrl(ctx, downloadUrl);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8C00)),
            child: const Text('Update', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}
