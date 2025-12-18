import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:confetti/confetti.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/pages/auth_page.dart';
import 'package:mentora_app/utils/responsive_helper.dart'; // ADDED
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
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
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
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
          // Background gradient
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
          // Floating particles
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
          // Animated rocket
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
                      MaterialPageRoute(
                        builder: (_) => const AuthPage(isLogin: false),
                      ),
                    );
                  },
                  onLogin: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthPage(isLogin: true),
                    ),
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
              // Roadmap Preview
              SliverToBoxAdapter(
                child: RoadmapPreviewSection()
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .scale(
                  begin: Offset(0.8, 0.8),
                  end: Offset(1, 1),
                ),
              ),
              // Gamification Stats
              SliverToBoxAdapter(
                child: GamificationStatsSection()
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms),
              ),
              // How It Works
              SliverToBoxAdapter(
                child: HowItWorks3DSection(
                  floatingController: _floatingController,
                ),
              ),
              // Team
              SliverToBoxAdapter(
                child: TeamSection(
                  floatingController: _floatingController,
                ).animate().fadeIn(delay: 800.ms),
              ),
              // Social Proof
              SliverToBoxAdapter(
                child: SocialProofSection().animate().fadeIn(delay: 900.ms),
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

// ============= ANIMATED ROCKET =============
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
    final double rightPosition = math.max(-50, 20 - (scrollOffset * 0.15));
    final double topPosition = math.max(-200, 80 + (scrollOffset * 0.3));
    final double rotation = math.min(0.3, scrollOffset * 0.0005);
    final double opacity = math.max(
      0.0,
      math.min(1.0, 1.0 - (scrollOffset / 800)),
    );

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
              child: Transform.rotate(angle: rotation, child: child),
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
              child: Text('🚀', style: TextStyle(fontSize: 100)),
            ),
          )
              .animate()
              .fadeIn(duration: 800.ms)
              .scale(delay: 200.ms),
        ),
      ),
    );
  }
}

