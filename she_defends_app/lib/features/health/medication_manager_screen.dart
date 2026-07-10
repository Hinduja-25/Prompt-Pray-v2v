import 'package:flutter/material.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Schedule & Refills Screen (Screenshot 3)
// ---------------------------------------------------------------------------

class ScheduleRefillsScreen extends StatelessWidget {
  const ScheduleRefillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Schedule & Refills',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Calendar Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "October 2023",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Track your daily adherence",
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _buildArrowButton(Icons.chevron_left),
                          const SizedBox(width: 8),
                          _buildArrowButton(Icons.chevron_right),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Weekday headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      _DayHeader("MON"), _DayHeader("TUE"), _DayHeader("WED"),
                      _DayHeader("THU"), _DayHeader("FRI"), _DayHeader("SAT"), _DayHeader("SUN"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mock Calendar Grid
                  _buildCalendarGrid(),
                  const SizedBox(height: 20),
                  // Legend
                  Row(
                    children: [
                      _buildLegendItem(Colors.blue, "Completed"),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.red, "Missed"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Monthly Adherence Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D0C57), Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D0C57).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "MONTHLY ADHERENCE",
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      Icon(Icons.trending_up, color: Colors.white, size: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text(
                        "94%",
                        style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Text(
                          "+2% from last month",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: const LinearProgressIndicator(
                      value: 0.94,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
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

  Widget _buildArrowButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 20),
        onPressed: () {},
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCalendarGrid() {
    // Generate simple rows of October
    final List<List<int?>> rows = [
      [null, null, null, null, null, 1, 2],
      [3, 4, 5, 6, 7, 8, 9],
      [10, 11, 12, 13, 14, 15, 16],
      [17, 18, 19, 20, 21, 22, 23],
      [24, 25, 26, 27, 28, 29, 30],
      [31, null, null, null, null, null, null],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((day) {
              if (day == null) {
                return const SizedBox(width: 32, height: 32);
              }
              final isSelected = day == 24;
              // Mock dots: Completed (blue) or Missed (red)
              final hasCompletedDot = day % 3 == 0 || day == 24;
              final hasMissedDot = day % 5 == 0 && day != 24;

              return Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "$day",
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textDark,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (hasCompletedDot)
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                        if (hasMissedDot)
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String day;
  const _DayHeader(this.day);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      child: Text(
        day,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Medication Sheet (Screenshot 2)
// ---------------------------------------------------------------------------

class AddMedicationSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  const AddMedicationSheet({super.key, required this.onAdd});

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String _frequency = "Daily";
  final List<String> _times = ["08:00 AM"];
  bool _remindersEnabled = true;
  final _notesCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.primary),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  "Add Medication",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 48), // Spacer
            ],
          ),
          const SizedBox(height: 16),
          // Health Sanctuary Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "HEALTH SANCTUARY",
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1),
                ),
                SizedBox(height: 6),
                Text(
                  "Maintain your wellness routine with precision and care.",
                  style: TextStyle(color: AppColors.primaryActive, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Name field
          _buildLabel("Medicine Name"),
          const SizedBox(height: 8),
          _buildTextField(_nameCtrl, "e.g. Vitamin D3"),
          const SizedBox(height: 20),
          // Dosage field
          _buildLabel("Dosage"),
          const SizedBox(height: 8),
          _buildTextField(_dosageCtrl, "e.g. 1000 IU or 1 Tablet"),
          const SizedBox(height: 20),
          // Frequency dropdown
          _buildLabel("Frequency"),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _frequency,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF3F4F6),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: "Daily", child: Text("Daily")),
              DropdownMenuItem(value: "Weekly", child: Text("Weekly")),
              DropdownMenuItem(value: "As Needed", child: Text("As Needed")),
            ],
            onChanged: (val) => setState(() => _frequency = val ?? "Daily"),
          ),
          const SizedBox(height: 20),
          // Reminder Times
          _buildLabel("Reminder Times"),
          const SizedBox(height: 8),
          Row(
            children: [
              ..._times.map((t) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(t, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => setState(() => _times.remove(t)),
                          child: const Icon(Icons.close, size: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                  )),
              GestureDetector(
                onTap: () => _showTimePicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.add, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text("Add Time", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Reminder Notifications Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Reminder Notifications", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Get a push notification for each dose.", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
              Switch(
                value: _remindersEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: (val) => setState(() => _remindersEnabled = val),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Notes
          _buildLabel("Notes (Optional)"),
          const SizedBox(height: 8),
          _buildTextField(_notesCtrl, "Take with food, avoid caffeine..."),
          const SizedBox(height: 28),
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_nameCtrl.text.isEmpty) return;
                widget.onAdd({
                  "name": _nameCtrl.text,
                  "dosage": _dosageCtrl.text,
                  "frequency": _frequency,
                  "times": _times,
                  "notes": _notesCtrl.text,
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text("Save Medication", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark));
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  void _showTimePicker() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) {
      final period = t.period == DayPeriod.am ? "AM" : "PM";
      final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
      final min = t.minute.toString().padLeft(2, '0');
      setState(() {
        _times.add("$hour:$min $period");
      });
    }
  }
}
