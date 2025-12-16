import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';

Future<void> showAuthPopup({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required Color iconColor,
  int? autoCloseDurationSeconds,
  VoidCallback? onClose,
  bool isEmailVerification = false,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (BuildContext dialogContext) {
      if (autoCloseDurationSeconds != null) {
        Future.delayed(Duration(seconds: autoCloseDurationSeconds), () {
          if (dialogContext.mounted) {
            Navigator.of(dialogContext).pop();
            onClose?.call();
          }
        });
      }

      return _AnimatedAuthPopup(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        autoCloseDurationSeconds: autoCloseDurationSeconds,
        isEmailVerification: isEmailVerification,
        onClose: () {
          Navigator.of(dialogContext).pop();
          onClose?.call();
        },
      );
    },
  );
}

class _AnimatedAuthPopup extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final int? autoCloseDurationSeconds;
  final bool isEmailVerification;
  final VoidCallback onClose;

  const _AnimatedAuthPopup({
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.autoCloseDurationSeconds,
    this.isEmailVerification = false,
    required this.onClose,
  });

  @override
  State<_AnimatedAuthPopup> createState() => _AnimatedAuthPopupState();
}

class _AnimatedAuthPopupState extends State<_AnimatedAuthPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 300,
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F0C29),
                Color(0xFF302b63),
                Color(0xFF24243e),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: GlassmorphicContainer(
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.6),
                Colors.white.withOpacity(0.2),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.iconColor.withOpacity(0.3),
                          widget.iconColor.withOpacity(0.1),
                        ],
                      ),
                      border: Border.all(
                        color: widget.iconColor.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.iconColor.withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      size: 26,
                      color: widget.iconColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Message
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    maxLines: widget.isEmailVerification ? 3 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),

                  // Email verification instructions
                  if (widget.isEmailVerification) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4facfe).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4facfe).withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.mail_outline,
                            color: Color(0xFF4facfe),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Check inbox & click verification link',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Auto-close timer
                  if (widget.autoCloseDurationSeconds != null) ...[
                    const SizedBox(height: 10),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: widget.autoCloseDurationSeconds!,
                        end: 0,
                      ),
                      duration: Duration(seconds: widget.autoCloseDurationSeconds!),
                      builder: (context, value, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Redirecting in ${value}s',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Button (only if NOT auto-closing)
                  if (widget.autoCloseDurationSeconds == null)
                    Container(
                      width: double.infinity,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onClose,
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
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
        ),
      ),
    );
  }
}

