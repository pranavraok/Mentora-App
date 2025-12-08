import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mentora_app/models/roadmap_node.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/pages/settings_page.dart';
import 'package:mentora_app/pages/notifications_page.dart';

import 'dart:math' as math;
import 'dart:ui';

class RoadmapPage extends ConsumerStatefulWidget {
  const RoadmapPage({super.key});

  @override
  ConsumerState<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends ConsumerState<RoadmapPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox();
        final nodesAsync = ref.watch(roadmapNodesProvider(user.id));

        return Scaffold(
          body: Stack(
            children: [
              // ✅ BACKGROUND GRADIENT
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
                  animation: _backgroundController,
                  builder: (context, child) {
                    final offset = math.sin(
                      (_backgroundController.value + index * 0.2) * 2 * math.pi,
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

              // ✅ MAIN CONTENT
              Column(
                children: [
                  // ============= MODERN GLASSMORPHIC HEADER =============
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
                                // ✅ LOGO
                                SizedBox(
                                  height: 60,
                                  child: Image.asset(
                                    'assets/images/logo.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                // ✅ GLASSMORPHIC ACTIONS
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildGlassButton(
                                      icon: Icons.notifications_rounded,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const NotificationsPage(),
                                          ),
                                        );
                                      },
                                      hasNotification: true,
                                    ),
                                    const SizedBox(width: 12),
                                    _buildGlassButton(
                                      icon: Icons.settings_rounded,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SettingsPage(),
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

                  // ============= PAGE TITLE SECTION =============
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFFD700,
                                    ).withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.map_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
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
                                      'LEARNING ROADMAP',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your journey to mastery starts now!',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2, end: 0),

                  // ============= SCROLLABLE CONTENT =============
                  Expanded(
                    child: nodesAsync.when(
                      data: (nodes) {
                        if (nodes.isEmpty) {
                          return _buildEmptyState();
                        }

                        return CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 8),
                            ),

                            // Progress Summary
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: _buildProgressSummary(nodes),
                              ),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 32),
                            ),

                            // 3D Roadmap
                            SliverToBoxAdapter(
                              child: ThreeDRoadmap(nodes: nodes),
                            ),

                            const SliverToBoxAdapter(
                              child: SizedBox(height: 60),
                            ),
                          ],
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
                                      colors: [
                                        Color(0xFFFFD700),
                                        Color(0xFFFFA500),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFD700,
                                        ).withOpacity(0.5),
                                        blurRadius: 30,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .rotate(duration: 2.seconds),
                            const SizedBox(height: 24),
                            Text(
                              'Loading your roadmap...',
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
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
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
                      const Color(0xFFFFD700).withOpacity(0.2),
                      const Color(0xFFFFA500).withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.map_rounded,
                  size: 70,
                  color: Colors.white54,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 2.seconds),
          const SizedBox(height: 32),
          const Text(
            'No Roadmap Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your learning journey awaits',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(List<RoadmapNode> nodes) {
    final completed = nodes
        .where((n) => n.status == NodeStatus.completed)
        .length;
    final inProgress = nodes
        .where((n) => n.status == NodeStatus.inProgress)
        .length;
    final total = nodes.length;
    final progress = total > 0 ? completed / total : 0.0;

    return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.25),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Journey Progress',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completed of $total completed',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700).withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: progress,
                        child: Container(
                          height: 14,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withOpacity(0.5),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatChip(
                        '✅ $completed',
                        'Done',
                        const Color(0xFF43e97b),
                      ),
                      _buildStatChip(
                        '🔄 $inProgress',
                        'Active',
                        const Color(0xFF4facfe),
                      ),
                      _buildStatChip(
                        '📚 ${total - completed - inProgress}',
                        'Locked',
                        const Color(0xFF6c757d),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: 300.ms)
        .slideY(begin: 0.3, end: 0)
        .then()
        .shimmer(duration: 2.seconds, color: Colors.white.withOpacity(0.1));
  }

  Widget _buildStatChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============= 3D ROADMAP =============
class ThreeDRoadmap extends ConsumerWidget {
  final List<RoadmapNode> nodes;

  const ThreeDRoadmap({super.key, required this.nodes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: nodes.length * 280.0,
      child: Stack(
        children: [
          // 3D Road
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, nodes.length * 280.0),
            painter: ThreeDRoadPainter(nodeCount: nodes.length),
          ),

          // Checkpoints
          ...nodes.asMap().entries.map((entry) {
            final index = entry.key;
            final node = entry.value;
            final isLeft = index % 2 == 0;

            return Positioned(
              top: index * 280.0 + 80,
              left: isLeft ? 30 : null,
              right: isLeft ? null : 30,
              width: MediaQuery.of(context).size.width * 0.4,
              child: RoadCheckpoint(node: node, index: index, isLeft: isLeft)
                  .animate(delay: Duration(milliseconds: 150 * index))
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: isLeft ? -0.5 : 0.5, end: 0)
                  .then()
                  .shimmer(
                    duration: 1500.ms,
                    color: Colors.white.withOpacity(0.1),
                  ),
            );
          }),

          // Numbered markers on road
          ...nodes.asMap().entries.map((entry) {
            final index = entry.key;
            final node = entry.value;
            final isLeft = index % 2 == 0;

            return Positioned(
              top: index * 280.0 + 100,
              left: isLeft
                  ? MediaQuery.of(context).size.width * 0.4 + 50
                  : MediaQuery.of(context).size.width * 0.3,
              child: RoadMarker(number: index + 1, node: node)
                  .animate(delay: Duration(milliseconds: 150 * index + 300))
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0, 0), end: const Offset(1, 1)),
            );
          }),
        ],
      ),
    );
  }
}

