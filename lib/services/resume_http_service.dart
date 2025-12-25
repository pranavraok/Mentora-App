// =====================================================
// RESUME HTTP SERVICE - Node Backend Communication
// =====================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class ResumeHttpService {
  // Node backend URL - update port if needed
  static const String backendUrl = 'http://localhost:3002';

  /// Analyze resume by calling Node backend
  /// Returns: { overallScore, techScore, readabilityScore, suggestions }
  static Future<Map<String, dynamic>> analyzeResume({
    required String resumeUrl,
    required String userId,
  }) async {
    try {
      print('Calling Node resume backend at $backendUrl/api/resume/analyze');
      
      final response = await http.post(
        Uri.parse('$backendUrl/api/resume/analyze'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'resumeUrl': resumeUrl,
          'userId': userId,
        }),
      );

      print('Backend response status: ${response.statusCode}');
      print('Backend response body length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        print('\n=== PARSING RESPONSE ===');
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('Response is Map<String, dynamic>: ${data is Map<String, dynamic>}');
        print('Response keys: ${data.keys.toList()}');
        print('overallScore type: ${data['overallScore']?.runtimeType}');
        print('techScore type: ${data['techScore']?.runtimeType}');
        print('readabilityScore type: ${data['readabilityScore']?.runtimeType}');
        print('suggestions type: ${data['suggestions']?.runtimeType}');
        if (data['suggestions'] is List) {
          print('suggestions length: ${(data['suggestions'] as List).length}');
        }
        print('========================\n');
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Server returned ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Node backend: $e');
      rethrow;
    }
  }

  /// Check if backend is healthy
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Backend health check failed: $e');
      return false;
    }
  }
}
