import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  final List<_PlayerEntry> _players = const [
    _PlayerEntry(
      name: 'You',
      xp: 12450,
      level: 12,
      rank: 1,
      streak: 18,
      avatarEmoji: '🚀',
    ),
    _PlayerEntry(
      name: 'CodeNinja',
      xp: 11800,
      level: 11,
      rank: 2,
      streak: 14,
      avatarEmoji: '👤',
    ),
    _PlayerEntry(
      name: 'BugHunter',
      xp: 11230,
      level: 11,
      rank: 3,
      streak: 9,
      avatarEmoji: '🕵️‍♂️',
    ),
    _PlayerEntry(
      name: 'PixelWizard',
      xp: 9800,
      level: 10,
      rank: 4,
      streak: 6,
      avatarEmoji: '🧙‍♂️',
    ),
    _PlayerEntry(
      name: 'StackMaster',
      xp: 9300,
      level: 9,
      rank: 5,
      streak: 5,
      avatarEmoji: '📚',
    ),
    _PlayerEntry(
      name: 'AsyncAce',
      xp: 8700,
      level: 9,
      rank: 6,
      streak: 4,
      avatarEmoji: '⚡',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topThree = _players.take(3).toList();

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

          // Floating blur circles
          ...List.generate(8, (index) {
            return AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                final offset =
                math.sin((_animController.value + index * 0.2) * 2 * math.pi);
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
              // Header: logo + notifications + settings
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
                        padding:
                        const EdgeInsets.fromLTRB(24, 18, 24, 18),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
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
                                _buildGlassButton(
                                  icon: Icons.notifications_rounded,
                                  onTap: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Leaderboard notifications coming soon 🔔',
                                        ),
                                        backgroundColor:
                                        Color(0xFF4facfe),
                                      ),
                                    );
                                  },
                                  hasNotification: true,
                                ),
                                const SizedBox(width: 12),
                                _buildGlassButton(
                                  icon: Icons.settings_rounded,
                                  onTap: () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Leaderboard filters coming soon ⚙️',
                                        ),
                                        backgroundColor:
                                        Color(0xFF764ba2),
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

              // Title + subtitle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 +
                              (math.sin(_animController.value *
                                  2 *
                                  math.pi) *
                                  0.08),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color.lerp(
                                    const Color(0xFFFFD700),
                                    const Color(0xFF4facfe),
                                    _animController.value,
                                  )!,
                                  const Color(0xFF00f2fe),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFD700)
                                      .withOpacity(0.6),
                                  blurRadius: 20 +
                                      (math.sin(_animController.value *
                                          2 *
                                          math.pi) *
                                          5),
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.leaderboard_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) =>
                              const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFFA500),
                                ],
                              ).createShader(bounds),
                          child: const Text(
                            'GLOBAL LEADERBOARD',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Text(
                          'Compete with other learners in real time',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.2, end: 0),

              // Scrollable body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPodium(topThree),
                      const SizedBox(height: 20),
                      _buildInfoChips(),
                      const SizedBox(height: 16),
                      _buildLeaderboardList(),
                      const SizedBox(height: 24),
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

  // ===== Podium (top 3) =====

  Widget _buildPodium(List<_PlayerEntry> topThree) {
    final p1 = topThree.isNotEmpty ? topThree[0] : null;
    final p2 = topThree.length > 1 ? topThree[1] : null;
    final p3 = topThree.length > 2 ? topThree[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            flex: 9,
            child: _ifPlayer(
              p2,
                  () => _buildPodiumCard(
                p2!,
                rankColor: const Color(0xFFC0C0C0),
                gradient: const LinearGradient(
                  colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 10,
            child: _ifPlayer(
              p1,
                  () => _buildPodiumCard(
                p1!,
                isCrowned: true,
                rankColor: const Color(0xFFFFD700),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 9,
            child: _ifPlayer(
              p3,
                  () => _buildPodiumCard(
                p3!,
                rankColor: const Color(0xFFCD7F32),
                gradient: const LinearGradient(
                  colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ifPlayer(_PlayerEntry? p, Widget Function() builder) {
    if (p == null) return const SizedBox.shrink();
    return builder();
  }

  Widget _buildPodiumCard(
      _PlayerEntry player, {
        required Color rankColor,
        required Gradient gradient,
        bool isCrowned = false,
      }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isCrowned)
          const Icon(
            Icons.emoji_events_rounded,
            color: Color(0xFFFFD700),
            size: 32,
          ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: rankColor.withOpacity(0.6),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            player.avatarEmoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '#${player.rank}',
          style: TextStyle(
            color: rankColor,
            fontWeight: FontWeight.w900,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          player.name,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${player.xp} XP • L${player.level}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: rankColor.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${player.streak} day streak 🔥',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '+${(player.xp / 100).round()} coins',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===== Info chips =====

  Widget _buildInfoChips() {
    return Row(
      children: [
        _buildInfoChip(
          icon: Icons.flash_on_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
          text: 'Daily XP decides your rank.',
        ),
        const SizedBox(width: 8),
        _buildInfoChip(
          icon: Icons.card_giftcard_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          text: 'Top 3 get bonus coins.',
        ),
      ],
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required Gradient gradient,
    required String text,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color:
              (gradient as LinearGradient).colors.first.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== List section =====

  Widget _buildLeaderboardList() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.2,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _players.length,
        separatorBuilder: (_, __) =>
            Container(height: 1, color: Colors.white.withOpacity(0.05)),
        itemBuilder: (context, index) {
          final player = _players[index];
          return _buildLeaderboardRow(player);
        },
      ),
    );
  }

  Widget _buildLeaderboardRow(_PlayerEntry player) {
    final isYou = player.rank == 1 || player.name == 'You';
    final gradient = _rowGradientForRank(player.rank);
    final medal = _medalForRank(player.rank);

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      padding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  '#${player.rank}',
                  style: TextStyle(
                    color: medal != null
                        ? Colors.white
                        : Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                if (medal != null)
                  Text(medal, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.08),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: Text(
              player.avatarEmoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isYou ? '${player.name} (You)' : player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                    isYou ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${player.streak} day streak • L${player.level}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.xp} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 80,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (player.xp % 10000) / 10000,
                    backgroundColor: Colors.white.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _rowBarColorForRank(player.rank),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Gradient _rowGradientForRank(int rank) {
    switch (rank) {
      case 1:
        return const LinearGradient(
          colors: [Color(0x33FFD700), Color(0x33FFA500)],
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0x333C99FF), Color(0x3300F2FE)],
        );
      case 3:
        return const LinearGradient(
          colors: [Color(0x33F093FB), Color(0x33F5576C)],
        );
      default:
        return const LinearGradient(
          colors: [Colors.transparent, Colors.transparent],
        );
    }
  }

  Color _rowBarColorForRank(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFF4facfe);
      case 3:
        return const Color(0xFFf093fb);
      default:
        return const Color(0xFF43e97b);
    }
  }

  String? _medalForRank(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  // ===== Shared glass button =====

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
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 22,
                    ),
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
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerEntry {
  final String name;
  final int xp;
  final int level;
  final int rank;
  final int streak;
  final String avatarEmoji;

  const _PlayerEntry({
    required this.name,
    required this.xp,
    required this.level,
    required this.rank,
    required this.streak,
    required this.avatarEmoji,
  });
}