// ============= 3D ROAD PAINTER =============
class ThreeDRoadPainter extends CustomPainter {
  final int nodeCount;

  ThreeDRoadPainter({required this.nodeCount});

  @override
  void paint(Canvas canvas, Size size) {
    final segmentHeight = 280.0;

    for (int i = 0; i < nodeCount; i++) {
      final y = i * segmentHeight;

      // Road segment path
      final path = Path();
      path.moveTo(size.width * 0.3, y);
      path.lineTo(size.width * 0.7, y);
      path.quadraticBezierTo(
        size.width * 0.85,
        y + segmentHeight / 2,
        size.width * 0.7,
        y + segmentHeight,
      );
      path.lineTo(size.width * 0.3, y + segmentHeight);
      path.quadraticBezierTo(
        size.width * 0.15,
        y + segmentHeight / 2,
        size.width * 0.3,
        y,
      );

      // Road gradient with enhanced 3D effect
      final gradient = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF2c3e50).withOpacity(0.95),
          const Color(0xFF4a5568).withOpacity(0.95),
          const Color(0xFF5a6678).withOpacity(0.95),
          const Color(0xFF4a5568).withOpacity(0.95),
          const Color(0xFF2c3e50).withOpacity(0.95),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(0, y, size.width, segmentHeight),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // Road edges
      final edgePaint = Paint()
        ..color = const Color(0xFF1a202c)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;

      canvas.drawPath(path, edgePaint);

      // Inner shadow effect
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawPath(path, shadowPaint);

      // Center dashed line
      _drawDashedLine(
        canvas,
        Offset(size.width * 0.5, y),
        Offset(size.width * 0.5, y + segmentHeight),
      );

      // Side lines
      _drawSideLine(
        canvas,
        Offset(size.width * 0.32, y),
        Offset(size.width * 0.32, y + segmentHeight),
        true,
      );
      _drawSideLine(
        canvas,
        Offset(size.width * 0.68, y),
        Offset(size.width * 0.68, y + segmentHeight),
        true,
      );
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    const dashWidth = 18.0;
    const dashSpace = 14.0;
    double distance = 0.0;
    final totalDistance = (end - start).distance;

    while (distance < totalDistance) {
      final startOffset = Offset.lerp(start, end, distance / totalDistance)!;
      distance += dashWidth;
      final endOffset = Offset.lerp(start, end, distance / totalDistance)!;
      canvas.drawLine(startOffset, endOffset, paint);
      distance += dashSpace;
    }
  }

