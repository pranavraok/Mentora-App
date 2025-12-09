import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/services/roadmap_service_supabase.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'dart:math' as math;

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  final _educationController = TextEditingController();
  final _careerGoalController = TextEditingController();
  final _currentRoleController = TextEditingController();
  final List<String> _selectedSkills = [];
  final List<String> _selectedInterests = [];
  int _weeklyHours = 10;
  String _experienceLevel = 'Beginner';
  String _learningStyle = 'Visual';
  String _motivation = 'Career Switch';
  late AnimationController _floatingController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _educationController.dispose();
    _careerGoalController.dispose();
    _currentRoleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      // Get current user from Supabase Auth
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not logged in. Please sign in first.'),
            ),
          );
        }
        return;
      }

      // Get or create user ID from database
      var userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', currentUser.id)
          .maybeSingle();

      String userId;

      if (userResponse == null) {
        // User profile doesn't exist yet - create it now
        final insertResponse = await SupabaseConfig.client
            .from('users')
            .insert({
              'supabase_uid': currentUser.id,
              'email': currentUser.email!,
              'name': currentUser.userMetadata?['name'] ?? 'User',
              'onboarding_complete': false,
            })
            .select('id')
            .single();

        userId = insertResponse['id'] as String;
      } else {
        userId = userResponse['id'] as String;
      }

      // Build comprehensive onboarding payload
      final payload = {
        'user_id': userId,
        'career_goal': _careerGoalController.text,
        'current_skills': _selectedSkills,
        'target_skills': _selectedInterests,
        'experience': _experienceLevel,
        'education': _educationController.text,
        'learning_style': _learningStyle,
        'time_commitment': _weeklyHours,
        'motivation': _motivation,
      };

      // Call Supabase Edge Function to generate roadmap via Gemini AI
      final roadmapService = RoadmapService();
      final result = await roadmapService.generateRoadmap(
        userId: userId,
        careerGoal: _careerGoalController.text,
        currentSkills: _selectedSkills,
        targetSkills: _selectedInterests,
        experience: _experienceLevel,
        education: _educationController.text,
        learningStyle: _learningStyle,
        timelineMonths: (_weeklyHours * 4)
            .toInt(), // Rough estimate based on commitment
      );

      // Update user profile with onboarding data
      await SupabaseConfig.client
          .from('users')
          .update({
            'onboarding_complete': true,
            'career_goal': _careerGoalController.text,
            'college': _educationController.text,
            'last_activity': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Also update local user model via provider
      final userAsync = ref.read(currentUserProvider);
      await userAsync.when(
        data: (user) async {
          if (user == null) return;
          final updatedUser = user.copyWith(
            education: _educationController.text,
            careerGoal: _careerGoalController.text,
            skills: _selectedSkills,
            weeklyHours: _weeklyHours,
            updatedAt: DateTime.now(),
          );
          final userService = ref.read(userServiceProvider);
          await userService.updateUser(updatedUser);
        },
        loading: () async {},
        error: (_, __) async {},
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Roadmap generated! Welcome to your journey!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e, stackTrace) {
      print('Error completing onboarding: $e');
      print('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _educationController.text.isNotEmpty &&
            _experienceLevel.isNotEmpty;
      case 1:
        return _selectedSkills.isNotEmpty;
      case 2:
        return _careerGoalController.text.isNotEmpty && _motivation.isNotEmpty;
      case 3:
        return _selectedInterests.isNotEmpty;
      case 4:
        return _weeklyHours > 0 && _learningStyle.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ UPDATED BACKGROUND - SAME AS OTHER PAGES
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302b63),
                  Color(0xFF24243e),
                ],
              ),
            ),
          ),

          // Floating particles (SAME AS OTHER PAGES)
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final offset = math.sin(
                  (_floatingController.value + index * 0.2) * 2 * math.pi,
                );
                return Positioned(
                  left: (index * 50.0) + offset * 20,
                  top: (index * 80.0) + offset * 30,
                  child: Container(
                    width: 60 + (index * 10.0),
                    height: 60 + (index * 10.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Progress bar with step indicator
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Step ${_currentStep + 1} of 5',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${((_currentStep + 1) / 5 * 100).toInt()}%',
                            style: const TextStyle(
                              color: AppColors.xpGold,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / 5,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(
                            AppColors.xpGold,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2, end: 0),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStepContent()
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideX(begin: 0.2, end: 0),
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _currentStep--),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_currentStep > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _canProceed()
                                  ? [
                                      const Color(0xFFFFD700),
                                      const Color(0xFFFFA500),
                                    ]
                                  : [
                                      Colors.grey.shade400,
                                      Colors.grey.shade500,
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _canProceed()
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFD700,
                                      ).withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (_canProceed() && !_isSubmitting)
                                  ? () {
                                      if (_currentStep < 4) {
                                        setState(() => _currentStep++);
                                      } else {
                                        _completeOnboarding();
                                      }
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: _isSubmitting
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            'Generating your roadmap...',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _currentStep < 4
                                                ? 'Next'
                                                : '🎉 Complete Setup',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEducationStep();
      case 1:
        return _buildSkillsStep();
      case 2:
        return _buildCareerGoalStep();
      case 3:
        return _buildInterestsStep();
      case 4:
        return _buildPreferencesStep();
      default:
        return const SizedBox();
    }
  }

  // ============= STEP 1: EDUCATION & EXPERIENCE =============
  Widget _buildEducationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.school, color: AppColors.xpGold, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '📚 Let\'s Start With Your Background',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Education Background',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us about your educational journey',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _educationController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
                'e.g., Bachelor\'s in Computer Science from XYZ University',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: const Icon(Icons.history_edu, color: AppColors.xpGold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.xpGold, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Current Role (if any)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _currentRoleController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'e.g., Junior Developer, Student, Career Switcher',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: const Icon(Icons.work_outline, color: AppColors.xpGold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.xpGold, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Experience Level',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ['Beginner', 'Intermediate', 'Advanced', 'Expert'].map((
            level,
          ) {
            final isSelected = _experienceLevel == level;
            return GestureDetector(
              onTap: () => setState(() => _experienceLevel = level),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.xpGold
                        : Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      level,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ============= STEP 2: SKILLS =============
  Widget _buildSkillsStep() {
    final availableSkills = [
      'Python',
      'JavaScript',
      'React',
      'Node.js',
      'Flutter',
      'Java',
      'C++',
      'SQL',
      'MongoDB',
      'AWS',
      'Docker',
      'Git',
      'Machine Learning',
      'Data Science',
      'UI/UX Design',
      'DevOps',
      'TypeScript',
      'GraphQL',
      'Firebase',
      'Kubernetes',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.code, color: AppColors.xpGold, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '💻 Show Us Your Skills',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Your Skills',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select all skills you\'re comfortable with',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.xpGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: AppColors.xpGold, size: 16),
              const SizedBox(width: 8),
              Text(
                'Selected: ${_selectedSkills.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedSkills.remove(skill);
                  } else {
                    _selectedSkills.add(skill);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00f2fe)
                        : Colors.white.withOpacity(0.3),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check, color: Colors.white, size: 18),
                    if (isSelected) const SizedBox(width: 6),
                    Text(
                      skill,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ============= STEP 3: CAREER GOALS =============
  Widget _buildCareerGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.flag, color: AppColors.xpGold, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '🎯 Define Your Goals',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Career Goals',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Where do you see yourself in the future?',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _careerGoalController,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
                'e.g., Full Stack Developer at a FAANG company, building innovative products',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: const Icon(Icons.emoji_events, color: AppColors.xpGold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.xpGold, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'What\'s Your Main Motivation?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              [
                'Career Switch',
                'Skill Upgrade',
                'Get Promoted',
                'Start Freelancing',
                'Build Startup',
                'Get First Job',
              ].map((mot) {
                final isSelected = _motivation == mot;
                return GestureDetector(
                  onTap: () => setState(() => _motivation = mot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFf5576c)
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mot,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ============= STEP 4: INTERESTS =============
  Widget _buildInterestsStep() {
    final interests = [
      '🌐 Web Development',
      '📱 Mobile Apps',
      '🤖 AI/ML',
      '☁️ Cloud Computing',
      '🎮 Game Dev',
      '🎨 UI/UX Design',
      '🔐 Cybersecurity',
      '📊 Data Analytics',
      '⚡ IoT',
      '🔗 Blockchain',
      '🎯 Product Management',
      '📈 Digital Marketing',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.favorite, color: AppColors.xpGold, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '❤️ What Excites You?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Areas of Interest',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select topics you\'re passionate about learning',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.xpGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline, color: AppColors.xpGold, size: 16),
              const SizedBox(width: 8),
              Text(
                'Selected: ${_selectedInterests.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: interests.length,
          itemBuilder: (context, index) {
            final interest = interests[index];
            final isSelected = _selectedInterests.contains(interest);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedInterests.remove(interest);
                  } else {
                    _selectedInterests.add(interest);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF38f9d7)
                        : Colors.white.withOpacity(0.3),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                    if (isSelected) const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        interest,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ============= STEP 5: PREFERENCES =============
  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.tune, color: AppColors.xpGold, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⚙️ Personalize Your Journey',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Learning Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Let\'s customize your learning experience',
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        const SizedBox(height: 32),

        // Weekly hours
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Time Commitment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'How many hours per week?',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_weeklyHours hrs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 24,
                  ),
                  activeTrackColor: AppColors.xpGold,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: AppColors.xpGold,
                  overlayColor: AppColors.xpGold.withOpacity(0.3),
                ),
                child: Slider(
                  value: _weeklyHours.toDouble(),
                  min: 1,
                  max: 40,
                  divisions: 39,
                  onChanged: (value) =>
                      setState(() => _weeklyHours = value.toInt()),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '1 hr',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '40 hrs',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Learning style
        const Text(
          'Preferred Learning Style',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              [
                {
                  'icon': Icons.visibility,
                  'label': 'Visual',
                  'desc': 'Videos & Diagrams',
                },
                {
                  'icon': Icons.menu_book,
                  'label': 'Reading',
                  'desc': 'Articles & Docs',
                },
                {
                  'icon': Icons.people,
                  'label': 'Interactive',
                  'desc': 'Hands-on Projects',
                },
                {
                  'icon': Icons.mic,
                  'label': 'Auditory',
                  'desc': 'Podcasts & Audio',
                },
              ].map((style) {
                final isSelected = _learningStyle == style['label'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _learningStyle = style['label'] as String),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 60) / 2,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            )
                          : null,
                      color: isSelected ? null : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF764ba2)
                            : Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          style['icon'] as IconData,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          style['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          style['desc'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 40),

        // Final CTA
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.xpGold.withOpacity(0.2),
                AppColors.xpGold.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.xpGold.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.rocket_launch, color: AppColors.xpGold, size: 40),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Begin Your Journey?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete setup to unlock your personalized learning path!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}
