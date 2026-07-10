import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:she_defends_app/core/services/notification_service.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';
import 'package:she_defends_app/features/home/home_screen.dart';
import 'package:she_defends_app/features/health/health_screen.dart';
import 'package:she_defends_app/features/safety/safety_screen.dart';
import 'package:she_defends_app/features/wellness/wellness_screen.dart';
import 'package:she_defends_app/features/profile/profile_screen.dart';
import 'package:she_defends_app/features/assistant/assistant_chat_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class DashboardWrapper extends ConsumerStatefulWidget {
  const DashboardWrapper({super.key});

  @override
  ConsumerState<DashboardWrapper> createState() => _DashboardWrapperState();
}

class _DashboardWrapperState extends ConsumerState<DashboardWrapper> {
  Timer? _systemTimer;
  int _sosElapsedSeconds = 0;
  Timer? _sosElapsedTimer;
  final _audioPlayer = AudioPlayer();

  String _calcDisplay = "0";
  final _apiClient = ApiClient();
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const HealthScreen(),
    const SafetyScreen(),
    const WellnessScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    _systemTimer?.cancel();
    _sosElapsedTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startSystemTimer() {
    _systemTimer?.cancel();
    _systemTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 1. SOS Countdown
      final sos = ref.read(sosProvider);
      if (sos.status == SosStatus.countingDown) {
        final stealth = ref.read(stealthProvider);
        if (stealth.isSilentSosEnabled) {
          // Trigger silently
          ref.read(sosProvider.notifier).triggerSos();
          _syncSosTriggerWithBackend();
          _startSosElapsedTimer();
        } else {
          ref.read(sosProvider.notifier).decrementCountdown();
        }
      }

      // 2. Fake Call Countdown
      final fakeCall = ref.read(fakeCallProvider);
      if (fakeCall.status == FakeCallStatus.scheduled) {
        ref.read(fakeCallProvider.notifier).decrementCountdown();
      }

      // Stop if neither is pending
      final isSosPending = ref.read(sosProvider).status == SosStatus.countingDown;
      final isFakeCallPending = ref.read(fakeCallProvider).status == FakeCallStatus.scheduled;
      if (!isSosPending && !isFakeCallPending) {
        timer.cancel();
      }
    });
  }

  void _startSosElapsedTimer() {
    _sosElapsedSeconds = 0;
    _sosElapsedTimer?.cancel();
    _sosElapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (ref.read(sosProvider).status == SosStatus.active) {
        setState(() => _sosElapsedSeconds++);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _syncSosTriggerWithBackend() async {
    final sos = ref.read(sosProvider);
    try {
      await _apiClient.post("/safety/sos/trigger", data: {
        "location": sos.location,
        "speed": sos.speed,
        "battery": sos.batteryPercentage,
        "phone": sos.phone,
        "message": sos.message,
      });
    } catch (e) {
      debugPrint("Failed to sync SOS with backend: $e");
    }
  }

  Future<void> _uploadMockAudioClip() async {
    final clipNum = ref.read(sosProvider).recordings.length + 1;
    final filename = "SOS_Record_Clip_#$clipNum.mp3";
    try {
      final res = await _apiClient.post("/safety/recordings", data: {
        "filename": filename,
        "duration": "0:30",
        "size": "120 KB",
      });
      if (res.data["recording"] != null) {
        ref.read(sosProvider.notifier).addMockRecording(filename, "0:30", "120 KB");
      }
    } catch (e) {
      debugPrint("Failed to sync recording with backend: $e");
    }
  }

  void _onCalcKeyPress(String key) {
    setState(() {
      if (key == "C") {
        _calcDisplay = "0";
      } else if (key == "=") {
        final pin = ref.read(stealthProvider).pin;
        if (_calcDisplay == pin) {
          ref.read(stealthProvider.notifier).unlockApp();
          _calcDisplay = "0";
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Decoy Decrypted. Welcome back Sarah!")),
          );
        } else {
          // Simple math expression evaluation simulation
          _calcDisplay = "42"; // Mock calculation answer
        }
      } else {
        if (_calcDisplay == "0" || _calcDisplay == "Error") {
          _calcDisplay = key;
        } else {
          _calcDisplay += key;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);
    final sosState = ref.watch(sosProvider);
    final guardianState = ref.watch(guardianProvider);
    final stealthState = ref.watch(stealthProvider);
    final fakeCallState = ref.watch(fakeCallProvider);

    Future<String> getCurrentLocation() async {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return "GPS Disabled";
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) return "Location Denied";
        }
        if (permission == LocationPermission.deniedForever) return "Location Denied Forever";
        Position position = await Geolocator.getCurrentPosition();
        return "${position.latitude},${position.longitude}";
      } catch(e) {
        return "Unknown";
      }
    }

    // Watch SOS state change to initiate timers & backend syncs
    ref.listen<SosState>(sosProvider, (previous, next) async {
      if (next.status == SosStatus.countingDown) {
        if (previous?.countdownSeconds != next.countdownSeconds) {
          HapticFeedback.vibrate();
          SystemSound.play(SystemSoundType.click);
        }
      }

      if (next.status == SosStatus.countingDown && previous?.status != SosStatus.countingDown) {
        _startSystemTimer();
      } else if (next.status == SosStatus.active && previous?.status != SosStatus.active) {
        _startSosElapsedTimer();

        // 1. Get real location
        String location = await getCurrentLocation();
        
        // 2. Play loud police siren
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/police_siren.ogg'));

        // 3. Send SMS to contacts
        final contacts = ref.read(emergencyContactsProvider);
        if (contacts.isNotEmpty) {
           List<String> phones = contacts.map((c) => c.phone).toList();
           String msg = "SOS! I may be in danger. My live location: https://maps.google.com/?q=$location Please help!";
           String uriStr = "sms:${phones.join(',')}?body=${Uri.encodeComponent(msg)}";
           if (await canLaunchUrl(Uri.parse(uriStr))) {
             await launchUrl(Uri.parse(uriStr));
           }
        }

        // update state with real location
        ref.read(sosProvider.notifier).state = ref.read(sosProvider).copyWith(location: location);
        _syncSosTriggerWithBackend();

        // Play loud alert notification sound
        NotificationService().showNotification(
          id: 999,
          title: "🚨 SOS EMERGENCY ACTIVE",
          body: "Emergency services and guardians are receiving your live GPS coordinate.",
        );

        // Vibrate the phone strongly
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 300), () => HapticFeedback.heavyImpact());
        Future.delayed(const Duration(milliseconds: 600), () => HapticFeedback.heavyImpact());
      } else if (next.status == SosStatus.idle && previous?.status == SosStatus.active) {
        _sosElapsedTimer?.cancel();
        await _audioPlayer.stop();
      }
    });

    // Watch Fake Call state change to start countdown timer
    ref.listen<FakeCallState>(fakeCallProvider, (previous, next) async {
      if (next.status == FakeCallStatus.scheduled && previous?.status != FakeCallStatus.scheduled) {
        _startSystemTimer();
      } else if (next.status == FakeCallStatus.ringing && previous?.status != FakeCallStatus.ringing) {
        // Play ringtone
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg'));
      } else if ((next.status == FakeCallStatus.active || next.status == FakeCallStatus.idle) && previous?.status == FakeCallStatus.ringing) {
        // Stop ringtone
        await _audioPlayer.stop();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. Core Selected Screen View
          _screens[currentTab],

          // 2. Calculator Decoy App Lock (Stealth Mode)
          if (stealthState.isCalculatorLockEnabled && stealthState.isAppLocked)
            _buildCalculatorDecoy(),

          // 3. Deviation check check-in popup (Guardian Mode warning)
          if (guardianState.status == GuardianStatus.deviationWarning && !stealthState.isAppLocked)
            _buildDeviationPopup(),

          // 4. Full Screen SOS Countdown Overlay
          if (sosState.status == SosStatus.countingDown && !stealthState.isSilentSosEnabled && !stealthState.isAppLocked)
            _buildSosCountdownOverlay(sosState.countdownSeconds),

          // 5. Full Screen SOS Active Alert Dashboard
          if (sosState.status == SosStatus.active && !stealthState.isSilentSosEnabled && !stealthState.isAppLocked)
            _buildSosActiveDashboard(sosState),

          // 6. Fake Call Overlay Ringing Screen
          if (fakeCallState.status == FakeCallStatus.ringing)
            _buildFakeCallRingingOverlay(fakeCallState),

          // 7. Fake Call Overlay Active Call Screen
          if (fakeCallState.status == FakeCallStatus.active)
            _buildFakeCallActiveOverlay(fakeCallState),
        ],
      ),
      bottomNavigationBar: (stealthState.isCalculatorLockEnabled && stealthState.isAppLocked)
          ? null
          : _buildBottomNavigationBar(currentTab),
      floatingActionButton: (sosState.status == SosStatus.idle && !(stealthState.isCalculatorLockEnabled && stealthState.isAppLocked))
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

  // --- Calculator decoy lock (Stealth Mode decoy) ---
  Widget _buildCalculatorDecoy() {
    final List<String> buttons = [
      "7", "8", "9", "/",
      "4", "5", "6", "*",
      "1", "2", "3", "-",
      "C", "0", "=", "+"
    ];

    return Container(
      color: const Color(0xFF17171C),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.calculate_outlined, color: Colors.white24),
              SizedBox(width: 8),
              Text("Decoy Mode", style: TextStyle(color: Colors.white24, fontSize: 13, letterSpacing: 1)),
            ],
          ),
          const Spacer(),
          // Display screen
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            alignment: Alignment.centerRight,
            child: Text(
              _calcDisplay,
              style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w300),
            ),
          ),
          const Divider(color: Colors.white12, height: 40),
          // Calculator keypad grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: buttons.length,
            itemBuilder: (context, index) {
              final btn = buttons[index];
              final isOperator = ["/", "*", "-", "+", "="].contains(btn);
              final isClear = btn == "C";

              return ElevatedButton(
                onPressed: () => _onCalcKeyPress(btn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOperator 
                      ? const Color(0xFFFF9F0A) 
                      : isClear 
                          ? const Color(0xFFA5A5A5) 
                          : const Color(0xFF333333),
                  foregroundColor: isClear ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  btn,
                  style: TextStyle(
                    fontSize: 26, 
                    fontWeight: FontWeight.bold,
                    color: isClear ? Colors.black : Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- Fake Call Overlay Ringing Screen ---
  Widget _buildFakeCallRingingOverlay(FakeCallState state) {
    return Container(
      color: const Color(0xFF0F0F1A),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          const CircleAvatar(
            radius: 56,
            backgroundColor: Color(0xFF1E293B),
            child: Icon(Icons.person, color: Colors.white70, size: 56),
          ),
          const SizedBox(height: 24),
          Text(
            state.callerName,
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Incoming call...",
            style: TextStyle(color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Decline Button
              Column(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(fakeCallProvider.notifier).endCall(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Decline", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              // Accept Button
              Column(
                children: [
                  GestureDetector(
                    onTap: () => ref.read(fakeCallProvider.notifier).acceptCall(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      child: const Icon(Icons.phone, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text("Accept", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- Fake Call Overlay Active Call Screen ---
  Widget _buildFakeCallActiveOverlay(FakeCallState state) {
    // Generate a simple timer from elapsed seconds
    final int minutes = _sosElapsedSeconds ~/ 60;
    final int seconds = _sosElapsedSeconds % 60;
    final timeStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    // Simple list of dialogue lines to show mock subtitles
    final List<String> dialogLines = [
      "Hello Sarah? I'm waiting outside the building.",
      "Just walk straight to the crowded junction, I see you.",
      "I will stay on the phone with you until you reach. Tell me when you pass the block.",
      "Are you close to the main street? Keep moving.",
      "Got it, keep talking so it's clear you're on a call."
    ];
    final dialogIndex = (_sosElapsedSeconds ~/ 4) % dialogLines.length;

    return Container(
      color: const Color(0xFF0F0F1A),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 60),
          Text(
            state.callerName,
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            timeStr,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
          const SizedBox(height: 60),
          
          // Subtitle box showing mock dialogue if active
          if (state.playConversation)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.record_voice_over, color: AppColors.success, size: 16),
                      SizedBox(width: 8),
                      Text("Simulated Conversation Subtitle", style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "\"${dialogLines[dialogIndex]}\"",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, fontStyle: FontStyle.italic, height: 1.4),
                  ),
                ],
              ),
            ),
          
          const Spacer(),
          // Call features mockup
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(icon: const Icon(Icons.mic_off, color: Colors.white54, size: 28), onPressed: () {}),
              IconButton(icon: const Icon(Icons.dialpad, color: Colors.white54, size: 28), onPressed: () {}),
              IconButton(icon: const Icon(Icons.volume_up, color: Colors.white54, size: 28), onPressed: () {}),
            ],
          ),
          const SizedBox(height: 48),
          // End call button
          GestureDetector(
            onTap: () => ref.read(fakeCallProvider.notifier).endCall(),
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.call_end, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- Active SOS Assistance Dashboard ---
  Widget _buildSosActiveDashboard(SosState state) {
    final int minutes = _sosElapsedSeconds ~/ 60;
    final int seconds = _sosElapsedSeconds % 60;
    final durationStr = "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

    return Container(
      color: Colors.white,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lens, color: AppColors.emergency, size: 10),
                      SizedBox(width: 8),
                      Text("EMERGENCY BROADCAST ACTIVE", style: TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.emergency.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(durationStr, style: const TextStyle(color: AppColors.emergency, fontWeight: FontWeight.bold, fontSize: 13)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              
              // Interactive Mock Map
              Card(
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  height: 180,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: MapRoutePainter(routeType: 'safe'),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                          child: Text("Speed: ${state.speed} mph", style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                          child: Text("Battery: ${state.batteryPercentage}%", style: const TextStyle(color: Colors.white, fontSize: 11)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tracking Link links
              Card(
                color: AppColors.lightGray,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.share, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Live Broadcast URL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              "https://shedefends.org/track/sarah_live?pin=8812",
                              style: TextStyle(color: Colors.blue.shade800, fontSize: 11, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Ambient voice recorder simulation
              const Text("Ambient Voice Recorder", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              const Text("Mic Active (Secure Storage Enabled)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _uploadMockAudioClip,
                            icon: const Icon(Icons.upload_file, size: 14),
                            label: const Text("Stash Clip", style: TextStyle(fontSize: 10)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              backgroundColor: AppColors.primaryActive,
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      // simulated sound waveform graphics
                      SizedBox(
                        height: 30,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(24, (index) {
                            // animated bounce height simulator using index offset
                            final h = 6 + (16 * (1 + (index % 4 == 0 ? 0.8 : (index % 2 == 0 ? 0.3 : -0.2))));
                            return Container(
                              width: 3,
                              height: h,
                              decoration: BoxDecoration(color: AppColors.emergency.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(2)),
                            );
                          }),
                        ),
                      ),
                      
                      // Audio clips list from state
                      if (state.recordings.isNotEmpty) ...[
                        const Divider(height: 24),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.recordings.length,
                          itemBuilder: (context, index) {
                            final rec = state.recordings[index];
                            return ListTile(
                              leading: const Icon(Icons.audiotrack, color: AppColors.primary, size: 20),
                              title: Text(rec.filename, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: Text("Size: ${rec.size} • Duration: ${rec.duration}"),
                              trailing: IconButton(
                                icon: const Icon(Icons.play_circle_outline, color: AppColors.success, size: 22),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Playing simulated clip: ${rec.filename}")),
                                  );
                                },
                              ),
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            );
                          },
                        )
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Notified contacts verification checklists
              const Text("Guardian Alerts Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: state.contactsNotified.map((contact) {
                    return ListTile(
                      leading: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      trailing: Text(contact.status, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      dense: true,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // SOS Stop controls
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(sosProvider.notifier).cancelSos();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Emergency mode deactivated. Safety broadcast stopped.")),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  child: const Text("I am Safe – Terminate SOS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SOS Countdown Overlay ---
  Widget _buildSosCountdownOverlay(int seconds) {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.95),
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 10),
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

  // --- Bottom Navigation Bar with pill design ---
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
                        ref.read(guardianProvider.notifier).reset();
                        ref.read(sosProvider.notifier).startCountdown();
                      },
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.emergency)),
                      child: const Text("Need Help", style: TextStyle(color: AppColors.emergency)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
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