  void _drawSideLine(Canvas canvas, Offset start, Offset end, bool isDashed) {
    if (isDashed) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..strokeWidth = 3;

      const dashWidth = 12.0;
      const dashSpace = 10.0;
      double distance = 0.0;
      final totalDistance = (end - start).distance;

      while (distance < totalDistance) {
        final startOffset = Offset.lerp(start, end, distance / totalDistance)!;
        distance += dashWidth;
        final endOffset = Offset.lerp(start, end, distance / totalDistance)!;
        canvas.drawLine(startOffset, endOffset, paint);
        distance += dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============= ROAD MARKER =============
class RoadMarker extends ConsumerStatefulWidget {
  final int number;
  final RoadmapNode node;

  const RoadMarker({super.key, required this.number, required this.node});

  @override
  ConsumerState<RoadMarker> createState() => _RoadMarkerState();
}

class _RoadMarkerState extends ConsumerState<RoadMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getNodeColor(widget.node.status);
    final gradient = _getNodeGradient(widget.node.status);

    return GestureDetector(
      onTap: () => _showNodeDetails(context, ref),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.node.status == NodeStatus.inProgress
                ? 1.0 + (_controller.value * 0.1)
                : 1.0,
            child: Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                gradient: gradient,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.7),
                    blurRadius: 25 + (_controller.value * 10),
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      widget.number.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (widget.node.status == NodeStatus.completed)
                    const Positioned(
                      top: -2,
                      right: -2,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 26,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  if (widget.node.status == NodeStatus.locked)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getNodeColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return const Color(0xFF43e97b);
      case NodeStatus.inProgress:
        return const Color(0xFF4facfe);
      case NodeStatus.unlocked:
        return const Color(0xFFFFD700);
      case NodeStatus.locked:
        return const Color(0xFF6c757d);
    }
  }

  LinearGradient _getNodeGradient(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        );
      case NodeStatus.inProgress:
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case NodeStatus.unlocked:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case NodeStatus.locked:
        return const LinearGradient(
          colors: [Color(0xFF6c757d), Color(0xFF495057)],
        );
    }
  }

  void _showNodeDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoadmapDetailSheet(node: widget.node),
    );
  }
}

// ============= ROAD CHECKPOINT =============
class RoadCheckpoint extends ConsumerWidget {
  final RoadmapNode node;
  final int index;
  final bool isLeft;

  const RoadCheckpoint({
    super.key,
    required this.node,
    required this.index,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getNodeColor(node.status);
    final gradient = _getNodeGradient(node.status);

    return GestureDetector(
      onTap: () => _showNodeDetails(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 120, maxHeight: 160),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.7), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: _getNodeIcon(node.type),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        node.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  node.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${node.estimatedHours}h',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${node.xpReward}',
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
        ),
      ),
    );
  }

  Color _getNodeColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return const Color(0xFF43e97b);
      case NodeStatus.inProgress:
        return const Color(0xFF4facfe);
      case NodeStatus.unlocked:
        return const Color(0xFFFFD700);
      case NodeStatus.locked:
        return const Color(0xFF6c757d);
    }
  }

  LinearGradient _getNodeGradient(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        );
      case NodeStatus.inProgress:
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case NodeStatus.unlocked:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case NodeStatus.locked:
        return const LinearGradient(
          colors: [Color(0xFF6c757d), Color(0xFF495057)],
        );
    }
  }

  Widget _getNodeIcon(NodeType type) {
    IconData iconData;
    switch (type) {
      case NodeType.course:
        iconData = Icons.school_rounded;
        break;
      case NodeType.project:
        iconData = Icons.construction_rounded;
        break;
      case NodeType.skillCheck:
        iconData = Icons.quiz_rounded;
        break;
      case NodeType.bossChallenge:
        iconData = Icons.shield_rounded;
        break;
      case NodeType.restStop:
        iconData = Icons.local_cafe_rounded;
        break;
      case NodeType.bonus:
        iconData = Icons.card_giftcard_rounded;
        break;
    }

    return Icon(iconData, color: Colors.white, size: 20);
  }

  void _showNodeDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoadmapDetailSheet(node: node),
    );
  }
}

