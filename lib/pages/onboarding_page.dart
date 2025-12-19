import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/services/roadmap_service_supabase.dart';
import 'package:mentora_app/theme.dart';

import '../providers/daily_challenge_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/user_activity_provider.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

/// Simple responsive layout helper
class _LayoutConfig {
  final double titleSize;
  final double sectionTitleSize;
  final double bodySize;
  final double chipFontSize;
  final double chipPaddingH;
  final double chipPaddingV;
  final double maxContentWidth;
  final int gridCrossAxisCount;
  final double topPadding;

  _LayoutConfig({
    required this.titleSize,
    required this.sectionTitleSize,
    required this.bodySize,
    required this.chipFontSize,
    required this.chipPaddingH,
    required this.chipPaddingV,
    required this.maxContentWidth,
    required this.gridCrossAxisCount,
    required this.topPadding,
  });

  factory _LayoutConfig.fromWidth(double width) {
    if (width <= 360) {
      // very small phones
      return _LayoutConfig(
        titleSize: 22,
        sectionTitleSize: 18,
        bodySize: 13,
        chipFontSize: 12,
        chipPaddingH: 12,
        chipPaddingV: 8,
        maxContentWidth: 420,
        gridCrossAxisCount: 2,
        topPadding: 12,
      );
    } else if (width <= 420) {
      // normal phones
      return _LayoutConfig(
        titleSize: 24,
        sectionTitleSize: 20,
        bodySize: 14,
        chipFontSize: 13,
        chipPaddingH: 14,
        chipPaddingV: 10,
        maxContentWidth: 460,
        gridCrossAxisCount: 2,
        topPadding: 16,
      );
    } else if (width <= 600) {
      // large phones / small tablets
      return _LayoutConfig(
        titleSize: 26,
        sectionTitleSize: 22,
        bodySize: 15,
        chipFontSize: 14,
        chipPaddingH: 16,
        chipPaddingV: 10,
        maxContentWidth: 520,
        gridCrossAxisCount: 2,
        topPadding: 20,
      );
    } else {
      // tablets
      return _LayoutConfig(
        titleSize: 28,
        sectionTitleSize: 22,
        bodySize: 16,
        chipFontSize: 14,
        chipPaddingH: 18,
        chipPaddingV: 12,
        maxContentWidth: 640,
        gridCrossAxisCount: 3,
        topPadding: 24,
      );
    }
  }
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
  String _careerField = 'Engineering';

  late AnimationController _floatingController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _educationController.addListener(() => setState(() {}));
    _careerGoalController.addListener(() => setState(() {}));
    _currentRoleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _educationController.dispose();
    _careerGoalController.dispose();
    _currentRoleController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _showAIGeneratingPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (BuildContext dialogContext) {
        return _AIGeneratingPopup();
      },
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    _showAIGeneratingPopup();

