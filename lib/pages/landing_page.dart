import 'package:flutter/material.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/widgets/gradient_button.dart';
import 'package:mentora_app/pages/auth_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: HeroSection(
                    onGetStarted: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage(isLogin: false)),
                    ),
                    onLogin: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage(isLogin: true)),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                const FeaturesSection(),
                const SizedBox(height: 60),
                const HowItWorksSection(),
                const SizedBox(height: 60),
                const FooterSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const HeroSection({
    super.key,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.white, size: 80),
          const SizedBox(height: 24),
          Text(
            'Your Career Journey,\nGamified',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Transform your professional development into an epic adventure with personalized roadmaps, skill-building projects, and AI-powered guidance.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: GradientButton(
                  text: 'Get Started',
                  onPressed: onGetStarted,
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: onLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final features = [
      {'icon': Icons.map, 'title': 'Interactive Roadmap', 'desc': 'Visual career path with themed regions'},
      {'icon': Icons.emoji_events, 'title': 'Gamification', 'desc': 'XP, levels, achievements, and rewards'},
      {'icon': Icons.auto_graph, 'title': 'Skills Analysis', 'desc': 'AI-powered gap analysis and recommendations'},
      {'icon': Icons.construction, 'title': 'Real Projects', 'desc': 'Build portfolio-worthy applications'},
      {'icon': Icons.description, 'title': 'AI Resume Checker', 'desc': 'Get instant feedback and ATS optimization'},
      {'icon': Icons.leaderboard, 'title': 'Community', 'desc': 'Compete and learn with peers'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Features',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: features.map((f) => SizedBox(
              width: MediaQuery.of(context).size.width < 600
                  ? double.infinity
                  : (MediaQuery.of(context).size.width - 80) / 2,
              child: FeatureCard(
                icon: f['icon'] as IconData,
                title: f['title'] as String,
                description: f['desc'] as String,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.lightBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gradientCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.gradientBlue),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'How It Works',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(5, (i) {
            final steps = [
              '📝 Complete onboarding',
              '🗺️ Get AI-generated roadmap',
              '🎯 Complete courses & projects',
              '🏆 Earn XP, levels & badges',
              '🚀 Launch your career',
            ];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.xpGold,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      steps[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBg,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            '© 2024 Ascent. All rights reserved.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Privacy', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Terms', style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Contact', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