// ============= HERO SECTION (FIXED) =============
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.spacing(context, 24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                top: ResponsiveHelper.spacing(context, 16),
                bottom: ResponsiveHelper.spacing(context, 16),
              ),
              child: SizedBox(
                height: ResponsiveHelper.height(context, 60),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                ),
              ).animate().fadeIn().scale(delay: 100.ms),
            ),
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 16)),
          // Badge - FIXED
          GlassmorphicContainer(
            width: ResponsiveHelper.spacing(context, 180),
            height: ResponsiveHelper.spacing(context, 36),
            borderRadius: 18,
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
                Icon(
                  Icons.rocket_launch,
                  color: AppColors.xpGold,
                  size: ResponsiveHelper.fontSize(context, 16),
                ),
                SizedBox(width: ResponsiveHelper.spacing(context, 6)),
                ResponsiveText(
                  'Level Up Your Career',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.fontSize(context, 11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().slideX(begin: -0.2, duration: 600.ms),
          SizedBox(height: ResponsiveHelper.spacing(context, 24)),
          // Main heading - FIXED
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Transform Your\nCareer Into An\nEpic Adventure',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  fontSize: ResponsiveHelper.fontSize(context, 38),
                  letterSpacing: -1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 800.ms)
              .slideY(begin: 0.3, end: 0),
          SizedBox(height: ResponsiveHelper.spacing(context, 16)),
          // Subtitle - FIXED
          Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: ResponsiveHelper.screenWidth(context) * 0.9,
              ),
              child: Text(
                'Master skills through gamified learning, unlock achievements, and compete while building real projects.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: ResponsiveHelper.fontSize(context, 15),
                  height: 1.5,
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 800.ms)
              .slideY(begin: 0.2, end: 0),
          SizedBox(height: ResponsiveHelper.spacing(context, 28)),
          // CTA buttons - FIXED
          Row(
            children: [
              Expanded(
                child: GlassmorphicContainer(
                  width: double.infinity,
                  height: ResponsiveHelper.height(context, 52),
                  borderRadius: 14,
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
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ResponsiveText(
                              'Start Your Quest',
                              style: TextStyle(
                                color: AppColors.gradientBlue,
                                fontSize: ResponsiveHelper.fontSize(context, 16),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: ResponsiveHelper.spacing(context, 8)),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.gradientBlue,
                              size: ResponsiveHelper.fontSize(context, 20),
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
              SizedBox(width: ResponsiveHelper.spacing(context, 12)),
              GlassmorphicContainer(
                width: ResponsiveHelper.height(context, 52),
                height: ResponsiveHelper.height(context, 52),
                borderRadius: 14,
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
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: Icon(
                        Icons.login_rounded,
                        color: Colors.white,
                        size: ResponsiveHelper.fontSize(context, 22),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(delay: 600.ms),
            ],
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 28)),
          // Stats row - FIXED
          Row(
            children: [
              _buildStatChip(context, '100+', 'Courses'),
              SizedBox(width: ResponsiveHelper.spacing(context, 12)),
              _buildStatChip(context, '500+', 'Skills'),
              SizedBox(width: ResponsiveHelper.spacing(context, 12)),
              _buildStatChip(context, '4.9⭐', 'Rating'),
            ],
          ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
          SizedBox(height: ResponsiveHelper.spacing(context, 32)),
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label) {
    return Expanded(
      child: GlassmorphicContainer(
        width: double.infinity,
        height: ResponsiveHelper.height(context, 60),
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
            ResponsiveText(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveHelper.fontSize(context, 17),
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: ResponsiveHelper.spacing(context, 3)),
            ResponsiveText(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: ResponsiveHelper.fontSize(context, 9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= BENTO GRID FEATURES (MINIMAL FIX) =============
class BentoFeaturesSection extends StatelessWidget {
  final double scrollOffset;

  const BentoFeaturesSection({super.key, required this.scrollOffset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
      child: Column(
        children: [
          Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'SUPERPOWERS UNLOCKED',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: ResponsiveHelper.fontSize(context, 24),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, 8)),
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
          SizedBox(height: ResponsiveHelper.spacing(context, 40)),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: ResponsiveHelper.spacing(context, 16),
            crossAxisSpacing: ResponsiveHelper.spacing(context, 16),
            childAspectRatio: 0.95, // CHANGED from 0.9 to 0.95 - slightly taller cards
            children: [
              _buildBentoCard(
                context,
                icon: Icons.map,
                title: 'Interactive\nRoadmap',
                description: 'Visualize your journey',
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                delay: 0,
              ),
              _buildBentoCard(
                context,
                icon: Icons.emoji_events,
                title: 'Epic\nRewards',
                description: 'XP, badges & more',
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
                delay: 100,
              ),
              _buildBentoCard(
                context,
                icon: Icons.auto_graph,
                title: 'AI Skills\nAnalysis',
                description: 'Gap detection & insights',
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
                delay: 200,
              ),
              _buildBentoCard(
                context,
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
          SizedBox(height: ResponsiveHelper.spacing(context, 16)),
          _buildWideBentoCard(
            context,
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

  Widget _buildBentoCard(
      BuildContext context, {
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
        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.2)],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: gradient.scale(0.3),
        ),
        padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 16)), // REDUCED from 20 to 16
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon Container
            Container(
              width: ResponsiveHelper.spacing(context, 50), // REDUCED from 56 to 50
              height: ResponsiveHelper.spacing(context, 50),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14), // REDUCED from 16 to 14
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: ResponsiveHelper.fontSize(context, 26), // REDUCED from 28 to 26
              ),
            ),
            // Text Section - WRAPPED IN FLEXIBLE
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.fontSize(context, 17), // REDUCED from 18 to 17
                        fontWeight: FontWeight.w800,
                        height: 1.15, // REDUCED from 1.2 to 1.15
                      ),
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.spacing(context, 6)), // REDUCED from 8 to 6
                  // Description
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: ResponsiveHelper.fontSize(context, 12), // REDUCED from 13 to 12
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale();
  }

  Widget _buildWideBentoCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String description,
        required Gradient gradient,
      }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: ResponsiveHelper.height(context, 120),
      borderRadius: 24,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.05)],
      ),
      borderGradient: LinearGradient(
        colors: [Colors.white.withOpacity(0.6), Colors.white.withOpacity(0.2)],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: gradient.scale(0.3),
        ),
        padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 20)),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.spacing(context, 70),
              height: ResponsiveHelper.spacing(context, 70),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: ResponsiveHelper.fontSize(context, 36),
              ),
            ),
            SizedBox(width: ResponsiveHelper.spacing(context, 20)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.fontSize(context, 20),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.spacing(context, 4)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: ResponsiveHelper.fontSize(context, 14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 400.ms)
        .slideX(begin: 0.2, end: 0);
  }
}


