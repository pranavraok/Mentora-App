// =====================================================
// SUPABASE CONFIGURATION
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Project credentials
  static const String supabaseUrl = 'https://vjbluyrmhgzcbltlvptj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZqYmx1eXJtaGd6Y2JsdGx2cHRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyMTA5NzIsImV4cCI6MjA4MDc4Njk3Mn0.Z_nm2JksoggrCymVmkrUsfR9wUPJvXzg0fhgEjcHecQ';

  // Storage buckets
  static const String resumeBucket = 'career-resumes';
  static const String avatarBucket = 'user-avatars';
  static const String projectBucket = 'project-thumbnails';

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Convenient accessor
  static SupabaseClient get client => Supabase.instance.client;
}
