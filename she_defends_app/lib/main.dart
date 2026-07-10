import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/features/auth/onboarding_screen.dart';
import 'package:she_defends_app/features/auth/login_screen.dart';
import 'package:she_defends_app/features/dashboard_wrapper.dart';
import 'package:she_defends_app/core/services/notification_service.dart';
import 'package:she_defends_app/core/network/api_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Discover working backend URL based on device environment
  await ApiClient.findActiveBaseUrl();
  
  // Initialize local notifications on startup
  await NotificationService().init();

  
  runApp(
    const ProviderScope(
      child: SheDefendsApp(),
    ),
  );
}

class SheDefendsApp extends ConsumerWidget {
  const SheDefendsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget homeScreen;
    if (!authState.onboardingCompleted) {
      homeScreen = const OnboardingScreen();
    } else if (!authState.isLoggedIn) {
      homeScreen = const LoginScreen();
    } else {
      homeScreen = const DashboardWrapper();
    }

    return MaterialApp(
      title: 'SheDefends',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: homeScreen,
    );
  }
}
