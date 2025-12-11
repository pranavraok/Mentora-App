import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mentora_app/models/notification.dart';
import 'package:mentora_app/providers/notification_provider.dart';
import 'dart:math' as math;
import 'dart:ui';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatingController;

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
    final notificationsAsync = ref.watch(notificationsProvider);
    final unreadCountAsync = ref.watch(unreadNotificationCountProvider);

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
                            _buildGlassButton(
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.pop(context),
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                unreadCountAsync.when(
                                  data: (count) => count > 0
                                      ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                      : const SizedBox.shrink(),
                                  loading: () => const SizedBox.shrink(),
                                  error: (_, __) => const SizedBox.shrink(),
                                ),
                              ],
                            ),
                            _buildGlassButton(
                              icon: Icons.done_all_rounded,
                              onTap: () async {
                                final actions = ref.read(notificationActionsProvider);
                                // Get current user ID
                                final notifications = await ref.read(notificationsProvider.future);
                                if (notifications.isNotEmpty) {
                                  await actions.markAllAsRead(notifications.first.userId);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.3, end: 0),

              // Notifications list
              Expanded(
                child: notificationsAsync.when(
                  data: (notifications) {
                    if (notifications.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationCard(notification, index)
                            .animate(delay: (100 * index).ms)
                            .fadeIn()
                            .slideX(begin: 0.2, end: 0);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  error: (error, stack) => Center(
                    child: Text(
                      'Error loading notifications: $error',
                      style: const TextStyle(color: Colors.white),
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

  Widget _buildNotificationCard(AppNotification notification, int index) {
    final actions = ref.read(notificationActionsProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) async {
          await actions.deleteNotification(notification.id);
        },
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: notification.isRead
                      ? [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ]
                      : [
                    const Color(0xFF4facfe).withOpacity(0.2),
                    const Color(0xFF00f2fe).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: notification.isRead
                      ? Colors.white.withOpacity(0.2)
                      : const Color(0xFF4facfe).withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: InkWell(
                onTap: () async {
                  if (!notification.isRead) {
                    await actions.markAsRead(notification.id);
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: _getGradientForType(notification.type),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _getColorForType(notification.type).withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Text(
                        notification.icon,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (!notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4facfe),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notification.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: Colors.white.withOpacity(0.6),
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                notification.timeAgo,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 60,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'All Caught Up!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have no notifications at the moment.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      )
          .animate()
          .fadeIn(delay: 300.ms)
          .scale(begin: const Offset(0.8, 0.8)),
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

  LinearGradient _getGradientForType(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]);
      case NotificationType.levelUp:
        return const LinearGradient(colors: [Color(0xFF667eea), Color(0xFF764ba2)]);
      case NotificationType.projectUnlocked:
      case NotificationType.projectCompleted:
        return const LinearGradient(colors: [Color(0xFF43e97b), Color(0xFF38f9d7)]);
      case NotificationType.streakMilestone:
        return const LinearGradient(colors: [Color(0xFFfa709a), Color(0xFFfee140)]);
      default:
        return const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]);
    }
  }

  Color _getColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.achievement:
        return const Color(0xFFFFD700);
      case NotificationType.levelUp:
        return const Color(0xFF667eea);
      case NotificationType.projectUnlocked:
      case NotificationType.projectCompleted:
        return const Color(0xFF43e97b);
      case NotificationType.streakMilestone:
        return const Color(0xFFfa709a);
      default:
        return const Color(0xFF4facfe);
    }
  }
}

