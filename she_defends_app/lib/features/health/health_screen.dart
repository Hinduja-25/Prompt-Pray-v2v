import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/providers/app_state.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _symptomController = TextEditingController();
  
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  final List<Map<String, dynamic>> _historyLogs = [];
  
  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _symptomController.dispose();
    super.dispose();
  }

  Future<void> _runSymptomAnalysis() async {
    final txt = _symptomController.text.trim();
    if (txt.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      final response = await _apiClient.post("/health/analyze", data: {"symptoms": txt});
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        setState(() {
          _analysisResult = data["analysis"];
          _historyLogs.insert(0, {
            "symptoms": txt,
            "timestamp": data["timestamp"],
            "urgency": _analysisResult?["urgency_level"] ?? "Low"
          });
        });
      }
    } catch (e) {
      debugPrint("Symptom analyzer API failed: $e");
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  void _showAddMedicationDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Medication"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "Medicine Name")),
            const SizedBox(height: 12),
            TextField(controller: dosageController, decoration: const InputDecoration(hintText: "Dosage (e.g. 1 pill)")),
            const SizedBox(height: 12),
            TextField(controller: timeController, decoration: const InputDecoration(hintText: "Reminder Time (e.g. 08:00 AM)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(medicationProvider.notifier).addMedication(
                  Medication(
                    name: nameController.text.trim(),
                    dosage: dosageController.text.trim(),
                    time: timeController.text.trim(),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Health Record", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: "Symptom Checker"),
            Tab(text: "Medication"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSymptomCheckerTab(),
          _buildMedicationTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // --- Symptom Checker Tab UI ---
  Widget _buildSymptomCheckerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Describe how you're feeling...", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
          const SizedBox(height: 16),
          
          // Symptom query box
          TextField(
            controller: _symptomController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "e.g., I have a headache, slight fever, and feel nauseous...",
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _runSymptomAnalysis,
              icon: const Icon(Icons.auto_awesome),
              label: Text(_isAnalyzing ? "Analyzing symptoms..." : "Analyze Symptoms"),
            ),
          ),
          const SizedBox(height: 28),

          // Diagnostic AI results UI matching Screenshot 4
          if (_isAnalyzing)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_analysisResult != null) ...[
            _buildAnalysisResultCard(),
            const SizedBox(height: 24),
            _buildVitalsSubcards(),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalysisResultCard() {
    final listConditions = (_analysisResult?["possible_conditions"] as List? ?? []).cast<String>();
    final listSuggestions = (_analysisResult?["suggestions"] as List? ?? []).cast<String>();
    final listWarnings = (_analysisResult?["warning_signs"] as List? ?? []).cast<String>();
    final urgency = _analysisResult?["urgency_level"] ?? "Low";
    
    Color urgencyColor = AppColors.success;
    if (urgency == "Medium") urgencyColor = AppColors.warning;
    if (urgency == "High") urgencyColor = AppColors.emergency;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.lavender, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    listConditions.isNotEmpty ? "Possible ${listConditions[0]}" : "Assessment Completed",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    "$urgency - Care suggested",
                    style: TextStyle(color: urgencyColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            
            // Suggestions block
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.primaryActive, size: 20),
                SizedBox(width: 8),
                Text("Self-care Suggestions", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 8),
            ...listSuggestions.map((sug) => Padding(
              padding: const EdgeInsets.only(left: 28.0, bottom: 6.0),
              child: Text("• $sug", style: const TextStyle(color: AppColors.textMuted)),
            )),
            const SizedBox(height: 16),

            // Warning block
            if (listWarnings.isNotEmpty) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppColors.emergency.withOpacity(0.04),
                  border: Border.all(color: AppColors.emergency.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 18),
                        SizedBox(width: 8),
                        Text("When to see a doctor", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emergency)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ...listWarnings.map((warn) => Padding(
                      padding: const EdgeInsets.only(left: 26.0, bottom: 4.0),
                      child: Text("• $warn", style: const TextStyle(color: AppColors.textDark, fontSize: 13)),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Text(
              _analysisResult?["disclaimer"] ?? "",
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVitalsSubcards() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.favorite, color: AppColors.emergency, size: 20),
                  SizedBox(height: 8),
                  Text("Heart Rate", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text("72 bpm", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.nightlight_round, color: AppColors.primaryActive, size: 20),
                  SizedBox(height: 8),
                  Text("Sleep Quality", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  Text("Good", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Medication Tab UI ---
  Widget _buildMedicationTab() {
    final medications = ref.watch(medicationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationDialog,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: medications.isEmpty
          ? const Center(child: Text("No medications added yet", style: TextStyle(color: AppColors.textMuted)))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: medications.length,
              itemBuilder: (context, index) {
                final med = medications[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: med.isTaken ? AppColors.success.withOpacity(0.1) : AppColors.lavender,
                      child: Icon(
                        Icons.medication,
                        color: med.isTaken ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${med.dosage} • Scheduled: ${med.time}"),
                    trailing: Checkbox(
                      value: med.isTaken,
                      activeColor: AppColors.success,
                      onChanged: (val) {
                        ref.read(medicationProvider.notifier).toggleTaken(index);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- History Tab UI ---
  Widget _buildHistoryTab() {
    final logs = _historyLogs;

    return logs.isEmpty
        ? const Center(child: Text("No health entries logged yet", style: TextStyle(color: AppColors.textMuted)))
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              Color uColor = AppColors.success;
              if (log["urgency"] == "Medium") uColor = AppColors.warning;
              if (log["urgency"] == "High") uColor = AppColors.emergency;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 48,
                        decoration: BoxDecoration(
                          color: uColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log["symptoms"],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Urgency: ${log["urgency"]} • ${log["timestamp"].toString().split('T')[0]}",
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
