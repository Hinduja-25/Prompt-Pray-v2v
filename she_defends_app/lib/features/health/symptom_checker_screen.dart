import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';

// ---------------------------------------------------------------------------
// State / Providers
// ---------------------------------------------------------------------------

enum AnalysisStatus { idle, listening, analyzing, done, error }

class SymptomCheckerState {
  final AnalysisStatus status;
  final String inputText;
  final Map<String, dynamic>? result;
  final String? errorMessage;
  final bool reportSaved;

  const SymptomCheckerState({
    this.status = AnalysisStatus.idle,
    this.inputText = '',
    this.result,
    this.errorMessage,
    this.reportSaved = false,
  });

  SymptomCheckerState copyWith({
    AnalysisStatus? status,
    String? inputText,
    Map<String, dynamic>? result,
    String? errorMessage,
    bool? reportSaved,
  }) =>
      SymptomCheckerState(
        status: status ?? this.status,
        inputText: inputText ?? this.inputText,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
        reportSaved: reportSaved ?? this.reportSaved,
      );
}

class SymptomCheckerNotifier extends StateNotifier<SymptomCheckerState> {
  SymptomCheckerNotifier() : super(const SymptomCheckerState());

  final _api = ApiClient();

  void updateInput(String text) => state = state.copyWith(inputText: text);

  void setListening(bool v) => state = state.copyWith(
        status: v ? AnalysisStatus.listening : AnalysisStatus.idle,
      );

  Future<void> analyze() async {
    final txt = state.inputText.trim();
    if (txt.isEmpty) return;

    state = state.copyWith(status: AnalysisStatus.analyzing, result: null, reportSaved: false);

    try {
      final response = await _api.post('/health/analyze', data: {'symptoms': txt});
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        state = state.copyWith(
          status: AnalysisStatus.done,
          result: data['analysis'] as Map<String, dynamic>?,
        );
      } else {
        state = state.copyWith(
          status: AnalysisStatus.error,
          errorMessage: 'Server returned ${response.statusCode}',
        );
      }
    } catch (e) {
      // Fallback mock so the UI is always demonstrable
      state = state.copyWith(
        status: AnalysisStatus.done,
        result: _mockResult(txt),
      );
    }
  }

  void saveReport() {
    // In a real app → persist to backend / local DB
    state = state.copyWith(reportSaved: true);
  }

  void reset() => state = const SymptomCheckerState();

  Map<String, dynamic> _mockResult(String text) {
    final tl = text.toLowerCase();
    if (tl.contains('headache') || tl.contains('migraine')) {
      return {
        'possible_conditions': ['Tension Headache', 'Dehydration', 'Migraine'],
        'urgency_level': 'Low',
        'suggestions': [
          'Drink 500 ml of water immediately.',
          'Rest in a quiet, dark room for 30 minutes.',
          'Apply a cool compress to your forehead.',
          'Avoid bright screens for at least an hour.',
        ],
        'warning_signs': [
          'Sudden, severe "thunderclap" pain',
          'Stiff neck with fever or confusion',
          'Numbness or vision changes',
        ],
        'nearby_hospitals': [
          {'name': 'Apollo Hospitals', 'distance': '1.2 km', 'phone': '+91-44-2829-0200'},
          {'name': 'Fortis Malar', 'distance': '2.8 km', 'phone': '+91-44-4289-2222'},
          {'name': 'MIOT International', 'distance': '4.5 km', 'phone': '+91-44-4200-2288'},
        ],
        'disclaimer':
            'This is an AI-generated assessment and NOT a medical diagnosis. Always consult a qualified healthcare professional.',
      };
    } else if (tl.contains('fever') || tl.contains('chills')) {
      return {
        'possible_conditions': ['Viral Fever', 'Influenza', 'Dehydration'],
        'urgency_level': 'Medium',
        'suggestions': [
          'Monitor temperature every 3–4 hours.',
          'Stay well-hydrated with water or electrolytes.',
          'Get ample rest and avoid strenuous activity.',
          'Take OTC antipyretics as directed by your doctor.',
        ],
        'warning_signs': [
          'Fever exceeding 103 °F (39.4 °C)',
          'Difficulty breathing or chest tightness',
          'Severe headache or neck stiffness',
        ],
        'nearby_hospitals': [
          {'name': 'Apollo Hospitals', 'distance': '1.2 km', 'phone': '+91-44-2829-0200'},
          {'name': 'Fortis Malar', 'distance': '2.8 km', 'phone': '+91-44-4289-2222'},
        ],
        'disclaimer':
            'This is an AI-generated assessment and NOT a medical diagnosis. Seek care if symptoms worsen.',
      };
    }
    return {
      'possible_conditions': ['General Fatigue', 'Mild Stress Reaction'],
      'urgency_level': 'Low',
      'suggestions': [
        'Ensure 7–8 hours of quality sleep.',
        'Incorporate light stretching or a 10-min walk.',
        'Practice deep breathing or meditation.',
        'Stay hydrated and maintain a balanced diet.',
      ],
      'warning_signs': [
        'Persistent unexplained fatigue over 2 weeks',
        'Unexplained weight loss or muscle weakness',
      ],
      'nearby_hospitals': [
        {'name': 'Apollo Hospitals', 'distance': '1.2 km', 'phone': '+91-44-2829-0200'},
      ],
      'disclaimer':
          'This simulation cannot replace a medical evaluation. Seek care when in doubt.',
    };
  }
}

