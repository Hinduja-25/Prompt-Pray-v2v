import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/features/dashboard_wrapper.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _currentStep = 1;
  final int _totalSteps = 3;

  // Controllers
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _selectedBlood = 'O+';
  final _allergiesController = TextEditingController();
  final _conditionsController = TextEditingController();
  String _selectedLang = 'English';

  final List<String> _emergencyContacts = [];
  final _contactController = TextEditingController();

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _languages = ['English', 'Spanish', 'Hindi', 'French', 'Arabic'];

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() => _currentStep++);
    } else {
      _saveProfile();
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  void _saveProfile() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in your name")),
      );
      return;
    }

    final profile = UserProfile(
      name: _nameController.text.trim(),
      age: _ageController.text.trim(),
      bloodGroup: _selectedBlood,
      allergies: _allergiesController.text.trim(),
      medicalConditions: _conditionsController.text.trim(),
      emergencyContacts: _emergencyContacts,
      preferredLanguage: _selectedLang,
    );

    // Save profile state using Riverpod
    ref.read(userProfileProvider.notifier).updateProfile(profile);
    ref.read(authProvider.notifier).login();

    // Navigate to Dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DashboardWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = _currentStep / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                onPressed: _prevStep,
              )
            : null,
        title: const Text(
          "Setup Profile",
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppColors.lavender,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Step $_currentStep of $_totalSteps",
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      Text(
                        "${(progress * 100).toInt()}% Complete",
                        style: const TextStyle(color: AppColors.primaryActive, fontWeight: FontWeight.w600, fontSize: 13),
                      )
                    ],
                  )
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _buildStepContent(),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentStep > 1)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _prevStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text("Back", style: TextStyle(color: AppColors.primary)),
                      ),
                    ),
                  if (_currentStep > 1) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      child: Text(_currentStep == _totalSteps ? "Complete" : "Next"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tell us about yourself",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              "This helps customize your health score and dashboard experience.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: "Enter your name"),
            ),
            const SizedBox(height: 24),
            const Text("Age", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "Enter your age"),
            ),
            const SizedBox(height: 24),
            const Text("Preferred Language", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLang,
              decoration: const InputDecoration(),
              items: _languages.map((lang) => DropdownMenuItem(
                value: lang,
                child: Text(lang),
              )).toList(),
              onChanged: (val) => setState(() => _selectedLang = val!),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Medical Card",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Essential medical details in case of emergency. (Optional fields can be bypassed)",
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const Text("Blood Group", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBlood,
              decoration: const InputDecoration(),
              items: _bloodGroups.map((bg) => DropdownMenuItem(
                value: bg,
                child: Text(bg),
              )).toList(),
              onChanged: (val) => setState(() => _selectedBlood = val!),
            ),
            const SizedBox(height: 24),
            const Text("Allergies (Optional)", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _allergiesController,
              decoration: const InputDecoration(hintText: "e.g. Penicillin, Peanuts"),
            ),
            const SizedBox(height: 24),
            const Text("Existing Medical Conditions (Optional)", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _conditionsController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: "e.g. Asthma, Hypertension"),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Emergency Guardians",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            const Text(
              "Add trusted contacts to be notified when you activate SOS or deviate from your route.",
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 32),
            const Text("Add Emergency Contact Number", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(hintText: "+1 (555) 019-2834"),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () {
                    final num = _contactController.text.trim();
                    if (num.isNotEmpty && !_emergencyContacts.contains(num)) {
                      setState(() {
                        _emergencyContacts.add(num);
                        _contactController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Guardians Added", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_emergencyContacts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: const Text("No contacts added yet", style: TextStyle(color: AppColors.textMuted)),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _emergencyContacts.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(_emergencyContacts[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.emergency),
                        onPressed: () {
                          setState(() {
                            _emergencyContacts.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
