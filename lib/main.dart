import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

import 'config/supabase_config.dart';
import 'pages/biometric_lock_screen.dart';
import 'pages/category_grid_page.dart';
import 'pages/login_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const PasswordManagerApp());
}

class PasswordManagerApp extends StatelessWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.dark,
      home: const AuthWrapper(),
    );
  }
}

// Wrapper to handle two-layer authentication:
// 1. Google Sign-In (Cloud Authentication)
// 2. Biometric/PIN (Local Device Security)
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _localAuthPassed = false;

  void _onLocalAuthPassed() {
    setState(() {
      _localAuthPassed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is signed in
        final isSignedIn = snapshot.hasData && snapshot.data?.session != null;

        if (!isSignedIn) {
          // Not signed in - show login page
          _localAuthPassed = false; // Reset local auth
          return const LoginPage();
        }

        // User is signed in
        // Now check local authentication (biometric/PIN)
        if (!_localAuthPassed) {
          return BiometricLockScreen(
            onAuthenticated: _onLocalAuthPassed,
          );
        }

        // Both authentications passed - show app
        return const CategoryGridPage();
      },
    );
  }
}
