import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/models/project.dart';
import 'package:mentora_app/models/project_extensions.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'dart:math' as math;
import 'dart:ui';

class ProjectsPage extends ConsumerStatefulWidget {
  const ProjectsPage({super.key});

  @override
  ConsumerState<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends ConsumerState<ProjectsPage> with SingleTickerProviderStateMixin {
  String selectedFilter = 'All';
  late AnimationController _animController;

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
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // ============= MAGICAL ANIMATED BACKGROUND (UPDATED) =============
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
            child: CustomPaint(
              painter: FloatingParticlesPainter(
                animation: _animController,
              ),
              size: Size.infinite,
            ),
          ),

          // ============= CONTENT LAYER =============
          Column(
            children: [
              // ============= PREMIUM HEADER =============
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0F0C29).withOpacity(0.95),
                      const Color(0xFF302b63).withOpacity(0.9),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 25,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 48), // Spacer for alignment
                            Column(
                              children: [
                                const Text(
                                  'Build Projects',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Transform ideas into reality',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withOpacity(0.4),
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Filter Chips
                      SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildFilterChip('All', Icons.apps_rounded),
                            const SizedBox(width: 10),
                            _buildFilterChip('In Progress', Icons.play_circle_outline),
                            const SizedBox(width: 10),
                            _buildFilterChip('Completed', Icons.check_circle_outline),
                            const SizedBox(width: 10),
                            _buildFilterChip('Unlocked', Icons.lock_open_rounded),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.2, end: 0),
              ),

              // Scrollable Content
              Expanded(
                child: projectsAsync.when(
                  data: (projects) {
                    if (projects.isEmpty) {
                      return _buildEmptyState();
                    }

                    final filteredProjects = _filterProjects(projects);
                    if (filteredProjects.isEmpty) {
                      return _buildEmptyFilterState();
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(20),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: filteredProjects.length,
                      itemBuilder: (context, index) => ProjectCard(
                        project: filteredProjects[index],
                        index: index,
                      ),
                    );
                  },
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF667eea).withOpacity(0.5),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ).animate(onPlay: (controller) => controller.repeat()).rotate(duration: 2.seconds),
                        const SizedBox(height: 24),
                        Text(
                          'Loading Projects...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 80,
                          color: Colors.red.withOpacity(0.7),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          e.toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF667eea).withOpacity(0.2),
                  const Color(0xFF764ba2).withOpacity(0.2),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              size: 70,
              color: Colors.white54,
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds),
          const SizedBox(height: 32),
          const Text(
            'No Projects Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start building amazing projects',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyFilterState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.filter_alt_off_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            'No projects match this filter',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.15),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF667eea).withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Project> _filterProjects(List<Project> projects) {
    switch (selectedFilter) {
      case 'In Progress':
        return projects.where((p) => p.status == ProjectStatus.inProgress).toList();
      case 'Completed':
        return projects.where((p) => p.status == ProjectStatus.completed).toList();
      case 'Unlocked':
        return projects.where((p) => p.status == ProjectStatus.unlocked).toList();
      default:
        return projects;
    }
  }
}

// ============= FLOATING PARTICLES BACKGROUND PAINTER =============
class FloatingParticlesPainter extends CustomPainter {
  final Animation<double> animation;

  FloatingParticlesPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating circles
    for (int i = 0; i < 20; i++) {
      final progress = (animation.value + (i * 0.05)) % 1.0;
      final x = (size.width * 0.1) + (i % 5) * (size.width * 0.2);
      final y = size.height * progress;
      final opacity = (1.0 - progress) * 0.3;
      final radius = 3.0 + (i % 3) * 2;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw gradient orbs
    final orbs = [
      {'x': 0.2, 'y': 0.3, 'color': const Color(0xFF667eea)},
      {'x': 0.8, 'y': 0.5, 'color': const Color(0xFF764ba2)},
      {'x': 0.5, 'y': 0.7, 'color': const Color(0xFF667eea)},
    ];

    for (var orb in orbs) {
      final offsetX = math.sin(animation.value * 2 * math.pi) * 30;
      final offsetY = math.cos(animation.value * 2 * math.pi) * 20;

      final gradient = RadialGradient(
        colors: [
          (orb['color'] as Color).withOpacity(0.15),
          (orb['color'] as Color).withOpacity(0.0),
        ],
      );

      final center = Offset(
        size.width * (orb['x'] as double) + offsetX,
        size.height * (orb['y'] as double) + offsetY,
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: 150),
      );
      canvas.drawCircle(center, 150, paint);
    }

