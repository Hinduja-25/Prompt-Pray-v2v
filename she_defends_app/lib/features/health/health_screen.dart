import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/features/health/symptom_checker_screen.dart';
import 'package:she_defends_app/features/health/health_history_screen.dart';
import 'package:she_defends_app/features/health/medication_manager_screen.dart';
import 'package:she_defends_app/core/services/notification_service.dart';
// ScheduleRefillsScreen and AddMedicationSheet are exported from medication_manager_screen.dart

import 'package:she_defends_app/core/network/api_client.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  DateTime _selectedMonthDate = DateTime.now();
  int _selectedCalendarDate = DateTime.now().day;
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _medications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    try {
      final res = await _apiClient.get("/health/medications");
      if (res.data is List) {
        setState(() {
          _medications = List<Map<String, dynamic>>.from(res.data);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncMedications() async {
    try {
      await _apiClient.post("/health/medications/sync", data: _medications);
    } catch (e) {
      debugPrint("Failed to sync medications: $e");
    }
  }

  String _getMonthName(int month) {
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return months[month - 1];
  }

  void _addMedication(Map<String, dynamic> med) {
    setState(() {
      _medications.add({
        "name": med["name"],
        "dosage": med["dosage"],
        "time": med["times"].isNotEmpty ? med["times"].first : "08:00 AM",
        "taken": false,
        "type": "pill",
      });
    });
    _syncMedications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
        title: const Text(
          'SheDefends',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          // Extra shortcut actions for other Health sub-modules
          IconButton(
            icon: const Icon(Icons.healing_outlined, color: AppColors.primary),
            tooltip: "Symptom Checker",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SymptomCheckerScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.primary),
            tooltip: "Health History",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HealthHistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with "August" picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Medications",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Stay on track with your health\nsanctuary.",
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.3),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedMonthDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedMonthDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F0FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.lavender),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _getMonthName(_selectedMonthDate.month),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Horizontal calendar
            _buildHorizontalCalendar(),
            const SizedBox(height: 20),

            // Next Dose banner
            _buildNextDoseBanner(),
            const SizedBox(height: 24),

            // Morning section
            Row(
              children: const [
                Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 18),
                SizedBox(width: 6),
                Text(
                  "Today's Schedule",
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Medications List
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_medications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No medications scheduled today.", style: TextStyle(color: AppColors.textMuted)),
              )
            else
              ..._medications.map((med) => _buildMedCard(med)),

            const SizedBox(height: 24),
            // Button to open Add Medication Screen
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    maxChildSize: 0.95,
                    minChildSize: 0.7,
                    builder: (_, scrollController) => AddMedicationSheet(
                      onAdd: _addMedication,
                    ),
                  ),
                ),
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text(
                  "Add New Medication",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.lavender, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalCalendar() {
    final List<Map<String, dynamic>> days = [
      {"day": "M", "date": 14},
      {"day": "T", "date": 15},
      {"day": "W", "date": 16},
      {"day": "T", "date": 17},
      {"day": "F", "date": 18},
      {"day": "S", "date": 19},
      {"day": "S", "date": 20},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final date = d["date"] as int;
        final isSel = date == _selectedCalendarDate;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCalendarDate = date;
            });
          },
          child: Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? Colors.transparent : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSel ? AppColors.primary : const Color(0xFFE5E7EB),
                width: isSel ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  d["day"],
                  style: TextStyle(
                    color: isSel ? AppColors.primary : AppColors.textMuted,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$date",
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNextDoseBanner() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2D0C57), Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "NEXT DOSE IN",
                style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              SizedBox(height: 6),
              Text(
                "Upcoming",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                "Schedule your next reminder",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          GestureDetector(
            onTap: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                final now = DateTime.now();
                var scheduledTime = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
                if (scheduledTime.isBefore(now)) {
                  scheduledTime = scheduledTime.add(const Duration(days: 1));
                }

                await NotificationService().scheduleMedicationReminder(
                  id: 101,
                  title: "💊 Medication Alarm",
                  body: "Time to take your scheduled dose: Multivitamin!",
                  scheduledTime: scheduledTime,
                );
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Medication alarm scheduled for ${pickedTime.format(context)}"),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedCard(Map<String, dynamic> med) {
    final isTaken = med["taken"] ?? false;
    final isPill = med["type"] == "pill";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isPill ? Icons.adjust : Icons.opacity,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med["name"],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  "${med["dosage"]} • ${med["time"]}",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                med["taken"] = !isTaken;
              });
              _syncMedications();
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isTaken ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTaken ? AppColors.primary : const Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
              child: Icon(
                isTaken ? Icons.check : Icons.add,
                color: isTaken ? Colors.white : AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
