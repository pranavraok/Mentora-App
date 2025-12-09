import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/pages/landing_page.dart';
import 'package:mentora_app/pages/dashboard_page.dart';
import 'package:mentora_app/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ascent - Gamified Career Development',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends ConsumerWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageProvider);
    final isAuthenticatedAsync = ref.watch(isAuthenticatedProvider);

    return storageAsync.when(
      data: (_) {
        return isAuthenticatedAsync.when(
          data: (isAuthenticated) {
            return isAuthenticated
                ? const DashboardPage()
                : const LandingPage();
          },
          loading: () => const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.rocket_launch,
                    size: 80,
                    color: AppColors.gradientPurple,
                  ),
                  SizedBox(height: 24),
                  CircularProgressIndicator(),
                ],
              ),
            ),
          ),
          error: (e, _) =>
              Scaffold(body: Center(child: Text('Auth error: $e'))),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rocket_launch,
                size: 80,
                color: AppColors.gradientPurple,
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error initializing app: $e'))),
    );
  }
}