    try {
      final currentUser = SupabaseConfig.client.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Not logged in. Please sign in first.'),
            ),
          );
        }
        return;
      }

      var userResponse = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('supabase_uid', currentUser.id)
          .maybeSingle();

      String userId;
      if (userResponse == null) {
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

      final roadmapService = RoadmapService();
      await roadmapService.generateRoadmap(
        userId: userId,
        careerGoal: _careerGoalController.text,
        currentSkills: _selectedSkills,
        targetSkills: _selectedInterests,
        experience: _experienceLevel,
        education: _educationController.text,
        learningStyle: _learningStyle,
        timelineMonths: (_weeklyHours * 4).toInt(),
      );

      await SupabaseConfig.client.from('users').update({
        'onboarding_complete': true,
        'career_goal': _careerGoalController.text,
        'college': _educationController.text,
        'last_activity': DateTime.now().toIso8601String(),
      }).eq('id', userId);

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

      // ✅ FIX: Properly await Future.wait with correct error handling
      try {
        await Future.wait([
          ref.refresh(currentUserProvider.future),
          ref.refresh(gamificationProvider.future).catchError((_) => null),
          ref.refresh(dailyChallengeProvider.future).catchError((_) => null),
          ref.refresh(recentActivitiesProvider.future).catchError((_) => null),
        ] as Iterable<Future>);
      } catch (e) {
        // Ignore provider refresh errors
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Roadmap generated! Welcome to your journey!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } catch (e, stackTrace) {
      // ignore: avoid_print
      print('Error completing onboarding: $e');
      // ignore: avoid_print
      print('Stack trace: $stackTrace');
      if (mounted) {
        Navigator.of(context).pop();
        final errorMessage = e.toString().toLowerCase();
        final isQuotaError = errorMessage.contains('429') ||
            errorMessage.contains('resource_exhausted') ||
            errorMessage.contains('quota');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isQuotaError
                  ? '⏳ LLM quota exceeded, please try again later.'
                  : 'Error: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: isQuotaError ? 5 : 3),
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
        return _careerField.isNotEmpty && _experienceLevel.isNotEmpty;
      case 1:
        return _educationController.text.trim().isNotEmpty;
      case 2:
        return _selectedSkills.isNotEmpty;
      case 3:
        return _careerGoalController.text.trim().isNotEmpty &&
            _motivation.isNotEmpty;
      case 4:
        return _selectedInterests.isNotEmpty;
      case 5:
        return _weeklyHours > 0 && _learningStyle.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final layout = _LayoutConfig.fromWidth(size.width);

    return Scaffold(
      body: Stack(
        children: [
          // background
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
          // floating circles
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final offset = math.sin(
                  (_floatingController.value + index * 0.2) * 2 * math.pi,
                ) *
                    20;
                return Positioned(
                  left: (index * 50.0) + offset,
                  top: (index * 80.0) +
                      math.sin(
                        (_floatingController.value + index * 0.2) *
                            2 *
                            math.pi,
                      ) *
                          30,
                  child: Container(
                    width: 40 + (index * 8.0),
                    height: 40 + (index * 8.0),
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
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: layout.maxContentWidth),
                child: Column(
                  children: [
                    // top progress
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        layout.topPadding,
                        20,
                        12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Step ${_currentStep + 1} of 6',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${((_currentStep + 1) / 6 * 100).toInt()}%',
                                style: const TextStyle(
                                  color: AppColors.xpGold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: (_currentStep + 1) / 6,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.xpGold,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(
                      begin: -0.2,
                      end: 0,
                    ),
                    // main content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: _buildStepContent(layout),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideX(begin: 0.2, end: 0),
                    ),
                    // bottom buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Row(
                        children: [
                          if (_currentStep > 0)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => setState(
                                      () => _currentStep--,
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Back',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_currentStep > 0) const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _canProceed()
                                      ? const [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ]
                                      : [
                                    Colors.grey.shade400,
                                    Colors.grey.shade500,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _canProceed()
                                    ? [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700)
                                        .withOpacity(0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                                    : [],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: (_canProceed() && !_isSubmitting)
                                      ? () {
                                    if (_currentStep < 5) {
                                      setState(
                                            () => _currentStep++,
                                      );
                                    } else {
                                      _completeOnboarding();
                                    }
                                  }
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _currentStep < 5
                                              ? 'Next'
                                              : '🎉 Complete Setup',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 20,
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
                    ).animate().fadeIn(delay: 300.ms).slideY(
                      begin: 0.2,
                      end: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(_LayoutConfig layout) {
    switch (_currentStep) {
      case 0:
        return _buildCareerFieldStep(layout);
      case 1:
        return _buildEducationStep(layout);
      case 2:
        return _buildSkillsStep(layout);
      case 3:
        return _buildCareerGoalStep(layout);
      case 4:
        return _buildInterestsStep(layout);
      case 5:
        return _buildPreferencesStep(layout);
      default:
        return const SizedBox();
    }
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required _LayoutConfig layout,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.xpGold, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: layout.sectionTitleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerFieldStep(_LayoutConfig layout) {
    final careerFields = [
      {
        'icon': '💻',
        'label': 'Engineering',
        'color': const Color(0xFF4facfe)
      },
      {'icon': '⚕️', 'label': 'Medical', 'color': const Color(0xFF43e97b)},
      {
        'icon': '💼',
        'label': 'Business/MBA',
        'color': const Color(0xFFf093fb)
      },
      {'icon': '📊', 'label': 'Commerce', 'color': const Color(0xFFFFD700)},
      {
        'icon': '🎨',
        'label': 'Arts & Design',
        'color': const Color(0xFFf5576c)
      },
      {'icon': '⚖️', 'label': 'Law', 'color': const Color(0xFF667eea)},
      {
        'icon': '🔬',
        'label': 'Science & Research',
        'color': const Color(0xFF38f9d7)
      },
      {'icon': '📚', 'label': 'Education', 'color': const Color(0xFFfda085)},
      {'icon': '📢', 'label': 'Marketing', 'color': const Color(0xFFa8edea)},
      {
        'icon': '🏗️',
        'label': 'Architecture',
        'color': const Color(0xFFfed6e3)
      },
      {
        'icon': '🎬',
        'label': 'Media & Entertainment',
        'color': const Color(0xFFfbc2eb)
      },
      {
        'icon': '🌾',
        'label': 'Agriculture',
        'color': const Color(0xFF81FBB8)
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.school,
          title: 'Choose Your Field',
          layout: layout,
        ),
        const SizedBox(height: 24),
        Text(
          'Career Field',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Select the field you're studying or working in",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: layout.bodySize,
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: layout.gridCrossAxisCount,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: careerFields.length,
          itemBuilder: (context, index) {
            final field = careerFields[index];
            final isSelected = _careerField == field['label'];
            final Color color = field['color'] as Color;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _careerField = field['label'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                    colors: [
                      color.withOpacity(0.8),
                      color,
                    ],
                  )
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                    isSelected ? color : Colors.white.withOpacity(0.3),
                    width: isSelected ? 2 : 1.3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      field['icon'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      field['label'] as String,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          'Experience Level',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.sectionTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Beginner', 'Intermediate', 'Advanced', 'Expert']
              .map((level) {
            final isSelected = _experienceLevel == level;
            return GestureDetector(
              onTap: () => setState(() => _experienceLevel = level),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.chipPaddingH,
                  vertical: layout.chipPaddingV,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFFFFD700),
                      Color(0xFFFFA500),
                    ],
                  )
                      : null,
                  color: isSelected
                      ? null
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.xpGold
                        : Colors.white.withOpacity(0.3),
                    width: 1.5,
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
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      level,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: layout.chipFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildEducationStep(_LayoutConfig layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.history_edu,
          title: 'Your Background',
          layout: layout,
        ),
        const SizedBox(height: 24),
        Text(
          'Education Background',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tell us about your educational journey',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: layout.bodySize,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _educationController,
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.bodySize,
          ),
          maxLines: 3,
          decoration: InputDecoration(
            hintText:
            "e.g., Bachelor's in Computer Science from XYZ University",
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: layout.bodySize,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: const Icon(
              Icons.history_edu,
              color: AppColors.xpGold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.xpGold,
                width: 1.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Current Role (optional)',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.sectionTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _currentRoleController,
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.bodySize,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Junior Developer, Student, Career Switcher',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: layout.bodySize,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: const Icon(
              Icons.work_outline,
              color: AppColors.xpGold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.xpGold,
                width: 1.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildSkillsStep(_LayoutConfig layout) {
    final Map<String, List<String>> fieldSkills = {
      'Engineering': [
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
      ],
      'Medical': [
        'Clinical Skills',
        'Anatomy',
        'Physiology',
        'Pharmacology',
        'Pharmacy Practice',
        'Patient Care',
        'Diagnostics',
        'Pathology',
        'Microbiology',
        'Surgery',
        'Emergency Care',
        'Public Health',
        'Clinical Research',
        'Hospital Admin',
        'Drug Formulation',
        'Pharmacovigilance',
        'Regulatory Affairs',
        'GMP Basics',
        'Medical Ethics',
        'Telemedicine',
      ],
      'Business/MBA': [
        'Strategy',
        'Finance',
        'Marketing',
        'Operations',
        'Leadership',
        'Analytics',
        'Consulting',
        'Project Mgmt',
        'Sales',
        'Negotiation',
        'Biz Dev',
        'Supply Chain',
        'Entrepreneurship',
        'HR Mgmt',
        'Risk Mgmt',
        'Biz Law',
        'CRM',
        'Design Thinking',
        'Intl Business',
        'Presentation',
      ],
      'Commerce': [
        'Accounting',
        'Cost Accounting',
        'Taxation',
        'Auditing',
        'Fin Analysis',
        'Excel',
        'Tally',
        'SAP',
        'Banking',
        'Insurance',
        'Economics',
        'Stock Market',
        'Corporate Finance',
        'Budgeting',
        'Payroll',
        'Working Capital',
        'MIS',
        'Forensic Acc',
        'Int Trade',
        'Wealth Mgmt',
      ],
      'Arts & Design': [
        'Drawing',
        'Graphic Design',
        'Illustration',
        'Photoshop',
        'Illustrator',
        'Figma',
        'UI Design',
        'Motion Graphics',
        'Video Edit',
        'Typography',
        'Branding',
        'Web UI',
        '3D Modeling',
        'Storyboarding',
        'Photography',
        'Color Theory',
        'User Research',
        'Print Design',
        'Design Systems',
        'Portfolio',
      ],
      'Law': [
        'Const Law',
        'Criminal Law',
        'Contract Law',
        'Corporate Law',
        'Legal Research',
        'Case Analysis',
        'Legal Drafting',
        'Litigation',
        'Arbitration',
        'IP Law',
        'Tax Law',
        'Labor Law',
        'Intl Law',
        'Cyber Law',
        'Evidence Law',
        'Family Law',
        'Real Estate Law',
        'Banking Law',
        'Competition Law',
        'Legal Ethics',
      ],
      'Science & Research': [
        'Research Design',
        'Exp Planning',
        'Stats',
        'Data Analysis',
        'Lab Skills',
        'Sci Writing',
        'Lit Review',
        'Python',
        'R',
        'Instrumentation',
        'Survey Design',
        'Thesis Writing',
        'Peer Review',
        'Grant Writing',
        'Open Science',
        'Research Ethics',
        'Meta-Analysis',
        'Data Viz',
        'Poster Prep',
        'Talk Prep',
      ],
      'Education': [
        'Teaching',
        'Curriculum',
        'Lesson Plans',
        'Classroom Mgmt',
        'Assessment',
        'Ed Tech',
        'E-Learning',
        'Spec Education',
        'Counseling',
        'Communication',
        'Ed Research',
        'Instructional Design',
        'Ed Policy',
        'Activity Teaching',
        'Test Design',
        'Parent Comm',
        'Data-Driven Teaching',
        'Career Guide',
        'Soft Skills',
        'Teacher Portfolio',
      ],
      'Marketing': [
        'Mktg Basics',
        'Branding',
        'Digital Mktg',
        'SEO',
        'SEM',
        'Social Media',
        'Content Writing',
        'Copywriting',
        'Email Mktg',
        'Analytics',
        'Product Mktg',
        'Market Research',
        'Influencer Mktg',
        'Video Mktg',
        'CRO',
        'PR',
        'Event Mktg',
        'CRM Tools',
        'Growth Hacking',
        'A/B Testing',
      ],
      'Architecture': [
        'Arch Drawing',
        'AutoCAD',
        'SketchUp',
        'Revit',
        'BIM Basics',
        '3D Modeling',
        'Interior Design',
        'Urban Planning',
        'Green Design',
        'Building Codes',
        'Construction Tech',
        'Rendering',
        'Landscape',
        'Lighting Design',
        'Cost Estimation',
        'Project Planning',
        'Housing Design',
        'Commercial Design',
        'Portfolio',
        'Client Comm',
      ],
      'Media & Entertainment': [
        'Video Prod',
        'Scriptwriting',
        'Cinematography',
        'Video Edit',
        'Sound Design',
        'Acting',
        'Direction',
        '2D Animation',
        '3D Animation',
        'VFX Basics',
        'Broadcasting',
        'Journalism',
        'Content Creation',
        'Photography',
        'Color Grading',
        'Podcasting',
        'Studio Lighting',
        'Prod Mgmt',
        'Media Law',
        'Audience Analytics',
      ],
      'Agriculture': [
        'Crop Mgmt',
        'Soil Science',
        'Irrigation',
        'Pest Mgmt',
        'Farm Mgmt',
        'Agri Machinery',
        'Horticulture',
        'Animal Husbandry',
        'Organic Farming',
        'Precision Agri',
        'Post-Harvest',
        'Food Processing',
        'Agri Economics',
        'Agri Finance',
        'Agri Marketing',
        'Seed Tech',
        'Agroforestry',
        'Greenhouse',
        'Climate-Smart Agri',
        'Agri Startup',
      ],
    };

    final availableSkills =
        fieldSkills[_careerField] ?? fieldSkills['Engineering']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.code,
          title: 'Show Us Your Skills',
          layout: layout,
        ),
        const SizedBox(height: 24),
        Text(
          'Your Skills',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Select all skills you're comfortable with",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: layout.bodySize,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.xpGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.xpGold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Selected: ${_selectedSkills.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: layout.bodySize - 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
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
                padding: EdgeInsets.symmetric(
                  horizontal: layout.chipPaddingH,
                  vertical: layout.chipPaddingV,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF4facfe),
                      Color(0xFF00f2fe),
                    ],
                  )
                      : null,
                  color: isSelected
                      ? null
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF00f2fe)
                        : Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Text(
                      skill,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: layout.chipFontSize,
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
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildCareerGoalStep(_LayoutConfig layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.flag,
          title: 'Define Your Goals',
          layout: layout,
        ),
        const SizedBox(height: 24),
        Text(
          'Career Goals',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Where do you see yourself in the future?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: layout.bodySize,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _careerGoalController,
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.bodySize,
          ),
          maxLines: 4,
          decoration: InputDecoration(
            hintText:
            'e.g., Full Stack Developer at a FAANG company, building innovative products',
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: layout.bodySize,
            ),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            prefixIcon: const Icon(
              Icons.emoji_events,
              color: AppColors.xpGold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.xpGold,
                width: 1.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          "What's Your Main Motivation?",
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.sectionTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
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
                padding: EdgeInsets.symmetric(
                  horizontal: layout.chipPaddingH,
                  vertical: layout.chipPaddingV,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFFf093fb),
                      Color(0xFFf5576c),
                    ],
                  )
                      : null,
                  color: isSelected
                      ? null
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFf5576c)
                        : Colors.white.withOpacity(0.3),
                    width: 1.5,
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
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      mot,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: layout.chipFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildInterestsStep(_LayoutConfig layout) {
    final interests = [
      '💻 Web Development',
      '📱 Mobile Apps',
      '🤖 AI/ML',
      '🎨 Design',
      '📊 Data Science',
      '💼 Business',
      '📈 Finance',
      '🩺 Healthcare',
      '🎬 Content Creation',
      '🔐 Cybersecurity',
      '☁️ Cloud Tech',
      '🎯 Marketing',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.favorite,
          title: '❤️ What Excites You?',
          layout: layout,
        ),
        const SizedBox(height: 24),
        Text(
          'Areas of Interest',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Select topics you're passionate about learning",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: layout.bodySize,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.xpGold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.xpGold,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Selected: ${_selectedInterests.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: layout.bodySize - 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                    colors: [
                      Color(0xFF43e97b),
                      Color(0xFF38f9d7),
                    ],
                  )
                      : null,
                  color: isSelected
                      ? null
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF38f9d7)
                        : Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                    if (isSelected) const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        interest,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
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
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildPreferencesStep(_LayoutConfig layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.tune,
          title: 'Personalize Your Journey',
          layout: layout,
        ),
        const SizedBox(height: 24),
        Text(
          'Learning Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.titleSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Let's customize your learning experience",
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: layout.bodySize,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.3,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ FIXED: Changed Row to use Expanded properly
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Time Commitment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: layout.sectionTitleSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How many hours per week?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: layout.bodySize - 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFD700),
                          Color(0xFFFFA500),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_weeklyHours hrs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: layout.sectionTitleSize,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 11,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
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
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '40 hrs',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Preferred Learning Style',
          style: TextStyle(
            color: Colors.white,
            fontSize: layout.sectionTitleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        // ✅ FIXED: Wrapped Wrap in LayoutBuilder for proper sizing
        LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final cardWidth = (availableWidth - 10) / 2;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
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
                  onTap: () => setState(
                        () => _learningStyle = style['label'] as String,
                  ),
                  child: Container(
                    width: cardWidth,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                        colors: [
                          Color(0xFF667eea),
                          Color(0xFF764ba2),
                        ],
                      )
                          : null,
                      color: isSelected
                          ? null
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF764ba2)
                            : Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          style['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          style['label'] as String,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: layout.chipFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          style['desc'] as String,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 26),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.xpGold.withOpacity(0.2),
                AppColors.xpGold.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.xpGold.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.rocket_launch,
                color: AppColors.xpGold,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Begin Your Journey?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: layout.sectionTitleSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete setup to unlock your personalized learning path!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: layout.bodySize,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}

class _AIGeneratingPopup extends StatefulWidget {
  @override
  State<_AIGeneratingPopup> createState() => _AIGeneratingPopupState();
}

class _AIGeneratingPopupState extends State<_AIGeneratingPopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _floatingController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _floatingController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.45;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 40,
          vertical: 24,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 300,
            maxHeight: maxHeight,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0C29),
                Color(0xFF302b63),
                Color(0xFF24243e),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.xpGold.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: GlassmorphicContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 24,
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.2),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          math.sin(
                            _floatingController.value * 2 * math.pi,
                          ) *
                              6,
                        ),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.xpGold.withOpacity(0.3),
                                AppColors.xpGold.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.xpGold.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.xpGold.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 36,
                            color: AppColors.xpGold,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'AI Generating Your Roadmap',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while our AI crafts a personalized learning path just for you...',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      color: AppColors.xpGold,
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
