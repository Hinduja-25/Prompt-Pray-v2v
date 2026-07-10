import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';
import 'package:she_defends_app/features/auth/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _apiClient = ApiClient();
  
  // Controllers for editing
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();

  String _selectedBloodGroup = "O+";
  String _selectedLanguage = "English";
  String _selectedActivity = "Lightly Active";
  String _selectedDiet = "Vegetarian";
  String _selectedGoal = "Healthy Maintenance";

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _apiClient.get("/auth/profile");
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final profile = UserProfile(
          name: data["name"] ?? "",
          age: data["age"] ?? "",
          bloodGroup: data["bloodGroup"] ?? "O+",
          allergies: data["allergies"] ?? "",
          medicalConditions: data["medicalConditions"] ?? "",
          preferredLanguage: data["preferredLanguage"] ?? "English",
          height: data["height"] ?? "165",
          weight: data["weight"] ?? "60",
          activityLevel: data["activityLevel"] ?? "Lightly Active",
          dietaryPreference: data["dietaryPreference"] ?? "Vegetarian",
          fitnessGoal: data["fitnessGoal"] ?? "Healthy Maintenance",
        );
        ref.read(userProfileProvider.notifier).updateProfile(profile);
      }
    } catch (e) {
      debugPrint("Failed to fetch profile: $e");
    }
  }

  Future<void> _saveProfile() async {
    final updated = UserProfile(
      name: _nameController.text.trim().isEmpty ? "Sarah" : _nameController.text.trim(),
      age: _ageController.text.trim().isEmpty ? "24" : _ageController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      allergies: _allergiesController.text.trim(),
      medicalConditions: _conditionsController.text.trim(),
      preferredLanguage: _selectedLanguage,
      height: _heightController.text.trim().isEmpty ? "165" : _heightController.text.trim(),
      weight: _weightController.text.trim().isEmpty ? "60" : _weightController.text.trim(),
      activityLevel: _selectedActivity,
      dietaryPreference: _selectedDiet,
      fitnessGoal: _selectedGoal,
    );

    try {
      final res = await _apiClient.post("/auth/profile", data: {
        "name": updated.name,
        "age": updated.age,
        "bloodGroup": updated.bloodGroup,
        "allergies": updated.allergies,
        "medicalConditions": updated.medicalConditions,
        "preferredLanguage": updated.preferredLanguage,
        "height": updated.height,
        "weight": updated.weight,
        "activityLevel": updated.activityLevel,
        "dietaryPreference": updated.dietaryPreference,
        "fitnessGoal": updated.fitnessGoal,
        "emergencyContacts": [], // Required by backend validator
      });
      
      if (!mounted) return;

      if (res.statusCode == 200) {
        ref.read(userProfileProvider.notifier).updateProfile(updated);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Health & Wellness profile updated successfully")),
        );
      }
    } catch (e) {
      debugPrint("Failed to update profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile")),
      );
    }
  }

  void _showEditProfileDialog(UserProfile current) {
    _nameController.text = current.name.isEmpty ? "Sarah" : current.name;
    _ageController.text = current.age.isEmpty ? "24" : current.age;
    _heightController.text = current.height;
    _weightController.text = current.weight;
    _allergiesController.text = current.allergies;
    _conditionsController.text = current.medicalConditions;
    _selectedBloodGroup = current.bloodGroup;
    _selectedLanguage = current.preferredLanguage;
    _selectedActivity = current.activityLevel;
    _selectedDiet = current.dietaryPreference;
    _selectedGoal = current.fitnessGoal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Edit Health & Wellness Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                const SizedBox(height: 20),
                
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Full Name")),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _ageController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Age"))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedBloodGroup,
                        decoration: const InputDecoration(labelText: "Blood Group"),
                        items: ["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => _selectedBloodGroup = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextField(controller: _heightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Height (cm)"))),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(controller: _weightController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Weight (kg)"))),
                  ],
                ),
                const SizedBox(height: 12),
                
                DropdownButtonFormField<String>(
                  initialValue: _selectedDiet,
                  decoration: const InputDecoration(labelText: "Dietary Preference"),
                  items: ["Vegetarian", "Vegan", "Non-Vegetarian"].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => _selectedDiet = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGoal,
                  decoration: const InputDecoration(labelText: "Fitness Goal"),
                  items: ["Healthy Maintenance", "Weight Loss", "Weight Gain", "Muscle Gain"].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => _selectedGoal = val);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedActivity,
                  decoration: const InputDecoration(labelText: "Activity Level"),
                  items: ["Sedentary", "Lightly Active", "Active", "Very Active"].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => _selectedActivity = val);
                  },
                ),
                const SizedBox(height: 12),
                
                TextField(controller: _allergiesController, decoration: const InputDecoration(labelText: "Allergies", hintText: "e.g. Peanuts, Penicillin")),
                const SizedBox(height: 12),
                TextField(controller: _conditionsController, decoration: const InputDecoration(labelText: "Medical Conditions", hintText: "e.g. Asthma, Hypertension")),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        child: const Text("Save changes"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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

            // Emergency Medical & Wellness Card Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Health & Wellness Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                TextButton.icon(
                  onPressed: () => _showEditProfileDialog(profile),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                )
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildMedicalRow("Blood Group", profile.bloodGroup),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Body Mass Index (BMI)", style: TextStyle(color: AppColors.textMuted)),
                        Row(
                          children: [
                            Text(
                              "${profile.bmi}",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                            ),
                            const SizedBox(width: 8),
                            _buildBmiBadge(profile.bmi),
                          ],
                        )
                      ],
                    ),
                    const Divider(),
                    _buildMedicalRow("Height / Weight", "${profile.height} cm / ${profile.weight} kg"),
                    const Divider(),
                    _buildMedicalRow("Dietary Preference", profile.dietaryPreference),
                    const Divider(),
                    _buildMedicalRow("Fitness Goal", profile.fitnessGoal),
                    const Divider(),
                    _buildMedicalRow("Activity Level", profile.activityLevel),
                    const Divider(),
                    _buildMedicalRow("Allergies", profile.allergies.isEmpty ? "None reported" : profile.allergies),
                    const Divider(),
                    _buildMedicalRow("Conditions", profile.medicalConditions.isEmpty ? "None reported" : profile.medicalConditions),
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
                  side: BorderSide(color: AppColors.emergency.withValues(alpha: 0.4)),
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

  Widget _buildBmiBadge(double bmi) {
    String text = "Normal";
    Color bg = AppColors.success.withValues(alpha: 0.1);
    Color fg = AppColors.success;
    
    if (bmi < 18.5) {
      text = "Underweight";
      bg = Colors.orange.withValues(alpha: 0.1);
      fg = Colors.orange;
    } else if (bmi >= 25 && bmi < 30) {
      text = "Overweight";
      bg = Colors.orange.withValues(alpha: 0.1);
      fg = Colors.orange;
    } else if (bmi >= 30) {
      text = "Obese";
      bg = AppColors.emergency.withValues(alpha: 0.1);
      fg = AppColors.emergency;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
