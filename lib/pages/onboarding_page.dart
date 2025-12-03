import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/widgets/gradient_button.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/providers/app_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _currentStep = 0;
  final _educationController = TextEditingController();
  final _careerGoalController = TextEditingController();
  final List<String> _selectedSkills = [];
  int _weeklyHours = 10;

  @override
  void dispose() {
    _educationController.dispose();
    _careerGoalController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
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

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      },
      loading: () async {},
      error: (_, __) async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              LinearProgressIndicator(
                value: (_currentStep + 1) / 4,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of 4',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildStepContent(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep--),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Back', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        text: _currentStep < 3 ? 'Next' : 'Complete',
                        onPressed: () {
                          if (_currentStep < 3) {
                            setState(() => _currentStep++);
                          } else {
                            _completeOnboarding();
                          }
                        },
                        gradient: const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
        return _buildPreferencesStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildEducationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Education Background',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tell us about your educational background',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _educationController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., Bachelor\'s in Computer Science',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsStep() {
    final availableSkills = [
      'Python', 'JavaScript', 'React', 'Node.js', 'Flutter', 'Java',
      'C++', 'SQL', 'MongoDB', 'AWS', 'Docker', 'Git',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Skills',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select the skills you already have',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: availableSkills.map((skill) {
            final isSelected = _selectedSkills.contains(skill);
            return FilterChip(
              label: Text(skill),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedSkills.add(skill);
                  } else {
                    _selectedSkills.remove(skill);
                  }
                });
              },
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              selectedColor: AppColors.gradientCyan,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
              ),
              checkmarkColor: Colors.white,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCareerGoalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Career Goals',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'What\'s your dream job or career goal?',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _careerGoalController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g., Full Stack Developer at a tech startup',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Learning Preferences',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How many hours per week can you dedicate?',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Weekly Hours',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Text(
                    '$_weeklyHours hours',
                    style: const TextStyle(
                      color: AppColors.xpGold,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _weeklyHours.toDouble(),
                min: 1,
                max: 40,
                divisions: 39,
                activeColor: AppColors.xpGold,
                inactiveColor: Colors.white.withValues(alpha: 0.2),
                onChanged: (value) => setState(() => _weeklyHours = value.toInt()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
