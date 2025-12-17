import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mentora_app/theme.dart';
import 'package:mentora_app/providers/app_providers.dart';
import 'package:mentora_app/pages/splash_page.dart';
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
      title: 'Mentora - Gamified Career Development',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const SplashPage(), // ✅ Changed to SplashPage
    );
  }
}

// ✅ Remove AppInitializer - SplashPage handles routing now
