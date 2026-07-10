import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:she_defends_app/core/theme/app_theme.dart';
import 'package:she_defends_app/core/network/api_client.dart';

class SymptomCheckerScreen extends ConsumerStatefulWidget {
  const SymptomCheckerScreen({super.key});

  @override
  ConsumerState<SymptomCheckerScreen> createState() => _SymptomCheckerScreenState();
}

class _SymptomCheckerScreenState extends ConsumerState<SymptomCheckerScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _analysisResult;
  final _api = ApiClient();

  Future<void> _analyzeSymptoms() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _analysisResult = null;
    });

    try {
      final response = await _api.post('/health/analyze', data: {'symptoms': text});
      if (response.statusCode == 200) {
        setState(() {
          _analysisResult = response.data['analysis'] as Map<String, dynamic>?;
        });
      } else {
        _setMockResult();
      }
    } catch (_) {
      _setMockResult();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setMockResult() {
    setState(() {
      _analysisResult = {
        'possible_conditions': ['Possible Tension Headache', 'Mild Dehydration'],
        'urgency_level': 'Low',
        'severity_level': 'Mild',
        'should_visit_doctor': false,
        'doctor_advice_message': 'A doctor visit is not immediately required. Try hydrating and resting first.',
        'nutrition_recommendations': [
          'Drink 500ml of water immediately (dehydration is a primary headache trigger).',
          'Drink a cup of ginger tea or peppermint tea to reduce tension.',
          'Consume magnesium-rich foods like almonds or spinach to ease blood vessels.'
        ],
        'suggestions': [
          'Hydrate, rest in a dark room, monitor for 2 hours.'
        ],
        'warning_signs': [
          'If pain worsens or you experience vision changes, please seek professional medical attention immediately.'
        ]
      };
    });
  }

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
          'Health Checker',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
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
            const Text(
              "Describe how you're\nfeeling...",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: TextField(
                controller: _controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "e.g., I have a headache and feel nauseous",
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _analyzeSymptoms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: const Text(
                  'Analyze',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_analysisResult != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final conditions = _analysisResult!['possible_conditions'] as List? ?? [];
    final mainCondition = conditions.isNotEmpty ? conditions.first : "Condition Found";
    final urgency = _analysisResult!['urgency_level'] ?? "Low";
    final severity = _analysisResult!['severity_level'] ?? "Mild";
    final shouldVisitDoctor = _analysisResult!['should_visit_doctor'] as bool? ?? false;
    final doctorAdviceMessage = _analysisResult!['doctor_advice_message'] ?? "";
    final nutritionRecs = _analysisResult!['nutrition_recommendations'] as List? ?? [];
    final suggestions = _analysisResult!['suggestions'] as List? ?? [];
    final warningSigns = _analysisResult!['warning_signs'] as List? ?? [];

    Color severityColor;
    if (severity == 'Severe') {
      severityColor = AppColors.emergency;
    } else if (severity == 'Moderate') {
      severityColor = Colors.orange;
    } else {
      severityColor = AppColors.success;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
            children: [
              Expanded(
                child: Text(
                  mainCondition,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const Icon(Icons.more_vert, color: AppColors.textMuted),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Urgency: $urgency",
                  style: const TextStyle(
                    color: AppColors.primaryActive,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Severity: $severity",
                  style: TextStyle(
                    color: severityColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Doctor Consultation recommendation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: shouldVisitDoctor ? const Color(0xFFFFF5F5) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: shouldVisitDoctor ? const Color(0xFFFEE2E2) : const Color(0xFFA7F3D0),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  shouldVisitDoctor ? Icons.local_hospital : Icons.health_and_safety,
                  color: shouldVisitDoctor ? AppColors.emergency : AppColors.success,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shouldVisitDoctor
                            ? "Doctor Consultation Recommended"
                            : "Self-Care & Home Recovery Indicated",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: shouldVisitDoctor ? AppColors.emergency : AppColors.textDark,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctorAdviceMessage,
                        style: TextStyle(
                          color: shouldVisitDoctor ? AppColors.emergency.withValues(alpha: 0.8) : AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI Nutrition & recovery diet Card
          if (nutritionRecs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.restaurant, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "AI Nutrition Recommendations",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...nutritionRecs.map((rec) => Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("• ", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                            Expanded(
                              child: Text(
                                rec.toString(),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (suggestions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Self-Care Checklist",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    suggestions.first,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          if (warningSigns.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFEE2E2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: AppColors.emergency, size: 18),
                      SizedBox(width: 8),
                      Text(
                        "When to seek immediate emergency care",
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.emergency),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    warningSigns.first,
                    style: const TextStyle(color: AppColors.emergency, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
