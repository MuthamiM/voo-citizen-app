import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'supabase_service.dart';

/// Service to check for app updates and FORCE users to update
class AppUpdateService {
  // Current app version - UPDATE THIS when releasing new versions
  static const String currentVersion = '1.4';
  static const int currentVersionCode = 14;

  
  // GitHub releases URL
  static const String githubReleasesUrl = 'https://github.com/MuthamiM/voo-citizen-app/releases';
  static const String directDownloadUrl = 'https://github.com/MuthamiM/voo-citizen-app/releases/download/v1.4/app-release.apk';

  /// Check if an update is required
  static Future<Map<String, dynamic>> checkForUpdate() async {
    try {
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

      return {'updateRequired': false, 'currentVersion': currentVersion};
    } catch (e) {
      return {'updateRequired': false, 'currentVersion': currentVersion, 'error': e.toString()};
    }
  }

  /// Compare version strings
  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    for (int i = 0; i < 3; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 < p2) return -1;
      if (p1 > p2) return 1;
    }
    return 0;
  }

  /// Show update overlay with circular progress
  static void showMandatoryUpdateOverlay(BuildContext context, {String? downloadUrl}) {
    final url = downloadUrl ?? directDownloadUrl;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: _UpdateDownloadScreen(downloadUrl: url),
      ),
    );
  }
}

/// Update download screen with circular progress indicator
class _UpdateDownloadScreen extends StatefulWidget {
  final String downloadUrl;
  const _UpdateDownloadScreen({required this.downloadUrl});

  @override
  State<_UpdateDownloadScreen> createState() => _UpdateDownloadScreenState();
}

class _UpdateDownloadScreenState extends State<_UpdateDownloadScreen> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _status = 'New version available!';
  String? _downloadedFilePath;
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  void _startDownload() async {
    if (_downloadedFilePath != null) {
      // APK already downloaded, open it
      await OpenFilex.open(_downloadedFilePath!);
      return;
    }

    if (_isDownloading) return; // Prevent spam clicks

    setState(() {
      _isDownloading = true;
      _status = 'Downloading update...';
      _progress = 0.0;
    });

    try {
      // Get download directory
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir!.path}/voo_update.apk';
      
      _cancelToken = CancelToken();

      // Download APK with progress
      await _dio.download(
        widget.downloadUrl,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            if (mounted) {
              setState(() => _progress = progress);
            }
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadedFilePath = savePath;
          _status = 'Download complete! Tap to install';
          _progress = 1.0;
          _isDownloading = false;
        });
        
        // Auto-trigger install
        await OpenFilex.open(savePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _status = 'Download failed. Tap to retry';
          _progress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Circular Progress Indicator
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            const Color(0xFFFF8C00).withOpacity(0.2),
                          ),
                        ),
                      ),
                      // Progress circle
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: _isDownloading ? _progress : 0.0,
                          strokeWidth: 8,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFFFF8C00),
                          ),
                        ),
                      ),
                      // Percentage text
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFFFF8C00),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Status text
                Text(
                  _status,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Download/Next button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : _startDownload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8C00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _progress >= 1.0 ? 'Install Update' : 'Download Now',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                if (!_isDownloading) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Later',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
