import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';

class WellnessScreen extends ConsumerStatefulWidget {
  const WellnessScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _journalController = TextEditingController();
  
  String _selectedMood = 'Neutral';
  bool _isSavingJournal = false;
  
  List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _recurringThemes = [
    {
      "label": "Work Stress",
      "status": "3 entries",
      "summary": "\"You've mentioned tight deadlines and evening emails three times this week.\""
    },
    {
      "label": "Better Sleep",
      "status": "Improved",
      "summary": "\"Your entries suggest a correlation between meditation and falling asleep faster.\""
    }
  ];

  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _journalController.dispose();
    super.dispose();
  }

  Future<void> _logMood(String mood) async {
    setState(() => _selectedMood = mood);
    try {
      await _apiClient.post("/wellness/mood", data: {"mood": mood});
    } catch (e) {
      debugPrint("Mood log sync failed: $e");
    }
  }

  Future<void> _saveJournalEntry() async {
    final txt = _journalController.text.trim();
    if (txt.isEmpty) return;

    setState(() => _isSavingJournal = true);
    try {
      final response = await _apiClient.post("/wellness/journal", data: {"content": txt});
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _journalEntries.insert(0, {
            "content": txt,
            "timestamp": data["timestamp"],
            "themes": data["themes"]
          });
          
          final extractedThemes = data["themes"] as List? ?? [];
          if (extractedThemes.isNotEmpty) {
            _recurringThemes = extractedThemes.cast<Map<String, dynamic>>();
          }
          _journalController.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Journal entry saved successfully")),
        );
      }
    } catch (e) {
      debugPrint("Journal entry sync failed: $e");
    } finally {
      setState(() => _isSavingJournal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Wellness Sanctuary", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Mood"),
            Tab(text: "Journal"),
            Tab(text: "Library"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMoodTab(),
          _buildJournalTab(),
          _buildLibraryTab(),
        ],
      ),
    );
  }

  // --- Mood Tab UI (Screenshot 3) ---
  Widget _buildMoodTab() {
    final moods = [
      {"icon": "😊", "label": "Happy"},
      {"icon": "😐", "label": "Neutral"},
      {"icon": "😔", "label": "Sad"},
      {"icon": "😰", "label": "Anxious"},
      {"icon": "😠", "label": "Angry"}
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How are you feeling, Sarah?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          const Text("Your sanctuary for peace and stability today.", style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          
          // Mood Buttons
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: moods.map((m) {
                  final label = m["label"]!;
                  final icon = m["icon"]!;
                  final isSel = label == _selectedMood;

                  return GestureDetector(
                    onTap: () => _logMood(label),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.lavender : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Column(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 32)),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSel ? AppColors.primaryActive : AppColors.textMuted,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mood History Graph using CustomPainter for high-fidelity aesthetics
          const Text("Mood History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Past 7 Days", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text("Average: Stable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryActive)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: MoodHistoryPainter(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Mon", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text("Tue", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text("Wed", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text("Thu", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text("Fri", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text("Sat", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      Text("Sun", style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Daily tip widget
          Card(
            color: AppColors.lavender.withOpacity(0.3),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.lavender)),
            child: const Padding(
              padding: EdgeInsets.all(20.0),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.lavender,
                  child: Icon(Icons.self_improvement, color: AppColors.primary),
                ),
                title: Text("Guided Meditation", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Join a 10-minute \"Instant Calm\" breathing exercise."),
                trailing: Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- Journal Tab UI (Screenshot 1) ---
  Widget _buildJournalTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Text("🧘", style: TextStyle(fontSize: 24)),
                  SizedBox(width: 12),
                  Text("Today's Mood: Feeling Calm", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text("How was your day?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          
          TextField(
            controller: _journalController,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: "Start typing your thoughts here...",
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSavingJournal ? null : _saveJournalEntry,
              child: Text(_isSavingJournal ? "Saving..." : "Save Entry"),
            ),
          ),
          const SizedBox(height: 28),

          // Recurring themes generated by backend Gemini API
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: AppColors.primaryActive, size: 20),
              SizedBox(width: 8),
              Text("Recurring Themes (AI-extracted)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          ..._recurringThemes.map((theme) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
                        child: Text(theme["label"]!, style: const TextStyle(color: AppColors.primaryActive, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      Text(theme["status"]!, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(theme["summary"]!, style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  // --- Wellness tips library UI (Screenshot 2) ---
  Widget _buildLibraryTab() {
    final categories = ["All", "Hydration", "Sleep", "Exercise", "Nutrition"];
    final tips = [
      {"title": "The Power of 5-Minute Mindfulness", "cat": "Mental Health", "time": "3 min read", "body": "Learn how a short midday pause reset can restore productivity."},
      {"title": "Morning Hydration Routine", "cat": "Hydration", "time": "2 min read", "body": "Drinking 500ml water with sea salt upon waking wakes up metabolism."},
      {"title": "The 4-7-8 Breathing Technique", "cat": "Sleep", "time": "4 min read", "body": "Fall asleep faster by regulating your nervous system with this count."},
      {"title": "Smart Snacking for Energy", "cat": "Nutrition", "time": "3 min read", "body": "Pair complex carbs with healthy fats to avoid afternoon crashes."}
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search box
          const TextField(
            decoration: InputDecoration(
              hintText: "Search wellness tips...",
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          
          // Chips
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final isFirst = index == 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(categories[index]),
                    selected: isFirst,
                    selectedColor: AppColors.primary,
                    disabledColor: AppColors.lightGray,
                    labelStyle: TextStyle(
                      color: isFirst ? Colors.white : AppColors.textDark,
                      fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          const Text("Daily Focus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 12),
          
          // Feature card
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryActive],
                )
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("MENTAL HEALTH", style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.bold, fontSize: 11)),
                  SizedBox(height: 8),
                  Text("The Power of 5-Minute Mindfulness", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                  SizedBox(height: 6),
                  Text("Reset your nervous system and increase daily workspace productivity.", style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 12),
          ...tips.map((tip) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(tip["title"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${tip["cat"]} • ${tip["time"]}\n${tip["body"]}"),
              isThreeLine: true,
              trailing: const Icon(Icons.bookmark_border, color: AppColors.textMuted),
            ),
          )),
        ],
      ),
    );
  }
}

// Simple path painter to draw high-fidelity line chart
class MoodHistoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryActive
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.lavender.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.15, size.height * 0.4);
    path.lineTo(size.width * 0.30, size.height * 0.45);
    path.lineTo(size.width * 0.45, size.height * 0.35);
    path.lineTo(size.width * 0.60, size.height * 0.55);
    path.lineTo(size.width * 0.75, size.height * 0.8);
    path.lineTo(size.width, size.height * 0.3);

    // Gradient fill below path
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots at points
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(0, size.height * 0.7), 4, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.45, size.height * 0.35), 4, dotPaint);
    canvas.drawCircle(Offset(size.width, size.height * 0.3), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
