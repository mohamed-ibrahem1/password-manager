import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Currently signed-in user, if any
  User? get currentUser => _supabase.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  String get userId => currentUser?.id ?? '';

  String get userEmail => currentUser?.email ?? '';

  String get userDisplayName =>
      currentUser?.userMetadata?['full_name'] ??
      currentUser?.userMetadata?['name'] ??
      currentUser?.email?.split('@').first ??
      'User';

  String? get userPhotoUrl =>
      currentUser?.userMetadata?['avatar_url'] ??
      currentUser?.userMetadata?['picture'];

  /// Sign in with Google handling platform differences
  Future<void> signInWithGoogle() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      await _signInWithGoogleNative();
    } else {
      await _signInWithGoogleDesktop();
    }
  }

  /// Native Google Sign-In for Android/iOS/Web
  Future<void> _signInWithGoogleNative() async {
    try {
      // Web Client ID is needed for the idToken to be valid for Supabase
      // This should be the same "Web Client ID" configured in Supabase Google Provider
      const webClientId = SupabaseConfig.googleWebClientId;

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in cancelled by user.');
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null) {
        throw const AuthException('No Access Token found.');
      }
      if (idToken == null) {
        throw const AuthException('No ID Token found.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on PlatformException catch (e) {
      throw AuthException('Google Sign-In Error: ${e.message}');
    } catch (e) {
      throw AuthException('Unexpected Error: $e');
    }
  }

  /// Desktop Google Sign-In using Local Server
  Future<void> _signInWithGoogleDesktop() async {
    HttpServer? server;
    try {
      // 1. Start local server
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      final redirectUrl = 'http://localhost:$port/callback';

      // 2. Start OAuth flow
      final success = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      if (!success) {
        throw const AuthException('Failed to launch auth URL.');
      }

      // 3. Wait for callback
      await for (final request in server) {
        final uri = request.uri;

        if (uri.path.endsWith('/callback')) {
          final code = uri.queryParameters['code'];
          final error = uri.queryParameters['error'];

          if (error != null) {
            _respond(request, 'Error: $error', 400);
            throw AuthException('Auth Error: $error');
          }

          if (code != null) {
            // Exchange code for session
            try {
              await _supabase.auth.exchangeCodeForSession(code);
              _respond(request, 'Login Successful! You can close this window.');
              await request.response.close();
              return;
            } catch (e) {
              _respond(request, 'Exchange Error: $e', 500);
              throw AuthException('Token Exchange Error: $e');
            }
          } else {
            _respond(request, 'No code received.', 400);
          }
        }
        // Close request if not handled above
        await request.response.close();
        break;
      }

      // Check if signed in
      if (_supabase.auth.currentSession != null) {
        return;
      }

      throw const AuthException('Auth flow ended without session.');
    } finally {
      await server?.close();
    }
  }

  void _respond(HttpRequest request, String message, [int statusCode = 200]) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.html
      ..write('''
        <!DOCTYPE html>
        <html>
        <head><title>Auth Status</title></head>
        <body style="font-family: sans-serif; text-align: center; padding: 50px;">
          <h3>$message</h3>
          <script>if($statusCode === 200) setTimeout(() => window.close(), 1000);</script>
        </body>
        </html>
      ''');
  }

  Future<void> signOut() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      await GoogleSignIn().signOut();
    }
    await _supabase.auth.signOut();
  }
}
