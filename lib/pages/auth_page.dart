import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/pages/onboarding_page.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/services/auth_service.dart';
import 'package:mentora_app/widgets/auth_popup_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class AuthPage extends ConsumerStatefulWidget {
  final bool isLogin;

  const AuthPage({super.key, this.isLogin = true});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _floatingController;
  late AnimationController _rotationController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _floatingController.dispose();
    _rotationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    _slideController.reset();
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AuthPage(isLogin: !widget.isLogin),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  // ✅ FIXED: Direct navigation without popup or ref.invalidate
  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();

      if (widget.isLogin) {
        // LOGIN
        try {
          final response = await authService.signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );

          if (response.user != null) {
            final isEmailVerified = response.user!.emailConfirmedAt != null;

            if (!isEmailVerified) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              await showAuthPopup(
                context: context,
                title: '📧 Email Not Verified',
                message:
                'Please verify your email before logging in. Check your inbox for the verification link.',
                icon: Icons.mark_email_unread_rounded,
                iconColor: const Color(0xFFFFA500),
                isEmailVerification: true,
                onClose: () {},
              );
              await authService.signOut();
              return;
            }

            // ✅ Wait for database sync
            await Future.delayed(const Duration(milliseconds: 500));

            final isComplete =
            await authService.isOnboardingComplete(response.user!.id);

            if (!mounted) return;

            // ✅ NO POPUP - Direct navigation with pushAndRemoveUntil
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => isComplete
                    ? const DashboardPage()
                    : const OnboardingPage(),
              ),
                  (route) => false, // Remove all routes
            );
          }
        } on AuthException catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);

          final errorMessage = e.message.toLowerCase();
          if (errorMessage.contains('email not confirmed')) {
            await showAuthPopup(
              context: context,
              title: '📧 Email Not Verified',
              message:
              'Please verify your email before logging in. Check your inbox and click the verification link.',
              icon: Icons.mark_email_unread_rounded,
              iconColor: const Color(0xFFFFA500),
              isEmailVerification: true,
              onClose: () {},
            );
          } else if (errorMessage.contains('invalid login credentials') ||
              errorMessage.contains('invalid password') ||
              errorMessage.contains('wrong password')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                const Text('Invalid email or password. Please try again.'),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
          return;
        }
      } else {
        // SIGN UP
        final response = await authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          name: _nameController.text.trim(),
        );

        if (response.user != null) {
          if (!mounted) return;
          setState(() => _isLoading = false);

          await showAuthPopup(
            context: context,
            title: '📧 Check Your Email!',
            message:
            'We\'ve sent a verification link to ${_emailController.text.trim()}. Please verify your email to continue.',
            icon: Icons.mark_email_read_rounded,
            iconColor: const Color(0xFF4facfe),
            isEmailVerification: true,
            autoCloseDurationSeconds: 10,
            onClose: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage(isLogin: true)),
              );
            },
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  // ✅ FIXED: Direct navigation without ref.invalidate
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final success = await authService.signInWithGoogle();

      if (success && mounted) {
        // ✅ Wait for database sync
        await Future.delayed(const Duration(milliseconds: 800));

        final user = authService.currentUser;
        if (user != null) {
          final isComplete =
          await authService.isOnboardingComplete(user.id);

          if (!mounted) return;

          // ✅ Direct navigation WITHOUT popup
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => isComplete
                  ? const DashboardPage()
                  : const OnboardingPage(),
            ),
                (route) => false,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google sign-in failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [
                      Color(0xFF0F0C29),
                      Color(0xFF302b63),
                      Color(0xFF24243e),
                      Color(0xFF302b63),
                    ],
                    transform: GradientRotation(
                      _rotationController.value * 2 * math.pi,
                    ),
                  ),
                ),
              );
            },
          ),

          // Floating orbs
          ...List.generate(5, (index) {
            return AnimatedBuilder(
              animation: _floatingController,
              builder: (context, child) {
                final offset = math.sin(
                  (_floatingController.value + index * 0.2) * 2 * math.pi,
                );
                return Positioned(
                  left: (index * 80.0) + offset * 30,
                  top: (index * 120.0) + offset * 40,
                  child: Container(
                    width: 100 + (index * 20.0),
                    height: 100 + (index * 20.0),
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
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Logo
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
                    child: SizedBox(
                      height: 80,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                      duration: 2000.ms,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    widget.isLogin ? 'Welcome Back!' : 'Join the Quest',
                    style:
                    Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    widget.isLogin
                        ? 'Continue your learning adventure'
                        : 'Start your career transformation',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 24),

                  // Form card
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: GlassmorphicContainer(
                      height: widget.isLogin ? 435 : 450,
                      width: double.infinity,
                      borderRadius: 28,
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
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Google button
                              _buildGoogleButton()
                                  .animate()
                                  .fadeIn(delay: 400.ms)
                                  .slideY(begin: 0.2, end: 0),
                              const SizedBox(height: 16),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'or',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withOpacity(0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 500.ms),
                              const SizedBox(height: 16),

                              // Name field (for signup)
                              if (!widget.isLogin) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                  validator: (v) => v?.isEmpty ?? true
                                      ? 'Name required'
                                      : null,
                                  delay: 600,
                                )
                                    .animate()
                                    .fadeIn(delay: 600.ms)
                                    .slideX(begin: -0.2, end: 0),
                                const SizedBox(height: 10),
                              ],

                              // Email field
                              _buildTextField(
                                controller: _emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v?.isEmpty ?? true) return 'Email required';
                                  if (!v!.contains('@')) return 'Invalid email';
                                  return null;
                                },
                                delay: widget.isLogin ? 600 : 700,
                              )
                                  .animate()
                                  .fadeIn(
                                delay: Duration(
                                  milliseconds: widget.isLogin ? 600 : 700,
                                ),
                              )
                                  .slideX(begin: -0.2, end: 0),
                              const SizedBox(height: 10),

                              // Password field
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Password',
                                icon: Icons.lock_outline,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (v) {
                                  if (v?.isEmpty ?? true)
                                    return 'Password required';
                                  if (v!.length < 6) return 'Min 6 characters';
                                  return null;
                                },
                                delay: widget.isLogin ? 700 : 800,
                              )
                                  .animate()
                                  .fadeIn(
                                delay: Duration(
                                  milliseconds: widget.isLogin ? 700 : 800,
                                ),
                              )
                                  .slideX(begin: -0.2, end: 0),

                              if (widget.isLogin) ...[
                                const SizedBox(height: 2),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ).animate().fadeIn(delay: 800.ms),
                              ],
                              const SizedBox(height: 16),

                              // Submit button
                              _buildSubmitButton()
                                  .animate()
                                  .fadeIn(
                                delay: Duration(
                                  milliseconds: widget.isLogin ? 900 : 1000,
                                ),
                              )
                                  .slideY(begin: 0.2, end: 0)
                                  .then()
                                  .shimmer(delay: 1000.ms, duration: 2000.ms),
                              const SizedBox(height: 10),

                              // Toggle auth mode
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.isLogin
                                        ? 'Don\'t have an account? '
                                        : 'Already have an account? ',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _toggleAuthMode,
                                    child: Text(
                                      widget.isLogin ? 'Sign Up' : 'Login',
                                      style: const TextStyle(
                                        color: AppColors.xpGold,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(
                                delay: Duration(
                                  milliseconds: widget.isLogin ? 1000 : 1100,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .scale(begin: const Offset(0.95, 0.95)),
                  ),
                  const SizedBox(height: 16),

                  // Trust badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTrustBadge(Icons.security, 'Secure'),
                      const SizedBox(width: 20),
                      _buildTrustBadge(Icons.verified_user, 'Trusted'),
                      const SizedBox(width: 20),
                      _buildTrustBadge(Icons.star, '4.9 Rating'),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 1200.ms)
                      .slideY(begin: 0.3, end: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleButton() {
    return GestureDetector(
      onTap: _handleGoogleSignIn,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.g_mobiledata, color: Colors.blue.shade700, size: 28),
            const SizedBox(width: 8),
            const Text(
              'Continue with Google',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    required int delay,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.xpGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.yellowAccent,
          fontWeight: FontWeight.w600,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      ),
      validator: validator,
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleAuth,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.isLogin ? 'Login & Continue' : 'Create Account',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.xpGold, size: 12),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
