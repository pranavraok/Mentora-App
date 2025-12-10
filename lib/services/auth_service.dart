// =====================================================
// AUTHENTICATION SERVICE
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';

class AuthService {
  final SupabaseClient _client = SupabaseConfig.client;

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

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.mentoraapp://login-callback',
    );
  }

  // Sign out
  Future<void> signOut() async {
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
