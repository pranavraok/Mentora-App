import 'package:cloud_firestore/cloud_firestore.dart';

class ResumeSection {
  final String name;
  final int score;
  final List<String> feedback;
  final List<String> suggestions;

  ResumeSection({
    required this.name,
    required this.score,
    required this.feedback,
    required this.suggestions,
  });

  factory ResumeSection.fromJson(Map<String, dynamic> json) {
    return ResumeSection(
      name: json['name'] as String,
      score: json['score'] as int,
      feedback: (json['feedback'] as List<dynamic>).cast<String>(),
      suggestions: (json['suggestions'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'score': score,
    'feedback': feedback,
    'suggestions': suggestions,
  };
}

class ResumeAnalysis {
  final String id;
  final String userId;
  final String fileName;
  final String? fileUrl;
  final int overallScore;
  final List<ResumeSection> sections;
  final List<String> keywords;
  final List<String> missingKeywords;
  final double atsScore;
  final String? improvedVersion;
  final DateTime analyzedAt;

  ResumeAnalysis({
    required this.id,
    required this.userId,
    required this.fileName,
    this.fileUrl,
    required this.overallScore,
    required this.sections,
    required this.keywords,
    required this.missingKeywords,
    required this.atsScore,
    this.improvedVersion,
    required this.analyzedAt,
  });

  factory ResumeAnalysis.fromJson(Map<String, dynamic> json) {
    return ResumeAnalysis(
      id: json['id'] as String,
      userId: json['userId'] as String,
      fileName: json['fileName'] as String,
      fileUrl: json['fileUrl'] as String?,
      overallScore: json['overallScore'] as int,
      sections: (json['sections'] as List<dynamic>)
          .map((e) => ResumeSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      keywords: (json['keywords'] as List<dynamic>).cast<String>(),
      missingKeywords: (json['missingKeywords'] as List<dynamic>).cast<String>(),
      atsScore: (json['atsScore'] as num).toDouble(),
      improvedVersion: json['improvedVersion'] as String?,
      analyzedAt: json['analyzedAt'] is Timestamp
          ? (json['analyzedAt'] as Timestamp).toDate()
          : DateTime.parse(json['analyzedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'fileName': fileName,
    'fileUrl': fileUrl,
    'overallScore': overallScore,
    'sections': sections.map((e) => e.toJson()).toList(),
    'keywords': keywords,
    'missingKeywords': missingKeywords,
    'atsScore': atsScore,
    'improvedVersion': improvedVersion,
    'analyzedAt': analyzedAt.toIso8601String(),
  };
}
