# 📱 Flutter Integration Guide - Supabase Backend

Complete guide to integrate the Supabase backend with your Flutter app.

## 📦 Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.3.4

  # State Management (already have flutter_riverpod)
  flutter_riverpod: ^2.5.1

  # HTTP & Storage
  http: ^1.2.0
  path_provider: ^2.1.2

  # OCR for Resume Analysis (client-side)
  google_mlkit_text_recognition: ^0.11.0

  # Image Picker (already have)
  image_picker: ^1.0.7

  # Utilities
  url_launcher: ^6.2.4
  shared_preferences: ^2.2.2
```

Run:

```bash
flutter pub get
```

## 🔧 Initialize Supabase

### 1. Create `lib/core/supabase_config.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL'; // e.g., https://xxx.supabase.co
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: kDebugMode,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  // Quick access helpers
  static GoTrueClient get auth => client.auth;
  static SupabaseStorageClient get storage => client.storage;
  static RealtimeClient get realtime => client.realtime;
}
```

### 2. Update `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/core/supabase_config.dart';
import 'package:mentora_app/pages/landing_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentora - AI Career Platform',
      theme: ThemeData.dark(),
      home: const LandingPage(),
    );
  }
}
```

## 🔐 Authentication Service

Create `lib/services/auth_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mentora_app/core/supabase_config.dart';

class AuthService {
  final _auth = SupabaseConfig.auth;
  final _supabase = SupabaseConfig.client;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // Sign up with email
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    if (response.user != null) {
      // Create user profile
      await _supabase.from('users').insert({
        'supabase_uid': response.user!.id,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  // Sign in with email
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.mentora://login-callback',
      );
      return true;
    } catch (e) {
      print('Google sign-in error: $e');
      return false;
    }
  }

  // Sign in with GitHub
  Future<bool> signInWithGitHub() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.mentora://login-callback',
      );
      return true;
    } catch (e) {
      print('GitHub sign-in error: $e');
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('supabase_uid', userId)
        .single();
    return response;
  }
}
```

## 🗺️ Roadmap Service

Create `lib/services/roadmap_service_supabase.dart`:

```dart
import 'package:mentora_app/core/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoadmapServiceSupabase {
  final _supabase = SupabaseConfig.client;
  final _functions = SupabaseConfig.client.functions;

  // Generate personalized roadmap using Gemini AI
  Future<Map<String, dynamic>> generateRoadmap({
    required Map<String, dynamic> userProfile,
  }) async {
    final response = await _functions.invoke(
      'generate-roadmap',
      body: {'user_profile': userProfile},
    );

    if (response.status != 200) {
      throw Exception('Failed to generate roadmap: ${response.data}');
    }

    return response.data as Map<String, dynamic>;
  }

  // Fetch user's roadmap nodes
  Future<List<Map<String, dynamic>>> getUserRoadmap(String userId) async {
    final response = await _supabase
        .from('roadmap_nodes')
        .select()
        .eq('user_id', userId)
        .order('order_index', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  // Update node progress
  Future<void> updateNodeProgress({
    required String nodeId,
    required int progressPercentage,
    String? status,
  }) async {
    final updates = {
      'progress_percentage': progressPercentage,
      if (status != null) 'status': status,
      if (progressPercentage == 100) 'completed_at': DateTime.now().toIso8601String(),
    };

    await _supabase
        .from('roadmap_nodes')
        .update(updates)
        .eq('id', nodeId);
  }

  // Subscribe to roadmap changes (realtime)
  RealtimeChannel subscribeToRoadmap(
    String userId,
    void Function(Map<String, dynamic> payload) onUpdate,
  ) {
    final channel = _supabase
        .channel('roadmap:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'roadmap_nodes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onUpdate(payload.newRecord),
        )
        .subscribe();

    return channel;
  }
}
```

## 🎮 Gamification Service

Create `lib/services/gamification_service.dart`:

```dart
import 'package:mentora_app/core/supabase_config.dart';

class GamificationService {
  final _supabase = SupabaseConfig.client;
  final _functions = SupabaseConfig.client.functions;

  // Award XP (called by backend, but can trigger from client)
  Future<Map<String, dynamic>> awardXP({
    required String userId,
    required int amount,
    required String reason,
    required String source,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _functions.invoke(
      'award-xp',
      body: {
        'user_id': userId,
        'amount': amount,
        'reason': reason,
        'source': source,
        'metadata': metadata ?? {},
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Claim daily rewards
  Future<Map<String, dynamic>> claimDailyRewards() async {
    final response = await _functions.invoke('daily-rewards');
    return response.data as Map<String, dynamic>;
  }

  // Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    final response = await _supabase
        .from('achievements')
        .select()
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Get notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final response = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(response);
  }

  // Mark notification as read
  Future<void> markNotificationRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'read': true})
        .eq('id', notificationId);
  }

  // Subscribe to notifications (realtime)
  RealtimeChannel subscribeToNotifications(
    String userId,
    void Function(Map<String, dynamic> notification) onNotification,
  ) {
    return _supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => onNotification(payload.newRecord),
        )
        .subscribe();
  }
}
```

## 📊 Project Service

Create `lib/services/project_service_supabase.dart`:

```dart
import 'package:mentora_app/core/supabase_config.dart';

