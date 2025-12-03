import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/widgets/level_badge.dart';
import 'package:mentora_app/pages/landing_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.gradientPurple, AppColors.darkBg],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.4],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gradientPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LevelBadge(level: user.level, title: user.levelTitle, size: 100),
                    const SizedBox(height: 32),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(context, '${user.xp}', 'Total XP', Icons.stars),
                          _buildStat(context, '${user.streak}', 'Streak', Icons.local_fire_department),
                          _buildStat(context, '${user.coins}', 'Coins', Icons.monetization_on),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      color: Theme.of(context).colorScheme.surface,
                      child: Column(
                        children: [
                          if (user.careerGoal != null)
                            _buildInfoTile(
                              context,
                              'Career Goal',
                              user.careerGoal!,
                              Icons.flag,
                            ),
                          if (user.education != null)
                            _buildInfoTile(
                              context,
                              'Education',
                              user.education!,
                              Icons.school,
                            ),
                          _buildInfoTile(
                            context,
                            'Weekly Hours',
                            '${user.weeklyHours} hours',
                            Icons.schedule,
                          ),
                          if (user.skills.isNotEmpty)
                            ListTile(
                              leading: const Icon(Icons.star),
                              title: const Text('Skills'),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: user.skills.map((skill) => Chip(
                                    label: Text(skill),
                                    backgroundColor: AppColors.gradientBlue.withValues(alpha: 0.15),
                                  )).toList(),
                                ),
                              ),
                            ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: const Text('Settings'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.help),
                            title: const Text('Help & Support'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {},
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout, color: AppColors.lockedDanger),
                            title: const Text(
                              'Logout',
                              style: TextStyle(color: AppColors.lockedDanger),
                            ),
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
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
