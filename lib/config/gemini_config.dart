// =====================================================
// GEMINI API CONFIGURATION
// =====================================================

import 'package:flutter_dotenv/flutter_dotenv.dart';


class GeminiConfig {
  /// Gemini API key loaded from environment variables
  static String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Check if API key is configured
  static bool get isConfigured =>
      apiKey.isNotEmpty && apiKey != 'YOUR_GEMINI_API_KEY_HERE';

  /// Gemini model to use for resume analysis
  static String get model => dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';

  /// Maximum tokens for response
  static const int maxTokens = 2048;

  /// Temperature for response generation (0.0 - 1.0)
  /// Lower = more focused, Higher = more creative
  static const double temperature = 0.2;
}
