// =====================================================
// RESUME ANALYSIS SERVICE
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'dart:typed_data';

class ResumeService {
  final SupabaseClient _client = SupabaseConfig.client;

  // Upload resume to storage
  Future<String> uploadResume(
    String userId,
    String filePath,
    List<int> fileBytes,
  ) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';

    await _client.storage
        .from(SupabaseConfig.resumeBucket)
        .uploadBinary(fileName, Uint8List.fromList(fileBytes));

    return _client.storage
        .from(SupabaseConfig.resumeBucket)
        .getPublicUrl(fileName);
  }

  // Analyze resume via Node backend (use ResumeHttpService instead)
  // This method is deprecated - use ResumeHttpService.analyzeResume() directly
  @Deprecated('Use ResumeHttpService.analyzeResume() instead')
  Future<Map<String, dynamic>> analyzeResume({
    required String userId,
    required String resumeText,
    required String fileUrl,
    String? fileName,
  }) async {
    throw UnimplementedError(
      'This method uses Supabase Edge Functions which are deprecated. '
      'Use ResumeHttpService.analyzeResume() instead with resumeUrl and userId.'
    );
  }

  // Get resume analysis history
  Future<List<Map<String, dynamic>>> getResumeHistory(String userId) async {
    final response = await _client
        .from('resume_analyses')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get latest analysis
  Future<Map<String, dynamic>?> getLatestAnalysis(String userId) async {
    final response = await _client
        .from('resume_analyses')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }
}
