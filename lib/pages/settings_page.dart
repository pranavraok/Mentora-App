import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:ui';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;

  // Settings states
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _dailyReminders = true;
  bool _weeklyProgress = true;
  bool _darkMode = true;
  bool _autoPlay = false;
  String _language = 'English';
  String _theme = 'Dark';

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
    return Scaffold(
      body: Stack(
        children: [
          // ✅ SAME BACKGROUND
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

          // ✅ FLOATING BLUR CIRCLES
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
              // ✅ GLASSMORPHIC HEADER
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
                            // Back button
                            _buildGlassButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context),
                            ),

                            // Title
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.white, Colors.white],
                              ).createShader(bounds),
                              child: const Text(
                                'Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),

                            // Placeholder for alignment
                            const SizedBox(width: 48),
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
                      const SizedBox(height: 24),

                      // 🔔 NOTIFICATIONS SECTION
                      _buildSectionTitle(
                            icon: Icons.notifications_rounded,
                            title: 'Notifications',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildSwitchTile(
                            icon: Icons.notifications_active,
                            title: 'Push Notifications',
                            subtitle: 'Receive notifications from the app',
                            value: _notificationsEnabled,
                            onChanged: (value) =>
                                setState(() => _notificationsEnabled = value),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildSwitchTile(
                            icon: Icons.volume_up_rounded,
                            title: 'Sound',
                            subtitle: 'Enable notification sounds',
                            value: _soundEnabled,
                            onChanged: (value) =>
                                setState(() => _soundEnabled = value),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildSwitchTile(
                            icon: Icons.alarm_rounded,
                            title: 'Daily Reminders',
                            subtitle: 'Get reminded to study daily',
                            value: _dailyReminders,
                            onChanged: (value) =>
                                setState(() => _dailyReminders = value),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildSwitchTile(
                            icon: Icons.bar_chart_rounded,
                            title: 'Weekly Progress',
                            subtitle: 'Receive weekly progress reports',
                            value: _weeklyProgress,
                            onChanged: (value) =>
                                setState(() => _weeklyProgress = value),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 600.ms)
                          .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 32),

                      // 🎨 APPEARANCE SECTION
                      _buildSectionTitle(
                            icon: Icons.palette_rounded,
                            title: 'Appearance',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 700.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildSwitchTile(
                            icon: Icons.dark_mode_rounded,
                            title: 'Dark Mode',
                            subtitle: 'Use dark theme',
                            value: _darkMode,
                            onChanged: (value) =>
                                setState(() => _darkMode = value),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 800.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.color_lens_rounded,
                            title: 'Theme',
                            subtitle: _theme,
                            onTap: () => _showThemeDialog(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 900.ms)
                          .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 32),

                      // 🌍 GENERAL SECTION
                      _buildSectionTitle(
                            icon: Icons.settings_rounded,
                            title: 'General',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1000.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.language_rounded,
                            title: 'Language',
                            subtitle: _language,
                            onTap: () => _showLanguageDialog(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1100.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildSwitchTile(
                            icon: Icons.play_circle_rounded,
                            title: 'Auto-play Videos',
                            subtitle: 'Automatically play next video',
                            value: _autoPlay,
                            onChanged: (value) =>
                                setState(() => _autoPlay = value),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1200.ms)
                          .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 32),

                      // 📱 SUPPORT SECTION
                      _buildSectionTitle(
                            icon: Icons.help_rounded,
                            title: 'Support & About',
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1300.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.privacy_tip_rounded,
                            title: 'Privacy Policy',
                            subtitle: 'Read our privacy policy',
                            onTap: () {},
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1400.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.description_rounded,
                            title: 'Terms of Service',
                            subtitle: 'Read terms and conditions',
                            onTap: () {},
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1500.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.info_rounded,
                            title: 'About',
                            subtitle: 'Version 1.0.0',
                            onTap: () => _showAboutDialog(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1600.ms)
                          .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 32),

                      // ⚠️ DANGER ZONE
                      _buildSectionTitle(
                            icon: Icons.warning_rounded,
                            title: 'Danger Zone',
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1700.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.delete_forever_rounded,
                            title: 'Clear Cache',
                            subtitle: 'Free up storage space',
                            onTap: () => _showClearCacheDialog(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1800.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.lock_reset_rounded,
                            title: 'Reset Progress',
                            subtitle: 'Reset all learning progress',
                            onTap: () => _showResetDialog(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 1900.ms)
                          .slideX(begin: -0.2, end: 0),

                      _buildTile(
                            icon: Icons.delete_outline_rounded,
                            title: 'Delete Account',
                            subtitle: 'Permanently delete your account',
                            onTap: () => _showDeleteAccountDialog(),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 2000.ms)
                          .slideX(begin: -0.2, end: 0),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required VoidCallback onTap,
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Center(child: Icon(icon, color: Colors.white, size: 22)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required Gradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: (gradient as LinearGradient).colors[0].withOpacity(
                    0.4,
                  ),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required Gradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (gradient as LinearGradient).colors[0].withOpacity(0.2),
                  gradient.colors[1].withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: gradient.colors[0].withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors[0].withOpacity(0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
                const SizedBox(width: 12),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: gradient.colors[0],
                    activeTrackColor: gradient.colors[0].withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Gradient gradient,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (gradient as LinearGradient).colors[0].withOpacity(0.2),
                      gradient.colors[1].withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: gradient.colors[0].withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: gradient.colors[0].withOpacity(0.3),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
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
                      size: 24,
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

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Dark'),
              leading: Radio<String>(
                value: 'Dark',
                groupValue: _theme,
                onChanged: (value) {
                  setState(() => _theme = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Light'),
              leading: Radio<String>(
                value: 'Light',
                groupValue: _theme,
                onChanged: (value) {
                  setState(() => _theme = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('System'),
              leading: Radio<String>(
                value: 'System',
                groupValue: _theme,
                onChanged: (value) {
                  setState(() => _theme = value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio<String>(
                value: 'English',
                groupValue: _language,
                onChanged: (value) {
                  setState(() => _language = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Spanish'),
              leading: Radio<String>(
                value: 'Spanish',
                groupValue: _language,
                onChanged: (value) {
                  setState(() => _language = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('French'),
              leading: Radio<String>(
                value: 'French',
                groupValue: _language,
                onChanged: (value) {
                  setState(() => _language = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Hindi'),
              leading: Radio<String>(
                value: 'Hindi',
                groupValue: _language,
                onChanged: (value) {
                  setState(() => _language = value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Mentora'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Mentora - Your AI Learning Companion'),
            SizedBox(height: 8),
            Text('© 2025 Mentora. All rights reserved.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear the cache? This will free up storage space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully!')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress'),
        content: const Text(
          'Are you sure you want to reset all your learning progress? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Progress reset!')));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion initiated')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
