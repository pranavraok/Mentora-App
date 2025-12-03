import 'package:cloud_firestore/cloud_firestore.dart';

class Skill {
  final String id;
  final String userId;
  final String name;
  final String category;
  final int currentProficiency;
  final int targetProficiency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Skill({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.currentProficiency = 0,
    this.targetProficiency = 100,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      currentProficiency: json['currentProficiency'] as int? ?? 0,
      targetProficiency: json['targetProficiency'] as int? ?? 100,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'category': category,
    'currentProficiency': currentProficiency,
    'targetProficiency': targetProficiency,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  int get gap => targetProficiency - currentProficiency;
  double get gapPercentage => gap / targetProficiency;
}

class Course {
  final String id;
  final String title;
  final String description;
  final String provider;
  final String skillName;
  final int durationHours;
  final String difficulty;
  final double price;
  final double rating;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.provider,
    required this.skillName,
    required this.durationHours,
    required this.difficulty,
    required this.price,
    required this.rating,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      provider: json['provider'] as String,
      skillName: json['skillName'] as String,
      durationHours: json['durationHours'] as int,
      difficulty: json['difficulty'] as String,
      price: (json['price'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      url: json['url'] as String,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'provider': provider,
    'skillName': skillName,
    'durationHours': durationHours,
    'difficulty': difficulty,
    'price': price,
    'rating': rating,
    'url': url,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
