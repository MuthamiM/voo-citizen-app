import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class StorageService {
  static const String announcementsBox = 'announcements';
  static const String issuesBox = 'issues';
  static const String bursariesBox = 'bursaries';
  static const String settingsBox = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(announcementsBox);
    await Hive.openBox(issuesBox);
    await Hive.openBox(bursariesBox);
    await Hive.openBox(settingsBox);
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

  static Future<void> clearAll() async {
    await Hive.box(announcementsBox).clear();
    await Hive.box(issuesBox).clear();
    await Hive.box(bursariesBox).clear();
    await Hive.box(settingsBox).clear();
  }
}
