import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';
import 'package:she_defends_app/features/auth/setup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _handleMockLogin(bool isGoogle) async {
    final email = _emailController.text.trim();
    if (email.isEmpty && !isGoogle) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }
    
    // Set global mock token (for development) if Firebase is not working
    // In a real app we'd use Firebase Auth. Here we just set a static variable for ApiClient to use.
    ApiClient.mockEmail = email.isNotEmpty ? email : "google_user";

    final apiClient = ApiClient();
    try {
      await apiClient.post("/auth/login");
      
      // Fetch profile to see if setup is done
      final profileResp = await apiClient.get("/auth/profile");
      if (profileResp.statusCode == 200 && profileResp.data != null) {
        final data = profileResp.data;
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          // Profile exists, go to Dashboard
          if (mounted) {
            ref.read(authProvider.notifier).login();
            
            // Also restore profile in Riverpod
            try {
              final p = UserProfile(
                name: data['name'] ?? '',
                age: data['age']?.toString() ?? '',
                bloodGroup: data['bloodGroup'] ?? 'O+',
                allergies: data['allergies'] ?? '',
                medicalConditions: data['medicalConditions'] ?? '',
                preferredLanguage: data['preferredLanguage'] ?? 'English',
                height: data['height']?.toString() ?? '165',
                weight: data['weight']?.toString() ?? '60',
                activityLevel: data['activityLevel'] ?? 'Lightly Active',
                dietaryPreference: data['dietaryPreference'] ?? 'Vegetarian',
                fitnessGoal: data['fitnessGoal'] ?? 'General Health',
                emergencyContacts: List<String>.from(data['emergencyContacts'] ?? []),
              );
              ref.read(userProfileProvider.notifier).updateProfile(p);
            } catch(e) {}

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const DashboardWrapper()),
            );
          }
          return;
        }
      }
    } catch (e) {
      debugPrint("Failed to register login event with database: $e");
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Welcome to\nSheDefends",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sign in to access your personal safety, wellness, and AI health assistant.",
                style: TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 48),
              
              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleMockLogin(true),
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.primary),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Row(
                children: [
                  Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text("or", style: TextStyle(color: AppColors.textMuted)),
                  ),
                  Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                ],
              ),
              const SizedBox(height: 24),

              // Email input
              const Text(
                "Email Address",
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: "Enter your email",
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),

              // Password input
              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Enter your password",
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: AppColors.primaryActive, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Primary Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleMockLogin(false),
                  child: const Text("Sign In"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