class ProjectServiceSupabase {
  final _supabase = SupabaseConfig.client;
  final _functions = SupabaseConfig.client.functions;

  // Get all projects
  Future<List<Map<String, dynamic>>> getProjects({
    String? category,
    String? difficulty,
    bool? featured,
  }) async {
    var query = _supabase.from('projects').select();

    if (category != null) query = query.eq('category', category);
    if (difficulty != null) query = query.eq('difficulty', difficulty);
    if (featured != null) query = query.eq('is_featured', featured);

    query = query.order('trending_score', ascending: false);

    final response = await query;
    return List<Map<String, dynamic>>.from(response);
  }

  // Get user's project progress
  Future<List<Map<String, dynamic>>> getUserProjectProgress(String userId) async {
    final response = await _supabase
        .from('user_project_progress')
        .select('*, projects(*)')
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // Unlock project
  Future<Map<String, dynamic>> unlockProject(String projectId) async {
    final response = await _functions.invoke(
      'unlock-project',
      body: {'project_id': projectId},
    );

    return response.data as Map<String, dynamic>;
  }

  // Complete project
  Future<Map<String, dynamic>> completeProject({
    required String projectId,
    String? githubUrl,
    String? demoUrl,
    String? submissionNotes,
  }) async {
    final response = await _functions.invoke(
      'complete-project',
      body: {
        'project_id': projectId,
        'github_url': githubUrl,
        'demo_url': demoUrl,
        'submission_notes': submissionNotes,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Update project progress
  Future<void> updateProjectProgress({
    required String projectId,
    required String userId,
    required int progressPercentage,
    String? status,
  }) async {
    await _supabase
        .from('user_project_progress')
        .update({
          'progress_percentage': progressPercentage,
          if (status != null) 'status': status,
        })
        .eq('project_id', projectId)
        .eq('user_id', userId);
  }
}
```

## 🏆 Leaderboard Service

Create `lib/services/leaderboard_service.dart`:

```dart
import 'package:mentora_app/core/supabase_config.dart';

class LeaderboardService {
  final _functions = SupabaseConfig.client.functions;
  final _supabase = SupabaseConfig.client;

  // Fetch leaderboard
  Future<Map<String, dynamic>> getLeaderboard({
    String period = 'all_time', // daily, weekly, monthly, all_time
    String category = 'overall', // overall, projects, courses, streak
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _functions.invoke(
      'leaderboard',
      method: HttpMethod.get,
      queryParameters: {
        'period': period,
        'category': category,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Subscribe to leaderboard updates (realtime)
  RealtimeChannel subscribeToLeaderboard(
    void Function() onUpdate,
  ) {
    return _supabase
        .channel('leaderboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_cache',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
```

## 📄 Resume Service

Create `lib/services/resume_service.dart`:

```dart
import 'dart:io';
import 'package:mentora_app/core/supabase_config.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ResumeService {
  final _supabase = SupabaseConfig.client;
  final _functions = SupabaseConfig.client.functions;
  final _storage = SupabaseConfig.storage;

  // Upload resume file
  Future<String> uploadResume(File file, String userId) async {
    final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final path = 'resumes/$fileName';

    await _storage.from('career-resumes').upload(path, file);

    final publicUrl = _storage.from('career-resumes').getPublicUrl(path);
    return publicUrl;
  }

  // Extract text from image using ML Kit (client-side OCR)
  Future<String> extractTextFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer();

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } finally {
      textRecognizer.close();
    }
  }

  // Analyze resume with AI
  Future<Map<String, dynamic>> analyzeResume({
    required String fileUrl,
    required String fileName,
    required String extractedText,
    String? targetRole,
    String? targetCompany,
  }) async {
    final response = await _functions.invoke(
      'analyze-resume',
      body: {
        'file_url': fileUrl,
        'file_name': fileName,
        'extracted_text': extractedText,
        'target_role': targetRole,
        'target_company': targetCompany,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // Get user's resume analyses
  Future<List<Map<String, dynamic>>> getResumeAnalyses(String userId) async {
    final response = await _supabase
        .from('resume_analyses')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
```

## 🔄 Riverpod Providers

Create `lib/providers/supabase_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/services/auth_service.dart';
import 'package:mentora_app/services/roadmap_service_supabase.dart';
import 'package:mentora_app/services/gamification_service.dart';
import 'package:mentora_app/services/project_service_supabase.dart';
import 'package:mentora_app/services/leaderboard_service.dart';
import 'package:mentora_app/services/resume_service.dart';

// Service Providers
final authServiceProvider = Provider((ref) => AuthService());
final roadmapServiceProvider = Provider((ref) => RoadmapServiceSupabase());
final gamificationServiceProvider = Provider((ref) => GamificationService());
final projectServiceProvider = Provider((ref) => ProjectServiceSupabase());
final leaderboardServiceProvider = Provider((ref) => LeaderboardService());
final resumeServiceProvider = Provider((ref) => ResumeService());

// Auth State Provider
final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider((ref) {
  return ref.watch(authServiceProvider).currentUser;
});
```

## 🚀 Usage Examples

### Example: Complete Onboarding & Generate Roadmap

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  final RoadmapServiceSupabase _roadmapService;

  OnboardingController(this._roadmapService) : super(const AsyncValue.data(null));

  Future<void> completeOnboarding(Map<String, dynamic> userProfile) async {
    state = const AsyncValue.loading();

    try {
      final result = await _roadmapService.generateRoadmap(
        userProfile: {
          'name': 'John Doe',
          'career_goal': 'Full-Stack Web Developer',
          'current_skills': [
            {'skill': 'HTML', 'level': 'Advanced'},
            {'skill': 'CSS', 'level': 'Advanced'},
            {'skill': 'JavaScript', 'level': 'Intermediate'},
          ],
          'target_skills': [
            {'skill': 'React', 'level': 'Advanced'},
            {'skill': 'Node.js', 'level': 'Advanced'},
            {'skill': 'PostgreSQL', 'level': 'Intermediate'},
          ],
          'interests': ['Web Development', 'UI/UX'],
          'timeline_months': 6,
        },
      );

      state = const AsyncValue.data(null);
      // Navigate to dashboard
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

### Example: Realtime Notifications

```dart
class NotificationsPage extends ConsumerStatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null) {
      _channel = ref.read(gamificationServiceProvider).subscribeToNotifications(
        userId,
        (notification) {
          // Show snackbar or update UI
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(notification['title'])),
          );
        },
      );
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
```

## 🔒 Environment Variables

Create `.env` file in project root:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

Use `flutter_dotenv` package to load:

```yaml
# pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0

# Load in main.dart
await dotenv.load(fileName: ".env");
```

## ✅ Testing

Test connection:

```dart
void testSupabaseConnection() async {
  try {
    final response = await SupabaseConfig.client
        .from('users')
        .select()
        .limit(1);
    print('✅ Supabase connected: $response');
  } catch (e) {
    print('❌ Supabase error: $e');
  }
}
```

---

**Your backend is now fully integrated! 🎉**

All Edge Functions are deployed and ready to use with the services provided above.
