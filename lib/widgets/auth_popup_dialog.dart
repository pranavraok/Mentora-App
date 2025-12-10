import 'package:flutter/material.dart';
import 'dart:async';

class AuthPopupDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color iconColor;
  final int autoCloseDurationSeconds;
  final VoidCallback? onClose;

  const AuthPopupDialog({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconColor,
    this.autoCloseDurationSeconds = 0,
    this.onClose,
  });

  @override
  State<AuthPopupDialog> createState() => _AuthPopupDialogState();
}

class _AuthPopupDialogState extends State<AuthPopupDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _autoCloseTimer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    )..forward();

    // Setup auto-close timer if duration is specified
    if (widget.autoCloseDurationSeconds > 0) {
      _remainingSeconds = widget.autoCloseDurationSeconds;
      _autoCloseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remainingSeconds--;
        });
        if (_remainingSeconds <= 0) {
          timer.cancel();
          if (mounted) {
            Navigator.of(context).pop();
            widget.onClose?.call();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
      child: AlertDialog(
        backgroundColor: const Color(0xFF1A1B2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: widget.iconColor.withOpacity(0.5), width: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [widget.iconColor, widget.iconColor.withOpacity(0.7)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.iconColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              widget.message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            if (_remainingSeconds > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Redirecting in $_remainingSeconds seconds...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (widget.autoCloseDurationSeconds == 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onClose?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.iconColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Got it!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show popups
Future<void> showAuthPopup({
  required BuildContext context,
  required String title,
  required String message,
  required IconData icon,
  required Color iconColor,
  int autoCloseDurationSeconds = 0,
  VoidCallback? onClose,
}) {
  return showDialog(
    context: context,
    barrierDismissible: autoCloseDurationSeconds == 0,
    builder: (context) => AuthPopupDialog(
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      autoCloseDurationSeconds: autoCloseDurationSeconds,
      onClose: onClose,
    ),
  );
}
