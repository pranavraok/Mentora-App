import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:rive/rive.dart' as rive;
import 'package:glassmorphism/glassmorphism.dart';
import 'package:confetti/confetti.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/widgets/gradient_button.dart';
import 'package:mentora_app/pages/auth_page.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _rotationController;
  late ConfettiController _confettiController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _rotationController.dispose();
    _confettiController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ✅ UPDATED BACKGROUND - SAME AS PROFILE/PROJECTS
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

          // Floating particles (SAME AS PROFILE)
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final offset = math.sin((_floatingController.value + index * 0.2) * 2 * math.pi);
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

          // ✅ ANIMATED ROCKET WITH SCROLL
          AnimatedRocket(
            floatingController: _floatingController,
            scrollOffset: _scrollOffset,
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: math.pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                AppColors.xpGold,
                AppColors.gradientBlue,
                AppColors.gradientCyan,
                Colors.purple,
              ],
            ),
          ),

          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: HeroSection3D(
                  floatingController: _floatingController,
                  onGetStarted: () {
                    _confettiController.play();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage(isLogin: false)),
                    );
                  },
                  onLogin: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage(isLogin: true)),
                  ),
                ),
              ),

              // Bento Grid Features
              SliverToBoxAdapter(
                child: BentoFeaturesSection(scrollOffset: _scrollOffset)
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
              ),

              // Interactive Roadmap Preview
              SliverToBoxAdapter(
                child: RoadmapPreviewSection()
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              ),

              // Gamification Stats
              SliverToBoxAdapter(
                child: GamificationStatsSection()
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
              ),

              // 3D How It Works
              SliverToBoxAdapter(
                child: HowItWorks3DSection(floatingController: _floatingController),
              ),

              // Team Section
              SliverToBoxAdapter(
                child: TeamSection(floatingController: _floatingController)
                    .animate()
                    .fadeIn(delay: 800.ms),
              ),

              // Social Proof
              SliverToBoxAdapter(
                child: SocialProofSection()
                    .animate()
                    .fadeIn(delay: 900.ms),
              ),

              // Footer
              const SliverToBoxAdapter(child: ModernFooter()),
            ],
          ),
        ],
      ),
    );
  }
}

// ============= ANIMATED ROCKET WITH SCROLL =============
class AnimatedRocket extends StatelessWidget {
  final AnimationController floatingController;
  final double scrollOffset;

  const AnimatedRocket({
    super.key,
    required this.floatingController,
    required this.scrollOffset,
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate rocket position based on scroll
    final double rightPosition = math.max(-50, 20 - (scrollOffset * 0.15));
    final double topPosition = math.max(
      -200,
      80 + (scrollOffset * 0.3),
    );

    // Calculate rotation based on scroll
    final double rotation = math.min(0.3, scrollOffset * 0.0005);

    // Calculate opacity - fades out after scrolling past hero section
    final double opacity = math.max(0.0, math.min(1.0, 1.0 - (scrollOffset / 800)));

    return Positioned(
      right: rightPosition,
      top: topPosition,
      child: Opacity(
        opacity: opacity,
        child: AnimatedBuilder(
          animation: floatingController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                0,
                math.sin(floatingController.value * 2 * math.pi) * 15,
              ),
              child: Transform.rotate(
                angle: rotation,
                child: child,
              ),
            );
          },
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.xpGold.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Center(
              child: Text(
                '🚀',
                style: TextStyle(fontSize: 100),
              ),
            ),
          ).animate().fadeIn(duration: 800.ms).scale(delay: 200.ms),
        ),
      ),
    );
  }
}

