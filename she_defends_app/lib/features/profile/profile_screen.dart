import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/features/auth/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("My Profile", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.lavender,
                      child: Text("👩", style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name.isEmpty ? "Sarah" : profile.name,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Age: ${profile.age.isEmpty ? '24' : profile.age} • Language: ${profile.preferredLanguage}",
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Medical Card Section
            const Text("Emergency Medical Card", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildMedicalRow("Blood Group", profile.bloodGroup),
                    const Divider(),
                    _buildMedicalRow("Allergies", profile.allergies.isEmpty ? "None reported" : profile.allergies),
                    const Divider(),
                    _buildMedicalRow("Medical Conditions", profile.medicalConditions.isEmpty ? "None reported" : profile.medicalConditions),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Settings Section
            const Text("Preferences & Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primaryActive),
                    title: const Text("Notification Preferences"),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primaryActive),
                    title: const Text("Location Permissions"),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_outlined, color: AppColors.primaryActive),
                    title: const Text("Emergency Settings"),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Logout Action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                icon: const Icon(Icons.logout, color: AppColors.emergency),
                label: const Text("Sign Out", style: TextStyle(color: AppColors.emergency)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.emergency.withOpacity(0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textMuted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