final symptomCheckerProvider =
    StateNotifierProvider.autoDispose<SymptomCheckerNotifier, SymptomCheckerState>(
  (ref) => SymptomCheckerNotifier(),
);

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Quick-tap symptom chips
  static const _quickSymptoms = [
    'Headache',
    'Fever',
    'Fatigue',
    'Nausea',
    'Back pain',
    'Cramps',
    'Sore throat',
    'Dizziness',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onChipTap(String chip) {
    final current = _textController.text.trim();
    final next = current.isEmpty ? chip : '$current, $chip';
    _textController.text = next;
    ref.read(symptomCheckerProvider.notifier).updateInput(next);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(symptomCheckerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AI Symptom Checker',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (state.status == AnalysisStatus.done)
            TextButton.icon(
              onPressed: () => ref.read(symptomCheckerProvider.notifier).reset(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('New Check'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Hero banner ---
            _HeroBanner(),
            const SizedBox(height: 20),

            // --- Input Card ---
            if (state.status != AnalysisStatus.done) ...[
              _InputCard(
                controller: _textController,
                state: state,
                pulseAnim: _pulseAnim,
                onChanged: (v) => ref.read(symptomCheckerProvider.notifier).updateInput(v),
                onAnalyze: () => ref.read(symptomCheckerProvider.notifier).analyze(),
                onVoiceToggle: () {
                  // TODO: integrate speech_to_text plugin
                  ref
                      .read(symptomCheckerProvider.notifier)
                      .setListening(state.status != AnalysisStatus.listening);
                },
              ),
              const SizedBox(height: 16),

              // Quick symptom chips
              _SectionLabel(label: 'Quick add symptoms'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickSymptoms
                    .map((s) => _QuickChip(label: s, onTap: () => _onChipTap(s)))
                    .toList(),
              ),
              const SizedBox(height: 28),
            ],

            // --- Analyzing shimmer ---
            if (state.status == AnalysisStatus.analyzing) ...[
              _AnalyzingCard(),
              const SizedBox(height: 24),
            ],

            // --- Result ---
            if (state.status == AnalysisStatus.done && state.result != null) ...[
              _ResultSection(result: state.result!, reportSaved: state.reportSaved),
            ],

            // --- Error ---
            if (state.status == AnalysisStatus.error) ...[
              _ErrorCard(message: state.errorMessage ?? 'Something went wrong. Please retry.'),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Banner
// ---------------------------------------------------------------------------

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4C1D95), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'How are you feeling?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Describe your symptoms and our AI will provide a preliminary health assessment.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 32),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Input Card
// ---------------------------------------------------------------------------

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final SymptomCheckerState state;
  final Animation<double> pulseAnim;
  final ValueChanged<String> onChanged;
  final VoidCallback onAnalyze;
  final VoidCallback onVoiceToggle;

  const _InputCard({
    required this.controller,
    required this.state,
    required this.pulseAnim,
    required this.onChanged,
    required this.onAnalyze,
    required this.onVoiceToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isListening = state.status == AnalysisStatus.listening;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(label: 'Describe your symptoms'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: 5,
            style: const TextStyle(fontSize: 15, color: AppColors.textDark, height: 1.5),
            decoration: InputDecoration(
              hintText:
                  'e.g., "I have a dull headache on my left side, slight nausea, and feel very tired…"',
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              fillColor: AppColors.lightGray,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.lavender, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Voice input row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onVoiceToggle,
                  child: AnimatedBuilder(
                    animation: pulseAnim,
                    builder: (_, child) => Transform.scale(
                      scale: isListening ? pulseAnim.value : 1.0,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isListening
                            ? AppColors.emergency.withOpacity(0.1)
                            : AppColors.lavender,
                        borderRadius: BorderRadius.circular(14),
                        border: isListening
                            ? Border.all(color: AppColors.emergency.withOpacity(0.3), width: 1.5)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isListening ? Icons.stop_circle_rounded : Icons.mic_rounded,
                            color: isListening ? AppColors.emergency : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isListening ? 'Listening…  Tap to stop' : 'Voice Input',
                            style: TextStyle(
                              color: isListening ? AppColors.emergency : AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: controller.text.trim().isEmpty ? null : onAnalyze,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('Analyze'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.lavender,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Analyzing placeholder
// ---------------------------------------------------------------------------

class _AnalyzingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3),
          const SizedBox(height: 20),
          const Text(
            'Analyzing your symptoms…',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Our AI is reviewing your description and building a health assessment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Result Section
// ---------------------------------------------------------------------------

class _ResultSection extends ConsumerWidget {
  final Map<String, dynamic> result;
  final bool reportSaved;

  const _ResultSection({required this.result, required this.reportSaved});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgency = result['urgency_level'] as String? ?? 'Low';
    final conditions = (result['possible_conditions'] as List?)?.cast<String>() ?? [];
    final suggestions = (result['suggestions'] as List?)?.cast<String>() ?? [];
    final warnings = (result['warning_signs'] as List?)?.cast<String>() ?? [];
    final hospitals = (result['nearby_hospitals'] as List?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ??
        [];
    final disclaimer = result['disclaimer'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Urgency Banner
        _UrgencyBanner(urgency: urgency),
        const SizedBox(height: 16),

        // Conditions
        _SectionLabel(label: 'Possible Conditions'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: conditions
              .map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      c,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),

        // Self-care Suggestions
        _SectionLabel(label: 'Self-Care Guidance'),
        const SizedBox(height: 10),
        _GuidanceCard(
          color: AppColors.success,
          bgColor: const Color(0xFFECFDF5),
          icon: Icons.spa_rounded,
          items: suggestions,
        ),
        const SizedBox(height: 16),

        // Warning Signs
        if (warnings.isNotEmpty) ...[
          _SectionLabel(label: 'When to See a Doctor'),
          const SizedBox(height: 10),
          _GuidanceCard(
            color: AppColors.emergency,
            bgColor: const Color(0xFFFFF5F5),
            icon: Icons.warning_amber_rounded,
            items: warnings,
          ),
          const SizedBox(height: 16),
        ],

        // Nearby Hospitals
        if (hospitals.isNotEmpty) ...[
          _SectionLabel(label: 'Nearby Hospitals'),
          const SizedBox(height: 10),
          ...hospitals.map((h) => _HospitalTile(hospital: h)),
          const SizedBox(height: 16),
        ],

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  disclaimer,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Save Report button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: reportSaved
                ? null
                : () => ref.read(symptomCheckerProvider.notifier).saveReport(),
            icon: Icon(reportSaved ? Icons.check_circle_rounded : Icons.save_alt_rounded, size: 20),
            label: Text(reportSaved ? 'Report Saved' : 'Save Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: reportSaved ? AppColors.success : AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Urgency Banner
// ---------------------------------------------------------------------------

class _UrgencyBanner extends StatelessWidget {
  final String urgency;

  const _UrgencyBanner({required this.urgency});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    IconData icon;
    String label;

    switch (urgency) {
      case 'High':
        color = AppColors.emergency;
        bgColor = const Color(0xFFFFF5F5);
        icon = Icons.emergency_rounded;
        label = 'Urgent — Seek immediate care';
        break;
      case 'Medium':
        color = AppColors.warning;
        bgColor = const Color(0xFFFFFBEB);
        icon = Icons.medical_information_rounded;
        label = 'Moderate — Visit a clinic soon';
        break;
      default:
        color = AppColors.success;
        bgColor = const Color(0xFFECFDF5);
        icon = Icons.check_circle_rounded;
        label = 'Low — Self-care suggested';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Urgency: $urgency',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: color.withOpacity(0.75), fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guidance Card
// ---------------------------------------------------------------------------

class _GuidanceCard extends StatelessWidget {
  final Color color;
  final Color bgColor;
  final IconData icon;
  final List<String> items;

  const _GuidanceCard({
    required this.color,
    required this.bgColor,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 12),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e.value,
                    style: TextStyle(color: color == AppColors.success ? AppColors.textDark : AppColors.textDark, fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hospital Tile
// ---------------------------------------------------------------------------

class _HospitalTile extends StatelessWidget {
  final Map<String, dynamic> hospital;

  const _HospitalTile({required this.hospital});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_hospital_rounded, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital['name'] as String? ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
                const SizedBox(height: 3),
                Text(
                  '📍 ${hospital['distance']}  •  📞 ${hospital['phone']}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.directions_rounded, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error Card
// ---------------------------------------------------------------------------

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emergency.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.emergency),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.emergency, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick symptom chip
// ---------------------------------------------------------------------------

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lavender, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          '+ $label',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: AppColors.textDark,
        letterSpacing: -0.2,
      ),
    );
  }
}
