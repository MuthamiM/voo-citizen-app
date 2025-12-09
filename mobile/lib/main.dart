import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/app_update_service.dart';
import 'providers/theme_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SupabaseService.initialize();
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
