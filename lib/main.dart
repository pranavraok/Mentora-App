import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/pages/landing_page.dart';
import 'package:mentora_app/pages/onboarding_page.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/pages//splash_page.dart';
import 'package:mentora_app/widgets/error_fallback_widget.dart';
import 'package:mentora_app/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mentora - Gamified Career Development',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(), // ✅ Changed to AuthWrapper
    );
  }
}

// ✅ NEW: Handles all auth and loading states with error recovery
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      // Loading state - show splash screen
      loading: () => const SplashPage(),

      // Error state - show error fallback with recovery options
      error: (error, stack) {
        debugPrint('❌ Error in AuthWrapper: $error');
        return ErrorFallbackWidget(
          title: 'Unable to Load Profile',
          message: error.toString().contains('TimeoutException')
              ? 'Connection timed out. Please check your internet and try again.'
              : 'We couldn\'t load your profile. This might be a temporary issue.',
          onRetry: () {
            // Refresh the provider to retry loading
            debugPrint('🔄 Retrying user profile load...');
            ref.invalidate(currentUserProvider);
          },
          onGoToLogin: () async {
            // Sign out and navigate to landing page
            debugPrint('🚪 Signing out and going to login...');
            try {
              await SupabaseConfig.client.auth.signOut();
              debugPrint('✅ Signed out successfully');
            } catch (e) {
              debugPrint('❌ Sign out error: $e');
            }

            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LandingPage()),
              );
            }
          },
        );
      },

      // Success state - route based on user data
      data: (user) {
        if (user == null) {
          // No user logged in - show landing page
          debugPrint('ℹ️ No user found, showing landing page');
          return const LandingPage();
        }

        debugPrint('✅ User found: ${user.name} (${user.email})');

        // Check if onboarding is complete
        // Note: Adjust this check based on your UserModel structure
        final hasCompletedOnboarding =
            user.careerGoal != null && user.careerGoal!.isNotEmpty;

        if (!hasCompletedOnboarding) {
          debugPrint('ℹ️ Onboarding incomplete, showing onboarding page');
          return const OnboardingPage();
        }

        // User is logged in and onboarded - show dashboard
        debugPrint('✅ User authenticated and onboarded, showing dashboard');
        return const DashboardPage();
      },
    );
  }
}
