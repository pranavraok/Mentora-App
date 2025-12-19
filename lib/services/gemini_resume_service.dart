// =====================================================
// GEMINI RESUME ANALYSIS SERVICE
// =====================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:mentora_app/config/gemini_config.dart';
import 'package:mentora_app/models/resume_analysis_result.dart';

/// Service for analyzing resumes using Google Gemini AI
///
/// This service handles:
/// 1. PDF text extraction from uploaded files
/// 2. Sending resume text to Gemini for analysis
/// 3. Parsing structured JSON responses from Gemini
///
/// NO Supabase Edge Functions are used - this is pure client-side analysis
class GeminiResumeService {
  /// Extract text from PDF file bytes
  ///
  /// Returns the full text content of the PDF
  /// Throws an exception if extraction fails
  Future<String> extractTextFromPdf(Uint8List pdfBytes) async {
    try {
      // Load PDF document from bytes
      final PdfDocument document = PdfDocument(inputBytes: pdfBytes);

      // Extract text from all pages
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String fullText = extractor.extractText();

      // Dispose the document
      document.dispose();

      if (fullText.trim().isEmpty) {
        throw Exception(
          'No text could be extracted from the PDF. The file may be image-based or corrupted.',
        );
      }

      print('✓ Extracted ${fullText.length} characters from PDF');
      return fullText.trim();
    } catch (e) {
      print('Error extracting text from PDF: $e');
      throw Exception('Failed to extract text from PDF: $e');
    }
  }

  /// Analyze resume text using Gemini AI
  ///
  /// Returns structured analysis with scores and suggestions
  /// Throws an exception if analysis fails
  Future<ResumeAnalysisResult> analyzeResumeWithGemini(
    String resumeText,
  ) async {
    // Check API key is configured
    if (!GeminiConfig.isConfigured) {
      throw Exception(
        'Gemini API key not configured. '
        'Please update lib/config/gemini_config.dart with your API key.',
      );
    }

    try {
      // Initialize Gemini model with JSON mode and schema
      final model = GenerativeModel(
        model: GeminiConfig.model,
        apiKey: GeminiConfig.apiKey,
        generationConfig: GenerationConfig(
          temperature: GeminiConfig.temperature,
          maxOutputTokens: 4096, // Increased to prevent truncation
          responseMimeType: 'application/json', // Force strict JSON output
          responseSchema: Schema.object(
            properties: {
              'overallScore': Schema.integer(
                description: 'Overall resume score from 0 to 100',
              ),
              'skillsScore': Schema.integer(
                description: 'Technical skills score from 0 to 100',
              ),
              'experienceScore': Schema.integer(
                description: 'Experience and achievements score from 0 to 100',
              ),
              'readabilityScore': Schema.integer(
                description: 'Readability and formatting score from 0 to 100',
              ),
              'suggestions': Schema.array(
                description: 'List of improvement suggestions',
                items: Schema.object(
                  properties: {
                    'title': Schema.string(
                      description: 'Short suggestion title (3-5 words)',
                    ),
                    'detail': Schema.string(
                      description: 'Detailed actionable advice (1-2 sentences)',
                    ),
                  },
                  requiredProperties: ['title', 'detail'],
                ),
              ),
            },
            requiredProperties: [
              'overallScore',
              'skillsScore',
              'experienceScore',
              'readabilityScore',
              'suggestions',
            ],
          ),
        ),
      );

      // Create prompt for structured resume analysis
      final prompt = _buildAnalysisPrompt(resumeText);

      print('→ Sending resume to Gemini for analysis...');

      // Generate response with JSON schema
      final response = await model.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Gemini returned empty response');
      }

      print('✓ Received response from Gemini');
      print('Response length: ${response.text!.length} characters');

      // Parse JSON from response (should be clean JSON now, no markdown)
      return _parseGeminiResponse(response.text!);
    } catch (e) {
      print('Error calling Gemini API: $e');

      // Provide user-friendly error messages
      if (e.toString().contains('API_KEY')) {
        throw Exception(
          'Invalid Gemini API key. Please check your configuration.',
        );
      } else if (e.toString().contains('QUOTA')) {
        throw Exception('Gemini API quota exceeded. Please try again later.');
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        throw Exception(
          'Network error. Please check your internet connection.',
        );
      } else {
        throw Exception('Failed to analyze resume: $e');
      }
    }
  }

  /// Build the analysis prompt for Gemini
  String _buildAnalysisPrompt(String resumeText) {
    return '''
You are an expert resume analyzer for tech roles. Analyze the following resume and provide scores and suggestions.

RESUME TEXT:
$resumeText

ANALYSIS TASK:
1. Evaluate the resume across 4 dimensions (each scored 0-100):
   - overallScore: Holistic assessment of the entire resume
   - skillsScore: Relevance and depth of technical skills listed
   - experienceScore: Quality of work experience, achievements, and measurable impact
   - readabilityScore: Formatting, clarity, grammar, and professional structure

2. Provide 3-5 actionable improvement suggestions with:
   - title: Short, specific recommendation (3-5 words)
   - detail: Concrete actionable advice (1-2 sentences)

IMPORTANT:
- Be specific and actionable in all suggestions
- Focus on tech industry standards and best practices
- Consider ATS optimization and recruiter preferences
- Highlight measurable achievements and quantifiable results
''';
  }

  /// Parse Gemini's text response into ResumeAnalysisResult
  ///
  /// With JSON mode enabled, response should be clean JSON without markdown
  ResumeAnalysisResult _parseGeminiResponse(String responseText) {
    try {
      // Clean the response - remove any whitespace
      String cleanedText = responseText.trim();

      // With responseMimeType: 'application/json', we should get clean JSON
      // But still handle edge cases where markdown might slip through
      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      } else if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }

      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      cleanedText = cleanedText.trim();

      // Parse JSON
      final Map<String, dynamic> jsonData = jsonDecode(cleanedText);

      print('✓ Successfully parsed Gemini JSON response');
      print(
        '  Scores: Overall=${jsonData['overallScore']}, Skills=${jsonData['skillsScore']}, Experience=${jsonData['experienceScore']}, Readability=${jsonData['readabilityScore']}',
      );
      print('  Suggestions: ${(jsonData['suggestions'] as List).length}');

      // Convert to model
      return ResumeAnalysisResult.fromJson(jsonData);
    } catch (e) {
      print('❌ Error parsing Gemini response: $e');
      print(
        'Response text (first 500 chars): ${responseText.substring(0, responseText.length > 500 ? 500 : responseText.length)}',
      );

      // Try to extract any JSON from the response as fallback
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(responseText);
        if (jsonMatch != null) {
          print('Attempting fallback JSON extraction...');
          final jsonData = jsonDecode(jsonMatch.group(0)!);
          return ResumeAnalysisResult.fromJson(jsonData);
        }
      } catch (fallbackError) {
        print('Fallback parsing also failed: $fallbackError');
      }

      throw Exception('Failed to parse JSON from Gemini response: $e');
    }
  }

  /// Complete resume analysis pipeline: PDF → Text → Analysis
  ///
  /// This is the main method to call from UI
  Future<ResumeAnalysisResult> analyzePdfResume(Uint8List pdfBytes) async {
    // Step 1: Extract text from PDF
    final String resumeText = await extractTextFromPdf(pdfBytes);

    // Step 2: Analyze with Gemini
    final result = await analyzeResumeWithGemini(resumeText);

    return result;
  }
}