// ============= DETAIL SHEET =============
class RoadmapDetailSheet extends ConsumerWidget {
  final RoadmapNode node;

  const RoadmapDetailSheet({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _getNodeColor(node.status);
    final gradient = _getNodeGradient(node.status);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1B2E), Color(0xFF0F0C29)],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.7),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _getNodeIcon(node.type, node.status),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              node.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color.withOpacity(0.4),
                                    color.withOpacity(0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Text(
                                _getStatusText(node.status),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          node.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(
                    Icons.star_rounded,
                    'XP Reward',
                    '${node.xpReward} XP',
                    const Color(0xFFFFD700),
                  ),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Duration',
                    '${node.estimatedHours} hours',
                    const Color(0xFF4facfe),
                  ),
                  if (node.providerName != null)
                    _buildDetailRow(
                      Icons.school_rounded,
                      'Provider',
                      node.providerName!,
                      const Color(0xFF667eea),
                    ),
                  if (node.skills.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      '💡 Skills You\'ll Learn',
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
                      children: node.skills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF667eea).withOpacity(0.5),
                                const Color(0xFF764ba2).withOpacity(0.5),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 32),
                  if (node.status == NodeStatus.unlocked ||
                      node.status == NodeStatus.inProgress)
                    Container(
                      width: double.infinity,
                      height: 62,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final roadmapService = ref.read(
                              roadmapServiceProvider,
                            );
                            await roadmapService.updateNode(
                              node.copyWith(
                                status: NodeStatus.inProgress,
                                startedAt: DateTime.now(),
                              ),
                            );
                            ref.invalidate(roadmapNodesProvider);
                            if (context.mounted) Navigator.pop(context);
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  node.status == NodeStatus.unlocked
                                      ? Icons.play_circle_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  node.status == NodeStatus.unlocked
                                      ? 'Start Learning'
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNodeColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return const Color(0xFF43e97b);
      case NodeStatus.inProgress:
        return const Color(0xFF4facfe);
      case NodeStatus.unlocked:
        return const Color(0xFFFFD700);
      case NodeStatus.locked:
        return const Color(0xFF6c757d);
    }
  }

  LinearGradient _getNodeGradient(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return const LinearGradient(
          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
        );
      case NodeStatus.inProgress:
        return const LinearGradient(
          colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
        );
      case NodeStatus.unlocked:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        );
      case NodeStatus.locked:
        return const LinearGradient(
          colors: [Color(0xFF6c757d), Color(0xFF495057)],
        );
    }
  }

  Widget _getNodeIcon(NodeType type, NodeStatus status) {
    if (status == NodeStatus.completed) {
      return const Icon(Icons.check_circle, color: Colors.white, size: 42);
    } else if (status == NodeStatus.locked) {
      return const Icon(Icons.lock_rounded, color: Colors.white, size: 38);
    }

    IconData iconData;
    switch (type) {
      case NodeType.course:
        iconData = Icons.school_rounded;
        break;
      case NodeType.project:
        iconData = Icons.construction_rounded;
        break;
      case NodeType.skillCheck:
        iconData = Icons.quiz_rounded;
        break;
      case NodeType.bossChallenge:
        iconData = Icons.shield_rounded;
        break;
      case NodeType.restStop:
        iconData = Icons.local_cafe_rounded;
        break;
      case NodeType.bonus:
        iconData = Icons.card_giftcard_rounded;
        break;
    }

    return Icon(iconData, color: Colors.white, size: 38);
  }

  String _getStatusText(NodeStatus status) {
    switch (status) {
      case NodeStatus.completed:
        return 'Completed ✓';
      case NodeStatus.inProgress:
        return 'In Progress';
      case NodeStatus.unlocked:
        return 'Available';
      case NodeStatus.locked:
        return 'Locked 🔒';
    }
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.3), color.withOpacity(0.15)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
