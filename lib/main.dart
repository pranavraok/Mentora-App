import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/pages/landing_page.dart';
import 'package:mentora_app/pages/onboarding_page.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/pages/splash_page.dart';
import 'package:mentora_app/widgets/error_fallback_widget.dart';
import 'package:mentora_app/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load();
  } catch (e) {
    debugPrint(
      '⚠️  .env file not found, using environment variables or defaults',
    );
  }

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
      home: const AuthWrapper(),
    );
  }
}

// ✅ CRITICAL FIX: Changed to StatefulWidget with auth listener
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();

    // ✅ CRITICAL: Listen to Supabase auth changes
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('🔔 Auth event detected: $event');

      // Only invalidate on actual sign in/out events (not token refresh)
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.signedOut) {
        debugPrint('🔄 Refreshing user provider due to auth change');

        // Small delay to let Supabase finish its work
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            ref.invalidate(currentUserProvider);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () {
        debugPrint('⏳ AuthWrapper: Loading user data...');
        return const SplashPage();
      },
      error: (error, stack) {
        debugPrint('❌ AuthWrapper error: $error');
        return ErrorFallbackWidget(
          title: 'Unable to Load Profile',
          message: error.toString().contains('TimeoutException')
              ? 'Connection timed out. Please check your internet and try again.'
              : 'We couldn\'t load your profile. This might be a temporary issue.',
          onRetry: () {
            debugPrint('🔄 Retrying user profile load...');
            ref.invalidate(currentUserProvider);
          },
          onGoToLogin: () async {
            debugPrint('🚪 Signing out and going to login...');
            try {
              await SupabaseConfig.client.auth.signOut();
              debugPrint('✅ Signed out successfully');
            } catch (e) {
              debugPrint('❌ Sign out error: $e');
            }

            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingPage()),
                    (route) => false,
              );
            }
          },
        );
      },
      data: (user) {
        if (user == null) {
          debugPrint('ℹ️  AuthWrapper: No user, showing landing page');
          return const LandingPage();
        }

        debugPrint('✅ AuthWrapper: User found - ${user.name} (${user.email})');

        final hasCompletedOnboarding =
            user.careerGoal != null && user.careerGoal!.isNotEmpty;

        if (!hasCompletedOnboarding) {
          debugPrint('ℹ️  AuthWrapper: Onboarding incomplete');
          return const OnboardingPage();
        }

        debugPrint('✅ AuthWrapper: Showing dashboard');
        return const DashboardPage();
      },
    );
  }
}
