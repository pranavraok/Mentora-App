import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/widgets/level_badge.dart';
import 'package:mentora_app/pages/landing_page.dart';
import 'dart:math' as math;

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  bool _showAvatarPicker = false;
  String _selectedAvatar = '🚀'; // Default avatar

  // Cool avatar options
  final List<String> _avatarEmojis = [
    '🚀', '🎮', '⚡', '🔥', '💎', '🏆', '🎯', '⭐',
    '🦄', '🐉', '🦸', '🧙', '🤖', '👾', '🎪', '🎨',
  ];

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
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();

        return Scaffold(
          body: Stack(
            children: [
              // Animated gradient background - UPDATED TO MATCH THEME
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

              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Header WITHOUT back button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 48), // Spacer for alignment
                            Text(
                              'My Profile',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2, end: 0),

                      const SizedBox(height: 20),

                      // Avatar section with floating animation
                      AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              0,
                              math.sin(_floatingController.value * 2 * math.pi) * 8,
                            ),
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          onTap: () => setState(() => _showAvatarPicker = !_showAvatarPicker),
                          child: Stack(
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.5),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    _selectedAvatar,
                                    style: const TextStyle(fontSize: 70),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.gradientCyan,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 20),

                      // Name and email
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 24),

                      // Level badge
                      LevelBadge(
                        level: user.level,
                        title: user.levelTitle,
                        size: 80,
                      ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                      const SizedBox(height: 32),

                      // Stats cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.stars,
                                value: '${user.xp}',
                                label: 'Total XP',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                delay: 600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.local_fire_department,
                                value: '${user.streak}',
                                label: 'Day Streak',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                                ),
                                delay: 700,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                icon: Icons.monetization_on,
                                value: '${user.coins}',
                                label: 'Coins',
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                delay: 800,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Avatar picker (if shown)
                      if (_showAvatarPicker)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GlassmorphicContainer(
                            width: double.infinity,
                            height: 180,
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
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '🎨 Choose Your Avatar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white),
                                        onPressed: () => setState(() => _showAvatarPicker = false),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: GridView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 8,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                    ),
                                    itemCount: _avatarEmojis.length,
                                    itemBuilder: (context, index) {
                                      final emoji = _avatarEmojis[index];
                                      final isSelected = emoji == _selectedAvatar;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedAvatar = emoji;
                                            _showAvatarPicker = false;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.xpGold.withOpacity(0.3)
                                                : Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.xpGold
                                                  : Colors.white.withOpacity(0.2),
                                              width: isSelected ? 2 : 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              emoji,
                                              style: const TextStyle(fontSize: 24),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),
                        ),

                      const SizedBox(height: 24),

                      // Information section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 32),

                            // Career info cards
                            if (user.careerGoal != null)
                              _buildInfoCard(
                                icon: Icons.flag,
                                title: 'Career Goal',
                                value: user.careerGoal!,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                              ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.2, end: 0),

                            if (user.education != null)
                              _buildInfoCard(
                                icon: Icons.school,
                                title: 'Education',
                                value: user.education!,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                ),
                              ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.2, end: 0),

                            _buildInfoCard(
                              icon: Icons.schedule,
                              title: 'Weekly Commitment',
                              value: '${user.weeklyHours} hours/week',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                              ),
                            ).animate().fadeIn(delay: 1100.ms).slideX(begin: -0.2, end: 0),

                            // Skills section
                            if (user.skills.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Skills & Expertise',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: user.skills.map((skill) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.gradientBlue.withOpacity(0.2),
                                                AppColors.gradientCyan.withOpacity(0.2),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: AppColors.gradientBlue.withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            skill,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2, end: 0),
                            ],

                            const SizedBox(height: 32),

                            // Action buttons
                            _buildActionButton(
                              icon: Icons.edit,
                              title: 'Edit Profile',
                              subtitle: 'Update your information',
                              onTap: () {},
                            ).animate().fadeIn(delay: 1300.ms),

                            _buildActionButton(
                              icon: Icons.notifications,
                              title: 'Notifications',
                              subtitle: 'Manage your alerts',
                              onTap: () {},
                            ).animate().fadeIn(delay: 1400.ms),

                            _buildActionButton(
                              icon: Icons.help,
                              title: 'Help & Support',
                              subtitle: 'Get assistance',
                              onTap: () {},
                            ).animate().fadeIn(delay: 1500.ms),

                            const Divider(height: 32),

                            // Logout button
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: GestureDetector(
                                onTap: () async {
                                  await ref.read(userNotifierProvider).logout();
                                  if (context.mounted) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (_) => const LandingPage()),
                                          (route) => false,
                                    );
                                  }
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.lockedDanger.withOpacity(0.3),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.logout,
                                        color: AppColors.lockedDanger,
                                        size: 20,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: AppColors.lockedDanger,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 1600.ms).shake(delay: 1600.ms),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.xpGold),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Gradient gradient,
    required int delay,
  }) {
    return GlassmorphicContainer(
      width: double.infinity,
      height: 110,
      borderRadius: 20,
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
          borderRadius: BorderRadius.circular(20),
          gradient: _scaleGradient(gradient, 0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale();
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Gradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _scaleGradient(gradient, 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (gradient as LinearGradient).colors.first.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.gradientBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.gradientBlue, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to scale gradient
  Gradient _scaleGradient(Gradient gradient, double opacity) {
    if (gradient is LinearGradient) {
      return LinearGradient(
        begin: gradient.begin,
        end: gradient.end,
        colors: gradient.colors.map((c) => c.withOpacity(opacity)).toList(),
      );
    }
    return gradient;
  }
}
