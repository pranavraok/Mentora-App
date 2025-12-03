import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/widgets/glassmorphic_card.dart';
import 'package:mentora_app/widgets/gradient_button.dart';
import 'package:mentora_app/pages/onboarding_page.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/models/user_model.dart';
import 'package:mentora_app/providers/app_providers.dart';

class AuthPage extends ConsumerStatefulWidget {
  final bool isLogin;

  const AuthPage({super.key, this.isLogin = true});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 1));

    final now = DateTime.now();
    final user = UserModel(
      id: 'user_${now.millisecondsSinceEpoch}',
      email: _emailController.text,
      name: widget.isLogin ? 'User' : _nameController.text,
      createdAt: now,
      updatedAt: now,
    );

    final userService = ref.read(userServiceProvider);
    await userService.saveUser(user);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (widget.isLogin) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassmorphicCard(
                blur: 15,
                opacity: 0.15,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rocket_launch, color: Colors.white, size: 60),
                      const SizedBox(height: 16),
                      Text(
                        widget.isLogin ? 'Welcome Back' : 'Create Account',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (!widget.isLogin) ...[
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                            prefixIcon: const Icon(Icons.person, color: Colors.white),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                          prefixIcon: const Icon(Icons.email, color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                          prefixIcon: const Icon(Icons.lock, color: Colors.white),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                              color: Colors.white,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => (v?.isEmpty ?? true) || v!.length < 6
                            ? 'Min 6 characters'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      GradientButton(
                        text: widget.isLogin ? 'Login' : 'Sign Up',
                        onPressed: _handleAuth,
                        isLoading: _isLoading,
                        gradient: const LinearGradient(
                          colors: [Colors.white, Colors.white],
                        ),
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AuthPage(isLogin: !widget.isLogin),
                          ),
                        ),
                        child: Text(
                          widget.isLogin
                              ? "Don't have an account? Sign up"
                              : 'Already have an account? Login',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
