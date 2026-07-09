import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/features/assistant/assistant_chat_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _waterCups = 3; // Mock tracking in state
  final int _waterGoal = 8;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final medications = ref.watch(medicationProvider);
    final guardianState = ref.watch(guardianProvider);
    
    // Dynamic greeting based on current time
    final hour = DateTime.now().hour;
    String greeting = "Good Morning,";
    if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon,";
    } else if (hour >= 17) {
      greeting = "Good Evening,";
    }

    final formattedDate = "${_getMonth(DateTime.now().month)} ${DateTime.now().day}, ${DateTime.now().year}";
    final dueMedsCount = medications.where((m) => !m.isTaken).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
                      ),
                      Text(
                        profile.name.isEmpty ? "Sarah" : profile.name,
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.notifications_outlined, color: AppColors.primary),
                  )
                ],
              ),
              const SizedBox(height: 4),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),

              // AI Recommendation Card
              _buildAiCard(),
              const SizedBox(height: 24),

              // SOS Floating Trigger Card
              _buildSosCard(),
              const SizedBox(height: 24),

              // Health Snapshot Card
              _buildHealthSnapshot(dueMedsCount),
              const SizedBox(height: 24),

              // Guardian / Safety Snapshot Card
              _buildSafetySnapshot(guardianState),
              const SizedBox(height: 24),

              // Wellness Snapshot Card
              _buildWellnessSnapshot(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- AI Contextual Card ---
  Widget _buildAiCard() {
    return Card(
      elevation: 0,
      color: AppColors.lavender,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const AssistantChatSheet(),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              const Text("✨", style: TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Assistant Tip",
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "\"You haven't completed today's hydration target. Tap to plan a safe route home?\"",
                      style: TextStyle(color: AppColors.primary, fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  // --- Emergency SOS Card ---
  Widget _buildSosCard() {
    return Card(
      elevation: 0,
      color: AppColors.emergency.withOpacity(0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.emergency, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Emergency Assistance", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emergency, fontSize: 15)),
                  SizedBox(height: 4),
                  Text("Tap and hold to broadcast your live GPS to your guardians and call helpers.", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onLongPress: () {
                ref.read(sosProvider.notifier).startCountdown();
              },
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.emergency,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x33EF4444), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                alignment: Alignment.center,
                child: const Text("SOS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Health Card ---
  Widget _buildHealthSnapshot(int dueMeds) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Health Snapshot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Text("Score: 82", style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Medication Info
            Row(
              children: [
                const Icon(Icons.medication_outlined, color: AppColors.primaryActive, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dueMeds == 0 ? "All medicines taken for today!" : "$dueMeds medicines remaining to take.",
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Water Log Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Water Intake", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text("$_waterCups / $_waterGoal cups logged", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _waterCups > 0 ? () => setState(() => _waterCups--) : null,
                      style: IconButton.styleFrom(backgroundColor: AppColors.lightGray),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _waterCups < 20 ? () => setState(() => _waterCups++) : null,
                      style: IconButton.styleFrom(backgroundColor: AppColors.lavender, foregroundColor: AppColors.primary),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- Safety Card ---
  Widget _buildSafetySnapshot(GuardianState state) {
    final isActive = state.status == GuardianStatus.active || state.status == GuardianStatus.deviationWarning;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Safety Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isActive ? Icons.navigation_rounded : Icons.verified_user_rounded,
                  color: isActive ? AppColors.warning : AppColors.success,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? "Active Journey Logged" : "You are currently secure",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive ? "Traveling: ${state.source} ➔ ${state.destination}" : "Guardian Mode is standby.",
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isActive) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("ETA: ${state.remainingMinutes} mins", style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      ref.read(currentTabProvider.notifier).state = 2; // Route to Safety module
                    },
                    child: const Text("View Route Map", style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              )
            ]
          ],
        ),
      ),
    );
  }

  // --- Wellness Card ---
  Widget _buildWellnessSnapshot() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Wellness Snapshot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text("😊", style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Text("Today's Mood: Feeling Good", style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                const Text("Sleep: 7.5 hrs", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Daily Tip", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                      SizedBox(height: 2),
                      Text("Take 5 minutes today to practice box breathing to help ground yourself.", style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const list = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    return list[month - 1];
  }
}
