import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:mentora_app/providers/notification_provider.dart';
import 'package:mentora_app/pages/settings_page.dart';
import 'package:mentora_app/pages/notifications_page.dart';
import 'dart:math' as math;
import 'dart:ui';

// User data provider
final userProfileProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final supabase = SupabaseConfig.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return Stream.value({});
  }

  return supabase
      .from('users')
      .select('id, supabase_uid, name, email, photo_url, avatar, college, major, graduation_year, career_goal, current_level, total_xp, total_coins, streak_days, last_activity')
      .eq('supabase_uid', user.id)
      .single()
      .asStream();
});

// Achievements provider
final userAchievementsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = SupabaseConfig.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  return supabase
      .from('users')
      .select('id')
      .eq('supabase_uid', user.id)
      .single()
      .asStream()
      .asyncExpand((userRow) {
    final userId = userRow['id'] as String;
    return supabase
        .from('achievements')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('unlocked_at', ascending: false)
        .limit(6);
  });
});

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;
  final _supabase = SupabaseConfig.client;
  bool _showAvatarPicker = false;

  // Cool avatar options
  final List<String> _avatarEmojis = [
    '🚀',
    '🎮',
    '⚡',
    '🔥',
    '💎',
    '🏆',
    '🎯',
    '⭐',
    '🦄',
    '🐉',
    '🦸',
    '🧙',
    '🤖',
    '👾',
    '🎪',
    '🎨',
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

  Future<void> _updateAvatar(String emoji, String userId) async {
    try {
      await _supabase.from('users').update({'avatar': emoji}).eq('id', userId);
      // Force refresh the provider
      ref.invalidate(userProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error updating avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $e')),
        );
      }
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> user) {
    final nameController = TextEditingController(text: user['name']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF667eea)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Display-only college field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'College',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['college'] ?? 'Not set',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Display-only career goal field
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Career Goal',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['career_goal'] ?? 'Not set',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabase.from('users').update({
                  'name': nameController.text,
                }).eq('id', user['id']);

                // Refresh the provider
                ref.invalidate(userProfileProvider);

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF43e97b))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final achievementsAsync = ref.watch(userAchievementsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

    return userProfileAsync.when(
      data: (user) {
        if (user.isEmpty) return const SizedBox();

        final currentAvatar = user['avatar'] ?? '🚀';
        final userName = user['name'] ?? 'User';
        final userEmail = user['email'] ?? '';
        final level = user['current_level'] ?? 1;
        final xp = user['total_xp'] ?? 0;
        final coins = user['total_coins'] ?? 0;
        final streak = user['streak_days'] ?? 0;
        final careerGoal = user['career_goal'];
        final college = user['college'];
        final major = user['major'];

        return Scaffold(
          body: Stack(
            children: [
              // Background
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

              // Floating blur circles
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
              Column(
                children: [
                  // Header
                  ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withOpacity(0.15),
                              Colors.white.withOpacity(0.05),
                            ],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 60,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    unreadCountAsync.when(
                                      data: (count) => _buildGlassButton(
                                        icon: Icons.notifications_rounded,
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const NotificationsPage(),
                                            ),
                                          );
                                        },
                                        hasNotification: count > 0,
                                      ),
                                      loading: () => _buildGlassButton(
                                        icon: Icons.notifications_rounded,
                                        onTap: () {},
                                        hasNotification: false,
                                      ),
                                      error: (_, __) => _buildGlassButton(
                                        icon: Icons.notifications_rounded,
                                        onTap: () {},
                                        hasNotification: false,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    _buildGlassButton(
                                      icon: Icons.settings_rounded,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const SettingsPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.3, end: 0),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),

                          // Avatar section
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
                                      border: Border.all(color: Colors.white, width: 4),
                                    ),
                                    child: Center(
                                      child: Text(currentAvatar, style: const TextStyle(fontSize: 70)),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                      ),
                                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),

                          const SizedBox(height: 20),

                          // Name and email
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 28,
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                          const SizedBox(height: 8),

                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 24),

                          // Level badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Level $level',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                                    value: '$xp',
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
                                    value: '$streak',
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
                                    value: '$coins',
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

                          // Avatar picker
                          if (_showAvatarPicker)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    width: double.infinity,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF667eea).withOpacity(0.3),
                                          const Color(0xFF764ba2).withOpacity(0.2),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Choose Your Avatar',
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
                                              final isSelected = emoji == currentAvatar;

                                              return GestureDetector(
                                                onTap: () async {
                                                  await _updateAvatar(emoji, user['id']);
                                                  setState(() => _showAvatarPicker = false);
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color(0xFFFFD700).withOpacity(0.3)
                                                        : Colors.white.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: isSelected
                                                          ? const Color(0xFFFFD700)
                                                          : Colors.white.withOpacity(0.2),
                                                      width: isSelected ? 2 : 1,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                    ),
                                  ),
                                ),
                              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),
                            ),

                          const SizedBox(height: 24),

                          // Darker section
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFF1e1e3f).withOpacity(0.95),
                                      const Color(0xFF0a0a1e).withOpacity(0.98),
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(40),
                                    topRight: Radius.circular(40),
                                  ),
                                  border: Border(
                                    top: BorderSide(
                                      color: const Color(0xFFFFD700).withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 40),

                                    // Career info cards
                                    if (careerGoal != null)
                                      _buildInfoCard(
                                        icon: Icons.flag,
                                        title: 'Career Goal',
                                        value: careerGoal,
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                        ),
                                      ).animate().fadeIn(delay: 900.ms).slideX(begin: -0.2, end: 0),

                                    if (college != null)
                                      _buildInfoCard(
                                        icon: Icons.school,
                                        title: 'College',
                                        value: '$college${major != null ? " • $major" : ""}',
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                        ),
                                      ).animate().fadeIn(delay: 1000.ms).slideX(begin: -0.2, end: 0),

                                    const SizedBox(height: 32),

                                    // Achievements section
                                    achievementsAsync.when(
                                      data: (achievements) {
                                        if (achievements.isEmpty) return const SizedBox();

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 24),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.all(10),
                                                    decoration: BoxDecoration(
                                                      gradient: const LinearGradient(
                                                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                                      ),
                                                      borderRadius: BorderRadius.circular(14),
                                                    ),
                                                    child: const Icon(Icons.emoji_events, color: Colors.white, size: 22),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  const Text(
                                                    'Achievements',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.w900,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 20),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 12,
                                                children: achievements.take(6).map((achievement) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          const Color(0xFFFFD700).withOpacity(0.3),
                                                          const Color(0xFFFFA500).withOpacity(0.2),
                                                        ],
                                                      ),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                        color: const Color(0xFFFFD700).withOpacity(0.5),
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Text('🏆', style: TextStyle(fontSize: 20)),
                                                        const SizedBox(width: 8),
                                                        Text(
                                                          achievement['title'],
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                        ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.2, end: 0);
                                      },
                                      loading: () => const SizedBox(),
                                      error: (_, __) => const SizedBox(),
                                    ),

                                    const SizedBox(height: 40),

                                    // Action buttons
                                    _buildActionButton(
                                      icon: Icons.edit,
                                      title: 'Edit Profile',
                                      subtitle: 'Update your information',
                                      onTap: () => _showEditProfileDialog(user),
                                    ).animate().fadeIn(delay: 1300.ms),

                                    const SizedBox(height: 24),

                                    // Logout button
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: GestureDetector(
                                        onTap: () async {
                                          await _supabase.auth.signOut();
                                          if (mounted) {
                                            // Navigate to landing page and clear all routes
                                            Navigator.of(context).pushNamedAndRemoveUntil(
                                              '/',
                                                  (route) => false,
                                            );
                                          }
                                        },
                                        child: Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(vertical: 18),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFFFF6B6B).withOpacity(0.4),
                                                const Color(0xFFFF8E53).withOpacity(0.3),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: const Color(0xFFFF6B6B).withOpacity(0.6),
                                              width: 2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFF6B6B).withOpacity(0.3),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.logout, color: Colors.white, size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                'Logout',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ).animate().fadeIn(delay: 1600.ms).shake(delay: 1600.ms),
                                    ),

                                    const SizedBox(height: 50),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD700)),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text('Error: $e', style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasNotification = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                ),
              ),
              if (hasNotification)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (gradient as LinearGradient).colors[0].withOpacity(0.3),
                gradient.colors[1].withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: gradient.colors[0].withOpacity(0.5),
              width: 2,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (gradient as LinearGradient).colors[0].withOpacity(0.25),
                  gradient.colors[1].withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: gradient.colors[0].withOpacity(0.4),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF667eea).withOpacity(0.25),
                      const Color(0xFF764ba2).withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.4),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.5),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
