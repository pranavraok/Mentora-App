// =====================================================
// AUTHENTICATION SERVICE
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mentora_app/config/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

  // ✅ ADD YOUR WEB CLIENT ID HERE (from Google Cloud Console)
  static const String webClientId = '734174786686-vbhdmhsa4i8udb4bcnopbt85137s35bc.apps.googleusercontent.com';

  // Get current user
  User? get currentUser => _client.auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Sign up with email
  Future<AuthResponse> signUpWithEmail(
      String email,
      String password, {
        required String name,
        String? college,
      }) async {
    // First, create the auth user
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'college': college},
      emailRedirectTo: null, // Email confirmation required
    );

    if (response.user != null) {
      // Wait a moment for auth session to establish
      await Future.delayed(const Duration(milliseconds: 500));

      // Try to create user profile - if it fails, we'll handle it in onboarding
      try {
        await _client.from('users').insert({
          'supabase_uid': response.user!.id,
          'email': email,
          'name': name,
          'college': college,
          'onboarding_complete': false,
        });
      } catch (e) {
        // Profile creation failed - we'll create it during onboarding instead
        print('Note: User profile will be created during onboarding');
      }
    }

    return response;
  }

  // Sign in with email
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ✅ UPDATED: Sign in with Google (Native Flow for Android)
  Future<bool> signInWithGoogle() async {
    try {
      // Initialize Google Sign In with your Web Client ID
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId, // CRITICAL for Android!
      );

      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return false;
      }

      // Obtain the auth details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Missing Google Auth Token');
      }

      // Sign in to Supabase with Google credentials
      final AuthResponse response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        // Check if user profile exists, create if not
        final existingUser = await _client
            .from('users')
            .select()
            .eq('supabase_uid', response.user!.id)
            .maybeSingle();

        if (existingUser == null) {
          // Create new user profile
          await _client.from('users').insert({
            'supabase_uid': response.user!.id,
            'email': response.user!.email,
            'name': response.user!.userMetadata?['full_name'] ??
                response.user!.userMetadata?['name'] ??
                'User',
            'onboarding_complete': false,
          });
        }

        return true;
      }

      return false;
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    // Sign out from Google as well
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      print('Google sign out error: $e');
    }

    await _client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // Check if onboarding is complete
  Future<bool> isOnboardingComplete(String supabaseUid) async {
    final response = await _client
        .from('users')
        .select('onboarding_complete')
        .eq('supabase_uid', supabaseUid)
        .maybeSingle();

    return response != null && response['onboarding_complete'] == true;
  }
}
