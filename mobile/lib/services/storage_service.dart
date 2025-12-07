import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String announcementsBox = 'announcements';
  static const String issuesBox = 'issues';
  static const String bursariesBox = 'bursaries';
  static const String settingsBox = 'settings';
  static const String pendingIssuesBox = 'pending_issues';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Setup Encryption
    const secureStorage = FlutterSecureStorage();
    String? keyStr = await secureStorage.read(key: 'hiveKey');
    if (keyStr == null) {
      final key = Hive.generateSecureKey();
      keyStr = base64UrlEncode(key);
      await secureStorage.write(key: 'hiveKey', value: keyStr);
    }
    
    final encryptionKey = base64Url.decode(keyStr!);
    
    // Open public boxes
    await Hive.openBox(announcementsBox);
    await Hive.openBox(settingsBox);
    
    // Open encrypted boxes
    try {
      await Hive.openBox(issuesBox, encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox(bursariesBox, encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox(pendingIssuesBox, encryptionCipher: HiveAesCipher(encryptionKey));
    } catch (e) {
      // If encryption fails (e.g. key mismatch or previously unencrypted), clear and retry
      print('Error opening encrypted boxes: $e. Clearing boxes.');
      await Hive.deleteBoxFromDisk(issuesBox);
      await Hive.deleteBoxFromDisk(bursariesBox);
      await Hive.deleteBoxFromDisk(pendingIssuesBox);
      
      await Hive.openBox(issuesBox, encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox(bursariesBox, encryptionCipher: HiveAesCipher(encryptionKey));
      await Hive.openBox(pendingIssuesBox, encryptionCipher: HiveAesCipher(encryptionKey));
    }
  }

  // Connectivity
  static Future<bool> isOnline() async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  // Generic Save/Get
  static Future<void> saveData(String boxName, String key, dynamic data) async {
    final box = Hive.box(boxName);
    await box.put(key, jsonEncode(data));
  }

  static dynamic getData(String boxName, String key) {
    final box = Hive.box(boxName);
    final data = box.get(key);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  // Specific Methods
  static Future<void> cacheAnnouncements(List<dynamic> announcements) async {
    await saveData(announcementsBox, 'list', announcements);
  }

  static List<dynamic> getCachedAnnouncements() {
    return (getData(announcementsBox, 'list') as List?) ?? [];
  }

  static Future<void> cacheIssues(List<dynamic> issues) async {
    await saveData(issuesBox, 'my_issues', issues);
  }

  static List<dynamic> getCachedIssues() {
    return (getData(issuesBox, 'my_issues') as List?) ?? [];
  }

  static Future<void> cacheBursaries(List<dynamic> bursaries) async {
    await saveData(bursariesBox, 'my_applications', bursaries);
  }

  static List<dynamic> getCachedBursaries() {
    return (getData(bursariesBox, 'my_applications') as List?) ?? [];
  }
  
  static Future<void> markAnnouncementRead(String id) async {
      final box = Hive.box(announcementsBox);
      final readIds = (box.get('read_ids') as List?)?.cast<String>() ?? [];
      if (!readIds.contains(id)) {
        readIds.add(id);
        await box.put('read_ids', readIds);
      }
  }

  static List<String> getReadAnnouncementIds() {
    final box = Hive.box(announcementsBox);
    return (box.get('read_ids') as List?)?.cast<String>() ?? [];
  }

  static Future<void> clearAll() async {
    await Hive.box(announcementsBox).clear();
    await Hive.box(issuesBox).clear();
    await Hive.box(bursariesBox).clear();
    await Hive.box(settingsBox).clear();
    await Hive.box(pendingIssuesBox).clear();
  }

  // Pending Issues (Offline Queue)
  static Future<void> cachePendingIssue(Map<String, dynamic> issueData) async {
    final box = Hive.box(pendingIssuesBox);
    await box.add(jsonEncode(issueData)); // Use auto-increment key
  }

  static List<Map<String, dynamic>> getPendingIssues() {
    final box = Hive.box(pendingIssuesBox);
    return box.values
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
  }

  static Future<void> clearPendingIssues() async {
    await Hive.box(pendingIssuesBox).clear();
  }
}
