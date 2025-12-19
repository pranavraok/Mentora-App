// =====================================================
// RESUME ANALYSIS RESULT MODEL
// =====================================================

/// Model class for structured resume analysis results from Gemini
class ResumeAnalysisResult {
  /// Overall resume score (0-100)
  final int overallScore;

  /// Technical skills score (0-100)
  final int skillsScore;

  /// Experience and achievements score (0-100)
  final int experienceScore;

  /// Readability and formatting score (0-100)
  final int readabilityScore;

  /// List of improvement suggestions
  final List<ResumeSuggestion> suggestions;

  ResumeAnalysisResult({
    required this.overallScore,
    required this.skillsScore,
    required this.experienceScore,
    required this.readabilityScore,
    required this.suggestions,
  });

  /// Parse from Gemini JSON response
  ///
  /// Handles malformed JSON gracefully by providing defaults
  factory ResumeAnalysisResult.fromJson(Map<String, dynamic> json) {
    try {
      // Parse suggestions list
      final suggestionsJson = json['suggestions'] as List<dynamic>? ?? [];
      final suggestions = suggestionsJson
          .map((item) {
            if (item is Map<String, dynamic>) {
              return ResumeSuggestion.fromJson(item);
            }
            return null;
          })
          .where((item) => item != null)
          .cast<ResumeSuggestion>()
          .toList();

      return ResumeAnalysisResult(
        overallScore: _parseScore(json['overallScore']),
        skillsScore: _parseScore(json['skillsScore']),
        experienceScore: _parseScore(json['experienceScore']),
        readabilityScore: _parseScore(json['readabilityScore']),
        suggestions: suggestions,
      );
    } catch (e) {
      print('Error parsing ResumeAnalysisResult: $e');
      // Return default values on error
      return ResumeAnalysisResult(
        overallScore: 0,
        skillsScore: 0,
        experienceScore: 0,
        readabilityScore: 0,
        suggestions: [
          ResumeSuggestion(
            title: 'Analysis Error',
            detail: 'Could not parse the resume analysis. Please try again.',
          ),
        ],
      );
    }
  }

  /// Parse score from dynamic type, ensuring it's between 0-100
  static int _parseScore(dynamic value) {
    if (value == null) return 0;

    int score;
    if (value is int) {
      score = value;
    } else if (value is double) {
      score = value.round();
    } else if (value is String) {
      score = int.tryParse(value) ?? 0;
    } else {
      score = 0;
    }

    // Clamp between 0 and 100
    return score.clamp(0, 100);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'overallScore': overallScore,
    'skillsScore': skillsScore,
    'experienceScore': experienceScore,
    'readabilityScore': readabilityScore,
    'suggestions': suggestions.map((s) => s.toJson()).toList(),
  };
}

/// Model for individual resume improvement suggestion
class ResumeSuggestion {
  /// Title of the suggestion
  final String title;

  /// Detailed explanation
  final String detail;

  ResumeSuggestion({required this.title, required this.detail});

  factory ResumeSuggestion.fromJson(Map<String, dynamic> json) {
    return ResumeSuggestion(
      title: json['title']?.toString() ?? 'Suggestion',
      detail: json['detail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'detail': detail};
}
