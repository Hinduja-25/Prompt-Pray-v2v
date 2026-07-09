import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/features/home/home_screen.dart';
import 'package:she_defends_app/features/health/health_screen.dart';
import 'package:she_defends_app/features/safety/safety_screen.dart';
import 'package:she_defends_app/features/wellness/wellness_screen.dart';
import 'package:she_defends_app/features/profile/profile_screen.dart';
import 'package:she_defends_app/features/assistant/assistant_chat_sheet.dart';

class DashboardWrapper extends ConsumerStatefulWidget {
  const DashboardWrapper({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends ConsumerState<DashboardWrapper> {
  Timer? _sosTimer;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HealthScreen(),
    const SafetyScreen(),
    const WellnessScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  void _startSosTimer() {
    _sosTimer?.cancel();
    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final sos = ref.read(sosProvider);
      if (sos.status == SosStatus.countingDown) {
        ref.read(sosProvider.notifier).decrementCountdown();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final sosState = ref.watch(sosProvider);
    final guardianState = ref.watch(guardianProvider);

    // Watch SOS state to manage timer
    ref.listen<SosState>(sosProvider, (previous, next) {
      if (next.status == SosStatus.countingDown && previous?.status != SosStatus.countingDown) {
        _startSosTimer();
      } else if (next.status == SosStatus.idle) {
        _sosTimer?.cancel();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Current Selected Screen View
          _screens[currentTab],

          // Deviation check pop-up overlay (Guardian Mode check-in)
          if (guardianState.status == GuardianStatus.deviationWarning)
            _buildDeviationPopup(),

          // Full Screen SOS Countdown Overlay
          if (sosState.status == SosStatus.countingDown)
            _buildSosCountdownOverlay(sosState.countdownSeconds),

          // Full Screen SOS Active Alert Screen
          if (sosState.status == SosStatus.active)
            _buildSosActiveOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(currentTab),
      floatingActionButton: sosState.status == SosStatus.idle
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AssistantChatSheet(),
                );
              },
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.assistant, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  // --- Bottom Navigation Bar with pill highlight active design ---
  Widget _buildBottomNavigationBar(int activeIndex) {
    final List<Map<String, dynamic>> items = [
      {"icon": Icons.home_outlined, "activeIcon": Icons.home, "label": "Home"},
      {"icon": Icons.medical_services_outlined, "activeIcon": Icons.medical_services, "label": "Health"},
      {"icon": Icons.shield_outlined, "activeIcon": Icons.shield, "label": "Safety"},
      {"icon": Icons.spa_outlined, "activeIcon": Icons.spa, "label": "Wellness"},
      {"icon": Icons.person_outline, "activeIcon": Icons.person, "label": "Profile"},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final isActive = index == activeIndex;
            final item = items[index];

            if (isActive) {
              // Active pill highlighted item
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(item["activeIcon"] as IconData, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      item["label"] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        fontFamily: 'Outfit',
                      ),
                    )
                  ],
                ),
              );
            } else {
              // Inactive item
              return InkWell(
                onTap: () => ref.read(currentTabProvider.notifier).state = index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Icon(item["icon"] as IconData, color: AppColors.textMuted, size: 22),
                ),
              );
            }
          }),
        ),
      ),
    );
  }

  // --- SOS Timer Screen ---
  Widget _buildSosCountdownOverlay(int seconds) {
    return Container(
      color: AppColors.primary.withOpacity(0.95),
      width: double.infinity,
      height: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "ALERTING GUARDIANS IN",
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 40),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 10),
            ),
            alignment: Alignment.center,
            child: Text(
              "$seconds",
              style: const TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 60),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Your location and a distress alert are ready to be sent to your Emergency contacts.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          const SizedBox(height: 60),
          OutlinedButton(
            onPressed: () {
              ref.read(sosProvider.notifier).cancelSos();
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text(
              "CANCEL ALERT",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // --- Active SOS Assistance Dashboard ---
  Widget _buildSosActiveOverlay() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(28.0),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 80),
            const SizedBox(height: 20),
            const Text(
              "SOS Mode Active",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.emergency.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Text(
                "HELP ALERT SENT",
                style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "Emergency contacts have been messaged with your live location. Your tracking details are broadcasting securely.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 48),
            Card(
              elevation: 0,
              color: AppColors.lightGray,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text("QUICK EMERGENCY SERVICES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.local_police, color: AppColors.primary),
                      title: const Text("Call Police (911)", style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.phone, color: AppColors.success),
                      onTap: () {},
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.local_hospital, color: AppColors.primary),
                      title: const Text("Call Ambulance", style: TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.phone, color: AppColors.success),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(sosProvider.notifier).cancelSos();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                child: const Text("I am Safe – Reset"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Deviation Warning Popup ---
  Widget _buildDeviationPopup() {
    return Container(
      color: Colors.black54,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning, color: AppColors.warning, size: 50),
              const SizedBox(height: 16),
              const Text(
                "Are you safe?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 12),
              const Text(
                "Guardian Mode detected an unexpected stop or route deviation. Please check-in.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Escalates immediately to SOS
                        ref.read(guardianProvider.notifier).reset();
                        ref.read(sosProvider.notifier).triggerSos();
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.emergency)),
                      child: const Text("Need Help", style: TextStyle(color: AppColors.emergency)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Re-verify safeness
                        ref.read(guardianProvider.notifier).resolveDeviation();
                      },
                      child: const Text("I'm Safe"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
