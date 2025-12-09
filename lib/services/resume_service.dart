// =====================================================
// RESUME ANALYSIS SERVICE
// =====================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/config/supabase_config.dart';

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
        .uploadBinary(fileName, fileBytes);

    return _client.storage
        .from(SupabaseConfig.resumeBucket)
        .getPublicUrl(fileName);
  }

  // Analyze resume (via Edge Function with Gemini)
  Future<Map<String, dynamic>> analyzeResume({
    required String userId,
    required String resumeText, // From OCR (Tesseract.js in Flutter)
    required String fileUrl,
    String? fileName,
  }) async {
    final response = await _client.functions.invoke(
      'analyze-resume',
      body: {
        'user_id': userId,
        'resume_text': resumeText,
        'file_url': fileUrl,
        'file_name': fileName,
      },
    );

    return response.data as Map<String, dynamic>;
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
