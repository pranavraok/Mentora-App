import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/pages/landing_page.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/services/auth_service.dart';
import 'package:mentora_app/utils/responsive_helper.dart'; // ADDED

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNextPage();
  }

  Future<void> _navigateToNextPage() async {
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;

    // Check if user is logged in
    final authService = AuthService();
    final user = authService.currentUser;

    if (user != null) {
      // User is logged in - go to Dashboard
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const DashboardPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // No user - go to Landing Page
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
          const LandingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302b63),
              Color(0xFF24243e),
            ],
          ),
        ),
        child: Column(
          children: [
            // Spacer to center content vertically
            const Spacer(),
            // Logo + Tagline together (RESPONSIVE)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo - RESPONSIVE
                SizedBox(
                  width: ResponsiveHelper.spacing(context, 240),
                  height: ResponsiveHelper.spacing(context, 240),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                // NEGATIVE MARGIN - RESPONSIVE
                Transform.translate(
                  offset: Offset(0, -ResponsiveHelper.spacing(context, 75)),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveHelper.spacing(context, 40),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'YOUR PERSONAL AI\nCAREER COUNSELOR',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.fontSize(context, 17),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          height: 1.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                ),
              ],
            ),
            // Spacer to push content up
            const Spacer(),
            // Loading indicator - RESPONSIVE
            SizedBox(
              width: ResponsiveHelper.spacing(context, 32),
              height: ResponsiveHelper.spacing(context, 32),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(
                  AppColors.xpGold,
                ),
              ),
            ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
            SizedBox(height: ResponsiveHelper.spacing(context, 24)),
            // Bottom branding - RESPONSIVE
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.spacing(context, 24),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'TRANSFORM YOUR CAREER JOURNEY',
                  style: GoogleFonts.montserrat(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: ResponsiveHelper.fontSize(context, 11),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 600.ms),
            SizedBox(height: ResponsiveHelper.spacing(context, 40)),
          ],
        ),
      ),
    );
  }
}
