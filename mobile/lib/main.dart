import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: const VooCitizenApp(),
    ),
  );
}

class VooCitizenApp extends StatelessWidget {
  const VooCitizenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOO Citizen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366f1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0f0f23),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1a1a3e),
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF1a1a3e),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366f1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2d1b69).withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
          ),
        ),
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