    // Draw grid pattern
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const gridSize = 50.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(FloatingParticlesPainter oldDelegate) => true;
}

// ============= PROJECT CARD (Keep all existing code) =============
class ProjectCard extends ConsumerWidget {
  final Project project;
  final int index;

  const ProjectCard({
    super.key,
    required this.project,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getStatusColor(project.status);
    final gradient = _getStatusGradient(project.status);
    final difficultyColor = _getDifficultyColor(project.difficulty);

    return GestureDetector(
      onTap: () => _showProjectDetails(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: color.withOpacity(0.6),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Icon Section
                Container(
                  height: 95,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    children: [
                      // Background Pattern
                      Positioned.fill(
                        child: CustomPaint(
                          painter: HexagonPatternPainter(color: Colors.white.withOpacity(0.15)),
                        ),
                      ),

                      // Icon
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getProjectIcon(project.status),
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Status Badge
                      if (project.status == ProjectStatus.completed)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Color(0xFF43e97b),
                            ),
                          ).animate(onPlay: (controller) => controller.repeat()).scale(
                            duration: 1.seconds,
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.1, 1.1),
                          ),
                        ),
                    ],
                  ),
                ),

                // Content Section
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Difficulty & XP
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      difficultyColor.withOpacity(0.3),
                                      difficultyColor.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(color: difficultyColor, width: 1.5),
                                ),
                                child: Text(
                                  project.difficulty.name.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    color: difficultyColor,
                                    letterSpacing: 0.4,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                                ),
                                borderRadius: BorderRadius.circular(7),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFD700).withOpacity(0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, size: 10, color: Colors.white),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${project.xpReward}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          project.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Description
                        Flexible(
                          child: Text(
                            project.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Progress Bar or Status
                        if (project.status == ProjectStatus.inProgress)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(project.completionPercentage * 100).toInt()}%',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${project.tasks.where((t) => t.isCompleted).length}/${project.tasks.length}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: project.completionPercentage,
                                      child: Container(
                                        height: 5,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [color, color.withOpacity(0.7)],
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.5),
                                              blurRadius: 8,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.25),
                                  color.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: color.withOpacity(0.5), width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                _getStatusText(project.status),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
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
          ),
        ),
      )
          .animate(delay: Duration(milliseconds: 100 * index))
          .fadeIn(duration: 600.ms)
          .slideY(begin: 0.3, end: 0)
          .then()
          .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.05)),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return const Color(0xFF43e97b);
      case ProjectStatus.inProgress:
        return const Color(0xFF4facfe);
      case ProjectStatus.unlocked:
        return const Color(0xFFFFD700);
      case ProjectStatus.locked:
        return const Color(0xFF6c757d);
    }
  }

  LinearGradient _getStatusGradient(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        );
      case ProjectStatus.inProgress:
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case ProjectStatus.unlocked:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case ProjectStatus.locked:
        return const LinearGradient(
          colors: [Color(0xFF6c757d), Color(0xFF495057)],
        );
    }
  }

  Color _getDifficultyColor(ProjectDifficulty difficulty) {
    switch (difficulty) {
      case ProjectDifficulty.beginner:
        return const Color(0xFF43e97b);
      case ProjectDifficulty.intermediate:
        return const Color(0xFFFFD700);
      case ProjectDifficulty.advanced:
        return const Color(0xFFFF6B6B);
      case ProjectDifficulty.expert:
        return const Color(0xFF8B00FF);
    }
  }

  IconData _getProjectIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return Icons.check_circle_rounded;
      case ProjectStatus.inProgress:
        return Icons.construction_rounded;
      case ProjectStatus.unlocked:
        return Icons.rocket_launch_rounded;
      case ProjectStatus.locked:
        return Icons.lock_rounded;
    }
  }

  String _getStatusText(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return 'Completed ✓';
      case ProjectStatus.inProgress:
        return 'In Progress';
      case ProjectStatus.unlocked:
        return 'Start Building';
      case ProjectStatus.locked:
        return 'Locked 🔒';
    }
  }

  void _showProjectDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectDetailSheet(project: project),
    );
  }
}

// ============= HEXAGON PATTERN PAINTER (Keep existing) =============
class HexagonPatternPainter extends CustomPainter {
  final Color color;

  HexagonPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const spacing = 22.0;

    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing * 1.5) {
        final offset = (y / spacing).floor() % 2 == 0 ? 0.0 : spacing * 0.75;
        _drawHexagon(canvas, paint, Offset(x + offset, y), 7);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Paint paint, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============= PROJECT DETAIL SHEET (Keep all existing code exactly as is) =============
class ProjectDetailSheet extends ConsumerWidget {
  final Project project;

  const ProjectDetailSheet({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getStatusColor(project.status);
    final gradient = _getStatusGradient(project.status);
    final difficultyColor = _getDifficultyColor(project.difficulty);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF1A1B2E).withOpacity(0.95),
                const Color(0xFF0F0C29).withOpacity(0.95),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Container(
                margin: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _getProjectIcon(project.status),
                                  size: 34,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      project.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: difficultyColor.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: Text(
                                            project.difficulty.name.toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star, color: Colors.white, size: 13),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${project.xpReward} XP',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w900,
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
                            ],
                          ),
                          if (project.status == ProjectStatus.inProgress) ...[
                            const SizedBox(height: 18),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Progress: ${(project.completionPercentage * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${project.tasks.where((t) => t.isCompleted).length}/${project.tasks.length} tasks',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Container(
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: project.completionPercentage,
                                    child: Container(
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withOpacity(0.5),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview
                      const Text(
                        '📝 Overview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              project.overview,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 14,
                                height: 1.6,
                              ),
                            ),
                          ),
                        ),
                      ),

                      if (project.requiredSkills.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          '💡 Required Skills',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: project.requiredSkills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF667eea).withOpacity(0.5),
                                    const Color(0xFF764ba2).withOpacity(0.5),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF667eea),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF667eea).withOpacity(0.3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      if (project.tasks.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          '✅ Tasks (${project.tasks.where((t) => t.isCompleted).length}/${project.tasks.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...project.tasks.map((task) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: task.isCompleted
                                          ? [
                                        const Color(0xFF43e97b).withOpacity(0.25),
                                        const Color(0xFF43e97b).withOpacity(0.1),
                                      ]
                                          : [
                                        Colors.white.withOpacity(0.1),
                                        Colors.white.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: task.isCompleted
                                          ? const Color(0xFF43e97b)
                                          : Colors.white.withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          gradient: task.isCompleted
                                              ? const LinearGradient(
                                            colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                                          )
                                              : null,
                                          color: task.isCompleted ? null : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: task.isCompleted
                                                ? const Color(0xFF43e97b)
                                                : Colors.white.withOpacity(0.5),
                                            width: 2,
                                          ),
                                        ),
                                        child: task.isCompleted
                                            ? const Icon(
                                          Icons.check,
                                          size: 14,
                                          color: Colors.white,
                                        )
                                            : null,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          task.title,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            decoration: task.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Action Button
              if (project.status == ProjectStatus.unlocked ||
                  project.status == ProjectStatus.inProgress)
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final projectService = ref.read(projectServiceProvider);
                          await projectService.updateProject(
                            project.copyWith(
                              status: ProjectStatus.inProgress,
                              startedAt: DateTime.now(),
                            ),
                          );
                          ref.invalidate(projectsProvider);
                          if (context.mounted) Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                project.status == ProjectStatus.unlocked
                                    ? Icons.play_circle_rounded
                                    : Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                project.status == ProjectStatus.unlocked
                                    ? 'Start Building'
                                    : 'Continue',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                ),
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
        ),
      ),
    );
  }

  Color _getStatusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return const Color(0xFF43e97b);
      case ProjectStatus.inProgress:
        return const Color(0xFF4facfe);
      case ProjectStatus.unlocked:
        return const Color(0xFFFFD700);
      case ProjectStatus.locked:
        return const Color(0xFF6c757d);
    }
  }

  LinearGradient _getStatusGradient(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        );
      case ProjectStatus.inProgress:
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case ProjectStatus.unlocked:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case ProjectStatus.locked:
        return const LinearGradient(
          colors: [Color(0xFF6c757d), Color(0xFF495057)],
        );
    }
  }

  Color _getDifficultyColor(ProjectDifficulty difficulty) {
    switch (difficulty) {
      case ProjectDifficulty.beginner:
        return const Color(0xFF43e97b);
      case ProjectDifficulty.intermediate:
        return const Color(0xFFFFD700);
      case ProjectDifficulty.advanced:
        return const Color(0xFFFF6B6B);
      case ProjectDifficulty.expert:
        return const Color(0xFF8B00FF);
    }
  }

  IconData _getProjectIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.completed:
        return Icons.check_circle_rounded;
      case ProjectStatus.inProgress:
        return Icons.construction_rounded;
      case ProjectStatus.unlocked:
        return Icons.rocket_launch_rounded;
      case ProjectStatus.locked:
        return Icons.lock_rounded;
    }
  }
}