// ============= HERO SECTION WITH 3D CHARACTER =============
class HeroSection3D extends StatelessWidget {
  final AnimationController floatingController;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const HeroSection3D({
    super.key,
    required this.floatingController,
    required this.onGetStarted,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.95,
      child: Column(
        children: [
          // ✅ FIXED LOGO AT TOP
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: SizedBox(
                height: 80,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ).animate().fadeIn().scale(delay: 100.ms),
            ),
          ),

          // ✅ SCROLLABLE CONTENT BELOW
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Badge
                  GlassmorphicContainer(
                    width: 180,
                    height: 40,
                    borderRadius: 20,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.rocket_launch, color: AppColors.xpGold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '🎮 Level Up Your Career',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideX(begin: -0.2, duration: 600.ms),
                  const SizedBox(height: 32),

                  // Main Heading
                  Text(
                    'Transform Your\nCareer Into An\nEpic Adventure',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      fontSize: 56,
                      letterSpacing: -2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 800.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 24),

                  // Subtitle
                  Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Text(
                      'Master skills through gamified learning paths, unlock achievements, and compete with peers while building real-world projects.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 18,
                        height: 1.6,
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 800.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 40),

                  // CTA Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GlassmorphicContainer(
                          width: double.infinity,
                          height: 60,
                          borderRadius: 16,
                          blur: 20,
                          alignment: Alignment.center,
                          border: 0,
                          linearGradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFFFFF),
                              Color(0xFFF0F0F0),
                            ],
                          ),
                          borderGradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.5),
                              Colors.white.withOpacity(0.2),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: onGetStarted,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Start Your Quest',
                                      style: TextStyle(
                                        color: AppColors.gradientBlue,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      color: AppColors.gradientBlue,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 500.ms)
                            .slideY(begin: 0.2, end: 0)
                            .shimmer(delay: 500.ms, duration: 1200.ms),
                      ),
                      const SizedBox(width: 16),
                      GlassmorphicContainer(
                        width: 60,
                        height: 60,
                        borderRadius: 16,
                        blur: 20,
                        alignment: Alignment.center,
                        border: 2,
                        linearGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.2),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onLogin,
                            borderRadius: BorderRadius.circular(16),
                            child: const Center(
                              child: Icon(
                                Icons.login_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).scale(delay: 600.ms),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Stats Row
                  Row(
                    children: [
                      _buildStatChip('100+', 'Active Courses'),
                      const SizedBox(width: 16),
                      _buildStatChip('500+', 'Skills'),
                      const SizedBox(width: 16),
                      _buildStatChip('4.9⭐', 'Rating'),
                    ],
                  ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 40), // Extra padding at bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label) {
    return Expanded(
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 70,
        borderRadius: 12,
        blur: 15,
        alignment: Alignment.center,
        border: 1.5,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.4),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============= BENTO GRID FEATURES =============
class BentoFeaturesSection extends StatelessWidget {
  final double scrollOffset;
  const BentoFeaturesSection({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                'SUPERPOWERS UNLOCKED',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // ✅ UNDERLINE
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Bento Grid Layout
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
            children: [
              _buildBentoCard(
                icon: Icons.map,
                title: 'Interactive\nRoadmap',
                description: 'Visual journey with themed regions',
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                delay: 0,
              ),
              _buildBentoCard(
                icon: Icons.emoji_events,
                title: 'Epic\nRewards',
                description: 'XP, badges & leaderboards',
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                delay: 100,
              ),
              _buildBentoCard(
                icon: Icons.auto_graph,
                title: 'AI Skills\nAnalysis',
                description: 'Gap detection & recommendations',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
                delay: 200,
              ),
              _buildBentoCard(
                icon: Icons.construction,
                title: 'Build Real\nProjects',
                description: 'Portfolio-worthy work',
                gradient: const LinearGradient(
                  colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                ),
                delay: 300,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Wide bento card
          _buildWideBentoCard(
            icon: Icons.description,
            title: 'AI Resume Optimizer',
            description: 'ATS-friendly feedback in seconds',
            gradient: const LinearGradient(
              colors: [Color(0xFFfa709a), Color(0xFFfee140)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required int delay,
  }) {
    return GlassmorphicContainer(
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
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: gradient.scale(0.3),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale();
  }

  Widget _buildWideBentoCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 24,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.2),
          Colors.white.withOpacity(0.05),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.2),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: gradient.scale(0.3),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.2, end: 0);
  }
}

// ============= ROADMAP PREVIEW =============
class RoadmapPreviewSection extends StatelessWidget {
  const RoadmapPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                'YOUR JOURNEY VISUALIZED',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // ✅ UNDERLINE
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GlassmorphicContainer(
            width: double.infinity,
            height: 300,
            borderRadius: 32,
            blur: 20,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.5),
                Colors.white.withOpacity(0.2),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🎯',
                    style: TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Interactive Learning Paths',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============= GAMIFICATION STATS =============
class GamificationStatsSection extends StatelessWidget {
  const GamificationStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                'LEVEL UP SYSTEM',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // ✅ UNDERLINE
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '1000+',
                  'XP Points',
                  Icons.stars,
                  const Color(0xFFFFD700),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '50+',
                  'Achievements',
                  Icons.emoji_events,
                  const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Top 10%',
                  'Leaderboard',
                  Icons.leaderboard,
                  const Color(0xFF4ECDC4),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Level 25',
                  'Current Rank',
                  Icons.workspace_premium,
                  const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 120,
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.1),
        ],
      ),
      borderGradient: LinearGradient(
        colors: [
          color.withOpacity(0.6),
          color.withOpacity(0.2),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}

// ============= HOW IT WORKS 3D =============
class HowItWorks3DSection extends StatelessWidget {
  final AnimationController floatingController;
  const HowItWorks3DSection({super.key, required this.floatingController});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'emoji': '👋', 'title': 'Create Account', 'desc': 'Join in 30 seconds'},
      {'emoji': '🎯', 'title': 'Choose Path', 'desc': 'AI suggests your roadmap'},
      {'emoji': '🚀', 'title': 'Start Learning', 'desc': 'Complete quests & projects'},
      {'emoji': '🏆', 'title': 'Earn Rewards', 'desc': 'Unlock badges & certificates'},
      {'emoji': '💼', 'title': 'Get Hired', 'desc': 'Land your dream job'},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                'HOW IT WORKS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // ✅ UNDERLINE
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          ...List.generate(steps.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 90,
                borderRadius: 20,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.15),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF667eea).withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            steps[i]['emoji']!,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              steps[i]['title']!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              steps[i]['desc']!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: i * 100))
                  .slideX(begin: 0.3, end: 0),
            );
          }),
        ],
      ),
    );
  }
}