// ============= ROADMAP PREVIEW (FIXED) =============
class RoadmapPreviewSection extends StatelessWidget {
  const RoadmapPreviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
      child: Column(
        children: [
          Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'YOUR JOURNEY VISUALIZED',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: ResponsiveHelper.fontSize(context, 24),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, 8)),
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
          SizedBox(height: ResponsiveHelper.spacing(context, 32)),
          GlassmorphicContainer(
            width: double.infinity,
            height: ResponsiveHelper.height(context, 300),
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
                  Text('🎯', style: TextStyle(fontSize: ResponsiveHelper.fontSize(context, 80))),
                  SizedBox(height: ResponsiveHelper.spacing(context, 16)),
                  ResponsiveText(
                    'Interactive Learning Paths',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveHelper.fontSize(context, 20),
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

// ============= GAMIFICATION STATS (FIXED) =============
class GamificationStatsSection extends StatelessWidget {
  const GamificationStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
      child: Column(
        children: [
          Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'LEVEL UP SYSTEM',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: ResponsiveHelper.fontSize(context, 24),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, 8)),
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
          SizedBox(height: ResponsiveHelper.spacing(context, 32)),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  '1000+',
                  'XP Points',
                  Icons.stars,
                  const Color(0xFFFFD700),
                ),
              ),
              SizedBox(width: ResponsiveHelper.spacing(context, 16)),
              Expanded(
                child: _buildStatCard(
                  context,
                  '50+',
                  'Achievements',
                  Icons.emoji_events,
                  const Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 16)),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Top 10%',
                  'Leaderboard',
                  Icons.leaderboard,
                  const Color(0xFF4ECDC4),
                ),
              ),
              SizedBox(width: ResponsiveHelper.spacing(context, 16)),
              Expanded(
                child: _buildStatCard(
                  context,
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

  Widget _buildStatCard(
      BuildContext context,
      String value,
      String label,
      IconData icon,
      Color color,
      ) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: ResponsiveHelper.height(context, 120),
      borderRadius: 20,
      blur: 20,
      alignment: Alignment.center,
      border: 2,
      linearGradient: LinearGradient(
        colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
      ),
      borderGradient: LinearGradient(
        colors: [color.withOpacity(0.6), color.withOpacity(0.2)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: ResponsiveHelper.fontSize(context, 32)),
          SizedBox(height: ResponsiveHelper.spacing(context, 12)),
          ResponsiveText(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveHelper.fontSize(context, 24),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 4)),
          ResponsiveText(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: ResponsiveHelper.fontSize(context, 13),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }
}

/// ============= HOW IT WORKS 3D (PERFECT FIX) =============
class HowItWorks3DSection extends StatelessWidget {
  final AnimationController floatingController;

  const HowItWorks3DSection({super.key, required this.floatingController});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'emoji': '👋', 'title': 'Create Account', 'desc': 'Join in 30 seconds'},
      {
        'emoji': '🎯',
        'title': 'Choose Path',
        'desc': 'AI suggests your roadmap',
      },
      {
        'emoji': '🚀',
        'title': 'Start Learning',
        'desc': 'Complete quests & projects',
      },
      {
        'emoji': '🏆',
        'title': 'Earn Rewards',
        'desc': 'Unlock badges & certificates',
      },
      {'emoji': '💼', 'title': 'Get Hired', 'desc': 'Land your dream job'},
    ];

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
      child: Column(
        children: [
          Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'HOW IT WORKS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: ResponsiveHelper.fontSize(context, 24),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, 8)),
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
          SizedBox(height: ResponsiveHelper.spacing(context, 40)),
          ...List.generate(steps.length, (i) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveHelper.spacing(context, 16),
              ),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: ResponsiveHelper.height(context, 95), // INCREASED from 90 to 95
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
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.spacing(context, 16), // REDUCED from 20 to 16
                    vertical: ResponsiveHelper.spacing(context, 14), // REDUCED from 20 to 14
                  ),
                  child: Row(
                    children: [
                      // Emoji Container
                      Container(
                        width: ResponsiveHelper.spacing(context, 56), // REDUCED from 60 to 56
                        height: ResponsiveHelper.spacing(context, 56),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF667eea),
                              Color(0xFF764ba2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14), // REDUCED from 16 to 14
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
                            style: TextStyle(
                              fontSize: ResponsiveHelper.fontSize(context, 26), // REDUCED from 28 to 26
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.spacing(context, 14)), // REDUCED from 20 to 14
                      // Text Content - WRAPPED IN FLEXIBLE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title with FittedBox
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                steps[i]['title']!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveHelper.fontSize(context, 17), // REDUCED from 18 to 17
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.spacing(context, 3)), // REDUCED from 4 to 3
                            // Description with FittedBox
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                steps[i]['desc']!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: ResponsiveHelper.fontSize(context, 13), // REDUCED from 14 to 13
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.spacing(context, 10)), // REDUCED from 20 to 10
                      // Number Badge
                      Container(
                        width: ResponsiveHelper.spacing(context, 38), // REDUCED from 40 to 38
                        height: ResponsiveHelper.spacing(context, 38),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${i + 1}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: ResponsiveHelper.fontSize(context, 17), // REDUCED from 18 to 17
                                fontWeight: FontWeight.w900,
                              ),
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


// ============= TEAM SECTION (FIXED) =============
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
        'gradient': const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      },
      {
        'name': 'Tushar P',
        'role': 'Backend Developer',
        'image': 'assets/images/tushar.png',
        'linkedin': 'https://www.linkedin.com/in/tushar-p2006/',
        'email': 'tusharpradeep06@gmail.com',
        'gradient': const LinearGradient(
          colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
        ),
      },
    ];

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
      child: Column(
        children: [
          Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'MEET THE BUILDERS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: ResponsiveHelper.fontSize(context, 24),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, 8)),
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
          SizedBox(height: ResponsiveHelper.spacing(context, 16)),
          Text(
            'Passionate about transforming careers through gamification',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: ResponsiveHelper.fontSize(context, 16),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 40)),
          Row(
            children: team.map((member) {
              final index = team.indexOf(member);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : ResponsiveHelper.spacing(context, 8),
                    right: index == team.length - 1 ? 0 : ResponsiveHelper.spacing(context, 8),
                  ),
                  child: AnimatedBuilder(
                    animation: floatingController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(
                          0,
                          math.sin(
                            (floatingController.value + index * 0.5) *
                                2 *
                                math.pi,
                          ) *
                              10,
                        ),
                        child: child,
                      );
                    },
                    child: GlassmorphicContainer(
                      width: double.infinity,
                      height: ResponsiveHelper.height(context, 320),
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
                          padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 20)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: ResponsiveHelper.spacing(context, 120),
                                height: ResponsiveHelper.spacing(context, 120),
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
                                    image: AssetImage(
                                      member['image'] as String,
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  ResponsiveText(
                                    member['name'] as String,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: ResponsiveHelper.fontSize(context, 18),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.spacing(context, 4)),
                                  ResponsiveText(
                                    member['role'] as String,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: ResponsiveHelper.fontSize(context, 13),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveHelper.spacing(context, 16)),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap: () => _launchURL(
                                          member['linkedin'] as String,
                                        ),
                                        child: _buildSocialIcon(context, Icons.work),
                                      ),
                                      SizedBox(width: ResponsiveHelper.spacing(context, 12)),
                                      GestureDetector(
                                        onTap: () => _launchURL(
                                          'mailto:${member['email']}',
                                        ),
                                        child: _buildSocialIcon(context, Icons.email),
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
                        .fadeIn(
                      delay: Duration(
                        milliseconds: 200 + (index * 200),
                      ),
                    )
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

  Widget _buildSocialIcon(BuildContext context, IconData icon) {
    return Container(
      width: ResponsiveHelper.spacing(context, 40),
      height: ResponsiveHelper.spacing(context, 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: ResponsiveHelper.fontSize(context, 20)),
    );
  }
}

// ============= SOCIAL PROOF (FIXED) =============
class SocialProofSection extends StatelessWidget {
  const SocialProofSection({super.key});

  @override
  Widget build(BuildContext context) {
    final testimonials = [
      {
        'name': 'Samarth K.',
        'role': 'Full Stack Dev',
        'text': 'Landed my dream job in 3 months!',
      },
      {
        'name': 'Likith R.',
        'role': 'Data Scientist',
        'text': 'The gamification kept me motivated',
      },
      {
        'name': 'Eeshwar L.',
        'role': 'UX Designer',
        'text': 'Best learning experience ever!',
      },
    ];

    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
      child: Column(
        children: [
          Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'WHAT OUR HEROES SAY',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: ResponsiveHelper.fontSize(context, 24),
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.spacing(context, 8)),
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
          SizedBox(height: ResponsiveHelper.spacing(context, 32)),
          SizedBox(
            height: ResponsiveHelper.height(context, 200),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: List.generate(testimonials.length, (i) {
                return Container(
                  width: ResponsiveHelper.spacing(context, 280),
                  margin: EdgeInsets.only(right: ResponsiveHelper.spacing(context, 16)),
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
                      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 24)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                                  (index) => Icon(
                                Icons.star,
                                color: AppColors.xpGold,
                                size: ResponsiveHelper.fontSize(context, 16),
                              ),
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.spacing(context, 16)),
                          Text(
                            '"${testimonials[i]['text']!}"',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveHelper.fontSize(context, 16),
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: ResponsiveHelper.fontSize(context, 14),
                                  ),
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.spacing(context, 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ResponsiveText(
                                      testimonials[i]['name']!,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveHelper.fontSize(context, 14),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    ResponsiveText(
                                      testimonials[i]['role']!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: ResponsiveHelper.fontSize(context, 12),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
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

// ============= MODERN FOOTER (FIXED) =============
class ModernFooter extends StatelessWidget {
  const ModernFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveHelper.spacing(context, 32)),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E27).withOpacity(0.8),
      ),
      child: Column(
        children: [
          SizedBox(
            height: ResponsiveHelper.height(context, 60),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 24)),
          Text(
            '© 2025 Mentora. All rights reserved.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: ResponsiveHelper.fontSize(context, 14),
            ),
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 20)),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: ResponsiveHelper.spacing(context, 24),
            children: [
              _buildFooterLink(context, 'Privacy'),
              _buildFooterLink(context, 'Terms'),
              _buildFooterLink(context, 'Contact'),
              _buildFooterLink(context, 'Careers'),
            ],
          ),
          SizedBox(height: ResponsiveHelper.spacing(context, 24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(context, Icons.facebook),
              _buildSocialIcon(context, Icons.camera_alt),
              Container(
                margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.spacing(context, 8)),
                width: ResponsiveHelper.spacing(context, 40),
                height: ResponsiveHelper.spacing(context, 40),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: ResponsiveHelper.fontSize(context, 20),
                ),
              ),
              _buildSocialIcon(context, Icons.play_arrow),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white70,
        fontSize: ResponsiveHelper.fontSize(context, 14),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSocialIcon(BuildContext context, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: ResponsiveHelper.spacing(context, 8)),
      width: ResponsiveHelper.spacing(context, 40),
      height: ResponsiveHelper.spacing(context, 40),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: ResponsiveHelper.fontSize(context, 20)),
    );
  }
}

// ============= GRADIENT EXTENSION =============
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

