import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';
import 'package:she_defends_app/features/auth/setup_screen.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/features/dashboard_wrapper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Sign In / Sign Up state and validations
  bool _isSignUp = false;
  final RegExp _emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");

  Future<void> _handleMockLogin(bool isGoogle) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!isGoogle) {
      if (email.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your email")),
        );
        return;
      }
      if (!_emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid email address")),
        );
        return;
      }
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your password")),
        );
        return;
      }
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password must be at least 6 characters long")),
        );
        return;
      }
    }

    // Set global mock token (for development)
    ApiClient.mockEmail = email.isNotEmpty ? email : "google_user";

    // If it's a new signup, always redirect to SetupScreen for Profile Completion
    if (_isSignUp) {
      final apiClient = ApiClient();
      try {
        await apiClient.post("/auth/login", data: {"is_signup": true});
      } catch (e) {
        debugPrint("Failed to register signup login event: $e");
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const SetupScreen()),
        );
      }
      return;
    }

    // Otherwise, check if user already has a completed profile
    final apiClient = ApiClient();
    try {
      await apiClient.post("/auth/login", data: {"is_signup": false});
      
      // Fetch profile to see if setup is done
      final profileResp = await apiClient.get("/auth/profile");
      if (profileResp.statusCode == 200 && profileResp.data != null) {
        final data = profileResp.data;
        if (data['name'] != null && data['name'].toString().isNotEmpty) {
          // Profile exists, go directly to Home Dashboard
          if (mounted) {
            ref.read(authProvider.notifier).login();
            
            // Restore profile in Riverpod
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
    } on DioException catch (e) {
      debugPrint("Failed to register login event with database: $e");
      String errMsg = "Login failed. Please try again.";
      if (e.response != null && e.response!.data != null) {
        final respData = e.response!.data;
        if (respData is Map && respData.containsKey("error")) {
          errMsg = respData["error"];
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errMsg)),
        );
      }
      return;
    } catch (e) {
      debugPrint("Failed to register login event with database: $e");
    }

    // If profile is incomplete, direct to SetupScreen
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
              const SizedBox(height: 20),
              
              // Segmented Tab Mode Switcher
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isSignUp ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              color: !_isSignUp ? Colors.white : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isSignUp ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sign Up",
                            style: TextStyle(
                              color: _isSignUp ? Colors.white : AppColors.textMuted,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              Text(
                _isSignUp ? "Create Account\non SheDefends" : "Welcome to\nSheDefends",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp
                    ? "Sign up to access your personal safety, wellness, and AI health assistant."
                    : "Sign in to access your personal safety, wellness, and AI health assistant.",
                style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
              const SizedBox(height: 36),
              
              // Google Login Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleMockLogin(true),
                  icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.primary),
                  label: Text(
                    _isSignUp ? "Sign Up with Google" : "Continue with Google",
                    style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
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
              
              if (!_isSignUp)
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
              const SizedBox(height: 24),

              // Primary Auth button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleMockLogin(false),
                  child: Text(_isSignUp ? "Sign Up" : "Sign In"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
