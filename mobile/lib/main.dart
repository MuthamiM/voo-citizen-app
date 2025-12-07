/**
 * ============================================================================
 * VOO Citizen Platform - Mobile Application
 * ============================================================================
 * 
 * Copyright (C) 2025 Musa Muthami. All Rights Reserved.
 * 
 * PROPRIETARY AND CONFIDENTIAL - SOURCE CODE CANNOT BE EDITED BY ANYONE
 * 
 * This software is the exclusive property of Musa Muthami and is protected
 * by copyright law. Unauthorized copying, modification, distribution, or use
 * of this software or any portion thereof is strictly prohibited and may
 * result in severe civil and criminal penalties.
 * 
 * THE SOURCE CODE CANNOT BE EDITED, MODIFIED, OR ALTERED BY ANYONE except
 * the original author (Musa Muthami). This is an absolute prohibition.
 * Any unauthorized editing is ILLEGAL and will result in legal action.
 * 
 * For licensing inquiries, contact: musamwange2@gmail.com
 * See LICENSE file for complete terms and conditions.
 * ============================================================================
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/lost_id/lost_id_screen.dart';
import 'screens/feedback/feedback_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/app_update_service.dart';
import 'services/cache/hive_cache_service.dart';
import 'providers/theme_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SupabaseService.initialize();
  await HiveCacheService.init(); // Initialize offline cache
  await NotificationService.initialize();
  await StorageService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const VooCitizenApp(),
    ),
  );
}

class VooCitizenApp extends StatefulWidget {
  const VooCitizenApp({super.key});

  @override
  State<VooCitizenApp> createState() => _VooCitizenAppState();
}

class _VooCitizenAppState extends State<VooCitizenApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Check for updates after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    final result = await AppUpdateService.checkForUpdate();
    if (result['updateRequired'] == true && mounted) {
      final ctx = _navigatorKey.currentContext;
      if (ctx != null) {
        // Show MANDATORY blocking overlay - user cannot dismiss
        AppUpdateService.showMandatoryUpdateOverlay(ctx, downloadUrl: result['downloadUrl']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'VOO Citizen',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          routes: {
            '/lost-id': (context) => const LostIdScreen(),
            '/feedback': (context) => const FeedbackScreen(),
          },
          home: Consumer<AuthService>(
            builder: (context, auth, _) {
              return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
            },
          ),
        );
      },
    );
  }
}
