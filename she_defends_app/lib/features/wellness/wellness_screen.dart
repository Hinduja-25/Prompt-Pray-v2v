import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';
import 'package:she_defends_app/core/providers/app_state.dart';

class WellnessScreen extends ConsumerStatefulWidget {
  const WellnessScreen({super.key});

  @override
  ConsumerState<WellnessScreen> createState() => _WellnessScreenState();
}

class _WellnessScreenState extends ConsumerState<WellnessScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _journalController = TextEditingController();

  String _selectedMood = 'Neutral';
  bool _isSavingJournal = false;
  bool _isLoadingJournals = true;

  final List<Map<String, dynamic>> _journalEntries = [];
  List<Map<String, dynamic>> _recurringThemes = [];

  // Library tab state
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final _apiClient = ApiClient();

  final List<Map<String, dynamic>> _allTips = [
    {"title": "The Power of 5-Minute Mindfulness", "cat": "Mental Health", "time": "3 min read", "body": "Learn how a short midday pause reset can restore productivity and reduce anxiety."},
    {"title": "Morning Hydration Routine", "cat": "Hydration", "time": "2 min read", "body": "Drinking 500ml water with sea salt upon waking activates your metabolism."},
    {"title": "The 4-7-8 Breathing Technique", "cat": "Sleep", "time": "4 min read", "body": "Fall asleep faster by regulating your nervous system with this counted breathing method."},
    {"title": "Smart Snacking for Energy", "cat": "Nutrition", "time": "3 min read", "body": "Pair complex carbs with healthy fats to avoid afternoon energy crashes."},
    {"title": "10-Minute Evening Walk Benefits", "cat": "Exercise", "time": "3 min read", "body": "A gentle post-dinner walk improves digestion and prepares your body for quality sleep."},
    {"title": "Optimal Sleep Hydration", "cat": "Hydration", "time": "2 min read", "body": "Stay hydrated before bed but avoid large amounts — balance is key for deep sleep cycles."},
    {"title": "Progressive Muscle Relaxation", "cat": "Sleep", "time": "5 min read", "body": "Tense and release muscle groups systematically to melt physical tension before sleep."},
    {"title": "The Power of 30-Minute Walks", "cat": "Exercise", "time": "4 min read", "body": "Daily walks are proven to reduce depression symptoms and boost creative thinking."},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadJournals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _journalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadJournals() async {
    try {
      final res = await _apiClient.get("/wellness/journals");
      if (res.data is List) {
        setState(() {
          _journalEntries.clear();
          _journalEntries.addAll(List<Map<String, dynamic>>.from(res.data));
        });

        // Build recurring themes from loaded entries
        final themes = <String, int>{};
        for (final entry in _journalEntries) {
          final entryThemes = entry["themes"] as List? ?? [];
          for (final t in entryThemes) {
            if (t is Map) {
              final label = t["label"]?.toString() ?? "";
              if (label.isNotEmpty) themes[label] = (themes[label] ?? 0) + 1;
            }
          }
        }
        if (themes.isNotEmpty) {
          setState(() {
            _recurringThemes = themes.entries
                .map((e) => {"label": e.key, "status": "${e.value} entries", "summary": "Mentioned ${e.value} time(s) in your journals."})
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Failed to load journals: $e");
    } finally {
      setState(() => _isLoadingJournals = false);
    }
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
        final newEntry = {
          "content": txt,
          "timestamp": data["timestamp"] ?? DateTime.now().toIso8601String(),
          "themes": data["themes"] ?? []
        };
        setState(() {
          _journalEntries.insert(0, newEntry);

          // Rebuild themes from new entry
          final entryThemes = (data["themes"] as List? ?? []);
          if (entryThemes.isNotEmpty) {
            final freshThemes = entryThemes.map((t) {
              if (t is Map) {
                return {"label": t["label"]?.toString() ?? "Theme", "status": "New", "summary": t["summary"]?.toString() ?? ""};
              }
              return {"label": t.toString(), "status": "New", "summary": ""};
            }).toList();
            _recurringThemes = List<Map<String, dynamic>>.from(freshThemes);
          }
          _journalController.clear();
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Journal entry saved successfully ✅")),
        );
      }
    } catch (e) {
      debugPrint("Journal entry sync failed: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save journal. Please try again.")),
      );
    } finally {
      setState(() => _isSavingJournal = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final firstName = userProfile.name.isNotEmpty
        ? userProfile.name.split(' ').first
        : 'there';

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
          _buildMoodTab(firstName),
          _buildJournalTab(firstName),
          _buildLibraryTab(),
        ],
      ),
    );
  }

  Widget _buildMoodTab(String firstName) {
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
          Text(
            "How are you feeling, $firstName?",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          const Text("Your sanctuary for peace and stability today.", style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
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
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.lavender : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(icon, style: const TextStyle(fontSize: 32)),
                        ),
                        const SizedBox(height: 8),
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
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text("Mood History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Past 7 Days", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      Text("Average: Stable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryActive)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 120,
                    width: double.infinity,
                    child: CustomPaint(painter: MoodHistoryPainter()),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
          Card(
            color: AppColors.lavender.withValues(alpha: 0.3),
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

  Widget _buildJournalTab(String firstName) {
    final moodEmoji = {
      'Happy': '😊', 'Neutral': '🧘', 'Sad': '😔', 'Anxious': '😰', 'Angry': '😠'
    }[_selectedMood] ?? '🧘';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(moodEmoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Text("Today's Mood: $_selectedMood", style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text("How was your day, $firstName?", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 12),
          TextField(
            controller: _journalController,
            maxLines: 6,
            decoration: const InputDecoration(hintText: "Start typing your thoughts here..."),
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
          if (_recurringThemes.isNotEmpty) ...[
            const Row(
              children: [
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
                          child: Text(theme["label"]?.toString() ?? "", style: const TextStyle(color: AppColors.primaryActive, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        Text(theme["status"]?.toString() ?? "", style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(theme["summary"]?.toString() ?? "", style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 24),
          ],
          const Text("Past Entries", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 12),
          if (_isLoadingJournals)
            const Center(child: CircularProgressIndicator())
          else if (_journalEntries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text("No journal entries yet. Write your first one above!", style: TextStyle(color: AppColors.textMuted)),
            )
          else
            ..._journalEntries.map((entry) {
              final content = entry["content"]?.toString() ?? "";
              final timestamp = entry["timestamp"]?.toString() ?? "";
              String dateStr = "";
              try {
                final dt = DateTime.parse(timestamp).toLocal();
                dateStr = "${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
              } catch (_) {
                dateStr = timestamp;
              }
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateStr, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(height: 8),
                      Text(
                        content.length > 200 ? "${content.substring(0, 200)}..." : content,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() {
    final categories = ["All", "Mental Health", "Hydration", "Sleep", "Exercise", "Nutrition"];
    final filteredTips = _allTips.where((tip) {
      final matchesCat = _selectedCategory == 'All' || tip["cat"] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          tip["title"]!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          tip["body"]!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: "Search wellness tips...",
              prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    disabledColor: AppColors.lightGray,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text("Daily Focus", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryActive]),
              ),
              padding: const EdgeInsets.all(20),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Articles (${filteredTips.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
              if (_selectedCategory != 'All' || _searchQuery.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _selectedCategory = 'All';
                    _searchQuery = '';
                    _searchController.clear();
                  }),
                  child: const Text("Clear filters"),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (filteredTips.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text("No tips found for this filter.", style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ...filteredTips.map((tip) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(tip["title"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(8)),
                            child: Text(tip["cat"]!, style: const TextStyle(color: AppColors.primaryActive, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text(tip["time"]!, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(tip["body"]!, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ],
                  ),
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.bookmark_border, color: AppColors.textMuted),
              ),
            )),
        ],
      ),
    );
  }
}

class MoodHistoryPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryActive
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppColors.lavender.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width * 0.15, size.height * 0.4);
    path.lineTo(size.width * 0.30, size.height * 0.45);
    path.lineTo(size.width * 0.45, size.height * 0.35);
    path.lineTo(size.width * 0.60, size.height * 0.55);
    path.lineTo(size.width * 0.75, size.height * 0.8);
    path.lineTo(size.width, size.height * 0.3);

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

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