// ============= TEAM SECTION =============
class TeamSection extends StatelessWidget {
  final AnimationController floatingController;
  const TeamSection({super.key, required this.floatingController});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = [
      {
        'name': 'Pranav Rao K',
        'role': 'Frontend Developer',
        'image': 'assets/images/pranav.jpg',
        'linkedin': 'https://www.linkedin.com/in/pranav-rao-k-487532312/',
        'email': 'pranavraok18@gmail.com',
        'gradient': const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]),
      },
      {
        'name': 'Tushar P',
        'role': 'Backend Developer',
        'image': 'assets/images/tushar.png',
        'linkedin': 'https://www.linkedin.com/in/tushar-p2006/',
        'email': 'tusharpradeep06@gmail.com',
        'gradient': const LinearGradient(colors: [Color(0xFFf093fb), Color(0xFFf5576c)]),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                'MEET THE BUILDERS',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // ✅ UNDERLINE
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Passionate about transforming careers through gamification',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            children: team.map((member) {
              final index = team.indexOf(member);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 8,
                    right: index == team.length - 1 ? 0 : 8,
                  ),
                  child: AnimatedBuilder(
                    animation: floatingController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          math.sin((floatingController.value + index * 0.5) * 2 * math.pi) * 10,
                        ),
                        child: child,
                      );
                    },
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: 320,
                      borderRadius: 24,
                      blur: 20,
                      alignment: Alignment.center,
                      border: 2,
                      linearGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.05),
                        ],
                      ),
                      borderGradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.5),
                          Colors.white.withOpacity(0.2),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: member['gradient'] as Gradient,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black.withOpacity(0.4),
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ✅ PROFILE IMAGE
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(member['image'] as String),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    member['name'] as String,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    member['role'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  // ✅ LINKEDIN + EMAIL BUTTONS
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _launchURL(member['linkedin'] as String),
                                        child: _buildSocialIcon(Icons.work),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () => _launchURL('mailto:${member['email']}'),
                                        child: _buildSocialIcon(Icons.email),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: Duration(milliseconds: 200 + (index * 200)))
                        .slideY(begin: 0.3, end: 0),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

// ============= SOCIAL PROOF =============
class SocialProofSection extends StatelessWidget {
  const SocialProofSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Column(
            children: [
              Text(
                'WHAT OUR HEROES SAY',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              // ✅ UNDERLINE
              Container(
                width: 80,
                height: 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(3, (i) {
                final testimonials = [
                  {'name': 'Samarth K.', 'role': 'Full Stack Dev', 'text': 'Landed my dream job in 3 months!'},
                  {'name': 'Likith R.', 'role': 'Data Scientist', 'text': 'The gamification kept me motivated'},
                  {'name': 'Eeshwar L.', 'role': 'UX Designer', 'text': 'Best learning experience ever!'},
                ];

                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 24,
                    blur: 20,
                    alignment: Alignment.center,
                    border: 2,
                    linearGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                                  (index) => const Icon(Icons.star, color: AppColors.xpGold, size: 16),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '"${testimonials[i]['text']}"',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppColors.gradientBlue,
                                child: Text(
                                  testimonials[i]['name']![0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    testimonials[i]['name']!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    testimonials[i]['role']!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============= MODERN FOOTER =============
class ModernFooter extends StatelessWidget {
  const ModernFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27).withOpacity(0.8),
      ),
      child: Column(
        children: [
          // ✅ LOGO PNG IN FOOTER
          SizedBox(
            height: 60,
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '© 2025 Mentora. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFooterLink('Privacy'),
              _buildFooterLink('Terms'),
              _buildFooterLink('Contact'),
              _buildFooterLink('Careers'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(Icons.facebook),
              _buildSocialIcon(Icons.camera_alt),
              const Icon(Icons.close, color: Colors.white, size: 20),
              _buildSocialIcon(Icons.play_arrow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

// Extension for gradient scaling
extension GradientScale on Gradient {
  Gradient scale(double opacity) {
    if (this is LinearGradient) {
      final lg = this as LinearGradient;
      return LinearGradient(
        begin: lg.begin,
        end: lg.end,
        colors: lg.colors.map((c) => c.withOpacity(opacity)).toList(),
      );
    }
    return this;
  }
}

